function Get-PowerPlatformCheckerFlowChartStyledGraph {
    <#
    .SYNOPSIS
        Applies style metadata to a flowchart graph.

    .DESCRIPTION
        Adds node and edge style categories plus resolved style definitions
        to a flowchart graph and all nested subgraphs.

    .PARAMETER Graph
        Flowchart graph object.

    .PARAMETER StyleOverrides
        Optional style overrides for the FlowChart style target.

    .EXAMPLE
        Apply flowchart style metadata before Mermaid rendering.

        PS> Get-PowerPlatformCheckerFlowChartStyledGraph -Graph $graph
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Graph,

        [Parameter(Mandatory = $false)]
        [hashtable] $StyleOverrides
    )

    $style = Get-PowerPlatformCheckerResolvedStyle -StyleTarget 'FlowChart' -StyleOverrides $StyleOverrides
    $styles = @{
        FlowAction = "fill:$($style.FlowAction),stroke:$($style.Stroke)"
        FlowDecision = "fill:$($style.FlowDecision),stroke:$($style.Stroke)"
        FlowTrigger = "fill:$($style.FlowTrigger),stroke:$($style.Stroke)"
        FlowSuccessPath = "stroke:$($style.FlowSuccessPath),stroke-width:2px,color:$($style.FlowSuccessPath)"
        FlowErrorPath = "stroke:$($style.FlowErrorPath),stroke-width:2px,color:$($style.FlowErrorPath)"
        FlowDefaultPath = "stroke:$($style.FlowDefaultPath),stroke-width:1px,color:$($style.FlowDefaultPath)"
    }

    $styleOrder = @('FlowAction', 'FlowDecision', 'FlowTrigger', 'FlowDefaultPath', 'FlowSuccessPath', 'FlowErrorPath')

    $pendingGraphs = [System.Collections.Generic.Queue[object]]::new()
    $pendingGraphs.Enqueue($Graph)

    while ($pendingGraphs.Count -gt 0) {
        $currentGraph = $pendingGraphs.Dequeue()

        foreach ($node in @($currentGraph.Nodes)) {
            $nodeClass = 'FlowAction'
            if ([string]$node.Shape -eq 'Decision') {
                $nodeClass = 'FlowDecision'
            }
            elseif ([string]$node.Shape -eq 'Trigger') {
                $nodeClass = 'FlowTrigger'
            }

            $node | Add-Member -MemberType NoteProperty -Name 'ClassKind' -Value $nodeClass -Force
        }

        foreach ($edge in @($currentGraph.Edges)) {
            $edgeClass = 'FlowDefaultPath'
            $edgeLabel = [string]$edge.Label
            if ($edgeLabel -match '(?i)error|fail|timeout') {
                $edgeClass = 'FlowErrorPath'
            }
            elseif ($edgeLabel -match '(?i)succeeded|success|ok|true') {
                $edgeClass = 'FlowSuccessPath'
            }

            $edgeMetadata = @{}
            if ($edge.PSObject.Properties.Name -contains 'Metadata' -and $edge.Metadata -is [System.Collections.IDictionary]) {
                foreach ($key in @($edge.Metadata.Keys)) {
                    $edgeMetadata[[string]$key] = $edge.Metadata[[string]$key]
                }
            }
            $edgeMetadata.StyleClass = $edgeClass
            $edge | Add-Member -MemberType NoteProperty -Name 'Metadata' -Value $edgeMetadata -Force
        }

        foreach ($subgraph in @($currentGraph.Subgraphs)) {
            $pendingGraphs.Enqueue($subgraph)
        }
    }

    $Graph | Add-Member -MemberType NoteProperty -Name 'Styles' -Value $styles -Force
    $Graph | Add-Member -MemberType NoteProperty -Name 'StyleOrder' -Value $styleOrder -Force

    return $Graph
}

