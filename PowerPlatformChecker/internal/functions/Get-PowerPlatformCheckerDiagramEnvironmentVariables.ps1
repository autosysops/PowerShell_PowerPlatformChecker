function Get-PowerPlatformCheckerDiagramEnvironmentVariables {
    <#
    .SYNOPSIS
        Selects environment variables that should be declared in the diagram.

    .DESCRIPTION
        Returns all environment variables for full diagrams, or only variables
        connected by rendered links for scoped diagrams.

    .PARAMETER SolutionObject
        Aggregated solution metadata containing environment variables.

    .PARAMETER IncludePolicy
        Include/exclude policy object resolved for this diagram request.

    .PARAMETER IsScopedDiagram
        Indicates whether the diagram is filtered to a selected component scope.

    .PARAMETER ConnectedNames
        Environment variable schema names linked by rendered components.

    .EXAMPLE
        Select environment variables for architecture rendering.

        PS> Get-PowerPlatformCheckerDiagramEnvironmentVariables -SolutionObject $solution -IncludePolicy $policy -IsScopedDiagram -ConnectedNames $connected

        Returns environment variables that should be declared for the current view.
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Internal helper name intentionally mirrors IncludeElements value EnvironmentVariables.')]
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
        [string[]] $ConnectedNames = @()
    )

    if (-not $IncludePolicy.IncludeEnvironmentVariables) {
        return @()
    }

    $envVars = @($SolutionObject.EnvironmentVariables | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.Name) })
    if (-not $IsScopedDiagram.IsPresent) {
        return $envVars
    }

    # Scoped diagrams should only declare nodes that are actually linked.
    $connected = @($ConnectedNames | Where-Object { $_ } | Select-Object -Unique)
    return @($envVars | Where-Object { $_.Name -in $connected })
}
