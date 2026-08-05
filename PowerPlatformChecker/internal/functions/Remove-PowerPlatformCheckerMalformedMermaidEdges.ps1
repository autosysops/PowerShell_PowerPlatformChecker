function Remove-PowerPlatformCheckerMalformedMermaidEdges {
    <#
    .SYNOPSIS
        Removes malformed Mermaid edge lines that have no target node.

    .DESCRIPTION
        Sanitizes Mermaid class diagram text by removing edge lines that end after
        the arrow token without a target node id, preserving parseable output for
        renderers and graph conversion.

    .PARAMETER MermaidText
        Mermaid text block to sanitize.

    .EXAMPLE
        Remove targetless edge lines from Mermaid text.

        PS> Remove-PowerPlatformCheckerMalformedMermaidEdges -MermaidText $diagram

        Returns Mermaid text with malformed edge lines removed.
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Function only transforms and returns in-memory text.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Function name is retained for compatibility with existing call sites.')]
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string] $MermaidText
    )

    if ([string]::IsNullOrEmpty($MermaidText)) {
        return $MermaidText
    }

    return [regex]::Replace($MermaidText, '(?m)^\s*[A-Za-z0-9_]+\s*-->\s*$\r?\n?', '')
}
