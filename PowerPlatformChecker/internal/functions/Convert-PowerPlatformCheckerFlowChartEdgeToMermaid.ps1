function Convert-PowerPlatformCheckerFlowChartEdgeToMermaid {
    <#
    .SYNOPSIS
        Renders one flowchart edge as Mermaid text.

    .DESCRIPTION
        Converts a normalized flowchart graph edge into Mermaid flowchart syntax.

    .PARAMETER Edge
        Flowchart graph edge.

    .EXAMPLE
        Render a flowchart edge for Mermaid output.

        Convert-PowerPlatformCheckerFlowChartEdgeToMermaid -Edge $edge
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Edge
    )

    $fromId = [string]$Edge.From
    $toId = [string]$Edge.To
    $label = [string]$Edge.Label

    if ([string]::IsNullOrWhiteSpace($label)) {
        return "$fromId --> $toId"
    }

    return "$fromId -- $label --> $toId"
}
