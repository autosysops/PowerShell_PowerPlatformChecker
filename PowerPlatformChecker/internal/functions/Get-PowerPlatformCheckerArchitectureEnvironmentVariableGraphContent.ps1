function Get-PowerPlatformCheckerArchitectureEnvironmentVariableGraphContent {
    <#
    .SYNOPSIS
        Builds environment variable nodes for an architecture diagram.

    .DESCRIPTION
        Selects all environment variables for full diagrams, or only variables
        connected by rendered links for scoped diagrams, and returns graph nodes.

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

        PS> Get-PowerPlatformCheckerArchitectureEnvironmentVariableGraphContent -SolutionObject $solution -IncludePolicy $policy -IsScopedDiagram -ConnectedNames $connected

        Returns environment variable graph nodes for the current view.
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
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
        return [pscustomobject]@{ Nodes = @(); Edges = @() }
    }

    $envVars = @($SolutionObject.EnvironmentVariables | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.Name) })
    if ($IsScopedDiagram.IsPresent) {
        $connected = @($ConnectedNames | Where-Object { $_ } | Select-Object -Unique)
        $envVars = @($envVars | Where-Object { $_.Name -in $connected })
    }

    $nodes = @($envVars | ForEach-Object {
            [pscustomobject]@{ Id = [string]$_.Name; Type = "EnvVar"; DisplayName = [string]$_.Name; ClassKind = "EnvVar"; Properties = @{}; Members = @("  EnvironmentalVariable"); HasExplicitDisplayName = $false }
        })

    $knownNodeIds = @($nodes | ForEach-Object { [string]$_.Id } | Select-Object -Unique)
    foreach ($connectedName in @($ConnectedNames | Where-Object { $_ } | Select-Object -Unique)) {
        if ($connectedName -in $knownNodeIds) {
            continue
        }

        $nodes += [pscustomobject]@{
            Id = [string]$connectedName
            Type = "EnvVar"
            DisplayName = [string]$connectedName
            ClassKind = "EnvVar"
            Properties = @{}
            Members = @("  EnvironmentalVariable")
            HasExplicitDisplayName = $false
        }
    }

    return [pscustomobject]@{ Nodes = $nodes; Edges = @() }
}
