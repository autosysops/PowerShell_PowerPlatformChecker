function Get-PowerPlatformCheckerDiagramCanvasApps {
    <#
    .SYNOPSIS
        Selects which canvas apps should be rendered in the architecture diagram.

    .DESCRIPTION
        Enforces include policy and scope compatibility, then optionally filters
        to one named canvas app for focused views.

    .PARAMETER SolutionObject
        Aggregated solution metadata containing canvas app records.

    .PARAMETER IncludePolicy
        Include/exclude policy object resolved for this diagram request.

    .PARAMETER HasFlowFilter
        Indicates the diagram is scoped to a specific flow.

    .PARAMETER HasModelDrivenFilter
        Indicates the diagram is scoped to a model-driven app.

    .PARAMETER CanvasAppName
        Optional canvas app internal name used for focused rendering.

    .EXAMPLE
        Select canvas apps for architecture rendering.

        PS> Get-PowerPlatformCheckerDiagramCanvasApps -SolutionObject $solution -IncludePolicy $policy

        Returns the canvas apps that are valid for the current scope and include settings.
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Internal helper name intentionally mirrors IncludeElements value CanvasApps.')]
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [object] $SolutionObject,

        [Parameter(Mandatory = $true)]
        [object] $IncludePolicy,

        [Parameter(Mandatory = $false)]
        [switch] $HasFlowFilter,

        [Parameter(Mandatory = $false)]
        [switch] $HasModelDrivenFilter,

        [Parameter(Mandatory = $false)]
        [string] $CanvasAppName
    )

    if (-not $IncludePolicy.IncludeCanvasApps) {
        return @()
    }

    # Canvas nodes are intentionally suppressed in flow-scoped or model-driven-scoped views.
    if ($HasFlowFilter.IsPresent -or $HasModelDrivenFilter.IsPresent) {
        return @()
    }

    $canvasApps = @($SolutionObject.CanvasApps)
    if (-not [string]::IsNullOrWhiteSpace([string]$CanvasAppName)) {
        $canvasApps = @($canvasApps | Where-Object { $_ -and $_.Name -eq $CanvasAppName })
    }

    return @($canvasApps)
}
