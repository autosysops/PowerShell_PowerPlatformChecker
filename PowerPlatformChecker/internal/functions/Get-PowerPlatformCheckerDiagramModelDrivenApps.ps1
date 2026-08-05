function Get-PowerPlatformCheckerDiagramModelDrivenApps {
    <#
    .SYNOPSIS
        Selects model-driven apps to render for the architecture diagram.

    .DESCRIPTION
        Applies include policy and scope compatibility before delegating metadata
        loading to Get-PowerPlatformCheckerModelDrivenApp.

    .PARAMETER SolutionPath
        Root path of the unpacked solution.

    .PARAMETER IncludePolicy
        Include/exclude policy object resolved for this diagram request.

    .PARAMETER HasFlowFilter
        Indicates the diagram is scoped to a specific flow.

    .PARAMETER HasCanvasFilter
        Indicates the diagram is scoped to a specific canvas app.

    .PARAMETER ModelDrivenAppName
        Optional model-driven app unique name used for focused rendering.

    .EXAMPLE
        Select model-driven apps for diagram rendering.

        PS> Get-PowerPlatformCheckerDiagramModelDrivenApps -SolutionPath $path -IncludePolicy $policy

        Returns model-driven app records that are valid for the current diagram scope.
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Internal helper name intentionally mirrors IncludeElements value ModelDrivenApps.')]
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SolutionPath,

        [Parameter(Mandatory = $true)]
        [object] $IncludePolicy,

        [Parameter(Mandatory = $false)]
        [switch] $HasFlowFilter,

        [Parameter(Mandatory = $false)]
        [switch] $HasCanvasFilter,

        [Parameter(Mandatory = $false)]
        [string] $ModelDrivenAppName
    )

    if (-not $IncludePolicy.IncludeModelDrivenApps) {
        return @()
    }

    if ($HasFlowFilter.IsPresent -or $HasCanvasFilter.IsPresent) {
        return @()
    }

    # Reuse public parser so this helper stays focused on projection/filter decisions only.
    $modelApps = @(Get-PowerPlatformCheckerModelDrivenApp -SolutionPath $SolutionPath)

    if (-not [string]::IsNullOrWhiteSpace([string]$ModelDrivenAppName)) {
        $modelApps = @($modelApps | Where-Object { $_ -and $_.UniqueName -eq $ModelDrivenAppName })
    }

    return @($modelApps)
}
