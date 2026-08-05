function Get-PowerPlatformCheckerDiagramIncludePolicy {
    <#
    .SYNOPSIS
        Computes include/exclude and scope policy for architecture diagram generation.

    .DESCRIPTION
        Normalizes IncludeElements plus active filters (flow/canvas/model-driven) into
        a single policy object that downstream helpers can consume.

    .PARAMETER IncludeElements
        Diagram element groups requested by caller.

    .PARAMETER HasFlowFilter
        Indicates a flow-scoped diagram request.

    .PARAMETER HasCanvasFilter
        Indicates a canvas-app scoped diagram request.

    .PARAMETER HasModelDrivenFilter
        Indicates a model-driven-app scoped diagram request.

    .EXAMPLE
        Get-PowerPlatformCheckerDiagramIncludePolicy -IncludeElements Flows,Connections -HasFlowFilter

        Returns the normalized include/scope policy that downstream helpers consume.
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $IncludeElements,

        [Parameter(Mandatory = $false)]
        [switch] $HasFlowFilter,

        [Parameter(Mandatory = $false)]
        [switch] $HasCanvasFilter,

        [Parameter(Mandatory = $false)]
        [switch] $HasModelDrivenFilter
    )

    $isScopedDiagram = $HasFlowFilter.IsPresent -or $HasCanvasFilter.IsPresent -or $HasModelDrivenFilter.IsPresent

    $policy = [pscustomobject]@{
        IncludeFlows = "Flows" -in $IncludeElements
        IncludeCanvasApps = "CanvasApps" -in $IncludeElements
        IncludeModelDrivenApps = "ModelDrivenApps" -in $IncludeElements
        IncludeEnvironmentVariables = "EnvironmentVariables" -in $IncludeElements
        IncludeConnections = "Connections" -in $IncludeElements
        IncludeEntities = "Entities" -in $IncludeElements
        IncludeDefaultEntities = "DefaultEntities" -in $IncludeElements
        IncludeWebResources = "WebResources" -in $IncludeElements
        IsScopedDiagram = $isScopedDiagram
        AllowFlowPass = ("Flows" -in $IncludeElements) -and -not $HasCanvasFilter.IsPresent
        AllowCanvasPass = ("CanvasApps" -in $IncludeElements) -and -not $HasFlowFilter.IsPresent -and -not $HasModelDrivenFilter.IsPresent
        AllowModelDrivenPass = ("ModelDrivenApps" -in $IncludeElements) -and -not $HasFlowFilter.IsPresent -and -not $HasCanvasFilter.IsPresent
    }

    return $policy
}
