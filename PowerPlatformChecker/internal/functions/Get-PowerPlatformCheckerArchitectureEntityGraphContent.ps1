function Get-PowerPlatformCheckerArchitectureEntityGraphContent {
    <#
    .SYNOPSIS
        Builds Mermaid entity class content and entity-driven relation/script/icon links.

    .DESCRIPTION
        Renders entity class blocks and relation links, and optionally includes
        linked form scripts and icon resources for each entity.

    .PARAMETER SolutionObject
        Aggregated solution metadata containing entity records.

    .PARAMETER IncludeEntities
        Include entity nodes and links in the architecture projection.

    .PARAMETER ConnectedEntitySetNames
        Entity set names connected to selected components in a scoped diagram.

    .PARAMETER DefaultFields
        Default/system attribute names that may be omitted in scoped diagrams.

    .PARAMETER IsScopedDiagram
        Indicates whether rendering is constrained to selected connected nodes.

    .PARAMETER IncludeDefaultEntities
        Include unresolved relation endpoints as default entity nodes.

    .PARAMETER IncludeWebResources
        Include form script and icon web resource links.

    .PARAMETER EntityByLogicalName
        Lookup table from entity logical name to entity metadata object.

    .PARAMETER WebResources
        JavaScript web resource metadata used to resolve script links.

    .PARAMETER IconResources
        Icon web resource metadata used to resolve icon links.

    .EXAMPLE
        Build entity class and relation content for diagram assembly.

        PS> Get-PowerPlatformCheckerArchitectureEntityGraphContent -SolutionObject $solution -EntityByLogicalName $entityMap -WebResources $scripts -IconResources $icons -IncludeEntities -IncludeWebResources

        Returns Mermaid class text and links derived from entity metadata and relations.
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [object] $SolutionObject,

        [Parameter(Mandatory = $false)]
        [switch] $IncludeEntities,

        [Parameter(Mandatory = $false)]
        [string[]] $ConnectedEntitySetNames = @(),

        [Parameter(Mandatory = $false)]
        [string[]] $DefaultFields = @(),

        [Parameter(Mandatory = $false)]
        [switch] $IsScopedDiagram,

        [Parameter(Mandatory = $false)]
        [switch] $IncludeDefaultEntities,

        [Parameter(Mandatory = $false)]
        [switch] $IncludeWebResources,

        [Parameter(Mandatory = $true)]
        [hashtable] $EntityByLogicalName,

        [Parameter(Mandatory = $false)]
        [object[]] $WebResources = @(),

        [Parameter(Mandatory = $false)]
        [object[]] $IconResources = @()
    )

    $nodes = @()
    $edges = @()
    $connectedEntities = @()
    $connectedDefaultEntities = @()
    $connectedIconResources = @()
    $iconNodes = @()
    $renderedEntityNodeIds = @()

    $entitiesToRender = @()
    if ($IncludeEntities.IsPresent) {
        $entitiesToRender = @($SolutionObject.Entities | Where-Object { $_ -and -not [string]::IsNullOrWhiteSpace([string]$_.EntitySetName) })
        if ($IsScopedDiagram.IsPresent) {
            $connected = @($ConnectedEntitySetNames | Where-Object { $_ } | Select-Object -Unique)
            $entitiesToRender = @($entitiesToRender | Where-Object { ([string]$_.EntitySetName).Trim().ToLower() -in $connected })
        }
    }

    foreach ($entity in @($entitiesToRender)) {
        if (-not $entity -or [string]::IsNullOrWhiteSpace([string]$entity.EntitySetName)) {
            continue
        }

        $entitySetName = $entity.EntitySetName.Trim().ToLower()
        $entityDisplayName = if ($entity.Name) { [string]$entity.Name } else { [string]$entitySetName }
        $renderedEntityNodeIds += $entitySetName
        $members = @()

        foreach ($attribute in @($entity.Attributes)) {
            if (-not $attribute.Name) {
                continue
            }
            if ($attribute.Name -in $DefaultFields -and $IsScopedDiagram.IsPresent) {
                continue
            }
            $members += "    [$($attribute.Type)]$($attribute.Name)"
        }
        $nodes += [pscustomobject]@{ Id = $entitySetName; Type = "Entity"; DisplayName = $entityDisplayName; ClassKind = "Entity"; Properties = @{}; Members = @($members); HasExplicitDisplayName = $true }

        # Relation links connect entity nodes and preserve unresolved endpoints as defaults.
        foreach ($relation in @($entity.Relations)) {
            if (-not $relation.Source -or -not $relation.Target) {
                continue
            }

            if ($IsScopedDiagram.IsPresent -and $entity.Name -and $relation.Source -and $relation.Source.ToLower() -ne $entity.Name.ToLower()) {
                continue
            }

            $relationSourceKey = [string]$relation.Source.ToLower()
            $relationTargetKey = [string]$relation.Target.ToLower()
            $sourceEntityObj = if ($EntityByLogicalName.ContainsKey($relationSourceKey)) { $EntityByLogicalName[$relationSourceKey] } else { $null }
            $targetEntityObj = if ($EntityByLogicalName.ContainsKey($relationTargetKey)) { $EntityByLogicalName[$relationTargetKey] } else { $null }

            if ($sourceEntityObj -and $targetEntityObj) {
                $sourceEntity = $sourceEntityObj.EntitySetName.ToLower()
                $targetEntity = $targetEntityObj.EntitySetName.ToLower()
                $edges += [pscustomobject]@{ SourceId = $sourceEntity; TargetId = $targetEntity; Label = "$($relation.Source)-$($relation.Type)"; EdgeType = "Link"; Metadata = @{ Arrow = "-->" } }
                $connectedEntities += $sourceEntity
                $connectedEntities += $targetEntity
            }
            elseif ($sourceEntityObj) {
                if (-not $IncludeDefaultEntities.IsPresent) { continue }
                $sourceEntity = $sourceEntityObj.EntitySetName.ToLower()
                $edges += [pscustomobject]@{ SourceId = $sourceEntity; TargetId = [string]$relation.Target.ToLower(); Label = [string]$relation.Type; EdgeType = "Link"; Metadata = @{ Arrow = "-->" } }
                $connectedDefaultEntities += $relation.Target.ToLower()
            }
            else {
                if (-not $IncludeDefaultEntities.IsPresent) { continue }
                if ($targetEntityObj) {
                    $targetEntity = $targetEntityObj.EntitySetName.ToLower()
                    $edges += [pscustomobject]@{ SourceId = $targetEntity; TargetId = [string]$relation.Source.ToLower(); Label = [string]$relation.Type; EdgeType = "Link"; Metadata = @{ Arrow = "-->" } }
                    $connectedDefaultEntities += $relation.Source.ToLower()
                }
            }
        }

        # Attach form scripts/icons so entity nodes explain their UI script dependencies.
        if ($IncludeWebResources.IsPresent) {
            foreach ($formWebResourceName in @($entity.FormWebResources)) {
                if ([string]::IsNullOrWhiteSpace([string]$formWebResourceName)) {
                    continue
                }

                $formWebResource = $WebResources | Where-Object { $_.Name -eq $formWebResourceName } | Select-Object -First 1
                if ($formWebResource) {
                    $edges += [pscustomobject]@{ SourceId = $entitySetName; TargetId = [string]$formWebResource.MermaidId; Label = "Script"; EdgeType = "Link"; Metadata = @{ Arrow = "-->" } }
                }
            }

            foreach ($iconMetadata in @($entity.IconResources)) {
                if (-not $iconMetadata -or [string]::IsNullOrWhiteSpace([string]$iconMetadata.WebResourceName)) {
                    continue
                }

                $iconResource = $IconResources | Where-Object { $_.Name -eq $iconMetadata.WebResourceName } | Select-Object -First 1
                if ($iconResource) {
                    $iconFieldName = if ($iconMetadata.FieldName) { [string]$iconMetadata.FieldName } else { 'Icon' }
                    $edges += [pscustomobject]@{ SourceId = $entitySetName; TargetId = [string]$iconResource.MermaidId; Label = $iconFieldName; EdgeType = "Link"; Metadata = @{ Arrow = "-->" } }
                    $connectedIconResources += $iconResource.Name
                    $iconNodes += [pscustomobject]@{ Id = [string]$iconResource.MermaidId; Type = "WebResource"; DisplayName = [string]$iconResource.DisplayName; ClassKind = "WebResource"; Properties = @{}; Members = @("  [Icon]$($iconResource.Type)"); HasExplicitDisplayName = $true }
                }
            }
        }
    }

    return [pscustomobject]@{
        Nodes = @($nodes)
        IconNodes = @($iconNodes)
        Edges = @($edges)
        ConnectedEntities = @($connectedEntities | Select-Object -Unique)
        ConnectedDefaultEntities = @($connectedDefaultEntities | Select-Object -Unique)
        ConnectedIconResources = @($connectedIconResources | Select-Object -Unique)
        RenderedEntityNodeIds = @($renderedEntityNodeIds | Select-Object -Unique)
    }
}
