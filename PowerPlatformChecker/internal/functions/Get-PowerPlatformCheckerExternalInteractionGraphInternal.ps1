function Get-PowerPlatformCheckerExternalInteractionGraphInternal {
    <#
    .SYNOPSIS
        Builds a condensed external interaction graph for selected solution paths.

    .DESCRIPTION
        Produces one internal solution node per source solution and aggregates
        directional interaction edges from solution nodes to external targets.

    .PARAMETER FilteredSolutionPaths
        Resolved and filtered solution paths.

    .PARAMETER Direction
        Graph direction metadata.

    .EXAMPLE
        Build a condensed graph from resolved solution paths.

        PS> Get-PowerPlatformCheckerExternalInteractionGraphInternal -FilteredSolutionPaths @($path) -Direction LR
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $FilteredSolutionPaths,

        [Parameter(Mandatory = $true)]
        [ValidateSet('LR', 'RL', 'TB', 'BT')]
        [string] $Direction
    )

    $combinedNodes = [System.Collections.Generic.List[object]]::new()
    $combinedEdges = [System.Collections.Generic.List[object]]::new()
    $styles = @{}
    $styleOrder = @()

    $getInteractionLabel = {
        param([string] $Direction)

        switch ([string]$Direction) {
            'Read' { return 'GET' }
            'Write' { return 'SET' }
            'Mixed' { return 'GET/SET' }
            default { return 'Unknown' }
        }
    }

    $mergeInteractionLabels = {
        param([string[]] $Labels)

        $normalized = @($Labels | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Select-Object -Unique)
        if ($normalized -contains 'GET/SET') {
            return 'GET/SET'
        }

        if (($normalized -contains 'GET') -and ($normalized -contains 'SET')) {
            return 'GET/SET'
        }

        if ($normalized.Count -eq 1) {
            return [string]$normalized[0]
        }

        if ($normalized.Count -eq 0) {
            return 'Unknown'
        }

        return (($normalized | Sort-Object) -join '/')
    }

    foreach ($solutionPath in $FilteredSolutionPaths) {
        $graph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $solutionPath -Direction $Direction -OutputFormat Graph -IncludeElements @('Flows','CanvasApps','ModelDrivenApps','Connections','Entities','DefaultEntities','WebResources','ExternalDomains')

        $solutionName = [System.IO.Path]::GetFileName([string]$solutionPath)
        $solutionNodeId = "solution_{0}" -f (Convert-PowerPlatformCheckerMermaidId -InputString $solutionName)
        if (-not ($combinedNodes | Where-Object { $_.Id -eq $solutionNodeId })) {
            [void]$combinedNodes.Add([pscustomobject]@{
                    Id = $solutionNodeId
                    Type = 'Solution'
                    DisplayName = $solutionName
                    ClassKind = 'Solution'
                    Properties = @{}
                    Members = @()
                    HasExplicitDisplayName = $true
                })
        }

        $nodeById = @{}
        foreach ($node in @($graph.Nodes)) {
            $nodeById[[string]$node.Id] = $node
        }

        $interactionByTarget = @{}
        $targetNodeById = @{}

        foreach ($edge in @($graph.Edges)) {
            $sourceNode = $nodeById[[string]$edge.SourceId]
            $targetNode = $nodeById[[string]$edge.TargetId]

            if ($null -eq $sourceNode -or $null -eq $targetNode) {
                continue
            }

            if ([string]$sourceNode.Type -eq 'Connection' -and [string]$targetNode.Type -in @('Flow', 'CanvasApp', 'ModelDrivenApp')) {
                $interactionLabel = & $getInteractionLabel -Direction ([string]$targetNode.Properties.InteractionDirection)
                $targetId = [string]$sourceNode.Id
                if (-not $interactionByTarget.ContainsKey($targetId)) {
                    $interactionByTarget[$targetId] = [System.Collections.Generic.List[string]]::new()
                }
                [void]$interactionByTarget[$targetId].Add($interactionLabel)
                $targetNodeById[$targetId] = $sourceNode
                continue
            }

            if ([string]$targetNode.Type -eq 'ExternalDomain' -and [string]$sourceNode.Type -in @('Flow', 'CanvasApp', 'ModelDrivenApp', 'WebResource')) {
                $interactionLabel = & $getInteractionLabel -Direction ([string]$sourceNode.Properties.InteractionDirection)
                $targetId = [string]$targetNode.Id
                if (-not $interactionByTarget.ContainsKey($targetId)) {
                    $interactionByTarget[$targetId] = [System.Collections.Generic.List[string]]::new()
                }
                [void]$interactionByTarget[$targetId].Add($interactionLabel)
                $targetNodeById[$targetId] = $targetNode
            }
        }

        foreach ($flowNode in @($graph.Nodes | Where-Object { $_.Type -eq 'Flow' })) {
            $destination = [string]$flowNode.Properties.Destination
            if ([string]::IsNullOrWhiteSpace($destination) -or $destination -eq 'Unknown') {
                continue
            }

            $destinationType = [string]$flowNode.Properties.DestinationType
            $interactionLabel = & $getInteractionLabel -Direction ([string]$flowNode.Properties.InteractionDirection)
            if ($destinationType -eq 'Domain') {
                $targetId = "externaldomain_{0}" -f (Convert-PowerPlatformCheckerMermaidId -InputString $destination)
                $targetNodeById[$targetId] = [pscustomobject]@{
                    Id = $targetId
                    Type = 'ExternalDomain'
                    DisplayName = $destination
                    ClassKind = 'ExternalDomain'
                    Properties = @{}
                    Members = @()
                    HasExplicitDisplayName = $true
                }
            }
            else {
                $targetId = "connection_{0}" -f (Convert-PowerPlatformCheckerMermaidId -InputString $destination)
                $targetNodeById[$targetId] = [pscustomobject]@{
                    Id = $targetId
                    Type = 'Connection'
                    DisplayName = $destination
                    ClassKind = 'Connection'
                    Properties = @{}
                    Members = @()
                    HasExplicitDisplayName = $true
                }
            }

            if (-not $interactionByTarget.ContainsKey($targetId)) {
                $interactionByTarget[$targetId] = [System.Collections.Generic.List[string]]::new()
            }
            [void]$interactionByTarget[$targetId].Add($interactionLabel)
        }

        foreach ($targetId in @($interactionByTarget.Keys | Sort-Object)) {
            $targetNode = $targetNodeById[$targetId]
            if ($null -eq $targetNode) {
                continue
            }

            if (-not ($combinedNodes | Where-Object { $_.Id -eq $targetId })) {
                [void]$combinedNodes.Add($targetNode)
            }

            $edgeLabel = & $mergeInteractionLabels -Labels @($interactionByTarget[$targetId])
            $edgeKey = "{0}|{1}|{2}|-->" -f $solutionNodeId, [string]$targetId, $edgeLabel
            $existingEdge = $combinedEdges | Where-Object {
                ("{0}|{1}|{2}|{3}" -f [string]$_.SourceId, [string]$_.TargetId, [string]$_.Label, [string]$_.Metadata.Arrow) -eq $edgeKey
            }

            if (-not $existingEdge) {
                [void]$combinedEdges.Add([pscustomobject]@{
                        SourceId = $solutionNodeId
                        TargetId = [string]$targetId
                        Label = $edgeLabel
                        EdgeType = 'Link'
                        Metadata = [pscustomobject]@{ Arrow = '-->' }
                    })
            }
        }

        if ($styles.Count -eq 0 -and $graph.Styles) {
            $styles = @{}
            foreach ($styleKey in $graph.Styles.Keys) {
                $styles[$styleKey] = [string]$graph.Styles[$styleKey]
            }
        }

        if ($styleOrder.Count -eq 0 -and $graph.StyleOrder) {
            $styleOrder = @($graph.StyleOrder)
        }
    }

    if (-not $styles.ContainsKey('Solution')) {
        $styles['Solution'] = 'fill:#f5f5f5,stroke:#111111,stroke-width:2px;'
    }
    if ($styleOrder -notcontains 'Solution') {
        $styleOrder += 'Solution'
    }

    return [pscustomobject]@{
        Metadata = [pscustomobject]@{
            Direction = $Direction
            IncludeElements = @('Flows','CanvasApps','ModelDrivenApps','Connections','Entities','DefaultEntities','WebResources','ExternalDomains')
            OutputFormat = 'Graph'
            SourceSolutions = @($FilteredSolutionPaths)
            SourceSolutionCount = @($FilteredSolutionPaths).Count
            IsScopedDiagram = $false
            SourceFilterType = 'None'
            SourceFilterValue = ''
        }
        Nodes = @($combinedNodes)
        Edges = @($combinedEdges)
        Styles = $styles
        StyleOrder = @($styleOrder)
    }
}
