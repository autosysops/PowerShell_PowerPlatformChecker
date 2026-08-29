function Get-PowerPlatformCheckerExternalInteractionGraphInternal {
    <#
    .SYNOPSIS
        Builds a condensed external interaction graph for selected solution paths.

    .DESCRIPTION
        Produces one internal solution node per source solution and aggregates
        directional interaction edges from solution nodes to external targets.

    .PARAMETER FilteredSolutionPaths
        Resolved and filtered solution paths.

    .PARAMETER Direction
        Graph direction metadata.

    .PARAMETER StyleOverrides
        Optional hashtable of per-call style overrides forwarded to architecture graph generation.

    .PARAMETER MergeName
        Optional merged solution block name. When provided, all selected solutions are
        aggregated under one solution node with this display name.

    .EXAMPLE
        Build a condensed graph from resolved solution paths.

        PS> Get-PowerPlatformCheckerExternalInteractionGraphInternal -FilteredSolutionPaths @($path) -Direction LR
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $FilteredSolutionPaths,

        [Parameter(Mandatory = $true)]
        [ValidateSet('LR', 'RL', 'TB', 'BT')]
        [string] $Direction,

        [Parameter(Mandatory = $false)]
        [hashtable] $StyleOverrides,

        [Parameter(Mandatory = $false)]
        [string] $MergeName
    )

    $hasMerge = $PSBoundParameters.ContainsKey('MergeName') -and -not [string]::IsNullOrWhiteSpace([string]$MergeName)
    $mergedSolutionName = if ($hasMerge) { [string]$MergeName } else { '' }

    $combinedNodes = [System.Collections.Generic.List[object]]::new()
    $combinedEdges = [System.Collections.Generic.List[object]]::new()
    $styles = @{}
    $styleOrder = @()
    $resolvedStyle = Get-PowerPlatformCheckerResolvedStyle -StyleTarget 'ArchitectureDiagram' -StyleOverrides $StyleOverrides
    $sourceAliasByNodeId = @{}
    $sourceAliasCounters = @{}
    $sourceLegend = [System.Collections.Generic.List[object]]::new()
    $connectorByKey = @{}
    $connectorLegend = [System.Collections.Generic.List[object]]::new()
    $legendNotes = [System.Collections.Generic.List[string]]::new()
    $hasUnresolvedConnectionFallback = $false

    foreach ($solutionPath in $FilteredSolutionPaths) {
        $graphParameters = @{
            SolutionPath = $solutionPath
            Direction = $Direction
            OutputFormat = 'Graph'
            IncludeElements = @('Flows','CanvasApps','ModelDrivenApps','Connections','Entities','DefaultEntities','WebResources','ExternalDomains')
            WarningAction = 'SilentlyContinue'
        }
        if ($PSBoundParameters.ContainsKey('StyleOverrides')) {
            $graphParameters.StyleOverrides = $StyleOverrides
        }

        $graph = Get-PowerPlatformCheckerArchitectureDiagram @graphParameters

        $solutionName = if ($hasMerge) { $mergedSolutionName } else { Get-PowerPlatformCheckerSolutionDisplayName -Path ([string]$solutionPath) }
        $solutionNodeId = "solution_{0}" -f (Convert-PowerPlatformCheckerMermaidId -InputString $solutionName)
        if (-not ($combinedNodes | Where-Object { $_.Id -eq $solutionNodeId })) {
            [void]$combinedNodes.Add([pscustomobject]@{
                    Id = $solutionNodeId
                    Type = 'Solution'
                    DisplayName = $solutionName
                    ClassKind = 'Solution'
                    Properties = @{}
                    Members = @()
                    HasExplicitDisplayName = $true
                })
        }

        $nodeById = @{}
        foreach ($node in @($graph.Nodes)) {
            $nodeById[[string]$node.Id] = $node
        }

        $interactionByTarget = @{}
        $targetNodeById = @{}
        $flowPathById = @{}
        $flowActionsByFlowId = @{}
        foreach ($flowJsonPath in @(Get-PowerPlatformCheckerFlowFile -SolutionPath $solutionPath -Type 'json')) {
            $flowIdMatch = [regex]::Match([string]$flowJsonPath, '(?i)-(?<id>[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\.json$')
            if ($flowIdMatch.Success) {
                $flowPathById[[string]$flowIdMatch.Groups['id'].Value.ToLowerInvariant()] = [string]$flowJsonPath
            }
        }

        foreach ($edge in @($graph.Edges)) {
            $sourceNode = $nodeById[[string]$edge.SourceId]
            $targetNode = $nodeById[[string]$edge.TargetId]

            if ($null -eq $sourceNode -or $null -eq $targetNode) {
                continue
            }

            if ([string]$sourceNode.Type -eq 'Connection' -and [string]$targetNode.Type -in @('CanvasApp', 'ModelDrivenApp')) {
                $sourceAlias = Get-PowerPlatformCheckerExternalInteractionSourceAlias -Node $targetNode -AliasByNodeId $sourceAliasByNodeId -AliasCounters $sourceAliasCounters -SourceLegend $sourceLegend -SolutionName $solutionName
                $connectorKey = [string]$sourceNode.DisplayName
                if ([string]::IsNullOrWhiteSpace($connectorKey)) {
                    $connectorKey = [string]$sourceNode.Id
                }
                $connectorProfile = Get-PowerPlatformCheckerExternalInteractionConnectorProfile -ConnectorKey $connectorKey -ConnectorDisplayName $connectorKey -ConnectorByKey $connectorByKey -ConnectorLegend $connectorLegend
                $connectorCode = if ($null -ne $connectorProfile) { [string]$connectorProfile.Code } else { '' }

                $appDomains = @()
                if ($targetNode.PSObject.Properties.Name -contains 'Properties' -and $null -ne $targetNode.Properties) {
                    if ($targetNode.Properties.ContainsKey('ExternalDomains')) {
                        $appDomains = @($targetNode.Properties.ExternalDomains)
                    }
                    elseif ($targetNode.Properties.ContainsKey('DestinationTargets')) {
                        $appDomains = @($targetNode.Properties.DestinationTargets)
                    }
                }

                $hasResolvedConnectorDomain = $false
                foreach ($appDomain in @($appDomains)) {
                    if (Test-PowerPlatformCheckerConnectorDomainMatch -ConnectorKey $connectorKey -DomainValue ([string]$appDomain)) {
                        $hasResolvedConnectorDomain = $true
                        break
                    }
                }

                if ($hasResolvedConnectorDomain) {
                    continue
                }

                $hasUnresolvedConnectionFallback = $true
                $targetId = [string]$sourceNode.Id
                foreach ($interactionLabel in @(Get-PowerPlatformCheckerExternalInteractionLabels -Direction ([string]$targetNode.Properties.InteractionDirection))) {
                    $sourceLabel = Get-PowerPlatformCheckerExternalInteractionSourceLabel -Node $targetNode -InteractionLabel $interactionLabel -SourceAlias $sourceAlias -ConnectorCode $connectorCode -DomainUnresolved
                    Add-PowerPlatformCheckerExternalInteractionEvidence -InteractionByTarget $interactionByTarget -TargetNodeById $targetNodeById -TargetId $targetId -InteractionLabel $interactionLabel -TargetNode $sourceNode -SourceNode $targetNode -Evidence ([string]$edge.Label) -SourceLabelOverride $sourceLabel
                }
                continue
            }

            if ([string]$targetNode.Type -eq 'ExternalDomain' -and [string]$sourceNode.Type -in @('Flow', 'CanvasApp', 'ModelDrivenApp', 'WebResource')) {
                if (-not (Test-PowerPlatformCheckerExternalDomainToken -DomainValue ([string]$targetNode.DisplayName))) {
                    continue
                }

                $targetId = [string]$targetNode.Id
                $edgeInteractionDirection = [string]$edge.Metadata.InteractionDirection
                if ([string]::IsNullOrWhiteSpace($edgeInteractionDirection)) {
                    $edgeInteractionDirection = [string]$sourceNode.Properties.InteractionDirection
                }

                $sourceAlias = Get-PowerPlatformCheckerExternalInteractionSourceAlias -Node $sourceNode -AliasByNodeId $sourceAliasByNodeId -AliasCounters $sourceAliasCounters -SourceLegend $sourceLegend -SolutionName $solutionName

                foreach ($interactionLabel in @(Get-PowerPlatformCheckerExternalInteractionLabels -Direction $edgeInteractionDirection)) {
                    $sourceLabel = Get-PowerPlatformCheckerExternalInteractionSourceLabel -Node $sourceNode -InteractionLabel $interactionLabel -SourceAlias $sourceAlias
                    Add-PowerPlatformCheckerExternalInteractionEvidence -InteractionByTarget $interactionByTarget -TargetNodeById $targetNodeById -TargetId $targetId -InteractionLabel $interactionLabel -TargetNode $targetNode -SourceNode $sourceNode -Evidence ([string]$edge.Label) -SourceLabelOverride $sourceLabel
                }
            }
        }

        foreach ($flowNode in @($graph.Nodes | Where-Object { $_.Type -eq 'Flow' })) {
            $flowAlias = Get-PowerPlatformCheckerExternalInteractionSourceAlias -Node $flowNode -AliasByNodeId $sourceAliasByNodeId -AliasCounters $sourceAliasCounters -SourceLegend $sourceLegend -SolutionName $solutionName
            $destinations = @($flowNode.Properties.DestinationTargets)
            if ($destinations.Count -eq 0) {
                $legacyDestination = [string]$flowNode.Properties.Destination
                if (-not [string]::IsNullOrWhiteSpace($legacyDestination) -and $legacyDestination -ne 'Unknown') {
                    $destinations = @($legacyDestination)
                }
            }
            $fallbackInteractionLabels = @(Get-PowerPlatformCheckerExternalInteractionLabels -Direction ([string]$flowNode.Properties.InteractionDirection))
            $targetIdsAddedForFlow = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

            $flowIdMatch = [regex]::Match([string]$flowNode.Id, '(?i)^flow(?<id>[0-9a-f\-]{36})$')
            if ($flowIdMatch.Success) {
                $flowId = [string]$flowIdMatch.Groups['id'].Value.ToLowerInvariant()
                if ($flowPathById.ContainsKey($flowId)) {
                    $flowPath = [string]$flowPathById[$flowId]
                    $flowActions = @(Get-PowerPlatformCheckerFlowActionList -Path $flowPath -Recurse -IncludeTrigger -Properties ExternalProfile,InteractionProfile,TriggerProfile,OperationProfile,ResponseProfile -WarningAction SilentlyContinue)
                    $flowActionsByFlowId[$flowId] = @($flowActions)
                    foreach ($flowAction in $flowActions) {
                        $connectorKey = [string]$flowAction.Group
                        $connectorDisplayName = [string]$flowAction.ConnectorDisplayName
                        if ([string]::IsNullOrWhiteSpace($connectorKey) -or $connectorKey -eq '*') {
                            $connectorKey = $connectorDisplayName
                        }
                        if ([string]::IsNullOrWhiteSpace($connectorDisplayName)) {
                            $connectorDisplayName = $connectorKey
                        }
                        $connectorProfile = Get-PowerPlatformCheckerExternalInteractionConnectorProfile -ConnectorKey $connectorKey -ConnectorDisplayName $connectorDisplayName -ConnectorByKey $connectorByKey -ConnectorLegend $connectorLegend
                        $connectorCode = if ($null -ne $connectorProfile) { [string]$connectorProfile.Code } else { '' }

                        if ($flowAction.PSObject.Properties.Name -contains 'IsTrigger' -and [bool]$flowAction.IsTrigger) {
                            continue
                        }

                        if ([string]$flowAction.Type -eq 'Response') {
                            $internetNode = [pscustomobject]@{
                                Id = 'externaldomain_internet'
                                Type = 'ExternalDomain'
                                DisplayName = 'internet'
                                ClassKind = 'ExternalDomain'
                                Properties = @{}
                                Members = @()
                                HasExplicitDisplayName = $true
                            }

                            $responseLabel = Get-PowerPlatformCheckerExternalInteractionFlowActionLabel -FlowNode $flowNode -FlowAction $flowAction -InteractionLabel 'OUTBOUND' -FlowAlias $flowAlias -ConnectorCode $connectorCode
                            $responseEvidence = [string]$flowAction.Name
                            Add-PowerPlatformCheckerExternalInteractionEvidence -InteractionByTarget $interactionByTarget -TargetNodeById $targetNodeById -TargetId 'externaldomain_internet' -InteractionLabel 'OUTBOUND' -TargetNode $internetNode -SourceNode $flowNode -Evidence $responseEvidence -SourceLabelOverride $responseLabel
                            [void]$targetIdsAddedForFlow.Add('externaldomain_internet')
                            continue
                        }

                        $domain = [string]$flowAction.ExternalEndpoint
                        if ([string]::IsNullOrWhiteSpace($domain) -or $domain -eq 'Unknown') {
                            $domain = [string]$flowAction.ExternalDomain
                        }
                        if (-not (Test-PowerPlatformCheckerExternalDomainToken -DomainValue $domain)) {
                            continue
                        }

                        $displayDomain = ([string]$domain).Trim()
                        $normalizedDomain = $displayDomain.ToLowerInvariant()
                        $targetNode = [pscustomobject]@{
                            Id = "externaldomain_{0}" -f (Convert-PowerPlatformCheckerMermaidId -InputString $normalizedDomain)
                            Type = 'ExternalDomain'
                            DisplayName = $displayDomain
                            ClassKind = 'ExternalDomain'
                            Properties = @{}
                            Members = @()
                            HasExplicitDisplayName = $true
                        }

                        $actionInteractionLabel = [string]$flowAction.GetSetAction
                        if ([string]::IsNullOrWhiteSpace($actionInteractionLabel) -or $actionInteractionLabel -eq 'Unknown') {
                            switch ([string]$flowAction.InteractionDirection) {
                                'Read' { $actionInteractionLabel = 'GET' }
                                'Write' { $actionInteractionLabel = 'SET' }
                                'Mixed' { $actionInteractionLabel = 'GET/SET' }
                                default { $actionInteractionLabel = 'Unknown' }
                            }
                        }

                        $actionInteractionLabel = [string]$actionInteractionLabel
                        if ($actionInteractionLabel -eq 'Get') {
                            $actionInteractionLabel = 'GET'
                        }
                        elseif ($actionInteractionLabel -eq 'Set') {
                            $actionInteractionLabel = 'SET'
                        }

                        $evidence = [string]$flowAction.Name
                        $sourceLabel = Get-PowerPlatformCheckerExternalInteractionFlowActionLabel -FlowNode $flowNode -FlowAction $flowAction -InteractionLabel ([string]$actionInteractionLabel) -FlowAlias $flowAlias -ConnectorCode $connectorCode
                        Add-PowerPlatformCheckerExternalInteractionEvidence -InteractionByTarget $interactionByTarget -TargetNodeById $targetNodeById -TargetId ([string]$targetNode.Id) -InteractionLabel ([string]$actionInteractionLabel) -TargetNode $targetNode -SourceNode $flowNode -Evidence $evidence -SourceLabelOverride $sourceLabel
                        [void]$targetIdsAddedForFlow.Add([string]$targetNode.Id)
                    }
                }
            }

            foreach ($destination in @($destinations | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) -and [string]$_ -ne 'Unknown' } | Select-Object -Unique)) {
                $destinationType = [string]$flowNode.Properties.DestinationType
                $targetNode = $null
                $targetId = ''
                if ($destinationType -eq 'Domain') {
                    if (-not (Test-PowerPlatformCheckerExternalDomainToken -DomainValue ([string]$destination))) {
                        continue
                    }

                    $displayDomain = ([string]$destination).Trim()
                    $normalizedDomain = $displayDomain.ToLowerInvariant()
                    $targetNode = [pscustomobject]@{
                        Id = "externaldomain_{0}" -f (Convert-PowerPlatformCheckerMermaidId -InputString $normalizedDomain)
                        Type = 'ExternalDomain'
                        DisplayName = $displayDomain
                        ClassKind = 'ExternalDomain'
                        Properties = @{}
                        Members = @()
                        HasExplicitDisplayName = $true
                    }
                    $targetId = [string]$targetNode.Id
                }
                else {
                    continue
                }

                if ($targetIdsAddedForFlow.Contains($targetId)) {
                    continue
                }

                foreach ($fallbackInteractionLabel in @($fallbackInteractionLabels)) {
                    $fallbackLabel = Get-PowerPlatformCheckerExternalInteractionSourceLabel -Node $flowNode -InteractionLabel ([string]$fallbackInteractionLabel) -SourceAlias $flowAlias
                    Add-PowerPlatformCheckerExternalInteractionEvidence -InteractionByTarget $interactionByTarget -TargetNodeById $targetNodeById -TargetId $targetId -InteractionLabel ([string]$fallbackInteractionLabel) -TargetNode $targetNode -SourceNode $flowNode -Evidence '' -SourceLabelOverride $fallbackLabel
                }
            }
        }

        $inboundFlows = @($graph.Nodes | Where-Object { $_.Type -eq 'Flow' -and [string]$_.Properties.TriggerMode -in @('Webhook', 'ManualHttp') })
        if ($inboundFlows.Count -gt 0) {
            $internetNodeId = 'externaldomain_internet'
            $internetNode = [pscustomobject]@{
                Id = $internetNodeId
                Type = 'ExternalDomain'
                DisplayName = 'internet'
                ClassKind = 'ExternalDomain'
                Properties = @{}
                Members = @()
                HasExplicitDisplayName = $true
            }

            if (-not ($combinedNodes | Where-Object { $_.Id -eq $internetNodeId })) {
                [void]$combinedNodes.Add($internetNode)
            }

            foreach ($inboundFlow in $inboundFlows) {
                $inboundAlias = Get-PowerPlatformCheckerExternalInteractionSourceAlias -Node $inboundFlow -AliasByNodeId $sourceAliasByNodeId -AliasCounters $sourceAliasCounters -SourceLegend $sourceLegend -SolutionName $solutionName
                $inboundFlowIdMatch = [regex]::Match([string]$inboundFlow.Id, '(?i)^flow(?<id>[0-9a-f\-]{36})$')
                if (-not $inboundFlowIdMatch.Success) {
                    continue
                }

                $inboundFlowId = [string]$inboundFlowIdMatch.Groups['id'].Value.ToLowerInvariant()
                $triggerActions = @()
                if ($flowActionsByFlowId.ContainsKey($inboundFlowId)) {
                    $triggerActions = @($flowActionsByFlowId[$inboundFlowId] | Where-Object {
                            $_ -and $_.PSObject.Properties.Name -contains 'IsTrigger' -and [bool]$_.IsTrigger
                        })
                }

                if ($triggerActions.Count -eq 0) {
                    $triggerLabel = Get-PowerPlatformCheckerExternalInteractionSourceLabel -Node $inboundFlow -InteractionLabel 'INBOUND' -SourceAlias $inboundAlias
                    $edgeKey = "{0}|{1}|{2}|-->" -f $internetNodeId, $solutionNodeId, $triggerLabel
                    $existingInbound = $combinedEdges | Where-Object {
                        ("{0}|{1}|{2}|{3}" -f [string]$_.SourceId, [string]$_.TargetId, [string]$_.Label, [string]$_.Metadata.Arrow) -eq $edgeKey
                    }
                    if (-not $existingInbound) {
                        [void]$combinedEdges.Add([pscustomobject]@{
                                SourceId = $internetNodeId
                                TargetId = $solutionNodeId
                                Label = $triggerLabel
                                EdgeType = 'Link'
                                Metadata = [pscustomobject]@{
                                    Arrow = '-->'
                                    Evidence = [string]$inboundFlow.DisplayName
                                }
                            })
                    }

                    continue
                }

                foreach ($triggerAction in $triggerActions) {
                    $triggerConnectorKey = [string]$triggerAction.Group
                    $triggerConnectorDisplayName = [string]$triggerAction.ConnectorDisplayName
                    if ([string]::IsNullOrWhiteSpace($triggerConnectorKey) -or $triggerConnectorKey -eq '*') {
                        $triggerConnectorKey = $triggerConnectorDisplayName
                    }
                    if ([string]::IsNullOrWhiteSpace($triggerConnectorDisplayName)) {
                        $triggerConnectorDisplayName = $triggerConnectorKey
                    }

                    $triggerExternalTarget = [string]$triggerAction.ExternalEndpoint
                    if ([string]::IsNullOrWhiteSpace($triggerExternalTarget) -or $triggerExternalTarget -eq 'Unknown') {
                        $triggerExternalTarget = [string]$triggerAction.ExternalDomain
                    }

                    $isManualInbound = [string]$triggerAction.Type -eq 'Request' -or [string]$triggerAction.TriggerKind -eq 'Http'
                    $hasExternalTriggerTarget = Test-PowerPlatformCheckerExternalDomainToken -DomainValue $triggerExternalTarget
                    if (-not $isManualInbound -and -not $hasExternalTriggerTarget) {
                        continue
                    }

                    $triggerConnectorProfile = Get-PowerPlatformCheckerExternalInteractionConnectorProfile -ConnectorKey $triggerConnectorKey -ConnectorDisplayName $triggerConnectorDisplayName -ConnectorByKey $connectorByKey -ConnectorLegend $connectorLegend
                    $triggerConnectorCode = if ($null -ne $triggerConnectorProfile) { [string]$triggerConnectorProfile.Code } else { '' }
                    $triggerLabel = Get-PowerPlatformCheckerExternalInteractionFlowActionLabel -FlowNode $inboundFlow -FlowAction $triggerAction -InteractionLabel 'INBOUND' -FlowAlias $inboundAlias -ConnectorCode $triggerConnectorCode
                    $triggerEvidence = [string]$triggerAction.Name
                    $edgeKey = "{0}|{1}|{2}|-->" -f $internetNodeId, $solutionNodeId, $triggerLabel
                    $existingInbound = $combinedEdges | Where-Object {
                        ("{0}|{1}|{2}|{3}" -f [string]$_.SourceId, [string]$_.TargetId, [string]$_.Label, [string]$_.Metadata.Arrow) -eq $edgeKey
                    }

                    if (-not $existingInbound) {
                        [void]$combinedEdges.Add([pscustomobject]@{
                                SourceId = $internetNodeId
                                TargetId = $solutionNodeId
                                Label = [string]$triggerLabel
                                EdgeType = 'Link'
                                Metadata = [pscustomobject]@{
                                    Arrow = '-->'
                                    Evidence = $triggerEvidence
                                }
                            })
                    }
                }
            }
        }

        foreach ($targetId in @($interactionByTarget.Keys | Sort-Object)) {
            $targetNode = $targetNodeById[$targetId]
            if ($null -eq $targetNode) {
                continue
            }

            if (-not ($combinedNodes | Where-Object { $_.Id -eq $targetId })) {
                [void]$combinedNodes.Add($targetNode)
            }

            foreach ($sourceLabel in @($interactionByTarget[$targetId].Keys | Sort-Object)) {
                $edgeLabel = [string]$sourceLabel
                $edgeKey = "{0}|{1}|{2}|-->" -f $solutionNodeId, [string]$targetId, $edgeLabel
                $existingEdge = $combinedEdges | Where-Object {
                    ("{0}|{1}|{2}|{3}" -f [string]$_.SourceId, [string]$_.TargetId, [string]$_.Label, [string]$_.Metadata.Arrow) -eq $edgeKey
                }

                if (-not $existingEdge) {
                    $edgeEvidence = (($interactionByTarget[$targetId][$sourceLabel] | Select-Object -First 3) -join ',')
                    [void]$combinedEdges.Add([pscustomobject]@{
                            SourceId = $solutionNodeId
                            TargetId = [string]$targetId
                            Label = $edgeLabel
                            EdgeType = 'Link'
                            Metadata = [pscustomobject]@{
                                Arrow = '-->'
                                Evidence = $edgeEvidence
                            }
                        })
                }
            }
        }

        if ($styles.Count -eq 0 -and $graph.Styles) {
            $styles = @{}
            foreach ($styleProperty in @($graph.Styles.PSObject.Properties)) {
                $styleKey = [string]$styleProperty.Name
                $styleValue = [string]$styleProperty.Value
                if ([string]::IsNullOrWhiteSpace($styleKey) -or [string]::IsNullOrWhiteSpace($styleValue)) {
                    continue
                }

                $styles[$styleKey] = $styleValue
            }
        }

        if ($styleOrder.Count -eq 0 -and $graph.StyleOrder) {
            $styleOrder = @($graph.StyleOrder)
        }
    }

    $requiredStyles = [ordered]@{}
    $requiredStyles['default'] = "fill:$($resolvedStyle.Default),stroke:$($resolvedStyle.Stroke)"
    if (@($combinedNodes | Where-Object { $_.ClassKind -eq 'Connection' }).Count -gt 0) {
        $requiredStyles['Connection'] = "fill:$($resolvedStyle.Connection),stroke:$($resolvedStyle.Stroke)"
    }
    if (@($combinedNodes | Where-Object { $_.ClassKind -eq 'CanvasApp' }).Count -gt 0) {
        $requiredStyles['CanvasApp'] = "fill:$($resolvedStyle.CanvasApp),stroke:$($resolvedStyle.Stroke)"
    }
    if (@($combinedNodes | Where-Object { $_.ClassKind -eq 'ModelDrivenApp' }).Count -gt 0) {
        $requiredStyles['ModelDrivenApp'] = "fill:$($resolvedStyle.ModelDrivenApp),stroke:$($resolvedStyle.Stroke)"
    }
    if (@($combinedNodes | Where-Object { $_.ClassKind -eq 'WebResource' }).Count -gt 0) {
        $requiredStyles['WebResource'] = "fill:$($resolvedStyle.WebResource),stroke:$($resolvedStyle.Stroke)"
    }
    if (@($combinedNodes | Where-Object { $_.ClassKind -eq 'Flow' }).Count -gt 0) {
        $requiredStyles['Flow'] = "fill:$($resolvedStyle.Flow),stroke:$($resolvedStyle.Stroke)"
    }
    if (@($combinedNodes | Where-Object { $_.ClassKind -eq 'Solution' }).Count -gt 0) {
        $requiredStyles['Solution'] = "fill:$($resolvedStyle.Solution),stroke:$($resolvedStyle.SolutionStroke),stroke-width:2px;"
    }
    if (@($combinedNodes | Where-Object { $_.ClassKind -eq 'ExternalDomain' }).Count -gt 0) {
        $requiredStyles['ExternalDomain'] = "fill:$($resolvedStyle.ExternalDomain),stroke:$($resolvedStyle.Stroke)"
    }

    foreach ($styleName in @($requiredStyles.Keys)) {
        # Always enforce required style definitions for external interaction
        # output so inherited style maps cannot leak malformed Mermaid tokens.
        $styles[$styleName] = [string]$requiredStyles[$styleName]
        if ($styleOrder -notcontains $styleName) {
            $styleOrder += $styleName
        }
    }

    $connectedNodeIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($edge in @($combinedEdges)) {
        [void]$connectedNodeIds.Add([string]$edge.SourceId)
        [void]$connectedNodeIds.Add([string]$edge.TargetId)
    }

    # Keep the primary solution node visible, but drop unreferenced external domain
    # placeholders (for example internet when no qualifying inbound/outbound edge exists).
    $combinedNodes = @(
        $combinedNodes |
            Where-Object {
                $_.ClassKind -ne 'ExternalDomain' -or $connectedNodeIds.Contains([string]$_.Id)
            }
    )

    if ($hasUnresolvedConnectionFallback) {
        [void]$legendNotes.Add('Connection fallback edges are labeled DomainUnresolved when no concrete external domain could be derived for that connector.')
    }

    return [pscustomobject]@{
        Metadata = [pscustomobject]@{
            Direction = $Direction
            DiagramKind = 'Flowchart'
            IncludeElements = @('Flows','CanvasApps','ModelDrivenApps','Connections','Entities','DefaultEntities','WebResources','ExternalDomains')
            OutputFormat = 'Graph'
            SourceSolutions = @($FilteredSolutionPaths)
            SourceSolutionCount = @($FilteredSolutionPaths).Count
            IsScopedDiagram = $false
            SourceFilterType = 'None'
            SourceFilterValue = ''
            SourceAliases = @($sourceLegend | Sort-Object Alias)
            ConnectorLegend = @($connectorLegend | Sort-Object Code)
            LegendNotes = @($legendNotes | Select-Object -Unique)
        }
        Nodes = @($combinedNodes)
        Edges = @($combinedEdges)
        Styles = $styles
        StyleOrder = @($styleOrder)
    }
}
