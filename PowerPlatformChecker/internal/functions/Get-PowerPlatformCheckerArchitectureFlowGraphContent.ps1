function Get-PowerPlatformCheckerArchitectureFlowGraphContent {
    <#
    .SYNOPSIS
        Builds Mermaid flow class nodes and associated links for architecture diagrams.

    .DESCRIPTION
        Creates flow node class text and flow-driven relationship links used by
        Get-PowerPlatformCheckerArchitectureDiagram. This helper is responsible for
        translating flow parameters and action metadata into diagram members and
        connections.

    .PARAMETER SolutionPath
        Root path of the unpacked solution used to locate workflow JSON files.

    .PARAMETER SolutionObject
        Aggregated solution metadata returned by Get-PowerPlatformCheckerSolutionObject.

    .PARAMETER EntitySetByReference
        Lookup table that maps logical/entity references to canonical entity set names.

    .PARAMETER IncludeFlows
        Include flow-to-flow links when action references resolve to other flows.

    .PARAMETER IncludeEnvironmentVariables
        Include parameter-driven environment variable members and links.

    .PARAMETER IncludeConnections
        Include connection reference members and links.

    .PARAMETER IncludeEntities
        Include action entity usage members and links.

    .PARAMETER HasFlowFilter
        Indicates whether rendering is scoped to a specific flow filter.

    .PARAMETER HasCanvasFilter
        Indicates whether rendering is scoped to a canvas app, which suppresses flows.

    .PARAMETER HasModelDrivenFilter
        Indicates whether rendering is scoped to a model-driven app.

    .PARAMETER FlowId
        Flow id that identifies the selected scope when HasFlowFilter is set.

    .PARAMETER ModelDrivenFlowFilter
        Flow ids referenced by the selected model-driven apps.

    .EXAMPLE
        Build flow diagram content for architecture assembly.

        PS> Get-PowerPlatformCheckerArchitectureFlowGraphContent -SolutionPath $path -SolutionObject $solution -EntitySetByReference $entityMap -IncludeFlows -IncludeConnections -IncludeEntities

        Returns node text plus link collections that the caller appends to the final diagram.
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SolutionPath,

        [Parameter(Mandatory = $true)]
        [object] $SolutionObject,

        [Parameter(Mandatory = $true)]
        [hashtable] $EntitySetByReference,

        [Parameter(Mandatory = $false)]
        [switch] $IncludeFlows,

        [Parameter(Mandatory = $false)]
        [switch] $IncludeEnvironmentVariables,

        [Parameter(Mandatory = $false)]
        [switch] $IncludeConnections,

        [Parameter(Mandatory = $false)]
        [switch] $IncludeEntities,

        [Parameter(Mandatory = $false)]
        [switch] $HasFlowFilter,

        [Parameter(Mandatory = $false)]
        [switch] $HasCanvasFilter,

        [Parameter(Mandatory = $false)]
        [switch] $HasModelDrivenFilter,

        [Parameter(Mandatory = $false)]
        [string] $FlowId,

        [Parameter(Mandatory = $false)]
        [string[]] $ModelDrivenFlowFilter = @()
    )

    $nodes = @()
    $edges = @()
    $connectedEnvVars = @()
    $connectedConnections = @()
    $connectedEntities = @()

    $flowsToRender = @()
    if ($IncludeFlows.IsPresent -and -not $HasCanvasFilter.IsPresent) {
        $flowsToRender = @($SolutionObject.Workflows | Where-Object { $_ -and -not [string]::IsNullOrWhiteSpace([string]$_.Id) })
        if ($HasFlowFilter.IsPresent -and -not [string]::IsNullOrWhiteSpace([string]$FlowId)) {
            $flowsToRender = @($flowsToRender | Where-Object { $_.Id -eq $FlowId })
        }
        if ($HasModelDrivenFilter.IsPresent) {
            $allowedFlowIds = @($ModelDrivenFlowFilter | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Select-Object -Unique)
            $flowsToRender = @($flowsToRender | Where-Object { $_.Id -in $allowedFlowIds })
        }
    }

    foreach ($flow in @($flowsToRender)) {
        if (-not $flow -or [string]::IsNullOrWhiteSpace([string]$flow.Id)) {
            continue
        }

        $flowNode = "flow$($flow.Id)"
        $flowMembers = @()
        $flowPath = Join-Path (Join-Path $SolutionPath "Workflows") ("*" + $flow.Id + "*.json")
        $flowType = Get-PowerPlatformCheckerFlowType -Path $flowPath
        $triggerMode = "Unknown"
        $interactionDirection = "Unknown"
        $directionConfidence = "Low"
        $sourceEvidence = "NoDirectionSignal"
        $destination = ""
        $destinationType = "Unknown"
        $destinationConfidence = "Low"
        $destinationEvidence = "NoDestinationSignal"
        if ([string]::IsNullOrWhiteSpace($flowType)) {
            $flowType = "Unknown"
        }

        if ($flowType -eq "Desktop") {
            $flowMembers += @(Get-PowerPlatformCheckerDesktopFlowClassMemberList -Path $flowPath)
        }

        # Flow parameters provide environment-variable usage links into the flow node.
        try {
            $parameters = Get-PowerPlatformCheckerFlowParameter -Path $flowPath
            foreach ($parameter in @($parameters)) {
                if (-not $IncludeEnvironmentVariables.IsPresent) { continue }
                $flowMembers += "    [$($parameter.Type)]$($parameter.SchemaName)"
                $edges += [pscustomobject]@{ SourceId = [string]$parameter.SchemaName; TargetId = $flowNode; Label = [string]$parameter.SchemaName; EdgeType = "Reference"; Metadata = @{ Arrow = "..>" } }
                $connectedEnvVars += $parameter.SchemaName
            }
        }
        catch {
            Write-Warning "Error in reading the parameters of flow $($flow.Name)"
        }

        # Flow action metadata drives flow-to-flow, flow-to-connector, and flow-to-entity links.
        try {
            $actions = Get-PowerPlatformCheckerFlowActionList -Path $flowPath -Recurse -IncludeTrigger -Properties References,Entities
            $triggerMode = Get-PowerPlatformCheckerFlowTriggerMode -Actions $actions
            $directionMetadata = Get-PowerPlatformCheckerFlowDirectionProfile -Actions $actions
            $interactionDirection = [string]$directionMetadata.InteractionDirection
            $directionConfidence = [string]$directionMetadata.DirectionConfidence
            $sourceEvidence = [string]$directionMetadata.SourceEvidence

            $destinationMetadata = Get-PowerPlatformCheckerFlowDestinationProfile -Path $flowPath -Actions $actions
            $destination = [string]$destinationMetadata.Destination
            $destinationType = [string]$destinationMetadata.DestinationType
            $destinationConfidence = [string]$destinationMetadata.DestinationConfidence
            $destinationEvidence = [string]$destinationMetadata.DestinationEvidence
            foreach ($action in @($actions)) {
                if ($null -ne $action.Reference -and $action.Reference -ne "") {
                    $referenceFlow = $SolutionObject.Workflows | Where-Object { $_.Id -eq $action.Reference } | Select-Object -First 1
                    if ($IncludeFlows.IsPresent -and $referenceFlow -and ((-not $HasFlowFilter.IsPresent) -or $referenceFlow.Id -eq $FlowId)) {
                        $edges += [pscustomobject]@{ SourceId = $flowNode; TargetId = "flow$($referenceFlow.Id)"; Label = [string]$action.Name.replace(' ', '_'); EdgeType = "Link"; Metadata = @{ Arrow = "-->" } }
                    }
                }

                if ($IncludeConnections.IsPresent -and $action.Group -ne "*" -and $null -ne $action.Group) {
                    $flowMembers += "    $($action.Name.replace(' ', '_'))($($action.Group))"
                    $edges += [pscustomobject]@{ SourceId = [string]$action.Group; TargetId = $flowNode; Label = [string]$action.Group; EdgeType = "Link"; Metadata = @{ Arrow = "-->" } }
                    $connectedConnections += $action.Group
                }

                if ($IncludeEntities.IsPresent -and $action.Entities.Count -gt 0) {
                    foreach ($entity in @($action.Entities)) {
                        $resolvedEntitySet = Get-PowerPlatformCheckerArchitectureDiagramEntitySetName -EntityReference ([string]$entity) -EntitySetByReference $EntitySetByReference
                        if (-not $resolvedEntitySet) {
                            continue
                        }

                        $flowMembers += "    $($action.Name.replace(' ', '_'))($($resolvedEntitySet))"
                        $edges += [pscustomobject]@{ SourceId = $flowNode; TargetId = [string]$resolvedEntitySet; Label = [string]$entity; EdgeType = "Link"; Metadata = @{ Arrow = "-->" } }
                        $connectedEntities += $resolvedEntitySet
                    }
                }
            }
        }
        catch {
            Write-Warning "Error in reading the actions of flow $($flow.Name)"
        }

        if ($IncludeConnections.IsPresent -and $flowType -eq "Desktop") {
            try {
                $desktopConnectors = @(Get-PowerPlatformCheckerFlowConnectorTier -Path $flowPath)
                foreach ($desktopConnector in @($desktopConnectors)) {
                    $connectorName = [string]$desktopConnector.Name
                    if ([string]::IsNullOrWhiteSpace($connectorName)) {
                        continue
                    }

                    $connectorNodeId = Convert-PowerPlatformCheckerMermaidId -InputString $connectorName

                    $flowMembers += "    ConnectionReference($connectorNodeId)"
                    $edges += [pscustomobject]@{ SourceId = $connectorNodeId; TargetId = $flowNode; Label = $connectorNodeId; EdgeType = "Link"; Metadata = @{ Arrow = "-->" } }
                    $connectedConnections += $connectorNodeId
                }
            }
            catch {
                Write-Warning "Error in resolving desktop connectors for flow $($flow.Name)"
            }
        }

        $nodes += [pscustomobject]@{
            Id = $flowNode
            Type = "Flow"
            DisplayName = [string]$flow.Name
            ClassKind = "Flow"
            Properties = @{
                FlowType = [string]$flowType
                TriggerMode = [string]$triggerMode
                InteractionDirection = [string]$interactionDirection
                DirectionConfidence = [string]$directionConfidence
                SourceEvidence = [string]$sourceEvidence
                Destination = [string]$destination
                DestinationType = [string]$destinationType
                DestinationConfidence = [string]$destinationConfidence
                DestinationEvidence = [string]$destinationEvidence
            }
            Members = @($flowMembers)
            HasExplicitDisplayName = $true
        }
    }

    return [pscustomobject]@{
        Nodes = @($nodes)
        Edges = @($edges)
        ConnectedEnvVars = @($connectedEnvVars | Select-Object -Unique)
        ConnectedConnections = @($connectedConnections | Select-Object -Unique)
        ConnectedEntities = @($connectedEntities | Select-Object -Unique)
    }
}
