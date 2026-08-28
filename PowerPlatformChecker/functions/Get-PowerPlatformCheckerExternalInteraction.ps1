function Get-PowerPlatformCheckerExternalInteraction {
    <#
    .SYNOPSIS
        Builds a combined external-interaction architecture graph for multiple solutions.

    .DESCRIPTION
        Resolves solution folders from one or more root paths, optionally recursing,
        and combines architecture graph output into one deterministic graph/mermaid
        view focused on external interactions.

    .PARAMETER SolutionPaths
        One or more solution root paths or parent folders.

    .PARAMETER Recurse
        Recursively discover solution folders under each root path.

    .PARAMETER IncludeSolutionFolders
        Optional wildcard list for folder names to include.

    .PARAMETER ExcludeSolutionFolders
        Optional wildcard list for folder names to exclude.

    .PARAMETER Direction
        Mermaid/graph direction.

    .PARAMETER OutputFormat
        Mermaid markdown (default) or Graph object.

    .PARAMETER StyleOverrides
        Optional hashtable that overrides recognized diagram color keys for this call only.

    .PARAMETER Merge
        Optional merged solution block name. When provided, all selected solutions are
        aggregated under one solution node with this display name.

    .EXAMPLE
        Build one combined external interaction view from multiple solution roots.

        PS> Get-PowerPlatformCheckerExternalInteraction -SolutionPaths @('C:\Solutions\A','C:\Solutions\B') -Recurse
    #>

    [CmdletBinding()]
    [OutputType([string], [pscustomobject])]
    param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string[]] $SolutionPaths,

        [Parameter(Mandatory = $false)]
        [switch] $Recurse,

        [Parameter(Mandatory = $false)]
        [string[]] $IncludeSolutionFolders = @('*'),

        [Parameter(Mandatory = $false)]
        [string[]] $ExcludeSolutionFolders = @(),

        [Parameter(Mandatory = $false)]
        [ValidateSet('LR', 'RL', 'TB', 'BT')]
        [string] $Direction = 'LR',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Mermaid', 'Graph')]
        [string] $OutputFormat = 'Mermaid',

        [Parameter(Mandatory = $false)]
        [hashtable] $StyleOverrides,

        [Parameter(Mandatory = $false)]
        [string] $Merge
    )

    $telemetryProperties = @{
        PathCount = @($SolutionPaths).Count
        Recurse = $Recurse.IsPresent
        IncludeFilterCount = @($IncludeSolutionFolders).Count
        ExcludeFilterCount = @($ExcludeSolutionFolders).Count
        Direction = $Direction
        OutputFormat = $OutputFormat
        HasStyleOverrides = $PSBoundParameters.ContainsKey('StyleOverrides')
        HasMerge = $PSBoundParameters.ContainsKey('Merge')
    }
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerExternalInteraction" -PropertiesHash $telemetryProperties

    $resolvedSolutionPaths = [System.Collections.Generic.List[string]]::new()

    foreach ($rootPath in @($SolutionPaths)) {
        if ([string]::IsNullOrWhiteSpace($rootPath) -or -not (Test-Path -Path $rootPath)) {
            continue
        }

        if ((Test-Path -Path (Join-Path $rootPath 'Workflows')) -or (Test-Path -Path (Join-Path $rootPath 'Other\Customizations.xml'))) {
            [void]$resolvedSolutionPaths.Add((Resolve-Path -Path $rootPath).Path)
            continue
        }

        $candidateFolders = @()
        if ($Recurse.IsPresent) {
            $candidateFolders = @(Get-ChildItem -Path $rootPath -Directory -Recurse -ErrorAction SilentlyContinue)
        }
        else {
            $candidateFolders = @(Get-ChildItem -Path $rootPath -Directory -ErrorAction SilentlyContinue)
        }

        foreach ($folder in $candidateFolders) {
            if ((Test-Path -Path (Join-Path $folder.FullName 'Workflows')) -or (Test-Path -Path (Join-Path $folder.FullName 'Other\Customizations.xml'))) {
                [void]$resolvedSolutionPaths.Add($folder.FullName)
            }
        }
    }

    $filteredSolutionPaths = @($resolvedSolutionPaths | Sort-Object -Unique | Where-Object {
            $leafName = [System.IO.Path]::GetFileName([string]$_)
            $includeMatch = $false
            foreach ($pattern in @($IncludeSolutionFolders)) {
                if ($leafName -like $pattern) {
                    $includeMatch = $true
                    break
                }
            }

            if (-not $includeMatch) {
                return $false
            }

            foreach ($excludePattern in @($ExcludeSolutionFolders)) {
                if ($leafName -like $excludePattern) {
                    return $false
                }
            }

            return $true
        })

    $internalGraphParameters = @{
        FilteredSolutionPaths = $filteredSolutionPaths
        Direction = $Direction
    }

    if ($PSBoundParameters.ContainsKey('StyleOverrides')) {
        $internalGraphParameters.StyleOverrides = $StyleOverrides
    }

    if ($PSBoundParameters.ContainsKey('Merge') -and -not [string]::IsNullOrWhiteSpace([string]$Merge)) {
        $internalGraphParameters.MergeName = [string]$Merge
    }

    $combinedGraph = Get-PowerPlatformCheckerExternalInteractionGraphInternal @internalGraphParameters

    if ($OutputFormat -eq 'Graph') {
        return $combinedGraph
    }

    return Convert-PowerPlatformCheckerArchitectureGraphToMermaid -Graph $combinedGraph
}
