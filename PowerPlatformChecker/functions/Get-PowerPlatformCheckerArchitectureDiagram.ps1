function Get-PowerPlatformCheckerArchitectureDiagram {
    <#
    .SYNOPSIS
        Generates a Mermaid class diagram for a Power Platform solution.

    .DESCRIPTION
        Produces markdown containing a Mermaid classDiagram based on flows, environment variables,
        connection references, entities, canvas apps, model-driven apps, and JavaScript web resources.

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

    .PARAMETER StyleOverrides
        Optional hashtable to override default color values for class definitions.

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
    [OutputType([string])]
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
        [ValidateSet("Flows", "CanvasApps", "ModelDrivenApps", "EnvironmentVariables", "Connections", "Entities", "DefaultEntities", "WebResources")]
        [string[]] $IncludeElements = @("Flows", "CanvasApps", "ModelDrivenApps", "EnvironmentVariables", "Connections", "Entities", "DefaultEntities", "WebResources"),

        [Parameter(Mandatory = $false)]
        [hashtable] $StyleOverrides
    )

    $telemetryProperties = @{
        ParameterSet = $PSCmdlet.ParameterSetName
        HasFlowFilter = $PSBoundParameters.ContainsKey("FlowId")
        HasCanvasFilter = $PSBoundParameters.ContainsKey("CanvasAppName")
        HasModelDrivenFilter = $PSBoundParameters.ContainsKey("ModelDrivenAppName")
        Direction = $Direction
        IncludeElements = (($IncludeElements | Sort-Object -Unique) -join ",")
        HasStyleOverrides = $PSBoundParameters.ContainsKey("StyleOverrides")
    }
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerArchitectureDiagram" -PropertiesHash $telemetryProperties

    $newline = [Environment]::NewLine
    $diagram = ""
    $diagram += ":::mermaid$newline"
    $diagram += "classDiagram$newline"
    $diagram += "direction $Direction$newline"

    # Resolve include flags once so downstream blocks can stay readable.
    $includeFlows = "Flows" -in $IncludeElements
    $includeCanvasApps = "CanvasApps" -in $IncludeElements
    $includeModelDrivenApps = "ModelDrivenApps" -in $IncludeElements
    $includeEnvVars = "EnvironmentVariables" -in $IncludeElements
    $includeConnections = "Connections" -in $IncludeElements
    $includeEntities = "Entities" -in $IncludeElements
    $includeDefaultEntities = "DefaultEntities" -in $IncludeElements
    $includeWebResources = "WebResources" -in $IncludeElements

    # Start from module defaults and apply per-call style overrides if provided.
    $style = @{}
    foreach ($key in $script:PowerPlatformCheckerDiagramColors.Keys) {
        $style[$key] = $script:PowerPlatformCheckerDiagramColors[$key]
    }
    if ($PSBoundParameters.ContainsKey("StyleOverrides")) {
        foreach ($key in $StyleOverrides.Keys) {
            if ($style.ContainsKey($key) -and -not [string]::IsNullOrWhiteSpace([string]$StyleOverrides[$key])) {
                $style[$key] = [string]$StyleOverrides[$key]
            }
        }
    }

    $solutionObject = Get-PowerPlatformCheckerSolutionObject -SolutionPath $SolutionPath
    $modelApps = if ($includeModelDrivenApps) { Get-PowerPlatformCheckerModelDrivenApp -SolutionPath $SolutionPath } else { @() }
    if ($PSBoundParameters.ContainsKey("ModelDrivenAppName")) {
        $modelApps = @($modelApps | Where-Object { $_.UniqueName -eq $ModelDrivenAppName })
    }

    # If model-driven app filtering is used, only include flows referenced by selected apps.
    $modelDrivenFlowFilter = @($modelApps | ForEach-Object { $_.FlowIds } | Sort-Object -Unique)
    $webResources = if ($includeWebResources) { Get-PowerPlatformCheckerWebResource -SolutionPath $SolutionPath -JavaScriptOnly } else { @() }

    $links = @()
    $connectedEnvVars = @()
    $connectedConnections = @()
    $connectedEntities = @()
    $connectedDefaultEntities = @()

    # Keep system fields in one helper so filtering rules are reusable and easy to maintain.
    $defaultFields = Get-PowerPlatformCheckerDefaultEntityFieldName
    $entitySetNames = @($solutionObject.Entities | Where-Object { $_ -and $_.EntitySetName } | ForEach-Object { $_.EntitySetName.ToLower() })

    # Flow nodes are only rendered when flow inclusion is enabled and canvas-only filtering is not active.
    if ($includeFlows -and -not $PSBoundParameters.ContainsKey("CanvasAppName")) {
        foreach ($flow in @($solutionObject.Workflows)) {
            if ($PSBoundParameters.ContainsKey("FlowId") -and $flow.Id -ne $FlowId) { continue }
            if ($PSBoundParameters.ContainsKey("ModelDrivenAppName") -and $flow.Id -notin $modelDrivenFlowFilter) { continue }

            $flowNode = "flow$($flow.Id)"
            $diagram += "class $flowNode[`"$($flow.Name)`"]:::Flow {$newline"

            try {
                $parameters = Get-PowerPlatformCheckerFlowParameter -Path (Join-Path (Join-Path $SolutionPath "Workflows") ("*" + $flow.Id + "*.json"))
                foreach ($parameter in @($parameters)) {
                    if (-not $includeEnvVars) { continue }
                    $diagram += "    [$($parameter.Type)]$($parameter.SchemaName)$newline"
                    $links += "$($parameter.SchemaName) ..> ${flowNode}:$($parameter.SchemaName)$newline"
                    $connectedEnvVars += $parameter.SchemaName
                }
            }
            catch {
                Write-Warning "Error in reading the parameters of flow $($flow.Name)"
            }

            try {
                $actions = Get-PowerPlatformCheckerFlowActionList -Path (Join-Path (Join-Path $SolutionPath "Workflows") ("*" + $flow.Id + "*.json")) -Recurse -IncludeTrigger -Properties References,Entities
                foreach ($action in @($actions)) {
                    if ($null -ne $action.Reference -and $action.Reference -ne "") {
                        $referenceFlow = $solutionObject.Workflows | Where-Object { $_.Id -eq $action.Reference } | Select-Object -First 1
                        if ($includeFlows -and $referenceFlow -and ((-not $PSBoundParameters.ContainsKey("FlowId")) -or $referenceFlow.Id -eq $FlowId)) {
                            $links += "${flowNode} --> flow$($referenceFlow.Id):$($action.Name.replace(' ', '_'))$newline"
                        }
                    }

                    if ($includeConnections -and $action.Group -ne "*" -and $null -ne $action.Group) {
                        $diagram += "    $($action.Name.replace(' ', '_'))($($action.Group))$newline"
                        $links += "$($action.Group) --> ${flowNode}:$($action.Group)$newline"
                        $connectedConnections += $action.Group
                    }

                    if ($includeEntities -and $action.Entities.Count -gt 0) {
                        foreach ($entity in @($action.Entities)) {
                            $diagram += "    $($action.Name.replace(' ', '_'))($($entity))$newline"
                            $links += "${flowNode} --> $($entity):$($entity)$newline"
                            $connectedEntities += $entity
                        }
                    }
                }
            }
            catch {
                Write-Warning "Error in reading the actions of flow $($flow.Name)"
            }

            $diagram += "}$newline"
        }
    }

    $defaultEntitiesInCanvasApps = @()

    # Canvas apps are excluded for flow-only and model-driven-only projections.
    if ($includeCanvasApps -and -not $PSBoundParameters.ContainsKey("FlowId") -and -not $PSBoundParameters.ContainsKey("ModelDrivenAppName")) {
        foreach ($canvasApp in @($solutionObject.CanvasApps)) {
            if ($PSBoundParameters.ContainsKey("CanvasAppName") -and $canvasApp.Name -ne $CanvasAppName) { continue }

            $canvasKey = if ($canvasApp.Name) { [string]$canvasApp.Name } elseif ($canvasApp.DisplayName) { [string]$canvasApp.DisplayName } else { $null }
            if (-not $canvasKey) {
                continue
            }

            $canvasId = Convert-PowerPlatformCheckerMermaidId -InputString $canvasKey
            $canvasDisplayName = if ($canvasApp.DisplayName) { [string]$canvasApp.DisplayName } else { $canvasKey }
            $diagram += ('class {0}["{1}"]:::CanvasApp{2}' -f $canvasId, $canvasDisplayName, $newline)

            foreach ($connection in @($canvasApp.ConnectionReferences)) {
                if (-not $includeConnections) { continue }
                if (-not $connection.id) { continue }
                $connectorName = $connection.id.Split("/")[-1]
                $links += "${connectorName} --> ${canvasId}:$connectorName$newline"
                $connectedConnections += $connectorName
            }

            foreach ($dataSource in @($canvasApp.DataSources.DataSources)) {
                if (-not $includeEntities -and -not $includeDefaultEntities) { continue }
                if ($dataSource.entitySetName -and $dataSource.entitySetName.ToLower() -in $entitySetNames) {
                    if (-not $includeEntities) { continue }
                    $links += "${canvasId} --> $($dataSource.entitySetName.ToLower()):$($dataSource.Name)$newline"
                    $connectedEntities += $dataSource.entitySetName.ToLower()
                }
                elseif ($dataSource.logicalName) {
                    if (-not $includeDefaultEntities) { continue }
                    $links += "${canvasId} --> $($dataSource.logicalName.ToLower()):$($dataSource.Name)$newline"
                    $defaultEntitiesInCanvasApps += $dataSource.logicalName.ToLower()
                    $connectedDefaultEntities += $dataSource.logicalName.ToLower()
                }
            }
        }
    }

    $connectedEnvVars = @($connectedEnvVars | Select-Object -Unique)
    $connectedConnections = @($connectedConnections | Select-Object -Unique)
    $connectedEntities = @($connectedEntities | Select-Object -Unique)
    $connectedDefaultEntities = @($connectedDefaultEntities | Select-Object -Unique)

    foreach ($envVar in @($solutionObject.EnvironmentVariables)) {
        if (-not $includeEnvVars) { continue }
        if ([string]::IsNullOrWhiteSpace([string]$envVar.Name)) {
            continue
        }
        if ((-not $PSBoundParameters.ContainsKey("FlowId") -and -not $PSBoundParameters.ContainsKey("CanvasAppName")) -or $envVar.Name -in $connectedEnvVars) {
            $diagram += "class $($envVar.Name):::EnvVar {$newline"
            $diagram += "  EnvironmentalVariable$newline"
            $diagram += "}$newline"
        }
    }

    foreach ($connection in @($solutionObject.ConnectionReferences)) {
        if (-not $includeConnections) { continue }
        if ([string]::IsNullOrWhiteSpace([string]$connection.ConnectorId)) {
            continue
        }
        $connectorName = Convert-PowerPlatformCheckerMermaidId -InputString $connection.ConnectorId.Split("/")[-1]
        if ((-not $PSBoundParameters.ContainsKey("FlowId") -and -not $PSBoundParameters.ContainsKey("CanvasAppName")) -or $connectorName -in $connectedConnections) {
            $diagram += "class ${connectorName}:::Connection {$newline"
            $diagram += "  ConnectionReference$newline"
            $diagram += "  $($connection.DisplayName)()$newline"
            $diagram += "}$newline"
        }
    }

    foreach ($entity in @($solutionObject.Entities)) {
        if (-not $includeEntities) { continue }
        if (-not $entity -or [string]::IsNullOrWhiteSpace([string]$entity.EntitySetName)) {
            continue
        }

        $entitySetName = $entity.EntitySetName.Trim().ToLower()
        if ((-not $PSBoundParameters.ContainsKey("FlowId") -and -not $PSBoundParameters.ContainsKey("CanvasAppName")) -or $entitySetName -in $connectedEntities) {
            $entityDisplayName = if ($entity.Name) { [string]$entity.Name } else { [string]$entitySetName }
            $diagram += ('class {0}["{1}"]:::Entity {{{2}' -f $entitySetName, $entityDisplayName, $newline)
            foreach ($attribute in @($entity.Attributes)) {
                if (-not $attribute.Name) {
                    continue
                }
                if ($attribute.Name -in $defaultFields -and ($PSBoundParameters.ContainsKey("FlowId") -or $PSBoundParameters.ContainsKey("CanvasAppName"))) {
                    continue
                }
                $diagram += "    [$($attribute.Type)]$($attribute.Name)$newline"
            }
            $diagram += "}$newline"

            foreach ($relation in @($entity.Relations)) {
                if (-not $relation.Source -or -not $relation.Target) {
                    continue
                }

                if ($relation.Source -in $solutionObject.Entities.Name -and $relation.Target -in $solutionObject.Entities.Name) {
                    $sourceEntityObj = $solutionObject.Entities | Where-Object { $_.Name -eq $relation.Source -and $_.EntitySetName } | Select-Object -First 1
                    $targetEntityObj = $solutionObject.Entities | Where-Object { $_.Name -eq $relation.Target -and $_.EntitySetName } | Select-Object -First 1
                    if ($sourceEntityObj -and $targetEntityObj) {
                        $sourceEntity = $sourceEntityObj.EntitySetName.ToLower()
                        $targetEntity = $targetEntityObj.EntitySetName.ToLower()
                        $links += "${sourceEntity} --> ${targetEntity}:$($relation.Source)-$($relation.Type)$newline"
                    }
                }
                elseif ($relation.Source -in $solutionObject.Entities.Name) {
                    if (-not $includeDefaultEntities) { continue }
                    $sourceEntityObj = $solutionObject.Entities | Where-Object { $_.Name -eq $relation.Source -and $_.EntitySetName } | Select-Object -First 1
                    if ($sourceEntityObj) {
                        $sourceEntity = $sourceEntityObj.EntitySetName.ToLower()
                        $links += "${sourceEntity} --> $($relation.Target.ToLower()):$($relation.Type)$newline"
                        $connectedDefaultEntities += $relation.Target.ToLower()
                    }
                }
                else {
                    if (-not $includeDefaultEntities) { continue }
                    $targetEntityObj = $solutionObject.Entities | Where-Object { $_.Name -eq $relation.Target -and $_.EntitySetName } | Select-Object -First 1
                    if ($targetEntityObj) {
                        $targetEntity = $targetEntityObj.EntitySetName.ToLower()
                        $links += "${targetEntity} --> $($relation.Source.ToLower()):$($relation.Type)$newline"
                        $connectedDefaultEntities += $relation.Source.ToLower()
                    }
                }
            }
        }
    }

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

    foreach ($entity in ($defaultEntitiesInCanvasApps | Where-Object { $_ } | Select-Object -Unique)) {
        if (-not $includeDefaultEntities) { continue }
        if ((-not $PSBoundParameters.ContainsKey("FlowId") -and -not $PSBoundParameters.ContainsKey("CanvasAppName")) -or $entity -in $connectedDefaultEntities) {
            if ($entity -and $entity -notin $solutionObject.Entities.Name) {
                $diagram += "class ${entity}:::DefaultEntity$newline"
            }
        }
    }

    foreach ($modelApp in @($modelApps)) {
        if (-not $includeModelDrivenApps) { continue }
        if ($PSBoundParameters.ContainsKey("CanvasAppName")) { continue }
        $diagram += "class $($modelApp.MermaidId)[`"$($modelApp.DisplayName)`"]:::ModelDrivenApp$newline"

        foreach ($flowReferenceId in @($modelApp.FlowIds)) {
            if (-not $includeFlows) { continue }
            $links += "$($modelApp.MermaidId) --> flow${flowReferenceId}:Flow$newline"
        }

        foreach ($entityName in @($modelApp.Entities)) {
            if (-not $includeEntities) { continue }
            $entityObj = $solutionObject.Entities | Where-Object { $_.Name -and $_.EntitySetName -and $_.Name.ToLower() -eq $entityName.ToLower() } | Select-Object -First 1
            if ($entityObj) {
                $links += "$($modelApp.MermaidId) --> $($entityObj.EntitySetName.ToLower()):Entity$newline"
            }
        }

        foreach ($webResourceName in @($modelApp.WebResources)) {
            if (-not $includeWebResources) { continue }
            $webResource = $webResources | Where-Object { $_.Name -eq $webResourceName } | Select-Object -First 1
            if ($webResource) {
                $links += "$($modelApp.MermaidId) --> $($webResource.MermaidId):Script$newline"
            }
        }
    }

    foreach ($webResource in @($webResources)) {
        if (-not $includeWebResources) { continue }
        $diagram += "class $($webResource.MermaidId)[`"$($webResource.DisplayName)`"]:::WebResource$newline"
        foreach ($dependency in @($webResource.Dependencies)) {
            if (-not $dependency) {
                continue
            }
            $dependencyId = Convert-PowerPlatformCheckerMermaidId -InputString $dependency
            $diagram += "class $dependencyId[`"$dependency`"]:::WebResource$newline"
            $links += "$dependencyId --> $($webResource.MermaidId):Dependency$newline"
        }
    }

    foreach ($link in ($links | Select-Object -Unique)) {
        $diagram += $link
    }

    # Emit only class definitions for enabled element groups so style blocks stay minimal.
    $diagram += "classDef default fill:$($style.Default),stroke:$($style.Stroke)$newline"
    if ($includeEnvVars) { $diagram += "classDef EnvVar fill:$($style.EnvVar),stroke:$($style.Stroke)$newline" }
    if ($includeConnections) { $diagram += "classDef Connection fill:$($style.Connection),stroke:$($style.Stroke)$newline" }
    if ($includeEntities) { $diagram += "classDef Entity fill:$($style.Entity),stroke:$($style.Stroke)$newline" }
    if ($includeDefaultEntities) { $diagram += "classDef DefaultEntity fill:$($style.DefaultEntity),stroke:$($style.Stroke)$newline" }
    if ($includeFlows) { $diagram += "classDef Flow fill:$($style.Flow),stroke:$($style.Stroke)$newline" }
    if ($includeCanvasApps) { $diagram += "classDef CanvasApp fill:$($style.CanvasApp),stroke:$($style.Stroke)$newline" }
    if ($includeModelDrivenApps) { $diagram += "classDef ModelDrivenApp fill:$($style.ModelDrivenApp),stroke:$($style.Stroke)$newline" }
    if ($includeWebResources) { $diagram += "classDef WebResource fill:$($style.WebResource),stroke:$($style.Stroke)$newline" }
    $diagram += ":::"

    return $diagram
}


