function Get-PowerPlatformCheckerDiagramConnections {
    <#
    .SYNOPSIS
        Selects connection reference nodes that should be rendered.

    .DESCRIPTION
        Returns all connection references for full diagrams, or only those linked
        by rendered components for scoped diagrams.

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

        PS> Get-PowerPlatformCheckerDiagramConnections -SolutionObject $solution -IncludePolicy $policy -IsScopedDiagram -ConnectedConnectorNames $connected

        Returns connection references that should be declared for the current view.
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Internal helper name intentionally mirrors IncludeElements value Connections.')]
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
        [string[]] $ConnectedConnectorNames = @()
    )

    if (-not $IncludePolicy.IncludeConnections) {
        return @()
    }

    $connections = @($SolutionObject.ConnectionReferences | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.ConnectorId) })
    if (-not $IsScopedDiagram.IsPresent) {
        return $connections
    }

    # Convert connector ids to Mermaid-safe node ids before scoped membership filtering.
    $connected = @($ConnectedConnectorNames | Where-Object { $_ } | Select-Object -Unique)
    return @($connections | Where-Object {
            $connectorName = Convert-PowerPlatformCheckerMermaidId -InputString ($_.ConnectorId.Split("/")[-1])
            $connectorName -in $connected
        })
}
