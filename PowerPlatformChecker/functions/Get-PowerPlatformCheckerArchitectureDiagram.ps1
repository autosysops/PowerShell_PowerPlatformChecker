function Get-PowerPlatformCheckerArchitectureDiagram {
    <#
    .SYNOPSIS
        Generates a Mermaid class diagram for a Power Platform solution.

    .DESCRIPTION
        Produces markdown containing a Mermaid classDiagram based on flows, environment variables,
        connection references, entities, canvas apps, model-driven apps, and JavaScript web resources.
        When a flow, canvas app, or model-driven app filter is used, the diagram is scoped to the
        directly connected components for that selected item.

    .PARAMETER SolutionPath
        The root path of the unpacked solution.

    .PARAMETER FlowId
        Optional flow id filter.

    .PARAMETER CanvasAppName
        Optional canvas app internal name filter.

    .PARAMETER ModelDrivenAppName
        Optional model-driven app unique name filter.

    .PARAMETER Direction
        Mermaid layout direction. Default is Left-to-Right (`LR`).

    .PARAMETER IncludeElements
        Which diagram element groups to include. Defaults to all groups.

    .PARAMETER OutputFormat
        Output format to return: Mermaid markdown text (default) or parsed Graph object.

    .PARAMETER StyleOverrides
        Optional hashtable to override default color values for class definitions.

    .EXAMPLE
        Generate a full architecture diagram markdown block for a solution.

        PS> Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath "C:\Solutions\MySolution"

    .EXAMPLE
        Generate an architecture diagram scoped to a single flow.

        PS> Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath "C:\Solutions\MySolution" -FlowId "00000000-0000-0000-0000-000000000000"

    .EXAMPLE
        Generate an architecture diagram with top-to-bottom layout.

        PS> Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath "C:\Solutions\MySolution" -Direction TB

    .EXAMPLE
        Generate a flow-only architecture view (exclude apps/entities/connections).

        PS> Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath "C:\Solutions\MySolution" -IncludeElements Flows

    .EXAMPLE
        Override diagram colors for this call only.

        PS> $style = @{ Flow = '#4CC9F0'; Connection = '#FFD166'; Stroke = '#2B2D42' }
        PS> Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath "C:\Solutions\MySolution" -StyleOverrides $style
    #>

    [CmdletBinding(DefaultParameterSetName = "NoFilter")]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "NoFilter")]
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "FilterByFlow")]
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "FilterByCanvasApp")]
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "FilterByModelDrivenApp")]
        [string] $SolutionPath,

        [Parameter(Mandatory = $true, Position = 2, ParameterSetName = "FilterByFlow")]
        [string] $FlowId,

        [Parameter(Mandatory = $true, Position = 2, ParameterSetName = "FilterByCanvasApp")]
        [string] $CanvasAppName,

        [Parameter(Mandatory = $true, Position = 2, ParameterSetName = "FilterByModelDrivenApp")]
        [string] $ModelDrivenAppName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("LR", "RL", "TB", "BT")]
        [string] $Direction = "LR",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Flows", "CanvasApps", "ModelDrivenApps", "EnvironmentVariables", "Connections", "Entities", "DefaultEntities", "WebResources")]
        [string[]] $IncludeElements = @("Flows", "CanvasApps", "ModelDrivenApps", "EnvironmentVariables", "Connections", "Entities", "DefaultEntities", "WebResources"),

        [Parameter(Mandatory = $false)]
        [ValidateSet("Mermaid", "Graph")]
        [string] $OutputFormat = "Mermaid",

        [Parameter(Mandatory = $false)]
        [hashtable] $StyleOverrides
    )

    $telemetryProperties = @{
        ParameterSet = $PSCmdlet.ParameterSetName
        HasFlowFilter = $PSBoundParameters.ContainsKey("FlowId")
        HasCanvasFilter = $PSBoundParameters.ContainsKey("CanvasAppName")
        HasModelDrivenFilter = $PSBoundParameters.ContainsKey("ModelDrivenAppName")
        Direction = $Direction
        OutputFormat = $OutputFormat
        IncludeElements = (($IncludeElements | Sort-Object -Unique) -join ",")
        HasStyleOverrides = $PSBoundParameters.ContainsKey("StyleOverrides")
    }
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerArchitectureDiagram" -PropertiesHash $telemetryProperties

    $newline = [Environment]::NewLine
    $diagram = ""
    $diagram += ":::mermaid$newline"
    $diagram += "classDiagram$newline"
    $diagram += "direction $Direction$newline"

    $includePolicy = Get-PowerPlatformCheckerDiagramIncludePolicy `
        -IncludeElements $IncludeElements `
        -HasFlowFilter:$($PSBoundParameters.ContainsKey("FlowId")) `
        -HasCanvasFilter:$($PSBoundParameters.ContainsKey("CanvasAppName")) `
        -HasModelDrivenFilter:$($PSBoundParameters.ContainsKey("ModelDrivenAppName"))

    # Resolve include flags once so downstream blocks can stay readable.
    $includeFlows = $includePolicy.IncludeFlows
    $includeModelDrivenApps = $includePolicy.IncludeModelDrivenApps
    $includeEnvVars = $includePolicy.IncludeEnvironmentVariables
    $includeConnections = $includePolicy.IncludeConnections
    $includeEntities = $includePolicy.IncludeEntities
    $includeDefaultEntities = $includePolicy.IncludeDefaultEntities
    $includeWebResources = $includePolicy.IncludeWebResources

    # Start from module defaults and apply per-call style overrides if provided.
    $style = @{}
    foreach ($key in $script:PowerPlatformCheckerDiagramColors.Keys) {
        $style[$key] = $script:PowerPlatformCheckerDiagramColors[$key]
    }
    if ($PSBoundParameters.ContainsKey("StyleOverrides")) {
        foreach ($key in $StyleOverrides.Keys) {
            if ($style.ContainsKey($key) -and -not [string]::IsNullOrWhiteSpace([string]$StyleOverrides[$key])) {
                $style[$key] = [string]$StyleOverrides[$key]
            }
        }
    }

    $solutionObject = Get-PowerPlatformCheckerSolutionObject -SolutionPath $SolutionPath
    $isScopedDiagram = $includePolicy.IsScopedDiagram

    # Resolve logical/entity names to the canonical entity set id so links remain stable across
    # casing/singular/plural variants. Downstream diagram code should only need to work with one id.
    $entitySetByReference = @{}
    $entityByLogicalName = @{}
    $entityBySetName = @{}
    $renderedEntityNodeIds = @()
    foreach ($entity in @($solutionObject.Entities)) {
        if (-not $entity -or [string]::IsNullOrWhiteSpace([string]$entity.EntitySetName)) {
            continue
        }

        $entitySetName = [string]$entity.EntitySetName.Trim().ToLower()
        $entitySetByReference[$entitySetName] = $entitySetName
        $entityBySetName[$entitySetName] = $entity

        if (-not [string]::IsNullOrWhiteSpace([string]$entity.Name)) {
            $entityLogicalName = [string]$entity.Name.ToLower()
            $entitySetByReference[$entityLogicalName] = $entitySetName
            $entityByLogicalName[$entityLogicalName] = $entity
        }
    }
    $modelApps = Get-PowerPlatformCheckerDiagramModelDrivenApps `
        -SolutionPath $SolutionPath `
        -IncludePolicy $includePolicy `
        -HasFlowFilter:$($PSBoundParameters.ContainsKey("FlowId")) `
        -HasCanvasFilter:$($PSBoundParameters.ContainsKey("CanvasAppName")) `
        -ModelDrivenAppName $ModelDrivenAppName

    # If model-driven app filtering is used, only include flows referenced by selected apps.
    # The app metadata already identifies those flow ids, so this becomes the authoritative filter.
    $modelDrivenFlowFilter = @($modelApps | ForEach-Object { $_.FlowIds } | Sort-Object -Unique)
    $preConnectedEntities = @()
    if ($PSBoundParameters.ContainsKey("ModelDrivenAppName") -and $includeEntities) {
        foreach ($modelApp in @($modelApps)) {
            foreach ($entityName in @($modelApp.Entities)) {
                $resolvedEntitySet = Get-PowerPlatformCheckerArchitectureDiagramEntitySetName -EntityReference ([string]$entityName) -EntitySetByReference $entitySetByReference
                if ($resolvedEntitySet) {
                    $preConnectedEntities += $resolvedEntitySet
                }
            }
        }
    }
    $webResourceData = Get-PowerPlatformCheckerDiagramWebResources `
        -SolutionPath $SolutionPath `
        -SolutionObject $solutionObject `
        -IncludePolicy $includePolicy `
        -HasModelDrivenFilter:$($PSBoundParameters.ContainsKey("ModelDrivenAppName")) `
        -ModelApps $modelApps

    $webResources = @($webResourceData.WebResources)
    $iconResources = @($webResourceData.IconResources)

    $links = @()
    $connectedEnvVars = @()
    $connectedConnections = @()
    $connectedEntities = @($preConnectedEntities)
    $connectedDefaultEntities = @()
    $connectedIconResources = @()

    # Keep system fields in one helper so filtering rules are reusable and easy to maintain.
    $defaultFields = Get-PowerPlatformCheckerDefaultEntityFieldName
    $entitySetNames = @($solutionObject.Entities | Where-Object { $_ -and $_.EntitySetName } | ForEach-Object { $_.EntitySetName.ToLower() })

    $flowsToRender = Get-PowerPlatformCheckerDiagramFlows `
        -SolutionObject $solutionObject `
        -IncludePolicy $includePolicy `
        -HasCanvasFilter:$($PSBoundParameters.ContainsKey("CanvasAppName")) `
        -HasFlowFilter:$($PSBoundParameters.ContainsKey("FlowId")) `
        -HasModelDrivenFilter:$($PSBoundParameters.ContainsKey("ModelDrivenAppName")) `
        -FlowId $FlowId `
        -ModelDrivenFlowFilter $modelDrivenFlowFilter

    # Flow nodes are only rendered when flow inclusion is enabled and canvas-only filtering is not active.
    # Collect the visible members for each flow first so we can avoid emitting an empty Mermaid class body.
    # Mermaid accepts `class Node["Label"]:::Type`, but rejects `class Node["Label"]:::Type {}`.
    $flowDiagramContent = Get-PowerPlatformCheckerFlowDiagramContent `
        -FlowsToRender $flowsToRender `
        -SolutionPath $SolutionPath `
        -SolutionObject $solutionObject `
        -EntitySetByReference $entitySetByReference `
        -IncludeFlows:$includeFlows `
        -IncludeEnvironmentVariables:$includeEnvVars `
        -IncludeConnections:$includeConnections `
        -IncludeEntities:$includeEntities `
        -HasFlowFilter:$($PSBoundParameters.ContainsKey("FlowId")) `
        -FlowId $FlowId `
        -NewLine $newline

    $diagram += [string]$flowDiagramContent.DiagramText
    $links += @($flowDiagramContent.Links)
    $connectedEnvVars += @($flowDiagramContent.ConnectedEnvVars)
    $connectedConnections += @($flowDiagramContent.ConnectedConnections)
    $connectedEntities += @($flowDiagramContent.ConnectedEntities)

    $defaultEntitiesInCanvasApps = @()

    $canvasAppsToRender = Get-PowerPlatformCheckerDiagramCanvasApps `
        -SolutionObject $solutionObject `
        -IncludePolicy $includePolicy `
        -HasFlowFilter:$($PSBoundParameters.ContainsKey("FlowId")) `
        -HasModelDrivenFilter:$($PSBoundParameters.ContainsKey("ModelDrivenAppName")) `
        -CanvasAppName $CanvasAppName

    # Canvas apps are excluded for flow-only and model-driven-only projections.
    # Their links are derived from connection references plus data-source metadata in the app package.
    $canvasDiagramContent = Get-PowerPlatformCheckerCanvasDiagramContent `
        -CanvasAppsToRender $canvasAppsToRender `
        -EntitySetByReference $entitySetByReference `
        -KnownEntitySetNames $entitySetNames `
        -IncludeConnections:$includeConnections `
        -IncludeEntities:$includeEntities `
        -IncludeDefaultEntities:$includeDefaultEntities `
        -NewLine $newline

    $diagram += [string]$canvasDiagramContent.DiagramText
    $links += @($canvasDiagramContent.Links)
    $connectedConnections += @($canvasDiagramContent.ConnectedConnections)
    $connectedEntities += @($canvasDiagramContent.ConnectedEntities)
    $defaultEntitiesInCanvasApps += @($canvasDiagramContent.DefaultEntitiesInCanvasApps)
    $connectedDefaultEntities += @($canvasDiagramContent.ConnectedDefaultEntities)

    # Keep unresolved connected entity references visible (for example cross-solution dependencies)
    # by promoting unknown entity ids to default-entity candidates.
    if ($includeDefaultEntities) {
        foreach ($connectedEntity in @($connectedEntities)) {
            if (-not [string]::IsNullOrWhiteSpace([string]$connectedEntity) -and -not $entityBySetName.ContainsKey([string]$connectedEntity)) {
                $connectedDefaultEntities += [string]$connectedEntity
            }
        }
    }

    $connectedEnvVars = @($connectedEnvVars | Select-Object -Unique)
    $connectedConnections = @($connectedConnections | Select-Object -Unique)
    $connectedEntities = @($connectedEntities | Select-Object -Unique)
    $connectedDefaultEntities = @($connectedDefaultEntities | Select-Object -Unique)
    $connectedIconResources = @($connectedIconResources | Select-Object -Unique)

    # Scoped diagrams start from explicitly connected nodes (flow/app selections), then expand
    # reachability so linked in-solution and default entities are declared before rendering.
    if ($isScopedDiagram -and $includeEntities -and $connectedEntities.Count -gt 0) {
        $expandedReachability = Expand-PowerPlatformCheckerScopedReachability `
            -ConnectedEntities $connectedEntities `
            -ConnectedDefaultEntities $connectedDefaultEntities `
            -EntityBySetName $entityBySetName `
            -EntityByLogicalName $entityByLogicalName `
            -IncludeDefaultEntities:$includeDefaultEntities

        $connectedEntities = @($expandedReachability.ConnectedEntities)
        $connectedDefaultEntities = @($expandedReachability.ConnectedDefaultEntities)
    }

    $envVarsToRender = Get-PowerPlatformCheckerDiagramEnvironmentVariables `
        -SolutionObject $solutionObject `
        -IncludePolicy $includePolicy `
        -IsScopedDiagram:$isScopedDiagram `
        -ConnectedNames $connectedEnvVars

    foreach ($envVar in @($envVarsToRender)) {
        $diagram += "class $($envVar.Name):::EnvVar {$newline"
        $diagram += "  EnvironmentalVariable$newline"
        $diagram += "}$newline"
    }

    $connectionsToRender = Get-PowerPlatformCheckerDiagramConnections `
        -SolutionObject $solutionObject `
        -IncludePolicy $includePolicy `
        -IsScopedDiagram:$isScopedDiagram `
        -ConnectedConnectorNames $connectedConnections

    foreach ($connection in @($connectionsToRender)) {
        $connectorName = Convert-PowerPlatformCheckerMermaidId -InputString $connection.ConnectorId.Split("/")[-1]
        $diagram += "class ${connectorName}:::Connection {$newline"
        $diagram += "  ConnectionReference$newline"
        $diagram += "  $($connection.DisplayName)()$newline"
        $diagram += "}$newline"
    }

    $entitiesToRender = Get-PowerPlatformCheckerDiagramEntities `
        -SolutionObject $solutionObject `
        -IncludePolicy $includePolicy `
        -IsScopedDiagram:$isScopedDiagram `
        -ConnectedEntitySetNames $connectedEntities

    $entityDiagramContent = Get-PowerPlatformCheckerEntityDiagramContent `
        -EntitiesToRender $entitiesToRender `
        -DefaultFields $defaultFields `
        -IsScopedDiagram:$isScopedDiagram `
        -IncludeDefaultEntities:$includeDefaultEntities `
        -IncludeWebResources:$includeWebResources `
        -EntityByLogicalName $entityByLogicalName `
        -WebResources $webResources `
        -IconResources $iconResources `
        -NewLine $newline

    $diagram += [string]$entityDiagramContent.DiagramText
    $links += @($entityDiagramContent.Links)
    $connectedEntities += @($entityDiagramContent.ConnectedEntities)
    $connectedDefaultEntities += @($entityDiagramContent.ConnectedDefaultEntities)
    $connectedIconResources += @($entityDiagramContent.ConnectedIconResources)
    $renderedEntityNodeIds += @($entityDiagramContent.RenderedEntityNodeIds)

    if ($includeDefaultEntities -and $solutionObject.Entities.Relations.Count -gt 0) {
        foreach ($relation in @($solutionObject.Entities.Relations)) {
            if ($relation.Source) {
                $defaultEntitiesInCanvasApps += $relation.Source.ToLower()
            }
            if ($relation.Target) {
                $defaultEntitiesInCanvasApps += $relation.Target.ToLower()
            }
        }
    }

    $defaultEntitiesToRender = Get-PowerPlatformCheckerDiagramDefaultEntities `
        -IncludePolicy $includePolicy `
        -IsScopedDiagram:$isScopedDiagram `
        -DefaultEntitiesInCanvasApps $defaultEntitiesInCanvasApps `
        -ConnectedDefaultEntities $connectedDefaultEntities `
        -EntitySetByReference $entitySetByReference `
        -RenderedEntityNodeIds $renderedEntityNodeIds

    foreach ($entity in @($defaultEntitiesToRender)) {
        $diagram += "class ${entity}:::DefaultEntity$newline"
    }

    foreach ($modelApp in @($modelApps)) {
        if (-not $includeModelDrivenApps) { continue }
        if ($PSBoundParameters.ContainsKey("CanvasAppName")) { continue }
        $diagram += Get-PowerPlatformCheckerModelDrivenAppClassDefinition -ModelApp $modelApp -NewLine $newline
        $modelAppLinkData = Get-PowerPlatformCheckerModelDrivenAppLinks `
            -ModelApp $modelApp `
            -SolutionObject $solutionObject `
            -EntitySetByReference $entitySetByReference `
            -WebResources $webResources `
            -IncludeFlows:$includeFlows `
            -IncludeEntities:$includeEntities `
            -IncludeDefaultEntities:$includeDefaultEntities `
            -IncludeWebResources:$includeWebResources `
            -NewLine $newline

        $links += @($modelAppLinkData.Links)
        $connectedEntities += @($modelAppLinkData.ConnectedEntities)
        $connectedDefaultEntities += @($modelAppLinkData.ConnectedDefaultEntities)
    }

    # Web resources are rendered after the app/entity graph so links can point at stable node ids.
    # Scripts get a class body so the diagram can show discovered method names in addition to type.
    $webResourceDiagramContent = Get-PowerPlatformCheckerWebResourceDiagramContent `
        -WebResources $webResources `
        -IncludeWebResources:$includeWebResources `
        -NewLine $newline
    $diagram += [string]$webResourceDiagramContent.DiagramText
    $links += @($webResourceDiagramContent.Links)

    $diagram += Get-PowerPlatformCheckerIconResourceDiagramContent `
        -IconResources $iconResources `
        -IncludeWebResources:$includeWebResources `
        -IsScopedDiagram:$isScopedDiagram `
        -ConnectedIconResources $connectedIconResources `
        -NewLine $newline

    # The diagram builder collects links from several passes; skip any empty items before appending.
    foreach ($link in ($links | Select-Object -Unique)) {
        if ([string]::IsNullOrWhiteSpace([string]$link)) {
            continue
        }
        $diagram += $link
    }

    # Emit only class definitions for enabled element groups so style blocks stay minimal.
    $diagram += Get-PowerPlatformCheckerMermaidStyleBlock -Style $style -IncludePolicy $includePolicy -NewLine $newline
    $diagram += ":::"

    # Defensive cleanup: if any upstream metadata produced a targetless edge, remove it so the
    # markdown stays parseable and the snapshot remains representative of valid output.
    $diagram = Remove-PowerPlatformCheckerMalformedMermaidEdges -MermaidText $diagram

    if ($OutputFormat -eq "Graph") {
        $sourceFilterType = if ($PSBoundParameters.ContainsKey("FlowId")) { "Flow" }
        elseif ($PSBoundParameters.ContainsKey("CanvasAppName")) { "CanvasApp" }
        elseif ($PSBoundParameters.ContainsKey("ModelDrivenAppName")) { "ModelDrivenApp" }
        else { "None" }

        $sourceFilterValue = if ($PSBoundParameters.ContainsKey("FlowId")) { [string]$FlowId }
        elseif ($PSBoundParameters.ContainsKey("CanvasAppName")) { [string]$CanvasAppName }
        elseif ($PSBoundParameters.ContainsKey("ModelDrivenAppName")) { [string]$ModelDrivenAppName }
        else { "" }

        $parsedGraph = Convert-PowerPlatformCheckerMermaidToGraph -MermaidText $diagram

        return [pscustomobject]@{
            Metadata = [pscustomobject]@{
                Direction = $Direction
                IncludeElements = @($IncludeElements)
                IsScopedDiagram = $isScopedDiagram
                SourceFilterType = $sourceFilterType
                SourceFilterValue = $sourceFilterValue
                OutputFormat = "Graph"
            }
            Nodes = @($parsedGraph.Nodes)
            Edges = @($parsedGraph.Edges)
            Styles = $parsedGraph.Styles
            Mermaid = $diagram
        }
    }

    return $diagram
}


