function Get-PowerPlatformCheckerCanvasDiagramContent {
    <#
    .SYNOPSIS
        Builds Mermaid canvas app nodes and associated links.

    .DESCRIPTION
        Produces canvas app class nodes and connection/entity/default links derived
        from canvas app connection references and data source metadata.

    .PARAMETER CanvasAppsToRender
        Canvas app records selected for rendering.

    .PARAMETER EntitySetByReference
        Lookup table that maps logical/entity references to canonical entity set names.

    .PARAMETER KnownEntitySetNames
        Known in-solution entity set names used to distinguish default references.

    .PARAMETER IncludeConnections
        Include connection reference links from canvas apps.

    .PARAMETER IncludeEntities
        Include links to resolved in-solution entities.

    .PARAMETER IncludeDefaultEntities
        Include unresolved data source references as default entity nodes.

    .PARAMETER NewLine
        Line separator used when composing Mermaid output.

    .EXAMPLE
        Build canvas app node and link content for architecture assembly.

        PS> Get-PowerPlatformCheckerCanvasDiagramContent -CanvasAppsToRender $apps -EntitySetByReference $entityMap -KnownEntitySetNames $known -IncludeConnections -IncludeEntities

        Returns Mermaid class text plus connection/entity/default link collections.
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)]
        [object[]] $CanvasAppsToRender = @(),

        [Parameter(Mandatory = $true)]
        [hashtable] $EntitySetByReference,

        [Parameter(Mandatory = $false)]
        [string[]] $KnownEntitySetNames = @(),

        [Parameter(Mandatory = $false)]
        [switch] $IncludeConnections,

        [Parameter(Mandatory = $false)]
        [switch] $IncludeEntities,

        [Parameter(Mandatory = $false)]
        [switch] $IncludeDefaultEntities,

        [Parameter(Mandatory = $false)]
        [string] $NewLine = [Environment]::NewLine
    )

    $diagram = ""
    $links = @()
    $connectedConnections = @()
    $connectedEntities = @()
    $defaultEntitiesInCanvasApps = @()
    $connectedDefaultEntities = @()

    foreach ($canvasApp in @($CanvasAppsToRender)) {
        $canvasKey = if ($canvasApp.Name) { [string]$canvasApp.Name } elseif ($canvasApp.DisplayName) { [string]$canvasApp.DisplayName } else { $null }
        if (-not $canvasKey) {
            continue
        }

        $canvasId = Convert-PowerPlatformCheckerMermaidId -InputString $canvasKey
        $canvasDisplayName = if ($canvasApp.DisplayName) { [string]$canvasApp.DisplayName } else { $canvasKey }
        $diagram += ('class {0}["{1}"]:::CanvasApp{2}' -f $canvasId, $canvasDisplayName, $NewLine)

        # Connection reference edges show which connectors are used by this canvas app.
        foreach ($connection in @($canvasApp.ConnectionReferences)) {
            if (-not $IncludeConnections.IsPresent) { continue }
            if (-not $connection.id) { continue }
            $connectorName = $connection.id.Split("/")[-1]
            $links += "${connectorName} --> ${canvasId}:$connectorName$NewLine"
            $connectedConnections += $connectorName
        }

        # Data source metadata maps app usage to in-solution entities or unresolved defaults.
        foreach ($dataSource in @($canvasApp.DataSources.DataSources)) {
            if (-not $IncludeEntities.IsPresent -and -not $IncludeDefaultEntities.IsPresent) { continue }
            $resolvedEntitySetName = if ($dataSource.entitySetName) { Get-PowerPlatformCheckerArchitectureDiagramEntitySetName -EntityReference ([string]$dataSource.entitySetName) -EntitySetByReference $EntitySetByReference } else { $null }
            if ($resolvedEntitySetName -and $resolvedEntitySetName -in $KnownEntitySetNames) {
                if (-not $IncludeEntities.IsPresent) { continue }
                $links += "${canvasId} --> ${resolvedEntitySetName}:$($dataSource.Name)$NewLine"
                $connectedEntities += $resolvedEntitySetName
            }
            elseif ($dataSource.logicalName) {
                $resolvedLogicalEntitySetName = Get-PowerPlatformCheckerArchitectureDiagramEntitySetName -EntityReference ([string]$dataSource.logicalName) -EntitySetByReference $EntitySetByReference
                if ($resolvedLogicalEntitySetName -and $resolvedLogicalEntitySetName -in $KnownEntitySetNames) {
                    if (-not $IncludeEntities.IsPresent) { continue }
                    $links += "${canvasId} --> ${resolvedLogicalEntitySetName}:$($dataSource.Name)$NewLine"
                    $connectedEntities += $resolvedLogicalEntitySetName
                }
                else {
                    if (-not $IncludeDefaultEntities.IsPresent) { continue }
                    $links += "${canvasId} --> $($dataSource.logicalName.ToLower()):$($dataSource.Name)$NewLine"
                    $defaultEntitiesInCanvasApps += $dataSource.logicalName.ToLower()
                    $connectedDefaultEntities += $dataSource.logicalName.ToLower()
                }
            }
        }
    }

    return [pscustomobject]@{
        DiagramText = $diagram
        Links = @($links)
        ConnectedConnections = @($connectedConnections | Select-Object -Unique)
        ConnectedEntities = @($connectedEntities | Select-Object -Unique)
        DefaultEntitiesInCanvasApps = @($defaultEntitiesInCanvasApps | Select-Object -Unique)
        ConnectedDefaultEntities = @($connectedDefaultEntities | Select-Object -Unique)
    }
}
