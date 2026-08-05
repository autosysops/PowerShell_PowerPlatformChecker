function Get-PowerPlatformCheckerDiagramFlows {
    <#
    .SYNOPSIS
        Selects which flows should participate in the architecture diagram.

    .DESCRIPTION
        Applies include policy plus active filters (canvas scope, explicit flow id,
        model-driven flow references) and returns only valid flow records with ids.

    .PARAMETER SolutionObject
        Aggregated solution metadata containing workflow records.

    .PARAMETER IncludePolicy
        Include/exclude policy object resolved for this diagram request.

    .PARAMETER HasCanvasFilter
        Indicates the diagram is scoped to a specific canvas app.

    .PARAMETER HasFlowFilter
        Indicates the diagram is scoped to a specific flow.

    .PARAMETER HasModelDrivenFilter
        Indicates the diagram is scoped to a model-driven app.

    .PARAMETER FlowId
        Explicit flow id used when HasFlowFilter is enabled.

    .PARAMETER ModelDrivenFlowFilter
        Flow ids allowed for model-driven scoped rendering.

    .EXAMPLE
        Select flows for architecture rendering.

        PS> Get-PowerPlatformCheckerDiagramFlows -SolutionObject $solution -IncludePolicy $policy -HasFlowFilter -FlowId $flowId

        Returns workflow records that should be rendered in the current projection.
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Internal helper name intentionally mirrors IncludeElements value Flows.')]
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [object] $SolutionObject,

        [Parameter(Mandatory = $true)]
        [object] $IncludePolicy,

        [Parameter(Mandatory = $false)]
        [switch] $HasCanvasFilter,

        [Parameter(Mandatory = $false)]
        [switch] $HasFlowFilter,

        [Parameter(Mandatory = $false)]
        [switch] $HasModelDrivenFilter,

        [Parameter(Mandatory = $false)]
        [string] $FlowId,

        [Parameter(Mandatory = $false)]
        [string[]] $ModelDrivenFlowFilter = @()
    )

    if (-not $IncludePolicy.IncludeFlows) {
        return @()
    }

    if ($HasCanvasFilter.IsPresent) {
        return @()
    }

    $flows = @($SolutionObject.Workflows)

    if ($HasFlowFilter.IsPresent -and -not [string]::IsNullOrWhiteSpace([string]$FlowId)) {
        $flows = @($flows | Where-Object { $_ -and $_.Id -eq $FlowId })
    }

    # Model-driven scope should only render flows explicitly referenced by the selected app(s).
    if ($HasModelDrivenFilter.IsPresent) {
        $allowedFlowIds = @($ModelDrivenFlowFilter | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Select-Object -Unique)
        $flows = @($flows | Where-Object { $_ -and $_.Id -in $allowedFlowIds })
    }

    return @($flows | Where-Object { $_ -and -not [string]::IsNullOrWhiteSpace([string]$_.Id) })
}
