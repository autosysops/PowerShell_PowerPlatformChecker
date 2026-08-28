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
        $nodeId = [string]$node.Id
        $nodeLabel = [string]$node.Label

        switch ([string]$node.Shape) {
            "Trigger" {
                $nodeDeclarationById[$nodeId] = "$nodeId([`"$nodeLabel`"] )" -replace " \)",")"
                continue
            }
            "Decision" {
                $nodeDeclarationById[$nodeId] = "$nodeId{`"$nodeLabel`"}"
                continue
            }
            default {
                $nodeDeclarationById[$nodeId] = "$nodeId[`"$nodeLabel`"]"
                continue
            }
        }
    }

    # Root and nested graphs use the same rendering frames. Only nested graphs
    # add Mermaid subgraph delimiters around their owned content.
    $renderStack = [System.Collections.Generic.Stack[object]]::new()
    $renderStack.Push([pscustomobject]@{
        Kind = "Graph"
        Graph = $Graph
        IsRoot = $true
    })

    while ($renderStack.Count -gt 0) {
        $frame = $renderStack.Pop()
        $currentGraph = $frame.Graph

        if ($frame.Kind -eq "End") {
            $lines += "end"
            continue
        }

        if ($frame.Kind -eq "Edges") {
            foreach ($edge in @($currentGraph.Edges)) {
                $fromId = [string]$edge.From
                $toId = [string]$edge.To
                $label = [string]$edge.Label

                if ([string]::IsNullOrWhiteSpace($label)) {
                    $lines += "$fromId --> $toId"
                }
                else {
                    $lines += "$fromId -- $label --> $toId"
                }
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

    $lines += ":::"
    return ($lines -join $newline)
}
