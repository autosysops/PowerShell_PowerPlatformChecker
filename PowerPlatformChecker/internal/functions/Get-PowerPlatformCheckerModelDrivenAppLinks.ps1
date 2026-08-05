function Get-PowerPlatformCheckerModelDrivenAppLinks {
    <#
    .SYNOPSIS
        Builds model-driven app link lines and connected-node updates for architecture diagrams.

    .DESCRIPTION
        Generates links from a model-driven app node to related flows, entities,
        and scripts, while tracking connected entity/default sets for downstream
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

    .PARAMETER NewLine
        Line separator used when composing Mermaid output.

    .EXAMPLE
        Build link data for one model-driven app.

        PS> Get-PowerPlatformCheckerModelDrivenAppLinks -ModelApp $app -SolutionObject $solution -EntitySetByReference $entityMap -WebResources $scripts -IncludeFlows -IncludeEntities -IncludeWebResources

        Returns link lines plus connected entity/default sets for architecture assembly.
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Helper returns multiple links and keeps established naming in refactor.')]
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
        [switch] $IncludeWebResources,

        [Parameter(Mandatory = $false)]
        [string] $NewLine = [Environment]::NewLine
    )

    $links = @()
    $connectedEntities = @()
    $connectedDefaultEntities = @()
    $entityLinkedScripts = New-Object 'System.Collections.Generic.HashSet[string]'
    $dependencyScripts = New-Object 'System.Collections.Generic.HashSet[string]'

    foreach ($flowReferenceId in @($ModelApp.FlowIds)) {
        if (-not $IncludeFlows.IsPresent) { continue }
        $links += "$($ModelApp.MermaidId) --> flow${flowReferenceId}:Flow$NewLine"
    }

    # Resolve app entities to entity-set nodes; unresolved names remain visible as default nodes.
    foreach ($entityName in @($ModelApp.Entities)) {
        if (-not $IncludeEntities.IsPresent) { continue }
        $entityObj = $SolutionObject.Entities | Where-Object { $_.Name -and $_.EntitySetName -and $_.Name.ToLower() -eq $entityName.ToLower() } | Select-Object -First 1
        if ($entityObj) {
            $resolvedEntitySet = [string]$entityObj.EntitySetName.ToLower()
            $connectedEntities += $resolvedEntitySet
            $links += "$($ModelApp.MermaidId) --> ${resolvedEntitySet}:Entity$NewLine"
        }
        elseif ($IncludeDefaultEntities.IsPresent -and -not [string]::IsNullOrWhiteSpace([string]$entityName)) {
            $missingEntityId = [string]$entityName.ToLower()
            $links += "$($ModelApp.MermaidId) --> ${missingEntityId}:Entity$NewLine"
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
                        $links += "${entitySetName} --> $($webResource.MermaidId):Script$NewLine"
                    }
                    else {
                        $links += "$($ModelApp.MermaidId) --> $($webResource.MermaidId):Script$NewLine"
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
            $links += "$($ModelApp.MermaidId) --> $($webResource.MermaidId):Script$NewLine"
        }
    }

    return [pscustomobject]@{
        Links = @($links)
        ConnectedEntities = @($connectedEntities | Select-Object -Unique)
        ConnectedDefaultEntities = @($connectedDefaultEntities | Select-Object -Unique)
    }
}
