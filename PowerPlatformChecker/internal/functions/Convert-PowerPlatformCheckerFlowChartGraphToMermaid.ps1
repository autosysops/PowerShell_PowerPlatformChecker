function Convert-PowerPlatformCheckerFlowChartGraphToMermaid {
    <#
    .SYNOPSIS
        Converts a flowchart graph object to Mermaid markdown.

    .DESCRIPTION
        Renders recursively owned nodes and edges within their graph or subgraph
        before producing Mermaid flowchart syntax wrapped in a markdown mermaid
        code block.

    .PARAMETER Graph
        Flowchart graph object produced by Get-PowerPlatformCheckerFlowChartInternal.

    .EXAMPLE
        Convert a graph object to Mermaid markdown.

        PS> $graph = Get-PowerPlatformCheckerFlowChartInternal -GraphContext $context -RootActionName $context.RootActionName -Direction TB
        PS> Convert-PowerPlatformCheckerFlowChartGraphToMermaid -Graph $graph
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object] $Graph
    )

    $newline = [Environment]::NewLine
    $direction = if ($Graph.Direction) { [string]$Graph.Direction } else { "TB" }

    if ($Graph.IsEmpty) {
        return ":::mermaid$newline flowchart $direction$newline empty[`"No actions found`"]$newline:::"
    }

    $lines = @()
    $lines += ":::mermaid"
    $lines += "flowchart $direction"

    $allGraphs = [System.Collections.Generic.List[object]]::new()
    $graphQueue = [System.Collections.Generic.Queue[object]]::new()
    $graphQueue.Enqueue($Graph)
    while ($graphQueue.Count -gt 0) {
        $currentGraph = $graphQueue.Dequeue()
        [void]$allGraphs.Add($currentGraph)
        foreach ($childGraph in @($currentGraph.Subgraphs)) {
            $graphQueue.Enqueue($childGraph)
        }
    }

    $flowchartNodes = @(
        $allGraphs |
            ForEach-Object { @($_.Nodes) } |
            Select-Object -Unique Id, Label, Shape |
            Sort-Object { [int]($_.Id -replace "\D", "") }
    )
    $nodeDeclarationById = @{}
    foreach ($node in $flowchartNodes) {
        $nodeDeclarationById[[string]$node.Id] = Convert-PowerPlatformCheckerFlowChartNodeToMermaid -Node $node
    }

    # Root and nested graphs use the same rendering frames. Only nested graphs
    # add Mermaid subgraph delimiters around their owned content.
    $renderStack = [System.Collections.Generic.Stack[object]]::new()
    $renderStack.Push([pscustomobject]@{
        Kind = "Graph"
        Graph = $Graph
        IsRoot = $true
    })
    $renderedEdgeIndex = 0
    $edgeIndexesByStyle = @{}

    while ($renderStack.Count -gt 0) {
        $frame = $renderStack.Pop()
        $currentGraph = $frame.Graph

        if ($frame.Kind -eq "End") {
            $lines += "end"
            continue
        }

        if ($frame.Kind -eq "Edges") {
            foreach ($edge in @($currentGraph.Edges)) {
                $lines += (Convert-PowerPlatformCheckerFlowChartEdgeToMermaid -Edge $edge)

                $edgeStyleClass = $null
                if ($edge.PSObject.Properties.Name -contains 'Metadata' -and $edge.Metadata -is [System.Collections.IDictionary] -and $edge.Metadata.ContainsKey('StyleClass')) {
                    $edgeStyleClass = [string]$edge.Metadata.StyleClass
                }

                if (-not [string]::IsNullOrWhiteSpace($edgeStyleClass)) {
                    if (-not $edgeIndexesByStyle.ContainsKey($edgeStyleClass)) {
                        $edgeIndexesByStyle[$edgeStyleClass] = [System.Collections.Generic.List[int]]::new()
                    }
                    [void]$edgeIndexesByStyle[$edgeStyleClass].Add($renderedEdgeIndex)
                }

                $renderedEdgeIndex++
            }
            continue
        }

        if (-not $frame.IsRoot) {
            $graphId = [string]$currentGraph.Id
            $graphTitle = [string]$currentGraph.Title
            $graphDirection = if ($currentGraph.Direction) { [string]$currentGraph.Direction } else { "TB" }
            if ([string]::IsNullOrWhiteSpace($graphTitle)) {
                $lines += "subgraph $graphId"
            }
            else {
                $lines += "subgraph $graphId[`"$graphTitle`"]"
            }
            $lines += "direction $graphDirection"
        }

        foreach ($node in @($currentGraph.Nodes | Sort-Object { [int]($_.Id -replace "\D", "") })) {
            $lines += $nodeDeclarationById[[string]$node.Id]
        }

        if (-not $frame.IsRoot) {
            $renderStack.Push([pscustomobject]@{
                Kind = "End"
                Graph = $currentGraph
                IsRoot = $false
            })
        }

        $renderStack.Push([pscustomobject]@{
            Kind = "Edges"
            Graph = $currentGraph
            IsRoot = $frame.IsRoot
        })

        $childSubgraphs = @($currentGraph.Subgraphs)
        for ($i = $childSubgraphs.Count - 1; $i -ge 0; $i--) {
            $childSubgraph = $childSubgraphs[$i]
            $renderStack.Push([pscustomobject]@{
                Kind = "Graph"
                Graph = $childSubgraph
                IsRoot = $false
            })
        }
    }

    $styleNames = @()
    if ($Graph.PSObject.Properties.Name -contains 'StyleOrder' -and @($Graph.StyleOrder).Count -gt 0) {
        $styleNames = @($Graph.StyleOrder)
    }
    elseif ($Graph.PSObject.Properties.Name -contains 'Styles') {
        if ($Graph.Styles -is [System.Collections.IDictionary]) {
            $styleNames = @($Graph.Styles.Keys | Sort-Object)
        }
        else {
            $styleNames = @($Graph.Styles.PSObject.Properties.Name | Sort-Object)
        }
    }

    foreach ($styleName in @($styleNames)) {
        $styleValue = ''
        if ($Graph.Styles -is [System.Collections.IDictionary]) {
            $styleValue = [string]$Graph.Styles[[string]$styleName]
        }
        else {
            $styleProperty = $Graph.Styles.PSObject.Properties[[string]$styleName]
            if ($null -ne $styleProperty) {
                $styleValue = [string]$styleProperty.Value
            }
        }

        if ([string]::IsNullOrWhiteSpace($styleValue)) {
            continue
        }

        if ($styleName -like 'Flow*Path') {
            continue
        }

        $lines += "classDef $styleName $styleValue"
    }

    foreach ($edgeStyleName in @($styleNames | Where-Object { $_ -like 'Flow*Path' })) {
        if (-not $edgeIndexesByStyle.ContainsKey([string]$edgeStyleName)) {
            continue
        }

        $styleValue = ''
        if ($Graph.Styles -is [System.Collections.IDictionary]) {
            $styleValue = [string]$Graph.Styles[[string]$edgeStyleName]
        }
        else {
            $styleProperty = $Graph.Styles.PSObject.Properties[[string]$edgeStyleName]
            if ($null -ne $styleProperty) {
                $styleValue = [string]$styleProperty.Value
            }
        }

        if ([string]::IsNullOrWhiteSpace($styleValue)) {
            continue
        }

        $edgeIndexes = @($edgeIndexesByStyle[[string]$edgeStyleName] | Sort-Object)
        if (@($edgeIndexes).Count -eq 0) {
            continue
        }

        $lines += ("linkStyle {0} {1}" -f (@($edgeIndexes) -join ','), $styleValue)
    }

    $lines += ":::"
    return ($lines -join $newline)
}
