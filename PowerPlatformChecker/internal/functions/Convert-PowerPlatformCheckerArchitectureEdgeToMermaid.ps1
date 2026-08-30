function Convert-PowerPlatformCheckerArchitectureEdgeToMermaid {
    <#
    .SYNOPSIS
        Renders one architecture-graph edge as Mermaid text.

    .DESCRIPTION
        Converts a normalized architecture graph edge into Mermaid flowchart or
        classDiagram syntax, including Mermaid-specific label selection.

    .PARAMETER Edge
        Graph edge to render.

    .PARAMETER DiagramKind
        Mermaid diagram kind, such as Flowchart or ClassDiagram.

    .EXAMPLE
        Render an architecture edge for Mermaid output.

        Convert-PowerPlatformCheckerArchitectureEdgeToMermaid -Edge $edge -DiagramKind Flowchart
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Edge,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Flowchart', 'ClassDiagram')]
        [string] $DiagramKind
    )

    if ($DiagramKind -eq 'Flowchart') {
        $arrow = if ($Edge.Metadata.Arrow) { [string]$Edge.Metadata.Arrow } elseif ($Edge.EdgeType -eq 'Reference') { '..>' } else { '-->' }
        if ($arrow -eq '..>') {
            $arrow = '-.->'
        }

        $edgeLabel = [string]$Edge.Label
        if ($Edge.Metadata -and $Edge.Metadata.PSObject.Properties.Name -contains 'MermaidLabel' -and -not [string]::IsNullOrWhiteSpace([string]$Edge.Metadata.MermaidLabel)) {
            $edgeLabel = [string]$Edge.Metadata.MermaidLabel
        }

        if ([string]::IsNullOrWhiteSpace($edgeLabel)) {
            return "$($Edge.SourceId) $arrow $($Edge.TargetId)"
        }

        $safeEdgeLabel = $edgeLabel
        $safeEdgeLabel = $safeEdgeLabel.Replace('|', '/')
        $safeEdgeLabel = $safeEdgeLabel.Replace('"', "'")
        $safeEdgeLabel = $safeEdgeLabel -replace '[\(\)\[\]\{\}]', ' '
        $safeEdgeLabel = $safeEdgeLabel -replace '[:;,]', ' '
        $safeEdgeLabel = $safeEdgeLabel -replace '\s{2,}', ' '
        $safeEdgeLabel = $safeEdgeLabel.Trim()
        return "$($Edge.SourceId) $arrow|$safeEdgeLabel| $($Edge.TargetId)"
    }

    $arrow = if ($Edge.Metadata.Arrow) { [string]$Edge.Metadata.Arrow } elseif ($Edge.EdgeType -eq 'Reference') { '..>' } else { '-->' }
    $edgeLine = "$($Edge.SourceId) $arrow $($Edge.TargetId)"
    if (-not [string]::IsNullOrWhiteSpace([string]$Edge.Label)) {
        $edgeLine += ":$($Edge.Label)"
    }

    return $edgeLine
}
