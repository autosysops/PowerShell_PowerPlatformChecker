. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerFlowChart" {
    $snapshotCases = @(
        @{ Name = "SampleFlow TB"; ActionsRef = "sampleActions"; Direction = "TB"; Snapshot = "FlowChart.SampleFlow.expected.md" }
        @{ Name = "SampleFlow LR"; ActionsRef = "sampleActions"; Direction = "LR"; Snapshot = "FlowChart.SampleFlow.LR.expected.md" }
        @{ Name = "SampleFlow RL"; ActionsRef = "sampleActions"; Direction = "RL"; Snapshot = "FlowChart.SampleFlow.RL.expected.md" }
        @{ Name = "ChildFlow BT"; ActionsRef = "childActions"; Direction = "BT"; Snapshot = "FlowChart.ChildFlow.BT.expected.md" }
        @{ Name = "SubgraphFlow TB"; ActionsRef = "subgraphActions"; Direction = "TB"; Snapshot = "FlowChart.SubgraphFlow.expected.md" }
        @{ Name = "TrueOnlyConditionFlow TB"; ActionsRef = "trueOnlyConditionActions"; Direction = "TB"; Snapshot = "FlowChart.TrueOnlyConditionFlow.expected.md" }
        @{ Name = "SwitchCaseFlow TB"; ActionsRef = "switchCaseActions"; Direction = "TB"; Snapshot = "FlowChart.SwitchCaseFlow.expected.md" }
        @{ Name = "ScopeInIfFlow TB"; ActionsRef = "scopeInIfActions"; Direction = "TB"; Snapshot = "FlowChart.ScopeInIfFlow.expected.md" }
        @{ Name = "DesktopFlow QuotedMetadata TB"; ActionsRef = "desktopQuotedMetadataActions"; Direction = "TB"; Snapshot = "FlowChart.DesktopFlow.QuotedMetadata.expected.md" }
        @{ Name = "DesktopFlow OnError TB"; ActionsRef = "desktopOnErrorActions"; Direction = "TB"; Snapshot = "FlowChart.DesktopOnError.expected.md" }
        @{ Name = "DesktopFlow OnBlockError TB"; ActionsRef = "desktopOnBlockErrorActions"; Direction = "TB"; Snapshot = "FlowChart.DesktopOnBlockError.expected.md" }
        @{ Name = "DesktopFlow LoopWaitCall TB"; ActionsRef = "desktopLoopWaitCallActions"; Direction = "TB"; Snapshot = "FlowChart.DesktopLoopWaitCall.expected.md" }
        @{ Name = "DesktopFlow ConnectorMultiline TB"; ActionsRef = "desktopConnectorMultilineActions"; Direction = "TB"; Snapshot = "FlowChart.DesktopConnectorMultiline.expected.md" }
        @{ Name = "DesktopFlow ScopeSuccessAndEmailBody TB"; ActionsRef = "desktopScopeSuccessAndEmailBodyActions"; Direction = "TB"; Snapshot = "FlowChart.DesktopScopeSuccessAndEmailBody.expected.md" }
        @{ Name = "DesktopFlow PdfwRegression TB"; ActionsRef = "desktopPdfwRegressionActions"; Direction = "TB"; Snapshot = "FlowChart.DesktopPdfwRegression.expected.md" }
    )
    $graphSnapshotCases = @(
        @{ Name = "SampleFlow TB"; ActionsRef = "sampleActions"; Direction = "TB"; Snapshot = "FlowChart.SampleFlow.expected.graph.json" }
        @{ Name = "ChildFlow BT"; ActionsRef = "childActions"; Direction = "BT"; Snapshot = "FlowChart.ChildFlow.BT.expected.graph.json" }
        @{ Name = "SubgraphFlow TB"; ActionsRef = "subgraphActions"; Direction = "TB"; Snapshot = "FlowChart.SubgraphFlow.expected.graph.json" }
        @{ Name = "TrueOnlyConditionFlow TB"; ActionsRef = "trueOnlyConditionActions"; Direction = "TB"; Snapshot = "FlowChart.TrueOnlyConditionFlow.expected.graph.json" }
        @{ Name = "SwitchCaseFlow TB"; ActionsRef = "switchCaseActions"; Direction = "TB"; Snapshot = "FlowChart.SwitchCaseFlow.expected.graph.json" }
        @{ Name = "ScopeInIfFlow TB"; ActionsRef = "scopeInIfActions"; Direction = "TB"; Snapshot = "FlowChart.ScopeInIfFlow.expected.graph.json" }
        @{ Name = "DesktopFlow QuotedMetadata TB"; ActionsRef = "desktopQuotedMetadataActions"; Direction = "TB"; Snapshot = "FlowChart.DesktopFlow.QuotedMetadata.expected.graph.json" }
        @{ Name = "DesktopFlow OnError TB"; ActionsRef = "desktopOnErrorActions"; Direction = "TB"; Snapshot = "FlowChart.DesktopOnError.expected.graph.json" }
        @{ Name = "DesktopFlow OnBlockError TB"; ActionsRef = "desktopOnBlockErrorActions"; Direction = "TB"; Snapshot = "FlowChart.DesktopOnBlockError.expected.graph.json" }
        @{ Name = "DesktopFlow LoopWaitCall TB"; ActionsRef = "desktopLoopWaitCallActions"; Direction = "TB"; Snapshot = "FlowChart.DesktopLoopWaitCall.expected.graph.json" }
        @{ Name = "DesktopFlow ConnectorMultiline TB"; ActionsRef = "desktopConnectorMultilineActions"; Direction = "TB"; Snapshot = "FlowChart.DesktopConnectorMultiline.expected.graph.json" }
        @{ Name = "DesktopFlow ScopeSuccessAndEmailBody TB"; ActionsRef = "desktopScopeSuccessAndEmailBodyActions"; Direction = "TB"; Snapshot = "FlowChart.DesktopScopeSuccessAndEmailBody.expected.graph.json" }
        @{ Name = "DesktopFlow PdfwRegression TB"; ActionsRef = "desktopPdfwRegressionActions"; Direction = "TB"; Snapshot = "FlowChart.DesktopPdfwRegression.expected.graph.json" }
    )

    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
        $script:desktopSolutionPath = Get-PowerPlatformCheckerDesktopFixtureSolutionPath
        $script:desktopFlowChartSolutionPath = (Resolve-Path (Join-Path $PSScriptRoot "..\fixtures\desktop-flowchart-solution\Managed")).Path
        $script:flowPath = Join-Path $script:solutionPath "Workflows\SampleFlow-11111111-1111-1111-1111-111111111111.json"
        $script:childFlowPath = Join-Path $script:solutionPath "Workflows\ChildFlow-22222222-2222-2222-2222-222222222222.json"
        $script:subgraphFlowPath = Join-Path $script:solutionPath "Workflows\SubgraphFlow-33333333-3333-3333-3333-333333333333.json"
        $script:trueOnlyConditionFlowPath = Join-Path $script:solutionPath "Workflows\TrueOnlyConditionFlow-44444444-4444-4444-4444-444444444444.json"
        $script:switchCaseFlowPath = Join-Path $script:solutionPath "Workflows\SwitchCaseFlow-55555555-5555-5555-5555-555555555555.json"
        $script:scopeInIfFlowPath = Join-Path $script:solutionPath "Workflows\ScopeInIfFlow-66666666-6666-6666-6666-666666666666.json"
        $script:desktopFlowPath = Join-Path $script:desktopSolutionPath "Workflows\DesktopFlow-77777777-7777-7777-7777-777777777777.json"
        $script:desktopQuotedMetadataFlowPath = Join-Path $script:desktopSolutionPath "Workflows\DesktopFlow-88888888-8888-8888-8888-888888888888.json"
        $script:desktopOnErrorFlowPath = Join-Path $script:desktopFlowChartSolutionPath "Workflows\DesktopFlow-OnError-aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa.json"
        $script:desktopOnBlockErrorFlowPath = Join-Path $script:desktopFlowChartSolutionPath "Workflows\DesktopFlow-OnBlockError-bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb.json"
        $script:desktopLoopWaitCallFlowPath = Join-Path $script:desktopFlowChartSolutionPath "Workflows\DesktopFlow-LoopWaitCall-cccccccc-cccc-cccc-cccc-cccccccccccc.json"
        $script:desktopConnectorMultilineFlowPath = Join-Path $script:desktopFlowChartSolutionPath "Workflows\DesktopFlow-ConnectorMultiline-dddddddd-dddd-dddd-dddd-dddddddddddd.json"
        $script:desktopScopeSuccessAndEmailBodyFlowPath = Join-Path $script:desktopFlowChartSolutionPath "Workflows\DesktopFlow-ScopeSuccessAndEmailBody-eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee.json"
        $script:desktopPdfwRegressionFlowPath = Join-Path $script:desktopFlowChartSolutionPath "Workflows\DesktopFlow-PdfwRegression-ffffffff-ffff-ffff-ffff-ffffffffffff.json"

        $script:sampleActions = Get-PowerPlatformCheckerFlowActionList -Path $script:flowPath -Recurse -IncludeTrigger -Properties References,Entities,RunAfter,ParentAction
        $script:childActions = Get-PowerPlatformCheckerFlowActionList -Path $script:childFlowPath -Recurse -IncludeTrigger -Properties References,Entities,RunAfter,ParentAction
        $script:subgraphActions = Get-PowerPlatformCheckerFlowActionList -Path $script:subgraphFlowPath -Recurse -IncludeTrigger -Properties References,Entities,RunAfter,ParentAction
        $script:trueOnlyConditionActions = Get-PowerPlatformCheckerFlowActionList -Path $script:trueOnlyConditionFlowPath -Recurse -IncludeTrigger -Properties References,Entities,RunAfter,ParentAction
        $script:switchCaseActions = Get-PowerPlatformCheckerFlowActionList -Path $script:switchCaseFlowPath -Recurse -IncludeTrigger -Properties References,Entities,RunAfter,ParentAction
        $script:scopeInIfActions = Get-PowerPlatformCheckerFlowActionList -Path $script:scopeInIfFlowPath -Recurse -IncludeTrigger -Properties References,Entities,RunAfter,ParentAction
        $script:desktopQuotedMetadataActions = Get-PowerPlatformCheckerFlowActionList -Path $script:desktopQuotedMetadataFlowPath -Recurse -Properties References,Entities,RunAfter,ParentAction
        $script:desktopOnErrorActions = Get-PowerPlatformCheckerFlowActionList -Path $script:desktopOnErrorFlowPath -Recurse -Properties References,Entities,RunAfter,ParentAction
        $script:desktopOnBlockErrorActions = Get-PowerPlatformCheckerFlowActionList -Path $script:desktopOnBlockErrorFlowPath -Recurse -Properties References,Entities,RunAfter,ParentAction
        $script:desktopLoopWaitCallActions = Get-PowerPlatformCheckerFlowActionList -Path $script:desktopLoopWaitCallFlowPath -Recurse -Properties References,Entities,RunAfter,ParentAction
        $script:desktopConnectorMultilineActions = Get-PowerPlatformCheckerFlowActionList -Path $script:desktopConnectorMultilineFlowPath -Recurse -Properties References,Entities,RunAfter,ParentAction
        $script:desktopScopeSuccessAndEmailBodyActions = Get-PowerPlatformCheckerFlowActionList -Path $script:desktopScopeSuccessAndEmailBodyFlowPath -Recurse -Properties References,Entities,RunAfter,ParentAction
        $script:desktopPdfwRegressionActions = Get-PowerPlatformCheckerFlowActionList -Path $script:desktopPdfwRegressionFlowPath -Recurse -Properties References,Entities,RunAfter,ParentAction
        $script:actionsByRef = @{
            sampleActions = $script:sampleActions
            childActions = $script:childActions
            subgraphActions = $script:subgraphActions
            trueOnlyConditionActions = $script:trueOnlyConditionActions
            switchCaseActions = $script:switchCaseActions
            scopeInIfActions = $script:scopeInIfActions
            desktopQuotedMetadataActions = $script:desktopQuotedMetadataActions
            desktopOnErrorActions = $script:desktopOnErrorActions
            desktopOnBlockErrorActions = $script:desktopOnBlockErrorActions
            desktopLoopWaitCallActions = $script:desktopLoopWaitCallActions
            desktopConnectorMultilineActions = $script:desktopConnectorMultilineActions
            desktopScopeSuccessAndEmailBodyActions = $script:desktopScopeSuccessAndEmailBodyActions
            desktopPdfwRegressionActions = $script:desktopPdfwRegressionActions
        }
        $script:flowGraphSnapshotNormalizer = {
            param(
                [Parameter(Mandatory = $true)]
                [object] $Graph
            )

            return [ordered]@{
                GraphType = [string]$Graph.GraphType
                Id = if ($null -eq $Graph.Id) { $null } else { [string]$Graph.Id }
                ActionName = if ($null -eq $Graph.ActionName) { $null } else { [string]$Graph.ActionName }
                Title = if ($null -eq $Graph.Title) { $null } else { [string]$Graph.Title }
                Direction = [string]$Graph.Direction
                IsEmpty = [bool]$Graph.IsEmpty
                Nodes = @($Graph.Nodes | ForEach-Object {
                        [ordered]@{
                            Id = [string]$_.Id
                            Label = [string]$_.Label
                            Shape = [string]$_.Shape
                        }
                    })
                Edges = @($Graph.Edges | ForEach-Object {
                        [ordered]@{
                            From = [string]$_.From
                            Label = [string]$_.Label
                            To = [string]$_.To
                        }
                    })
                Subgraphs = @($Graph.Subgraphs | ForEach-Object {
                        & $script:flowGraphSnapshotNormalizer -Graph $_
                    })
            }
        }
        $script:flowGraphSnapshotConverter = {
            param(
                [Parameter(Mandatory = $true)]
                [object] $Graph
            )

            return (& $script:flowGraphSnapshotNormalizer -Graph $Graph | ConvertTo-Json -Depth 30)
        }
    }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    Context "Scenario Snapshots" {
        It "matches expected flowchart snapshots for key scenarios" -TestCases $snapshotCases {
            param($Name, $ActionsRef, $Direction, $Snapshot)

            $actions = $script:actionsByRef[$ActionsRef]
            if ($null -eq $actions) { throw "Unknown actions reference: $ActionsRef" }

            $expected = Get-PowerPlatformCheckerExpectedSnapshot -FileName $Snapshot
            $markdown = Get-PowerPlatformCheckerFlowChart -Actions $actions -Direction $Direction

            (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
                Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $expected)
        }

        It "matches expected graph snapshots for key scenarios" -TestCases $graphSnapshotCases {
            param($Name, $ActionsRef, $Direction, $Snapshot)

            $actions = $script:actionsByRef[$ActionsRef]
            if ($null -eq $actions) { throw "Unknown actions reference: $ActionsRef" }

            $expected = Get-PowerPlatformCheckerExpectedSnapshot -FileName $Snapshot
            $graph = Get-PowerPlatformCheckerFlowChart -Actions $actions -Direction $Direction -OutputFormat Graph
            $actual = & $script:flowGraphSnapshotConverter -Graph $graph

            (Normalize-PowerPlatformCheckerSnapshotText -Text $actual) |
                Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $expected)
        }
    }

    Context "General Behavior" {
        It "uses TB as default direction" {
            $implicitDirection = Get-PowerPlatformCheckerFlowChart -Actions $script:sampleActions
            $explicitDirection = Get-PowerPlatformCheckerFlowChart -Actions $script:sampleActions -Direction TB

            (Normalize-PowerPlatformCheckerSnapshotText -Text $implicitDirection) |
                Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $explicitDirection)
        }

        It "keeps cloud snapshot contract for sample flow" {
            $expected = Get-PowerPlatformCheckerExpectedSnapshot -FileName "FlowChart.SampleFlow.expected.md"
            $markdown = Get-PowerPlatformCheckerFlowChart -Actions $script:sampleActions -Direction TB

            (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
                Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $expected)
        }

        It "renders desktop flow chart from desktop fixture actions" {
            $desktopActions = Get-PowerPlatformCheckerFlowActionList -Path $script:desktopFlowPath -Recurse -Properties RunAfter,ParentAction
            $desktopMarkdown = Get-PowerPlatformCheckerFlowChart -Actions $desktopActions -Direction TB
            $desktopGraph = Get-PowerPlatformCheckerFlowChart -Actions $desktopActions -Direction TB -OutputFormat Graph
            $expectedDesktopMarkdown = Get-PowerPlatformCheckerExpectedSnapshot -FileName "FlowChart.DesktopFlow.expected.md"
            $expectedDesktopGraph = Get-PowerPlatformCheckerExpectedSnapshot -FileName "FlowChart.DesktopFlow.expected.graph.json"
            $actualDesktopGraph = & $script:flowGraphSnapshotConverter -Graph $desktopGraph

            $desktopMarkdown | Should -Match "^:::mermaid"
            $desktopMarkdown | Should -Match "DISPLAY"
            $desktopMarkdown | Should -Match "LAUNCH"
            $desktopMarkdown | Should -Match "WRITE"
            @($desktopGraph.Nodes).Count | Should -BeGreaterThan 0

            (Normalize-PowerPlatformCheckerSnapshotText -Text $desktopMarkdown) |
                Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $expectedDesktopMarkdown)
            (Normalize-PowerPlatformCheckerSnapshotText -Text $actualDesktopGraph) |
                Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $expectedDesktopGraph)
        }

        It "keeps desktop ON BLOCK ERROR boundary edges at root graph level" {
            $graph = Get-PowerPlatformCheckerFlowChart -Actions $script:desktopOnBlockErrorActions -Direction TB -OutputFormat Graph
            $scopeGraph = $graph.Subgraphs | Where-Object { $_.Title -eq "Scope: Try executing the flow" } | Select-Object -First 1
            $handlerNode = $graph.Nodes | Where-Object { $_.Label -like "CALL*" } | Select-Object -First 1
            $throwNode = $graph.Nodes | Where-Object { $_.Label -eq "THROW" } | Select-Object -First 1

            ($graph.Edges | Where-Object { $_.From -eq $scopeGraph.Id -and $_.Label -eq "Error" -and $_.To -eq $handlerNode.Id }).Count | Should -Be 1
            ($scopeGraph.Edges | Where-Object { $_.From -eq $scopeGraph.Id -and $_.Label -eq "Error" -and $_.To -eq $handlerNode.Id }).Count | Should -Be 0
            ($graph.Edges | Where-Object { $_.From -eq $handlerNode.Id -and $_.Label -eq "Succeeded" -and $_.To -eq $throwNode.Id }).Count | Should -Be 1
            ($scopeGraph.Nodes | Where-Object { $_.Label -like "CALL*" }).Count | Should -Be 0
            ($scopeGraph.Nodes | Where-Object { $_.Label -eq "THROW" }).Count | Should -Be 0
        }

        It "renders external connector actions with connector operation label and ignores multiline body lines" {
            $graph = Get-PowerPlatformCheckerFlowChart -Actions $script:desktopConnectorMultilineActions -Direction TB -OutputFormat Graph

            @($graph.Nodes).Count | Should -Be 2
            ($graph.Nodes | Select-Object -ExpandProperty Label) | Should -Contain "External.InvokeCloudConnector (shared_office365.SendEmailV2)"
            ($graph.Nodes | Select-Object -ExpandProperty Label) | Should -Not -Contain "Please review these entries"
            ($graph.Nodes | Select-Object -ExpandProperty Label) | Should -Not -Contain "Line two"
        }

        It "keeps scope success path visible and ignores email body text tokens" {
            $graph = Get-PowerPlatformCheckerFlowChart -Actions $script:desktopScopeSuccessAndEmailBodyActions -Direction TB -OutputFormat Graph
            $scopeGraph = $graph.Subgraphs | Where-Object { $_.Title -eq "Scope: Try executing the flow" } | Select-Object -First 1
            $postScopeNode = $graph.Nodes | Where-Object { $_.Label -eq "Logging.LogMessage" } | Select-Object -First 1

            ($graph.Edges | Where-Object { $_.From -eq $scopeGraph.Id -and $_.Label -eq "Succeeded" -and $_.To -eq $postScopeNode.Id }).Count | Should -Be 1
            ($graph.Nodes | Select-Object -ExpandProperty Label) | Should -Contain "External.InvokeCloudConnector (shared_office365.SendEmailV2)"
            ($graph.Nodes | Select-Object -ExpandProperty Label) | Should -Not -Contain "Please"
            ($graph.Nodes | Select-Object -ExpandProperty Label) | Should -Not -Contain "If"
            ($graph.Nodes | Select-Object -ExpandProperty Label) | Should -Not -Contain "List"
            ($graph.Nodes | Select-Object -ExpandProperty Label) | Should -Not -Contain "Unieke"
        }

        It "keeps scope success path in PDFW-like desktop definitions and ignores leaked email body words" {
            $graph = Get-PowerPlatformCheckerFlowChart -Actions $script:desktopPdfwRegressionActions -Direction TB -OutputFormat Graph
            $scopeGraph = $graph.Subgraphs | Where-Object { $_.Title -eq "Scope: Try executing the flow" } | Select-Object -First 1
            $postScopeNode = $graph.Nodes | Where-Object { $_.Label -eq "Logging.LogMessage_2" } | Select-Object -First 1

            ($graph.Edges | Where-Object { $_.From -eq $scopeGraph.Id -and $_.Label -eq "Succeeded" -and $_.To -eq $postScopeNode.Id }).Count | Should -Be 1
            ($graph.Nodes | Select-Object -ExpandProperty Label) | Should -Contain "External.InvokeCloudConnector (shared_office365.SendEmailV2)"
            ($graph.Nodes | Select-Object -ExpandProperty Label) | Should -Not -Contain "Please"
            ($graph.Nodes | Select-Object -ExpandProperty Label) | Should -Not -Contain "If"
            ($graph.Nodes | Select-Object -ExpandProperty Label) | Should -Not -Contain "List"
            ($graph.Nodes | Select-Object -ExpandProperty Label) | Should -Not -Contain "Unieke"
        }

        It "renders blank-title subgraphs without Mermaid label text" {
            $markdown = Get-PowerPlatformCheckerFlowChart -Actions $script:scopeInIfActions -Direction TB

            $markdown | Should -Not -Match '(?m)^subgraph\s+action\d+_group\[" "\]$'
        }

        It "does not render empty subgraph blocks" -TestCases $snapshotCases {
            param($Name, $ActionsRef, $Direction, $Snapshot)

            $actions = $script:actionsByRef[$ActionsRef]
            if ($null -eq $actions) { throw "Unknown actions reference: $ActionsRef" }

            $markdown = Get-PowerPlatformCheckerFlowChart -Actions $actions -Direction $Direction
            $markdown | Should -Not -Match '(?ms)^subgraph\s+[^\r\n]+\r?\ndirection\s+[^\r\n]+\r?\nend\s*$'
        }

        It "throws for unsupported direction values" {
            { Get-PowerPlatformCheckerFlowChart -Actions $script:sampleActions -Direction "INVALID" } | Should -Throw
        }

        It "marks actions parameter as mandatory in command metadata" {
            $command = Get-Command Get-PowerPlatformCheckerFlowChart
            $actionsParameter = $command.Parameters["Actions"]

            $actionsParameter.Attributes.Mandatory | Should -Contain $true
        }

        It "sends telemetry with direction metadata" {
            $telemetryCalls = [System.Collections.Generic.List[object]]::new()
            Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {
                param([string]$ModuleName, [string]$EventName, [hashtable]$PropertiesHash)
                [void]$telemetryCalls.Add([pscustomobject]@{ ModuleName = $ModuleName; EventName = $EventName; PropertiesHash = $PropertiesHash })
            }

            [void](Get-PowerPlatformCheckerFlowChart -Actions $script:sampleActions -Direction LR -OutputFormat Mermaid)
            Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerFlowChart" -ExpectedKeys @("ActionCountBucket", "Direction", "OutputFormat") -ConfidentialValues @("SampleFlow", "Call_Child_Workflow")

            $telemetryCalls.Clear()
            [void](Get-PowerPlatformCheckerFlowChart -Actions $script:sampleActions -Direction TB -OutputFormat Graph)
            Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerFlowChart" -ExpectedKeys @("ActionCountBucket", "Direction", "OutputFormat") -ConfidentialValues @("SampleFlow", "Call_Child_Workflow")
        }

        It "returns graph output when requested" {
            $graph = Get-PowerPlatformCheckerFlowChart -Actions $script:sampleActions -Direction TB -OutputFormat Graph

            $graph.GraphType | Should -Be "FlowchartGraph"
            $graph.Direction | Should -Be "TB"
            @($graph.Nodes).Count | Should -BeGreaterThan 0
            @($graph.Edges).Count | Should -BeGreaterThan 0
        }

        It "renders Mermaid from graph output equivalently" {
            $graph = Get-PowerPlatformCheckerFlowChart -Actions $script:subgraphActions -Direction TB -OutputFormat Graph
            $mermaidFromPublic = Get-PowerPlatformCheckerFlowChart -Actions $script:subgraphActions -Direction TB -OutputFormat Mermaid

            $mermaidFromGraph = InModuleScope PowerPlatformChecker {
                param($InnerGraph)
                Convert-PowerPlatformCheckerFlowChartGraphToMermaid -Graph $InnerGraph
            } -Parameters @{ InnerGraph = $graph }

            (Normalize-PowerPlatformCheckerSnapshotText -Text $mermaidFromGraph) |
                Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $mermaidFromPublic)
        }

        It "marks outputformat parameter with Mermaid and Graph validate-set values" {
            $command = Get-Command Get-PowerPlatformCheckerFlowChart
            $outputParameter = $command.Parameters["OutputFormat"]
            $validateSetAttribute = $outputParameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] } | Select-Object -First 1

            $validateSetAttribute.ValidValues | Should -Be @("Mermaid", "Graph")
        }

        It "does not emit dangling edge endpoints" -TestCases $snapshotCases {
            param($Name, $ActionsRef, $Direction, $Snapshot)

            $actions = $script:actionsByRef[$ActionsRef]
            if ($null -eq $actions) { throw "Unknown actions reference: $ActionsRef" }

            $markdown = Get-PowerPlatformCheckerFlowChart -Actions $actions -Direction $Direction
            $lines = @($markdown -split [Environment]::NewLine)

            $nodeIds = @($lines |
                Where-Object { $_ -match '^(action\d+)(\(|\[|\{)' } |
                ForEach-Object { $matches[1] } |
                Select-Object -Unique)

            $subgraphIds = @($lines |
                Where-Object { $_ -match '^subgraph (action\d+_group)(?:\[|$)' } |
                ForEach-Object { $matches[1] } |
                Select-Object -Unique)

            $declaredIds = @($nodeIds + $subgraphIds | Select-Object -Unique)

            $edgeLines = @($lines | Where-Object { $_ -match '-->' })
            foreach ($edgeLine in $edgeLines) {
                $edgeNodeIds = @([regex]::Matches($edgeLine, 'action\d+(_group)?') | ForEach-Object { $_.Value } | Select-Object -Unique)
                foreach ($edgeNodeId in $edgeNodeIds) {
                    $edgeNodeId | Should -BeIn $declaredIds
                }
            }
        }

        It "builds expected wrapper boundaries in graph output" {
            $graph = Get-PowerPlatformCheckerFlowChart -Actions $script:subgraphActions -Direction TB -OutputFormat Graph
            $rootEdgeKeys = @($graph.Edges | ForEach-Object { "{0}|{1}|{2}" -f $_.From, $_.Label, $_.To })
            $supplierGraph = $graph.Subgraphs | Where-Object ActionName -eq "Try_Supplier_check"
            $supplierEdgeKeys = @($supplierGraph.Edges | ForEach-Object { "{0}|{1}|{2}" -f $_.From, $_.Label, $_.To })

            $supplierEdgeKeys | Should -Contain "action11|Succeeded|action10_group"
            $rootEdgeKeys | Should -Not -Contain "action11|Succeeded|action10_group"
            $rootEdgeKeys | Should -Contain "action12_group|Succeeded|action5"
            $rootEdgeKeys | Should -Not -Contain "action10_group|Succeeded|action5"
        }

        It "uses the same graph contract recursively" {
            $graph = Get-PowerPlatformCheckerFlowChart -Actions $script:subgraphActions -Direction TB -OutputFormat Graph
            $pendingGraphs = [System.Collections.Generic.Queue[object]]::new()
            $pendingGraphs.Enqueue($graph)
            $graphCount = 0

            while ($pendingGraphs.Count -gt 0) {
                $currentGraph = $pendingGraphs.Dequeue()
                $currentGraph.GraphType | Should -Be "FlowchartGraph"
                $currentGraph.PSObject.Properties.Name | Should -Contain "Nodes"
                $currentGraph.PSObject.Properties.Name | Should -Contain "Edges"
                $currentGraph.PSObject.Properties.Name | Should -Contain "Subgraphs"
                $graphCount++

                foreach ($nestedGraph in @($currentGraph.Subgraphs)) {
                    $pendingGraphs.Enqueue($nestedGraph)
                }
            }

            $graphCount | Should -BeGreaterThan 1
        }
    }
}

