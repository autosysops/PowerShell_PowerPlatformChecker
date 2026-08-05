function Get-PowerPlatformCheckerDiagramWebResources {
    <#
    .SYNOPSIS
        Resolves script and icon web resources used by the diagram.

    .DESCRIPTION
        Retrieves JavaScript resources globally or, for model-driven scoped views,
        computes a transitive closure over script dependencies so referenced
        libraries remain visible. Also resolves icon web resources from entity metadata.

    .PARAMETER SolutionPath
        Root path of the unpacked solution.

    .PARAMETER SolutionObject
        Aggregated solution metadata containing entity and icon metadata.

    .PARAMETER IncludePolicy
        Include/exclude policy object resolved for this diagram request.

    .PARAMETER HasModelDrivenFilter
        Indicates whether rendering is scoped to selected model-driven app(s).

    .PARAMETER ModelApps
        Model-driven app metadata used to determine selected scripts and dependencies.

    .EXAMPLE
        Resolve web resources for architecture rendering.

        PS> Get-PowerPlatformCheckerDiagramWebResources -SolutionPath $path -SolutionObject $solution -IncludePolicy $policy

        Returns selected script resources and icon resources for the current diagram projection.
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Internal helper name intentionally mirrors IncludeElements value WebResources.')]
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SolutionPath,

        [Parameter(Mandatory = $true)]
        [object] $SolutionObject,

        [Parameter(Mandatory = $true)]
        [object] $IncludePolicy,

        [Parameter(Mandatory = $false)]
        [switch] $HasModelDrivenFilter,

        [Parameter(Mandatory = $false)]
        [object[]] $ModelApps = @()
    )

    if (-not $IncludePolicy.IncludeWebResources) {
        return [pscustomobject]@{
            WebResources = @()
            IconResources = @()
        }
    }

    $webResources = @()
    if ($HasModelDrivenFilter.IsPresent) {
        # Load once, then filter by selected app resources and their dependencies.
        $allWebResources = @(Get-PowerPlatformCheckerWebResource -SolutionPath $SolutionPath -JavaScriptOnly)
        $webResourcesByName = @{}
        foreach ($webResource in @($allWebResources)) {
            if ($webResource.Name) {
                $webResourcesByName[$webResource.Name] = $webResource
            }
        }

        $selectedWebResourceNames = @(
            @($ModelApps | ForEach-Object { $_.WebResources }) +
            @($ModelApps | ForEach-Object { $_.EntityWebResources } | ForEach-Object { $_.WebResources })
        ) | Sort-Object -Unique | Where-Object { $_ }

        $selectedWebResourceSet = New-Object 'System.Collections.Generic.HashSet[string]'
        $pendingWebResources = New-Object 'System.Collections.Generic.Queue[string]'

        foreach ($webResourceName in $selectedWebResourceNames) {
            [void]$pendingWebResources.Enqueue($webResourceName)
        }

        # Breadth-first expansion keeps dependent helper scripts attached to selected roots.
        while ($pendingWebResources.Count -gt 0) {
            $currentWebResourceName = $pendingWebResources.Dequeue()
            if (-not $selectedWebResourceSet.Add($currentWebResourceName)) {
                continue
            }

            $currentWebResource = $webResourcesByName[$currentWebResourceName]
            foreach ($dependency in @($currentWebResource.Dependencies)) {
                if ($dependency -and -not $selectedWebResourceSet.Contains($dependency)) {
                    [void]$pendingWebResources.Enqueue($dependency)
                }
            }
        }

        $webResources = @($allWebResources | Where-Object { $webResourcesByName.ContainsKey($_.Name) -and $selectedWebResourceSet.Contains($_.Name) })
    }
    else {
        $webResources = @(Get-PowerPlatformCheckerWebResource -SolutionPath $SolutionPath -JavaScriptOnly)
    }

    # Icons are separate resources that originate from entity IconVectorName metadata.
    $iconResources = @()
    $iconNames = @($SolutionObject.Entities | Where-Object { $_ -and $_.IconVectorName } | ForEach-Object { [string]$_.IconVectorName } | Sort-Object -Unique)
    foreach ($iconName in $iconNames) {
        $iconResource = Get-PowerPlatformCheckerWebResource -SolutionPath $SolutionPath -Name $iconName | Select-Object -First 1
        if ($iconResource) {
            $iconResources += $iconResource
        }
    }

    return [pscustomobject]@{
        WebResources = @($webResources)
        IconResources = @($iconResources)
    }
}
