function Get-PowerPlatformCheckerArchitectureModelDrivenAppGraphContent {
    <#
    .SYNOPSIS
        Builds a model-driven app node and its connected graph edges.

    .DESCRIPTION
        Generates the model-driven app node and links to related flows, entities,
        and scripts while tracking connected entity/default sets for downstream
        scoped rendering decisions.

    .PARAMETER ModelApp
        Model-driven app metadata object to process.

    .PARAMETER SolutionObject
        Aggregated solution metadata containing entities and workflows.

    .PARAMETER EntitySetByReference
        Lookup table that maps logical/entity references to canonical entity set names.

    .PARAMETER WebResources
        Web resource metadata used to resolve script and dependency links.

    .PARAMETER IncludeFlows
        Include links from the app to referenced flows.

    .PARAMETER IncludeEntities
        Include links from the app to referenced entities.

    .PARAMETER IncludeDefaultEntities
        Keep unresolved entity references as default-entity links.

    .PARAMETER IncludeWebResources
        Include links to script web resources.

    .EXAMPLE
        Build link data for one model-driven app.

        PS> Get-PowerPlatformCheckerArchitectureModelDrivenAppGraphContent -ModelApp $app -SolutionObject $solution -EntitySetByReference $entityMap -WebResources $scripts -IncludeFlows -IncludeEntities -IncludeWebResources

        Returns graph content plus connected entity/default sets for architecture assembly.
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [object] $ModelApp,

        [Parameter(Mandatory = $true)]
        [object] $SolutionObject,

        [Parameter(Mandatory = $true)]
        [hashtable] $EntitySetByReference,

        [Parameter(Mandatory = $false)]
        [object[]] $WebResources = @(),

        [Parameter(Mandatory = $false)]
        [switch] $IncludeFlows,

        [Parameter(Mandatory = $false)]
        [switch] $IncludeEntities,

        [Parameter(Mandatory = $false)]
        [switch] $IncludeDefaultEntities,

        [Parameter(Mandatory = $false)]
        [switch] $IncludeWebResources
    )

    $modelAppMembers = @()
    foreach ($component in @($ModelApp.Components)) {
        if (-not $component) { continue }
        $componentValue = if (-not [string]::IsNullOrWhiteSpace([string]$component.SchemaName)) { [string]$component.SchemaName } elseif (-not [string]::IsNullOrWhiteSpace([string]$component.Id)) { ([string]$component.Id).Trim('{}') } else { $null }
        if ($componentValue) { $modelAppMembers += "  [$($component.ComponentTypeName)]$componentValue" }
    }

    $nodes = @([pscustomobject]@{ Id = [string]$ModelApp.MermaidId; Type = "ModelDrivenApp"; DisplayName = [string]$ModelApp.DisplayName; ClassKind = "ModelDrivenApp"; Properties = @{}; Members = @($modelAppMembers | Select-Object -Unique); HasExplicitDisplayName = $true })
    $nodes[0].Properties = @{
        Components = @($ModelApp.Components)
        EntityWebResources = @($ModelApp.EntityWebResources)
        FlowIds = @($ModelApp.FlowIds)
        WebResources = @($ModelApp.WebResources)
    }
    $edges = @()
    $connectedEntities = @()
    $connectedDefaultEntities = @()
    $entityLinkedScripts = New-Object 'System.Collections.Generic.HashSet[string]'
    $dependencyScripts = New-Object 'System.Collections.Generic.HashSet[string]'

    foreach ($flowReferenceId in @($ModelApp.FlowIds)) {
        if (-not $IncludeFlows.IsPresent) { continue }
        $edges += [pscustomobject]@{ SourceId = [string]$ModelApp.MermaidId; TargetId = "flow${flowReferenceId}"; Label = "Flow"; EdgeType = "Link"; Metadata = @{ Arrow = "-->" } }
    }

    # Resolve app entities to entity-set nodes; unresolved names remain visible as default nodes.
    foreach ($entityName in @($ModelApp.Entities)) {
        if (-not $IncludeEntities.IsPresent) { continue }
        $entityObj = $SolutionObject.Entities | Where-Object { $_.Name -and $_.EntitySetName -and $_.Name.ToLower() -eq $entityName.ToLower() } | Select-Object -First 1
        if ($entityObj) {
            $resolvedEntitySet = [string]$entityObj.EntitySetName.ToLower()
            $connectedEntities += $resolvedEntitySet
            $edges += [pscustomobject]@{ SourceId = [string]$ModelApp.MermaidId; TargetId = $resolvedEntitySet; Label = "Entity"; EdgeType = "Link"; Metadata = @{ Arrow = "-->" } }
        }
        elseif ($IncludeDefaultEntities.IsPresent -and -not [string]::IsNullOrWhiteSpace([string]$entityName)) {
            $missingEntityId = [string]$entityName.ToLower()
            $edges += [pscustomobject]@{ SourceId = [string]$ModelApp.MermaidId; TargetId = $missingEntityId; Label = "Entity"; EdgeType = "Link"; Metadata = @{ Arrow = "-->" } }
            $connectedDefaultEntities += $missingEntityId
        }
    }

    # Entity-owned scripts are linked from entity nodes (or app node when entities are excluded).
    if ($ModelApp.PSObject.Properties.Name -contains "EntityWebResources") {
        foreach ($entityWebResource in @($ModelApp.EntityWebResources)) {
            if (-not $entityWebResource -or [string]::IsNullOrWhiteSpace([string]$entityWebResource.EntitySchemaName)) {
                continue
            }

            $entitySetName = Get-PowerPlatformCheckerArchitectureDiagramEntitySetName -EntityReference ([string]$entityWebResource.EntitySchemaName) -EntitySetByReference $EntitySetByReference
            if (-not $entitySetName) {
                continue
            }

            foreach ($webResourceName in @($entityWebResource.WebResources)) {
                if (-not $IncludeWebResources.IsPresent) { continue }
                if ([string]::IsNullOrWhiteSpace([string]$webResourceName)) { continue }

                $webResource = $WebResources | Where-Object { $_.Name -eq $webResourceName } | Select-Object -First 1
                if ($webResource) {
                    if ($IncludeEntities.IsPresent) {
                        $edges += [pscustomobject]@{ SourceId = $entitySetName; TargetId = [string]$webResource.MermaidId; Label = "Script"; EdgeType = "Link"; Metadata = @{ Arrow = "-->" } }
                    }
                    else {
                        $edges += [pscustomobject]@{ SourceId = [string]$ModelApp.MermaidId; TargetId = [string]$webResource.MermaidId; Label = "Script"; EdgeType = "Link"; Metadata = @{ Arrow = "-->" } }
                    }
                    [void]$entityLinkedScripts.Add($webResourceName)
                }
            }
        }

        # Capture dependency targets to avoid duplicate direct links for dependency-only scripts.
        foreach ($modelAppWebResourceName in @($ModelApp.WebResources)) {
            if ([string]::IsNullOrWhiteSpace([string]$modelAppWebResourceName)) {
                continue
            }

            $modelAppWebResource = $WebResources | Where-Object { $_.Name -eq $modelAppWebResourceName } | Select-Object -First 1
            if (-not $modelAppWebResource) {
                continue
            }

            foreach ($modelAppDependency in @($modelAppWebResource.Dependencies)) {
                if (-not [string]::IsNullOrWhiteSpace([string]$modelAppDependency)) {
                    [void]$dependencyScripts.Add([string]$modelAppDependency)
                }
            }
        }
    }

    # Add remaining direct app script links once entity/dependency-owned links are handled.
    foreach ($webResourceName in @($ModelApp.WebResources)) {
        if (-not $IncludeWebResources.IsPresent) { continue }
        if ($entityLinkedScripts.Contains([string]$webResourceName)) { continue }
        if ($dependencyScripts.Contains([string]$webResourceName)) { continue }
        $webResource = $WebResources | Where-Object { $_.Name -eq $webResourceName } | Select-Object -First 1
        if ($webResource) {
            $edges += [pscustomobject]@{ SourceId = [string]$ModelApp.MermaidId; TargetId = [string]$webResource.MermaidId; Label = "Script"; EdgeType = "Link"; Metadata = @{ Arrow = "-->" } }
        }
    }

    return [pscustomobject]@{
        Nodes = @($nodes)
        Edges = @($edges)
        ConnectedEntities = @($connectedEntities | Select-Object -Unique)
        ConnectedDefaultEntities = @($connectedDefaultEntities | Select-Object -Unique)
    }
}
