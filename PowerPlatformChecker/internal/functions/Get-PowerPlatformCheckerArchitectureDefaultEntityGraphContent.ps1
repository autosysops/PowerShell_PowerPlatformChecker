function Get-PowerPlatformCheckerArchitectureDefaultEntityGraphContent {
    <#
    .SYNOPSIS
        Builds unresolved/default entity nodes for an architecture diagram.

    .DESCRIPTION
        Merges default-entity candidates from canvas/entity/model-driven passes,
        applies scope rules, suppresses ids that resolved to rendered in-solution
        entities, and returns graph nodes.

    .PARAMETER IncludePolicy
        Include/exclude policy object resolved for this diagram request.

    .PARAMETER IsScopedDiagram
        Indicates whether rendering is constrained to selected connected nodes.

    .PARAMETER DefaultEntitiesInCanvasApps
        Default entity candidates discovered from canvas app data sources.

    .PARAMETER ConnectedDefaultEntities
        Default entity candidates discovered from relation/link processing.

    .PARAMETER EntitySetByReference
        Lookup table that maps logical/entity references to canonical entity set names.

    .PARAMETER RenderedEntityNodeIds
        Entity node ids already rendered as regular Entity classes.

    .EXAMPLE
        Select default entity nodes for architecture rendering.

        PS> Get-PowerPlatformCheckerArchitectureDefaultEntityGraphContent -IncludePolicy $policy -ConnectedDefaultEntities $defaults -EntitySetByReference $entityMap

        Returns unresolved/default entity graph nodes for the current view.
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [object] $IncludePolicy,

        [Parameter(Mandatory = $false)]
        [switch] $IsScopedDiagram,

        [Parameter(Mandatory = $false)]
        [string[]] $DefaultEntitiesInCanvasApps = @(),

        [Parameter(Mandatory = $false)]
        [string[]] $ConnectedDefaultEntities = @(),

        [Parameter(Mandatory = $true)]
        [hashtable] $EntitySetByReference,

        [Parameter(Mandatory = $false)]
        [string[]] $RenderedEntityNodeIds = @()
    )

    if (-not $IncludePolicy.IncludeDefaultEntities) {
        return [pscustomobject]@{ Nodes = @(); Edges = @() }
    }

    $candidates = @($DefaultEntitiesInCanvasApps + $ConnectedDefaultEntities | Where-Object { $_ } | Select-Object -Unique)
    if ($IsScopedDiagram.IsPresent) {
        $candidates = @($candidates | Where-Object { $_ -in $ConnectedDefaultEntities })
    }

    $result = @()
    foreach ($entity in $candidates) {
        # If this reference resolves to an entity node that was already rendered, skip it.
        $resolvedEntitySet = Get-PowerPlatformCheckerArchitectureDiagramEntitySetName -EntityReference ([string]$entity) -EntitySetByReference $EntitySetByReference
        if ($resolvedEntitySet -and $resolvedEntitySet -in $RenderedEntityNodeIds) {
            continue
        }

        if ($entity -notin $RenderedEntityNodeIds) {
            $result += [string]$entity
        }
    }

    $nodes = @($result | Select-Object -Unique | ForEach-Object {
            [pscustomobject]@{ Id = [string]$_; Type = "DefaultEntity"; DisplayName = [string]$_; ClassKind = "DefaultEntity"; Properties = @{}; Members = @(); HasExplicitDisplayName = $false }
        })

    return [pscustomobject]@{ Nodes = $nodes; Edges = @() }
}
