function Get-PowerPlatformCheckerArchitectureDiagram {
    <#
    .SYNOPSIS
        Generates a Mermaid class diagram for a Power Platform solution.

    .DESCRIPTION
        Produces markdown containing a Mermaid classDiagram based on flows, environment variables,
        connection references, entities, canvas apps, model-driven apps, and JavaScript web resources.
        When a flow, canvas app, or model-driven app filter is used, the diagram is scoped to the
        directly connected components for that selected item.

    .PARAMETER SolutionPath
        The root path of the unpacked solution.

    .PARAMETER FlowId
        Optional flow id filter.

    .PARAMETER CanvasAppName
        Optional canvas app internal name filter.

    .PARAMETER ModelDrivenAppName
        Optional model-driven app unique name filter.

    .PARAMETER Direction
        Mermaid layout direction. Default is Left-to-Right (`LR`).

    .PARAMETER IncludeElements
        Which diagram element groups to include. Defaults to all groups.

    .PARAMETER OutputFormat
        Output format to return: Mermaid markdown text (default) or parsed Graph object.

    .PARAMETER StyleOverrides
        Optional hashtable that overrides recognized diagram color keys for this call only.
        Values set with Set-PowerPlatformCheckerStyle provide the session baseline;
        values supplied here take precedence without changing that baseline.

    .OUTPUTS
        System.String when OutputFormat is Mermaid. Returns Azure DevOps-flavored Mermaid
        markdown containing a classDiagram.

        System.Management.Automation.PSCustomObject when OutputFormat is Graph. The graph
        contains Metadata, Nodes, Edges, Styles, and StyleOrder. Metadata describes direction,
        included element groups, and source filtering. Each node contains Id, Type, DisplayName,
        ClassKind, Properties, Members, and HasExplicitDisplayName. Each edge contains SourceId,
        TargetId, Label, EdgeType, and Metadata.Arrow. Styles maps class names to Mermaid style
        declarations; StyleOrder preserves deterministic rendering order.

    .EXAMPLE
        Generate a full architecture diagram markdown block for a solution.

        PS> Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath "C:\Solutions\MySolution"

    .EXAMPLE
        Generate an architecture diagram scoped to a single flow.

        PS> Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath "C:\Solutions\MySolution" -FlowId "00000000-0000-0000-0000-000000000000"

    .EXAMPLE
        Generate an architecture diagram with top-to-bottom layout.

        PS> Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath "C:\Solutions\MySolution" -Direction TB

    .EXAMPLE
        Generate a flow-only architecture view (exclude apps/entities/connections).

        PS> Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath "C:\Solutions\MySolution" -IncludeElements Flows

    .EXAMPLE
        Override diagram colors for this call only.

        PS> $style = @{ Flow = '#4CC9F0'; Connection = '#FFD166'; Stroke = '#2B2D42' }
        PS> Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath "C:\Solutions\MySolution" -StyleOverrides $style
    #>

    [CmdletBinding(DefaultParameterSetName = "NoFilter")]
    [OutputType([string], [pscustomobject])]
    param(
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "NoFilter")]
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "FilterByFlow")]
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "FilterByCanvasApp")]
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "FilterByModelDrivenApp")]
        [string] $SolutionPath,

        [Parameter(Mandatory = $true, Position = 2, ParameterSetName = "FilterByFlow")]
        [string] $FlowId,

        [Parameter(Mandatory = $true, Position = 2, ParameterSetName = "FilterByCanvasApp")]
        [string] $CanvasAppName,

        [Parameter(Mandatory = $true, Position = 2, ParameterSetName = "FilterByModelDrivenApp")]
        [string] $ModelDrivenAppName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("LR", "RL", "TB", "BT")]
        [string] $Direction = "LR",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Flows", "CanvasApps", "ModelDrivenApps", "EnvironmentVariables", "Connections", "Entities", "DefaultEntities", "WebResources", "ExternalDomains")]
        [string[]] $IncludeElements = @("Flows", "CanvasApps", "ModelDrivenApps", "EnvironmentVariables", "Connections", "Entities", "DefaultEntities", "WebResources", "ExternalDomains"),

        [Parameter(Mandatory = $false)]
        [ValidateSet("Mermaid", "Graph")]
        [string] $OutputFormat = "Mermaid",

        [Parameter(Mandatory = $false)]
        [hashtable] $StyleOverrides
    )

    $telemetryProperties = @{
        ParameterSet = $PSCmdlet.ParameterSetName
        HasFlowFilter = $PSBoundParameters.ContainsKey("FlowId")
        HasCanvasFilter = $PSBoundParameters.ContainsKey("CanvasAppName")
        HasModelDrivenFilter = $PSBoundParameters.ContainsKey("ModelDrivenAppName")
        Direction = $Direction
        OutputFormat = $OutputFormat
        IncludeElements = (($IncludeElements | Sort-Object -Unique) -join ",")
        HasStyleOverrides = $PSBoundParameters.ContainsKey("StyleOverrides")
    }
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerArchitectureDiagram" -PropertiesHash $telemetryProperties

    $nodes = @()
    $edges = @()

    $includePolicy = Get-PowerPlatformCheckerDiagramIncludePolicy `
        -IncludeElements $IncludeElements `
        -HasFlowFilter:$($PSBoundParameters.ContainsKey("FlowId")) `
        -HasCanvasFilter:$($PSBoundParameters.ContainsKey("CanvasAppName")) `
        -HasModelDrivenFilter:$($PSBoundParameters.ContainsKey("ModelDrivenAppName"))

    # Resolve include flags once so downstream blocks can stay readable.
    $includeFlows = $includePolicy.IncludeFlows
    $includeModelDrivenApps = $includePolicy.IncludeModelDrivenApps
    $includeEnvVars = $includePolicy.IncludeEnvironmentVariables
    $includeConnections = $includePolicy.IncludeConnections
    $includeEntities = $includePolicy.IncludeEntities
    $includeDefaultEntities = $includePolicy.IncludeDefaultEntities
    $includeWebResources = $includePolicy.IncludeWebResources
    $includeExternalDomains = $includePolicy.IncludeExternalDomains

    # Keep style resolution centralized so all diagram producers honor the same defaults and overrides.
    $style = Get-PowerPlatformCheckerResolvedStyle -StyleTarget 'ArchitectureDiagram' -StyleOverrides $StyleOverrides

    $solutionObject = Get-PowerPlatformCheckerSolutionObject -SolutionPath $SolutionPath
    $isScopedDiagram = $includePolicy.IsScopedDiagram

    # Resolve logical/entity names to the canonical entity set id so links remain stable across
    # casing/singular/plural variants. Downstream diagram code should only need to work with one id.
    $entitySetByReference = @{}
    $entityByLogicalName = @{}
    $entityBySetName = @{}
    $renderedEntityNodeIds = @()
    foreach ($entity in @($solutionObject.Entities)) {
        if (-not $entity -or [string]::IsNullOrWhiteSpace([string]$entity.EntitySetName)) {
            continue
        }

        $entitySetName = [string]$entity.EntitySetName.Trim().ToLower()
        $entitySetByReference[$entitySetName] = $entitySetName
        $entityBySetName[$entitySetName] = $entity

        if (-not [string]::IsNullOrWhiteSpace([string]$entity.Name)) {
            $entityLogicalName = [string]$entity.Name.ToLower()
            $entitySetByReference[$entityLogicalName] = $entitySetName
            $entityByLogicalName[$entityLogicalName] = $entity
        }
    }
    $modelApps = @()
    if ($includeModelDrivenApps -and -not $PSBoundParameters.ContainsKey("FlowId") -and -not $PSBoundParameters.ContainsKey("CanvasAppName")) {
        $modelApps = @(Get-PowerPlatformCheckerAppModelDriven -SolutionPath $SolutionPath)
        if (-not [string]::IsNullOrWhiteSpace([string]$ModelDrivenAppName)) {
            $modelApps = @($modelApps | Where-Object { $_ -and $_.UniqueName -eq $ModelDrivenAppName })
        }
    }

    # If model-driven app filtering is used, only include flows referenced by selected apps.
    # The app metadata already identifies those flow ids, so this becomes the authoritative filter.
    $modelDrivenFlowFilter = @($modelApps | ForEach-Object { $_.FlowIds } | Sort-Object -Unique)
    $preConnectedEntities = @()
    if ($PSBoundParameters.ContainsKey("ModelDrivenAppName") -and $includeEntities) {
        foreach ($modelApp in @($modelApps)) {
            foreach ($entityName in @($modelApp.Entities)) {
                $resolvedEntitySet = Get-PowerPlatformCheckerArchitectureDiagramEntitySetName -EntityReference ([string]$entityName) -EntitySetByReference $entitySetByReference
                if ($resolvedEntitySet) {
                    $preConnectedEntities += $resolvedEntitySet
                }
            }
        }
    }
    $webResourceGraphContent = Get-PowerPlatformCheckerArchitectureWebResourceGraphContent `
        -SolutionPath $SolutionPath `
        -SolutionObject $solutionObject `
        -IncludeWebResources:$includeWebResources `
        -IncludeExternalDomains:$includeExternalDomains `
        -HasModelDrivenFilter:$($PSBoundParameters.ContainsKey("ModelDrivenAppName")) `
        -ModelApps $modelApps

    $webResources = @($webResourceGraphContent.WebResources)
    $iconResources = @($webResourceGraphContent.IconResources)

    $connectedEnvVars = @()
    $connectedConnections = @()
    $connectedEntities = @($preConnectedEntities)
    $connectedDefaultEntities = @()

    # Keep system fields in one helper so filtering rules are reusable and easy to maintain.
    $defaultFields = Get-PowerPlatformCheckerDefaultEntityFieldName
    $entitySetNames = @($solutionObject.Entities | Where-Object { $_ -and $_.EntitySetName } | ForEach-Object { $_.EntitySetName.ToLower() })

    # Flow nodes are only rendered when flow inclusion is enabled and canvas-only filtering is not active.
    # Collect the visible members for each flow first so we can avoid emitting an empty Mermaid class body.
    # Mermaid accepts `class Node["Label"]:::Type`, but rejects `class Node["Label"]:::Type {}`.
    $flowDiagramContent = Get-PowerPlatformCheckerArchitectureFlowGraphContent `
        -SolutionPath $SolutionPath `
        -SolutionObject $solutionObject `
        -EntitySetByReference $entitySetByReference `
        -IncludeFlows:$includeFlows `
        -IncludeEnvironmentVariables:$includeEnvVars `
        -IncludeConnections:$includeConnections `
        -IncludeEntities:$includeEntities `
        -HasCanvasFilter:$($PSBoundParameters.ContainsKey("CanvasAppName")) `
        -HasFlowFilter:$($PSBoundParameters.ContainsKey("FlowId")) `
        -HasModelDrivenFilter:$($PSBoundParameters.ContainsKey("ModelDrivenAppName")) `
        -FlowId $FlowId `
        -ModelDrivenFlowFilter $modelDrivenFlowFilter

    $nodes += @($flowDiagramContent.Nodes)
    $edges += @($flowDiagramContent.Edges)
    $connectedEnvVars += @($flowDiagramContent.ConnectedEnvVars)
    $connectedConnections += @($flowDiagramContent.ConnectedConnections)
    $connectedEntities += @($flowDiagramContent.ConnectedEntities)

    $defaultEntitiesInCanvasApps = @()

    # Canvas apps are excluded for flow-only and model-driven-only projections.
    # Their links are derived from connection references plus data-source metadata in the app package.
    $canvasDiagramContent = Get-PowerPlatformCheckerArchitectureCanvasAppGraphContent `
        -SolutionObject $solutionObject `
        -EntitySetByReference $entitySetByReference `
        -KnownEntitySetNames $entitySetNames `
        -IncludeCanvasApps:$includePolicy.IncludeCanvasApps `
        -IncludeConnections:$includeConnections `
        -IncludeEntities:$includeEntities `
        -IncludeDefaultEntities:$includeDefaultEntities `
        -IncludeExternalDomains:$includeExternalDomains `
        -HasFlowFilter:$($PSBoundParameters.ContainsKey("FlowId")) `
        -HasModelDrivenFilter:$($PSBoundParameters.ContainsKey("ModelDrivenAppName")) `
        -CanvasAppName $CanvasAppName

    $nodes += @($canvasDiagramContent.Nodes)
    $edges += @($canvasDiagramContent.Edges)
    $connectedConnections += @($canvasDiagramContent.ConnectedConnections)
    $connectedEntities += @($canvasDiagramContent.ConnectedEntities)
    $defaultEntitiesInCanvasApps += @($canvasDiagramContent.DefaultEntitiesInCanvasApps)
    $connectedDefaultEntities += @($canvasDiagramContent.ConnectedDefaultEntities)

    # Keep unresolved connected entity references visible (for example cross-solution dependencies)
    # by promoting unknown entity ids to default-entity candidates.
    if ($includeDefaultEntities) {
        foreach ($connectedEntity in @($connectedEntities)) {
            if (-not [string]::IsNullOrWhiteSpace([string]$connectedEntity) -and -not $entityBySetName.ContainsKey([string]$connectedEntity)) {
                $connectedDefaultEntities += [string]$connectedEntity
            }
        }
    }

    $connectedEnvVars = @($connectedEnvVars | Select-Object -Unique)
    $connectedConnections = @($connectedConnections | Select-Object -Unique)
    $connectedEntities = @($connectedEntities | Select-Object -Unique)
    $connectedDefaultEntities = @($connectedDefaultEntities | Select-Object -Unique)

    # Scoped diagrams start from explicitly connected nodes (flow/app selections), then expand
    # reachability so linked in-solution and default entities are declared before rendering.
    if ($isScopedDiagram -and $includeEntities -and $connectedEntities.Count -gt 0) {
        $expandedReachability = Expand-PowerPlatformCheckerScopedReachability `
            -ConnectedEntities $connectedEntities `
            -ConnectedDefaultEntities $connectedDefaultEntities `
            -EntityBySetName $entityBySetName `
            -EntityByLogicalName $entityByLogicalName `
            -IncludeDefaultEntities:$includeDefaultEntities

        $connectedEntities = @($expandedReachability.ConnectedEntities)
        $connectedDefaultEntities = @($expandedReachability.ConnectedDefaultEntities)
    }

    $environmentVariableGraphContent = Get-PowerPlatformCheckerArchitectureEnvironmentVariableGraphContent `
        -SolutionObject $solutionObject `
        -IncludePolicy $includePolicy `
        -IsScopedDiagram:$isScopedDiagram `
        -ConnectedNames $connectedEnvVars
    $nodes += @($environmentVariableGraphContent.Nodes)

    $connectionGraphContent = Get-PowerPlatformCheckerArchitectureConnectionGraphContent `
        -SolutionObject $solutionObject `
        -IncludePolicy $includePolicy `
        -IsScopedDiagram:$isScopedDiagram `
        -ConnectedConnectorNames $connectedConnections
    $nodes += @($connectionGraphContent.Nodes)

    $entityDiagramContent = Get-PowerPlatformCheckerArchitectureEntityGraphContent `
        -SolutionObject $solutionObject `
        -IncludeEntities:$includeEntities `
        -ConnectedEntitySetNames $connectedEntities `
        -DefaultFields $defaultFields `
        -IsScopedDiagram:$isScopedDiagram `
        -IncludeDefaultEntities:$includeDefaultEntities `
        -IncludeWebResources:$includeWebResources `
        -EntityByLogicalName $entityByLogicalName `
        -WebResources $webResources `
        -IconResources $iconResources

    $nodes += @($entityDiagramContent.Nodes)
    $edges += @($entityDiagramContent.Edges)
    $connectedEntities += @($entityDiagramContent.ConnectedEntities)
    $connectedDefaultEntities += @($entityDiagramContent.ConnectedDefaultEntities)
    $renderedEntityNodeIds += @($entityDiagramContent.RenderedEntityNodeIds)

    if ($includeDefaultEntities -and $solutionObject.Entities.Relations.Count -gt 0) {
        foreach ($relation in @($solutionObject.Entities.Relations)) {
            if ($relation.Source) {
                $defaultEntitiesInCanvasApps += $relation.Source.ToLower()
            }
            if ($relation.Target) {
                $defaultEntitiesInCanvasApps += $relation.Target.ToLower()
            }
        }
    }

    $defaultEntityGraphContent = Get-PowerPlatformCheckerArchitectureDefaultEntityGraphContent `
        -IncludePolicy $includePolicy `
        -IsScopedDiagram:$isScopedDiagram `
        -DefaultEntitiesInCanvasApps $defaultEntitiesInCanvasApps `
        -ConnectedDefaultEntities $connectedDefaultEntities `
        -EntitySetByReference $entitySetByReference `
        -RenderedEntityNodeIds $renderedEntityNodeIds
    $nodes += @($defaultEntityGraphContent.Nodes)

    foreach ($modelApp in @($modelApps)) {
        $modelAppLinkData = Get-PowerPlatformCheckerArchitectureModelDrivenAppGraphContent `
            -ModelApp $modelApp `
            -SolutionObject $solutionObject `
            -EntitySetByReference $entitySetByReference `
            -WebResources $webResources `
            -IncludeFlows:$includeFlows `
            -IncludeEntities:$includeEntities `
            -IncludeDefaultEntities:$includeDefaultEntities `
            -IncludeWebResources:$includeWebResources

        $nodes += @($modelAppLinkData.Nodes)
        $edges += @($modelAppLinkData.Edges)
        $connectedEntities += @($modelAppLinkData.ConnectedEntities)
        $connectedDefaultEntities += @($modelAppLinkData.ConnectedDefaultEntities)
    }

    # Web resources are rendered after the app/entity graph so links can point at stable node ids.
    # Scripts get a class body so the diagram can show discovered method names in addition to type.
    $nodes += @($webResourceGraphContent.Nodes)
    $edges += @($webResourceGraphContent.Edges)
    $nodes += @($entityDiagramContent.IconNodes)

    $sourceFilterType = if ($PSBoundParameters.ContainsKey("FlowId")) { "Flow" }
        elseif ($PSBoundParameters.ContainsKey("CanvasAppName")) { "CanvasApp" }
        elseif ($PSBoundParameters.ContainsKey("ModelDrivenAppName")) { "ModelDrivenApp" }
        else { "None" }

    $sourceFilterValue = if ($PSBoundParameters.ContainsKey("FlowId")) { [string]$FlowId }
        elseif ($PSBoundParameters.ContainsKey("CanvasAppName")) { [string]$CanvasAppName }
        elseif ($PSBoundParameters.ContainsKey("ModelDrivenAppName")) { [string]$ModelDrivenAppName }
        else { "" }

    $graph = Get-PowerPlatformCheckerArchitectureDiagramGraph `
        -Nodes $nodes `
        -Edges $edges `
        -Direction $Direction `
        -IncludeElements $IncludeElements `
        -IncludePolicy $includePolicy `
        -Style $style `
        -IsScopedDiagram $isScopedDiagram `
        -SourceFilterType $sourceFilterType `
        -SourceFilterValue $sourceFilterValue

    if ($OutputFormat -eq "Graph") {
        return $graph
    }

    return Convert-PowerPlatformCheckerArchitectureGraphToMermaid -Graph $graph
}


