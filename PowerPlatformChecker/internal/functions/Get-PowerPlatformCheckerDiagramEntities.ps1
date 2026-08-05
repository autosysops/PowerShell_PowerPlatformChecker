function Get-PowerPlatformCheckerDiagramEntities {
    <#
    .SYNOPSIS
        Selects entity records for architecture diagram rendering.

    .DESCRIPTION
        Returns all entities for full diagrams, or only connected entity sets for
        scoped diagrams.

    .PARAMETER SolutionObject
        Aggregated solution metadata containing entity records.

    .PARAMETER IncludePolicy
        Include/exclude policy object resolved for this diagram request.

    .PARAMETER IsScopedDiagram
        Indicates whether the diagram is filtered to a selected component scope.

    .PARAMETER ConnectedEntitySetNames
        Entity set names that are linked by already rendered components.

    .EXAMPLE
        Select entities for architecture rendering.

        PS> Get-PowerPlatformCheckerDiagramEntities -SolutionObject $solution -IncludePolicy $policy -IsScopedDiagram -ConnectedEntitySetNames $connected

        Returns entity records that should be declared for the current diagram projection.
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Internal helper name intentionally mirrors IncludeElements value Entities.')]
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [object] $SolutionObject,

        [Parameter(Mandatory = $true)]
        [object] $IncludePolicy,

        [Parameter(Mandatory = $false)]
        [switch] $IsScopedDiagram,

        [Parameter(Mandatory = $false)]
        [string[]] $ConnectedEntitySetNames = @()
    )

    if (-not $IncludePolicy.IncludeEntities) {
        return @()
    }

    $entities = @($SolutionObject.Entities | Where-Object { $_ -and -not [string]::IsNullOrWhiteSpace([string]$_.EntitySetName) })
    if (-not $IsScopedDiagram.IsPresent) {
        return $entities
    }

    # Compare against normalized entity set names to keep scoped rendering deterministic.
    $connected = @($ConnectedEntitySetNames | Where-Object { $_ } | Select-Object -Unique)
    return @($entities | Where-Object { ([string]$_.EntitySetName).Trim().ToLower() -in $connected })
}
