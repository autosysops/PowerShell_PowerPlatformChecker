function Get-PowerPlatformCheckerArchitectureConnectionGraphContent {
    <#
    .SYNOPSIS
        Builds connection reference nodes for an architecture diagram.

    .DESCRIPTION
        Selects all connection references for full diagrams, or only those linked
        by rendered components for scoped diagrams, and returns graph nodes.

    .PARAMETER SolutionObject
        Aggregated solution metadata containing connection references.

    .PARAMETER IncludePolicy
        Include/exclude policy object resolved for this diagram request.

    .PARAMETER IsScopedDiagram
        Indicates whether the diagram is filtered to a selected component scope.

    .PARAMETER ConnectedConnectorNames
        Connector node ids that are linked by already rendered components.

    .EXAMPLE
        Select connection references for architecture rendering.

        PS> Get-PowerPlatformCheckerArchitectureConnectionGraphContent -SolutionObject $solution -IncludePolicy $policy -IsScopedDiagram -ConnectedConnectorNames $connected

        Returns connection reference graph nodes for the current view.
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
        [string[]] $ConnectedConnectorNames = @()
    )

    if (-not $IncludePolicy.IncludeConnections) {
        return [pscustomobject]@{ Nodes = @(); Edges = @() }
    }

    $connections = @($SolutionObject.ConnectionReferences | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.ConnectorId) })
    if ($IsScopedDiagram.IsPresent) {
        $connected = @($ConnectedConnectorNames | Where-Object { $_ } | Select-Object -Unique)
        $connections = @($connections | Where-Object {
                $connectorName = Convert-PowerPlatformCheckerMermaidId -InputString ($_.ConnectorId.Split("/")[-1])
                $connectorName -in $connected
            })
    }

    $nodes = @($connections | ForEach-Object {
            $connectorName = Convert-PowerPlatformCheckerMermaidId -InputString ($_.ConnectorId.Split("/")[-1])
            [pscustomobject]@{ Id = $connectorName; Type = "Connection"; DisplayName = $connectorName; ClassKind = "Connection"; Properties = @{}; Members = @("  ConnectionReference", "  $($_.DisplayName)()"); HasExplicitDisplayName = $false }
        })

    return [pscustomobject]@{ Nodes = $nodes; Edges = @() }
}
