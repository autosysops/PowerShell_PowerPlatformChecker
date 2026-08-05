function Get-PowerPlatformCheckerEntityDiagramContent {
    <#
    .SYNOPSIS
        Builds Mermaid entity class content and entity-driven relation/script/icon links.

    .DESCRIPTION
        Renders entity class blocks and relation links, and optionally includes
        linked form scripts and icon resources for each entity.

    .PARAMETER EntitiesToRender
        Entity records selected for diagram rendering.

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

    .PARAMETER NewLine
        Line separator used when composing Mermaid output.

    .EXAMPLE
        Build entity class and relation content for diagram assembly.

        PS> Get-PowerPlatformCheckerEntityDiagramContent -EntitiesToRender $entities -EntityByLogicalName $entityMap -WebResources $scripts -IconResources $icons -IncludeWebResources

        Returns Mermaid class text and links derived from entity metadata and relations.
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)]
        [object[]] $EntitiesToRender = @(),

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
        [object[]] $IconResources = @(),

        [Parameter(Mandatory = $false)]
        [string] $NewLine = [Environment]::NewLine
    )

    $diagram = ""
    $links = @()
    $connectedEntities = @()
    $connectedDefaultEntities = @()
    $connectedIconResources = @()
    $renderedEntityNodeIds = @()

    foreach ($entity in @($EntitiesToRender)) {
        if (-not $entity -or [string]::IsNullOrWhiteSpace([string]$entity.EntitySetName)) {
            continue
        }

        $entitySetName = $entity.EntitySetName.Trim().ToLower()
        $entityDisplayName = if ($entity.Name) { [string]$entity.Name } else { [string]$entitySetName }
        $diagram += ('class {0}["{1}"]:::Entity {{{2}' -f $entitySetName, $entityDisplayName, $NewLine)
        $renderedEntityNodeIds += $entitySetName

        foreach ($attribute in @($entity.Attributes)) {
            if (-not $attribute.Name) {
                continue
            }
            if ($attribute.Name -in $DefaultFields -and $IsScopedDiagram.IsPresent) {
                continue
            }
            $diagram += "    [$($attribute.Type)]$($attribute.Name)$NewLine"
        }
        $diagram += "}$NewLine"

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
                $links += "${sourceEntity} --> ${targetEntity}:$($relation.Source)-$($relation.Type)$NewLine"
                $connectedEntities += $sourceEntity
                $connectedEntities += $targetEntity
            }
            elseif ($sourceEntityObj) {
                if (-not $IncludeDefaultEntities.IsPresent) { continue }
                $sourceEntity = $sourceEntityObj.EntitySetName.ToLower()
                $links += "${sourceEntity} --> $($relation.Target.ToLower()):$($relation.Type)$NewLine"
                $connectedDefaultEntities += $relation.Target.ToLower()
            }
            else {
                if (-not $IncludeDefaultEntities.IsPresent) { continue }
                if ($targetEntityObj) {
                    $targetEntity = $targetEntityObj.EntitySetName.ToLower()
                    $links += "${targetEntity} --> $($relation.Source.ToLower()):$($relation.Type)$NewLine"
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
                    $links += "${entitySetName} --> $($formWebResource.MermaidId):Script$NewLine"
                }
            }

            foreach ($iconMetadata in @($entity.IconResources)) {
                if (-not $iconMetadata -or [string]::IsNullOrWhiteSpace([string]$iconMetadata.WebResourceName)) {
                    continue
                }

                $iconResource = $IconResources | Where-Object { $_.Name -eq $iconMetadata.WebResourceName } | Select-Object -First 1
                if ($iconResource) {
                    $iconFieldName = if ($iconMetadata.FieldName) { [string]$iconMetadata.FieldName } else { 'Icon' }
                    $links += "${entitySetName} --> $($iconResource.MermaidId):$iconFieldName$NewLine"
                    $connectedIconResources += $iconResource.Name
                }
            }
        }
    }

    return [pscustomobject]@{
        DiagramText = $diagram
        Links = @($links)
        ConnectedEntities = @($connectedEntities | Select-Object -Unique)
        ConnectedDefaultEntities = @($connectedDefaultEntities | Select-Object -Unique)
        ConnectedIconResources = @($connectedIconResources | Select-Object -Unique)
        RenderedEntityNodeIds = @($renderedEntityNodeIds | Select-Object -Unique)
    }
}
