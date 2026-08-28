function Get-PowerPlatformCheckerResolvedStyle {
    <#
    .SYNOPSIS
        Resolves a cloned style map with optional per-call overrides applied.

    .DESCRIPTION
        Centralizes style resolution so diagram producers use the same default
        values and override rules instead of duplicating style-merging logic.

    .PARAMETER StyleTarget
        Named style target to resolve.

    .PARAMETER StyleOverrides
        Optional hashtable of replacement values for known style keys.

    .EXAMPLE
        Resolve the ArchitectureDiagram style with a custom connection color.

        PS> Get-PowerPlatformCheckerResolvedStyle -StyleTarget ArchitectureDiagram -StyleOverrides @{ Connection = '#123456' }
    #>

    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('ArchitectureDiagram')]
        [string] $StyleTarget,

        [Parameter(Mandatory = $false)]
        [hashtable] $StyleOverrides
    )

    if (-not $script:PowerPlatformCheckerStyles.ContainsKey($StyleTarget)) {
        throw "Unsupported style target '$StyleTarget'."
    }

    $resolvedStyle = @{}
    foreach ($key in @($script:PowerPlatformCheckerStyles[$StyleTarget].Keys)) {
        $resolvedStyle[[string]$key] = [string]$script:PowerPlatformCheckerStyles[$StyleTarget][[string]$key]
    }

    if ($PSBoundParameters.ContainsKey('StyleOverrides')) {
        foreach ($key in @($StyleOverrides.Keys)) {
            $styleKey = [string]$key
            if ($resolvedStyle.ContainsKey($styleKey) -and -not [string]::IsNullOrWhiteSpace([string]$StyleOverrides[$styleKey])) {
                $resolvedStyle[$styleKey] = [string]$StyleOverrides[$styleKey]
            }
        }
    }

    return $resolvedStyle
}
