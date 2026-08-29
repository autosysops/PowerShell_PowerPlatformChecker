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

    $styleStore = $script:PowerPlatformCheckerDiagramStyles

    $defaultStyleStore = $script:PowerPlatformCheckerDiagramStyleDefaults
    if (-not $defaultStyleStore) {
        $defaultStyleStore = $styleStore
    }

    if (-not $styleStore.ContainsKey($StyleTarget)) {
        throw "Unsupported style target '$StyleTarget'."
    }

    $resolvedStyle = @{}
    foreach ($key in @($styleStore[$StyleTarget].Keys)) {
        $resolvedStyle[[string]$key] = [string]$styleStore[$StyleTarget][[string]$key]
    }

    if ($PSBoundParameters.ContainsKey('StyleOverrides')) {
        foreach ($key in @($StyleOverrides.Keys)) {
            $styleKey = [string]$key
            if ($resolvedStyle.ContainsKey($styleKey) -and -not [string]::IsNullOrWhiteSpace([string]$StyleOverrides[$styleKey])) {
                $resolvedStyle[$styleKey] = [string]$StyleOverrides[$styleKey]
            }
        }
    }

    foreach ($key in @($resolvedStyle.Keys)) {
        $defaultValue = [string]$resolvedStyle[$key]
        if ($defaultStyleStore.ContainsKey($StyleTarget) -and $defaultStyleStore[$StyleTarget].ContainsKey([string]$key)) {
            $defaultValue = [string]$defaultStyleStore[$StyleTarget][[string]$key]
        }

        $candidate = [string]$resolvedStyle[[string]$key]
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            $resolvedStyle[[string]$key] = $defaultValue
            continue
        }

        $candidate = $candidate.Trim()
        if (($candidate.StartsWith('"') -and $candidate.EndsWith('"')) -or ($candidate.StartsWith("'") -and $candidate.EndsWith("'"))) {
            $candidate = $candidate.Substring(1, $candidate.Length - 2).Trim()
        }

        if ([string]::IsNullOrWhiteSpace($candidate)) {
            $resolvedStyle[[string]$key] = $defaultValue
            continue
        }

        if ($candidate -match '^(#[0-9a-fA-F]{3,8}|[A-Za-z]+)$') {
            $resolvedStyle[[string]$key] = $candidate
        }
        else {
            $resolvedStyle[[string]$key] = $defaultValue
        }
    }

    return $resolvedStyle
}
