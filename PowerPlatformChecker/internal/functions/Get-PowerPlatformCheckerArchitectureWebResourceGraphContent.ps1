function Get-PowerPlatformCheckerArchitectureWebResourceGraphContent {
    <#
    .SYNOPSIS
        Retrieves projected web resources and builds their architecture graph content.

    .DESCRIPTION
        Retrieves JavaScript resources, applies model-driven dependency closure when
        scoped, resolves entity icon resources, and builds script nodes and dependency
        edges. Missing dependencies remain visible as placeholder nodes.

    .PARAMETER SolutionPath
        Root path of the unpacked solution.

    .PARAMETER SolutionObject
        Aggregated solution metadata containing entity icon metadata.

    .PARAMETER ModelApps
        Selected model-driven app metadata used to project script dependencies.

    .PARAMETER HasModelDrivenFilter
        Indicates whether model-driven script dependency closure should be applied.

    .PARAMETER IncludeWebResources
        Indicates whether web resource rendering is enabled.

    .EXAMPLE
        Build web resource class and dependency content.

        PS> Get-PowerPlatformCheckerArchitectureWebResourceGraphContent -SolutionPath $path -SolutionObject $solution -IncludeWebResources

        Returns selected metadata plus graph nodes and dependency edges.
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SolutionPath,

        [Parameter(Mandatory = $true)]
        [object] $SolutionObject,

        [Parameter(Mandatory = $false)]
        [object[]] $ModelApps = @(),

        [Parameter(Mandatory = $false)]
        [switch] $HasModelDrivenFilter,

        [Parameter(Mandatory = $false)]
        [switch] $IncludeWebResources
    )

    if (-not $IncludeWebResources.IsPresent) {
        return [pscustomobject]@{
            Nodes = @()
            Edges = @()
            WebResources = @()
            IconResources = @()
        }
    }

    $allWebResources = @(Get-PowerPlatformCheckerWebResource -SolutionPath $SolutionPath -JavaScriptOnly)
    $webResources = @($allWebResources)
    if ($HasModelDrivenFilter.IsPresent) {
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

        while ($pendingWebResources.Count -gt 0) {
            $currentWebResourceName = $pendingWebResources.Dequeue()
            if (-not $selectedWebResourceSet.Add($currentWebResourceName)) { continue }

            $currentWebResource = $webResourcesByName[$currentWebResourceName]
            foreach ($dependency in @($currentWebResource.Dependencies)) {
                if ($dependency -and -not $selectedWebResourceSet.Contains($dependency)) {
                    [void]$pendingWebResources.Enqueue($dependency)
                }
            }
        }

        $webResources = @($allWebResources | Where-Object { $webResourcesByName.ContainsKey($_.Name) -and $selectedWebResourceSet.Contains($_.Name) })
    }

    $iconResources = @()
    $iconNames = @($SolutionObject.Entities | Where-Object { $_ -and $_.IconVectorName } | ForEach-Object { [string]$_.IconVectorName } | Sort-Object -Unique)
    foreach ($iconName in $iconNames) {
        $iconResource = Get-PowerPlatformCheckerWebResource -SolutionPath $SolutionPath -Name $iconName | Select-Object -First 1
        if ($iconResource) { $iconResources += $iconResource }
    }

    $nodes = @()
    $edges = @()

    foreach ($webResource in @($webResources)) {
        $members = @("  [$($webResource.Kind)]$($webResource.Type)")
        foreach ($methodName in @($webResource.Methods)) {
            $members += "  [$($webResource.Kind)]$methodName"
        }
        $nodes += [pscustomobject]@{ Id = [string]$webResource.MermaidId; Type = "WebResource"; DisplayName = [string]$webResource.DisplayName; ClassKind = "WebResource"; Properties = @{}; Members = @($members); HasExplicitDisplayName = $true }

        foreach ($dependency in @($webResource.Dependencies)) {
            if (-not $dependency) {
                continue
            }

            $dependencyResource = $webResources | Where-Object { $_.Name -eq $dependency } | Select-Object -First 1
            if ($dependencyResource) {
                $edges += [pscustomobject]@{ SourceId = [string]$webResource.MermaidId; TargetId = [string]$dependencyResource.MermaidId; Label = "Dependency"; EdgeType = "Link"; Metadata = @{ Arrow = "-->" } }
                continue
            }

            $dependencyId = Convert-PowerPlatformCheckerMermaidId -InputString $dependency
            $nodes += [pscustomobject]@{ Id = $dependencyId; Type = "WebResource"; DisplayName = [string]$dependency; ClassKind = "WebResource"; Properties = @{}; Members = @(); HasExplicitDisplayName = $true }
        }
    }

    return [pscustomobject]@{
        Nodes = @($nodes)
        Edges = @($edges)
        WebResources = @($webResources)
        IconResources = @($iconResources)
    }
}
