function Get-PowerPlatformCheckerExternalInteractionLabels {
    <#
    .SYNOPSIS
        Expands an interaction direction into one or more condensed edge labels.

    .DESCRIPTION
        External interaction diagrams collapse component details into solution-to-
        target edges. This helper keeps direction-to-label mapping consistent.

    .PARAMETER Direction
        Normalized interaction direction such as Read, Write, Mixed, or Unknown.

    .EXAMPLE
        Expand a mixed direction into both GET and SET labels.

        PS> Get-PowerPlatformCheckerExternalInteractionLabels -Direction Mixed
    #>

    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $false)]
        [string] $Direction
    )

    switch ([string]$Direction) {
        'Read' { return @('GET') }
        'Write' { return @('SET') }
        'Mixed' { return @('GET', 'SET') }
        default { return @('Unknown') }
    }
}
