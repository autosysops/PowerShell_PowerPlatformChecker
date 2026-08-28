function Get-PowerPlatformCheckerArchitectureCanvasAppGraphContent {
    <#
    .SYNOPSIS
        Builds Mermaid canvas app nodes and associated links.

    .DESCRIPTION
        Produces canvas app class nodes and connection/entity/default links derived
        from canvas app connection references and data source metadata.

    .PARAMETER SolutionObject
        Aggregated solution metadata containing canvas app records.

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

    .PARAMETER IncludeExternalDomains
        Include external-domain target nodes and edges inferred from canvas app datasource profiles.

    .PARAMETER IncludeCanvasApps
        Include canvas apps in the architecture projection.

    .PARAMETER HasFlowFilter
        Indicates whether rendering is scoped to a flow, which suppresses canvas apps.

    .PARAMETER HasModelDrivenFilter
        Indicates whether rendering is scoped to a model-driven app, which suppresses canvas apps.

    .PARAMETER CanvasAppName
        Optional canvas app internal name used for focused rendering.

    .EXAMPLE
        Build canvas app node and link content for architecture assembly.

        PS> Get-PowerPlatformCheckerArchitectureCanvasAppGraphContent -SolutionObject $solution -EntitySetByReference $entityMap -KnownEntitySetNames $known -IncludeCanvasApps -IncludeConnections -IncludeEntities

        Returns Mermaid class text plus connection/entity/default link collections.
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [object] $SolutionObject,

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
        [switch] $IncludeExternalDomains,

        [Parameter(Mandatory = $false)]
        [switch] $IncludeCanvasApps,

        [Parameter(Mandatory = $false)]
        [switch] $HasFlowFilter,

        [Parameter(Mandatory = $false)]
        [switch] $HasModelDrivenFilter,

        [Parameter(Mandatory = $false)]
        [string] $CanvasAppName
    )

    $nodes = @()
    $edges = @()
    $connectedConnections = @()
    $connectedEntities = @()
    $defaultEntitiesInCanvasApps = @()
    $connectedDefaultEntities = @()

    $canvasAppsToRender = @()
    if ($IncludeCanvasApps.IsPresent -and -not $HasFlowFilter.IsPresent -and -not $HasModelDrivenFilter.IsPresent) {
        $canvasAppsToRender = @($SolutionObject.CanvasApps)
        if (-not [string]::IsNullOrWhiteSpace([string]$CanvasAppName)) {
            $canvasAppsToRender = @($canvasAppsToRender | Where-Object { $_ -and $_.Name -eq $CanvasAppName })
        }
    }

    foreach ($canvasApp in @($canvasAppsToRender)) {
        $canvasKey = if ($canvasApp.Name) { [string]$canvasApp.Name } elseif ($canvasApp.DisplayName) { [string]$canvasApp.DisplayName } else { $null }
        if (-not $canvasKey) {
            continue
        }

        $canvasId = Convert-PowerPlatformCheckerMermaidId -InputString $canvasKey
        $canvasDisplayName = if ($canvasApp.DisplayName) { [string]$canvasApp.DisplayName } else { $canvasKey }
        $destinationMetadata = Get-PowerPlatformCheckerCanvasDestinationProfile -CanvasApp $canvasApp
        $nodes += [pscustomobject]@{
            Id = $canvasId
            Type = "CanvasApp"
            DisplayName = $canvasDisplayName
            ClassKind = "CanvasApp"
            Properties = @{
                Destination = [string]$destinationMetadata.Destination
                DestinationType = [string]$destinationMetadata.DestinationType
                DestinationConfidence = [string]$destinationMetadata.DestinationConfidence
                DestinationEvidence = [string]$destinationMetadata.DestinationEvidence
                InteractionDirection = if ([string]::IsNullOrWhiteSpace([string]$canvasApp.InteractionDirection)) { 'Unknown' } else { [string]$canvasApp.InteractionDirection }
                InteractionEvidence = if ([string]::IsNullOrWhiteSpace([string]$canvasApp.InteractionEvidence)) { 'NoInteractionSignal' } else { [string]$canvasApp.InteractionEvidence }
                SourceSignals = @($canvasApp.SourceSignals)
            }
            Members = @()
            HasExplicitDisplayName = $true
        }

        # Connection reference edges show which connectors are used by this canvas app.
        foreach ($connection in @($canvasApp.ConnectionReferences)) {
            if (-not $IncludeConnections.IsPresent) { continue }
            if (-not $connection.id) { continue }
            $connectorName = $connection.id.Split("/")[-1]
            $edges += [pscustomobject]@{ SourceId = $connectorName; TargetId = $canvasId; Label = $connectorName; EdgeType = "Link"; Metadata = @{ Arrow = "-->" } }
            $connectedConnections += $connectorName
        }

        if ($IncludeExternalDomains.IsPresent) {
            foreach ($domainInteraction in @($canvasApp.DomainInteractions)) {
                $externalDomain = [string]$domainInteraction.Domain
                if ([string]::IsNullOrWhiteSpace($externalDomain)) {
                    continue
                }

                $domainNodeId = "externaldomain_{0}" -f (Convert-PowerPlatformCheckerMermaidId -InputString ([string]$externalDomain.ToLowerInvariant()))
                if (-not ($nodes | Where-Object { $_.Id -eq $domainNodeId })) {
                    $nodes += [pscustomobject]@{
                        Id = $domainNodeId
                        Type = 'ExternalDomain'
                        DisplayName = $externalDomain
                        ClassKind = 'ExternalDomain'
                        Properties = @{}
                        Members = @()
                        HasExplicitDisplayName = $true
                    }
                }

                $interactionDirection = if ([string]::IsNullOrWhiteSpace([string]$domainInteraction.Direction)) { 'Unknown' } else { [string]$domainInteraction.Direction }
                $interactionLabel = switch ($interactionDirection) {
                    'Read' { 'GET' }
                    'Write' { 'SET' }
                    'Mixed' { 'GET/SET' }
                    default { 'Unknown' }
                }

                $dataSourceName = [string]$domainInteraction.DataSourceName
                $safeDataSourceName = if ([string]::IsNullOrWhiteSpace($dataSourceName)) { 'datasource' } else { $dataSourceName.Replace(':', ' ') }
                $edgeLabel = "{0} {1}" -f $safeDataSourceName, $interactionLabel
                $edges += [pscustomobject]@{
                    SourceId = $canvasId
                    TargetId = $domainNodeId
                    Label = [string]$edgeLabel
                    EdgeType = 'ExternalCall'
                    Metadata = @{
                        Arrow = '-->'
                        InteractionDirection = $interactionDirection
                        Evidence = [string]$domainInteraction.Evidence
                    }
                }
            }
        }

        # Data source metadata maps app usage to in-solution entities or unresolved defaults.
        foreach ($dataSource in @($canvasApp.DataSources.DataSources)) {
            if (-not $IncludeEntities.IsPresent -and -not $IncludeDefaultEntities.IsPresent) { continue }
            $resolvedEntitySetName = if ($dataSource.entitySetName) { Get-PowerPlatformCheckerArchitectureDiagramEntitySetName -EntityReference ([string]$dataSource.entitySetName) -EntitySetByReference $EntitySetByReference } else { $null }
            if ($resolvedEntitySetName -and $resolvedEntitySetName -in $KnownEntitySetNames) {
                if (-not $IncludeEntities.IsPresent) { continue }
                $edges += [pscustomobject]@{ SourceId = $canvasId; TargetId = [string]$resolvedEntitySetName; Label = [string]$dataSource.Name; EdgeType = "Link"; Metadata = @{ Arrow = "-->" } }
                $connectedEntities += $resolvedEntitySetName
            }
            elseif ($dataSource.logicalName) {
                $resolvedLogicalEntitySetName = Get-PowerPlatformCheckerArchitectureDiagramEntitySetName -EntityReference ([string]$dataSource.logicalName) -EntitySetByReference $EntitySetByReference
                if ($resolvedLogicalEntitySetName -and $resolvedLogicalEntitySetName -in $KnownEntitySetNames) {
                    if (-not $IncludeEntities.IsPresent) { continue }
                    $edges += [pscustomobject]@{ SourceId = $canvasId; TargetId = [string]$resolvedLogicalEntitySetName; Label = [string]$dataSource.Name; EdgeType = "Link"; Metadata = @{ Arrow = "-->" } }
                    $connectedEntities += $resolvedLogicalEntitySetName
                }
                else {
                    if (-not $IncludeDefaultEntities.IsPresent) { continue }
                    $edges += [pscustomobject]@{ SourceId = $canvasId; TargetId = [string]$dataSource.logicalName.ToLower(); Label = [string]$dataSource.Name; EdgeType = "Link"; Metadata = @{ Arrow = "-->" } }
                    $defaultEntitiesInCanvasApps += $dataSource.logicalName.ToLower()
                    $connectedDefaultEntities += $dataSource.logicalName.ToLower()
                }
            }
        }
    }

    return [pscustomobject]@{
        Nodes = @($nodes)
        Edges = @($edges)
        ConnectedConnections = @($connectedConnections | Select-Object -Unique)
        ConnectedEntities = @($connectedEntities | Select-Object -Unique)
        DefaultEntitiesInCanvasApps = @($defaultEntitiesInCanvasApps | Select-Object -Unique)
        ConnectedDefaultEntities = @($connectedDefaultEntities | Select-Object -Unique)
    }
}
