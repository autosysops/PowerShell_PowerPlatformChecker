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
    )
    $graphSnapshotCases = @(
        @{ Name = "SampleFlow TB"; ActionsRef = "sampleActions"; Direction = "TB"; Snapshot = "FlowChart.SampleFlow.expected.graph.json" }
        @{ Name = "ChildFlow BT"; ActionsRef = "childActions"; Direction = "BT"; Snapshot = "FlowChart.ChildFlow.BT.expected.graph.json" }
        @{ Name = "SubgraphFlow TB"; ActionsRef = "subgraphActions"; Direction = "TB"; Snapshot = "FlowChart.SubgraphFlow.expected.graph.json" }
        @{ Name = "TrueOnlyConditionFlow TB"; ActionsRef = "trueOnlyConditionActions"; Direction = "TB"; Snapshot = "FlowChart.TrueOnlyConditionFlow.expected.graph.json" }
        @{ Name = "SwitchCaseFlow TB"; ActionsRef = "switchCaseActions"; Direction = "TB"; Snapshot = "FlowChart.SwitchCaseFlow.expected.graph.json" }
        @{ Name = "ScopeInIfFlow TB"; ActionsRef = "scopeInIfActions"; Direction = "TB"; Snapshot = "FlowChart.ScopeInIfFlow.expected.graph.json" }
    )

    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
        $script:flowPath = Join-Path $script:solutionPath "Workflows\SampleFlow-11111111-1111-1111-1111-111111111111.json"
        $script:childFlowPath = Join-Path $script:solutionPath "Workflows\ChildFlow-22222222-2222-2222-2222-222222222222.json"
        $script:subgraphFlowPath = Join-Path $script:solutionPath "Workflows\SubgraphFlow-33333333-3333-3333-3333-333333333333.json"
        $script:trueOnlyConditionFlowPath = Join-Path $script:solutionPath "Workflows\TrueOnlyConditionFlow-44444444-4444-4444-4444-444444444444.json"
        $script:switchCaseFlowPath = Join-Path $script:solutionPath "Workflows\SwitchCaseFlow-55555555-5555-5555-5555-555555555555.json"
        $script:scopeInIfFlowPath = Join-Path $script:solutionPath "Workflows\ScopeInIfFlow-66666666-6666-6666-6666-666666666666.json"

        $script:sampleActions = Get-PowerPlatformCheckerFlowActionList -Path $script:flowPath -Recurse -IncludeTrigger -Properties References,Entities,RunAfter,ParentAction
        $script:childActions = Get-PowerPlatformCheckerFlowActionList -Path $script:childFlowPath -Recurse -IncludeTrigger -Properties References,Entities,RunAfter,ParentAction
        $script:subgraphActions = Get-PowerPlatformCheckerFlowActionList -Path $script:subgraphFlowPath -Recurse -IncludeTrigger -Properties References,Entities,RunAfter,ParentAction
        $script:trueOnlyConditionActions = Get-PowerPlatformCheckerFlowActionList -Path $script:trueOnlyConditionFlowPath -Recurse -IncludeTrigger -Properties References,Entities,RunAfter,ParentAction
        $script:switchCaseActions = Get-PowerPlatformCheckerFlowActionList -Path $script:switchCaseFlowPath -Recurse -IncludeTrigger -Properties References,Entities,RunAfter,ParentAction
        $script:scopeInIfActions = Get-PowerPlatformCheckerFlowActionList -Path $script:scopeInIfFlowPath -Recurse -IncludeTrigger -Properties References,Entities,RunAfter,ParentAction
        $script:actionsByRef = @{
            sampleActions = $script:sampleActions
            childActions = $script:childActions
            subgraphActions = $script:subgraphActions
            trueOnlyConditionActions = $script:trueOnlyConditionActions
            switchCaseActions = $script:switchCaseActions
            scopeInIfActions = $script:scopeInIfActions
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

        It "throws for unsupported direction values" {
            { Get-PowerPlatformCheckerFlowChart -Actions $script:sampleActions -Direction "INVALID" } | Should -Throw
        }

        It "marks actions parameter as mandatory in command metadata" {
            $command = Get-Command Get-PowerPlatformCheckerFlowChart
            $actionsParameter = $command.Parameters["Actions"]

            $actionsParameter.Attributes.Mandatory | Should -Contain $true
        }

        It "sends telemetry with direction metadata" {
            [void](Get-PowerPlatformCheckerFlowChart -Actions $script:sampleActions -Direction LR)

            Should -Invoke -CommandName Send-THEvent -ModuleName PowerPlatformChecker -Times 1 -Exactly -ParameterFilter {
                $EventName -eq "Get-PowerPlatformCheckerFlowChart" -and
                $PropertiesHash.Direction -eq "LR"
            }
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
                Where-Object { $_ -match '^subgraph (action\d+_group)\[' } |
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

