function Convert-PowerPlatformCheckerFlowChartNodeToMermaid {
    <#
    .SYNOPSIS
        Renders one flowchart node as Mermaid text.

    .DESCRIPTION
        Converts the normalized flowchart graph node contract into Mermaid node
        syntax based on the declared node shape.

    .PARAMETER Node
        Flowchart graph node.

    .EXAMPLE
        Render a flowchart node for Mermaid output.

        Convert-PowerPlatformCheckerFlowChartNodeToMermaid -Node $node
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Node
    )

    $nodeId = [string]$Node.Id
    $nodeLabel = [string]$Node.Label

    switch ([string]$Node.Shape) {
        'Trigger' {
            return ("$nodeId([`"$nodeLabel`"] )" -replace ' \)', ')')
        }
        'Decision' {
            return "$nodeId{`"$nodeLabel`"}"
        }
        default {
            return "$nodeId[`"$nodeLabel`"]"
        }
    }
}
