function Get-PowerPlatformCheckerArchitectureDiagramInternal {
    <#
    .SYNOPSIS
        Collects architecture data and shapes the architecture graph.

    .DESCRIPTION
        Centralizes the internal architecture-diagram pipeline so the public
        command can focus on input handling, telemetry, and output selection.

    .PARAMETER SolutionPath
        Root path of the unpacked solution.

    .PARAMETER FlowId
        Optional scoped flow id.

    .PARAMETER CanvasAppName
        Optional scoped canvas app name.

    .PARAMETER ModelDrivenAppName
        Optional scoped model-driven app name.

    .PARAMETER Direction
        Diagram layout direction.

    .PARAMETER IncludeElements
        Requested element groups.

    .PARAMETER StyleOverrides
        Optional per-call style overrides.

    .EXAMPLE
        Build the internal architecture graph for a solution and selected include set.

        Build the internal architecture graph for a solution.

        PS> Get-PowerPlatformCheckerArchitectureDiagramInternal -SolutionPath 'C:\Solutions\MySolution' -Direction LR -IncludeElements @('Flows')
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SolutionPath,

        [Parameter(Mandatory = $false)]
        [string] $FlowId,

        [Parameter(Mandatory = $false)]
        [string] $CanvasAppName,

        [Parameter(Mandatory = $false)]
        [string] $ModelDrivenAppName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('LR', 'RL', 'TB', 'BT')]
        [string] $Direction,

        [Parameter(Mandatory = $true)]
        [string[]] $IncludeElements,

        [Parameter(Mandatory = $false)]
        [hashtable] $StyleOverrides
    )

    $nodes = @()
    $edges = @()

    $hasFlowFilter = -not [string]::IsNullOrWhiteSpace([string]$FlowId)
    $hasCanvasFilter = -not [string]::IsNullOrWhiteSpace([string]$CanvasAppName)
    $hasModelDrivenFilter = -not [string]::IsNullOrWhiteSpace([string]$ModelDrivenAppName)

    $includePolicy = Get-PowerPlatformCheckerDiagramIncludePolicy `
        -IncludeElements $IncludeElements `
        -HasFlowFilter:$hasFlowFilter `
        -HasCanvasFilter:$hasCanvasFilter `
        -HasModelDrivenFilter:$hasModelDrivenFilter

    $includeFlows = $includePolicy.IncludeFlows
    $includeModelDrivenApps = $includePolicy.IncludeModelDrivenApps
    $includeEnvVars = $includePolicy.IncludeEnvironmentVariables
    $includeConnections = $includePolicy.IncludeConnections
    $includeEntities = $includePolicy.IncludeEntities
    $includeDefaultEntities = $includePolicy.IncludeDefaultEntities
    $includeWebResources = $includePolicy.IncludeWebResources
    if ($hasFlowFilter) {
        $includeWebResources = $false
    }
    $includeExternalDomains = $includePolicy.IncludeExternalDomains

    $style = Get-PowerPlatformCheckerResolvedStyle -StyleTarget 'ArchitectureDiagram' -StyleOverrides $StyleOverrides

    $solutionObject = Get-PowerPlatformCheckerSolutionObject -SolutionPath $SolutionPath
    $isScopedDiagram = $includePolicy.IsScopedDiagram

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
    if ($includeModelDrivenApps -and -not $hasFlowFilter -and -not $hasCanvasFilter) {
        $modelApps = @(Get-PowerPlatformCheckerAppModelDriven -SolutionPath $SolutionPath)
        if ($hasModelDrivenFilter) {
            $modelApps = @($modelApps | Where-Object { $_ -and $_.UniqueName -eq $ModelDrivenAppName })
        }
    }

    $modelDrivenFlowFilter = @($modelApps | ForEach-Object { $_.FlowIds } | Sort-Object -Unique)
    $preConnectedEntities = @()
    if ($hasModelDrivenFilter -and $includeEntities) {
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
        -HasModelDrivenFilter:$hasModelDrivenFilter `
        -ModelApps $modelApps

    $webResources = @($webResourceGraphContent.WebResources)
    $iconResources = @($webResourceGraphContent.IconResources)

    $connectedEnvVars = @()
    $connectedConnections = @()
    $connectedEntities = @($preConnectedEntities)
    $connectedDefaultEntities = @()

    $defaultFields = Get-PowerPlatformCheckerDefaultEntityFieldName
    $entitySetNames = @($solutionObject.Entities | Where-Object { $_ -and $_.EntitySetName } | ForEach-Object { $_.EntitySetName.ToLower() })

    $flowDiagramContent = Get-PowerPlatformCheckerArchitectureFlowGraphContent `
        -SolutionPath $SolutionPath `
        -SolutionObject $solutionObject `
        -EntitySetByReference $entitySetByReference `
        -IncludeFlows:$includeFlows `
        -IncludeEnvironmentVariables:$includeEnvVars `
        -IncludeConnections:$includeConnections `
        -IncludeEntities:$includeEntities `
        -HasCanvasFilter:$hasCanvasFilter `
        -HasFlowFilter:$hasFlowFilter `
        -HasModelDrivenFilter:$hasModelDrivenFilter `
        -FlowId $FlowId `
        -ModelDrivenFlowFilter $modelDrivenFlowFilter

    $nodes += @($flowDiagramContent.Nodes)
    $edges += @($flowDiagramContent.Edges)
    $connectedEnvVars += @($flowDiagramContent.ConnectedEnvVars)
    $connectedConnections += @($flowDiagramContent.ConnectedConnections)
    $connectedEntities += @($flowDiagramContent.ConnectedEntities)

    $defaultEntitiesInCanvasApps = @()
    $canvasDiagramContent = Get-PowerPlatformCheckerArchitectureCanvasAppGraphContent `
        -SolutionObject $solutionObject `
        -EntitySetByReference $entitySetByReference `
        -KnownEntitySetNames $entitySetNames `
        -IncludeCanvasApps:$includePolicy.IncludeCanvasApps `
        -IncludeConnections:$includeConnections `
        -IncludeEntities:$includeEntities `
        -IncludeDefaultEntities:$includeDefaultEntities `
        -IncludeExternalDomains:$includeExternalDomains `
        -HasFlowFilter:$hasFlowFilter `
        -HasModelDrivenFilter:$hasModelDrivenFilter `
        -CanvasAppName $CanvasAppName

    $nodes += @($canvasDiagramContent.Nodes)
    $edges += @($canvasDiagramContent.Edges)
    $connectedConnections += @($canvasDiagramContent.ConnectedConnections)
    $connectedEntities += @($canvasDiagramContent.ConnectedEntities)
    $defaultEntitiesInCanvasApps += @($canvasDiagramContent.DefaultEntitiesInCanvasApps)
    $connectedDefaultEntities += @($canvasDiagramContent.ConnectedDefaultEntities)

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

    $nodes += @($webResourceGraphContent.Nodes)
    $edges += @($webResourceGraphContent.Edges)
    $nodes += @($entityDiagramContent.IconNodes)

    $sourceFilterType = if ($hasFlowFilter) { 'Flow' }
        elseif ($hasCanvasFilter) { 'CanvasApp' }
        elseif ($hasModelDrivenFilter) { 'ModelDrivenApp' }
        else { 'None' }

    $sourceFilterValue = if ($hasFlowFilter) { [string]$FlowId }
        elseif ($hasCanvasFilter) { [string]$CanvasAppName }
        elseif ($hasModelDrivenFilter) { [string]$ModelDrivenAppName }
        else { '' }

    return Get-PowerPlatformCheckerArchitectureDiagramGraph `
        -Nodes $nodes `
        -Edges $edges `
        -Direction $Direction `
        -IncludeElements $IncludeElements `
        -IncludePolicy $includePolicy `
        -Style $style `
        -IsScopedDiagram $isScopedDiagram `
        -SourceFilterType $sourceFilterType `
        -SourceFilterValue $sourceFilterValue
}
