. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerArchitectureDiagram" {
    $mermaidSnapshotCases = @(
        @{ Name = "full"; Arguments = @{}; Snapshot = "ArchitectureDiagram.Full.expected.md" }
        @{ Name = "desktop full"; Arguments = @{ SolutionPath = "__DESKTOP__" }; Snapshot = "ArchitectureDiagram.Desktop.expected.md" }
        @{ Name = "model-driven"; Arguments = @{ ModelDrivenAppName = "ppc_ModelApp" }; Snapshot = "ArchitectureDiagram.ModelDriven.expected.md" }
        @{ Name = "flow TB"; Arguments = @{ FlowId = "11111111-1111-1111-1111-111111111111"; Direction = "TB" }; Snapshot = "ArchitectureDiagram.Flow.TB.expected.md" }
        @{ Name = "canvas RL"; Arguments = @{ CanvasAppName = "ppc_canvas_sales_0001"; Direction = "RL" }; Snapshot = "ArchitectureDiagram.CanvasApp.RL.expected.md" }
        @{ Name = "model-driven BT"; Arguments = @{ ModelDrivenAppName = "ppc_ModelApp"; Direction = "BT" }; Snapshot = "ArchitectureDiagram.ModelDriven.BT.expected.md" }
        @{ Name = "flows only"; Arguments = @{ IncludeElements = @("Flows") }; Snapshot = "ArchitectureDiagram.FlowsOnly.expected.md" }
        @{ Name = "flow style override"; Arguments = @{ FlowId = "22222222-2222-2222-2222-222222222222"; StyleOverrides = @{ Flow = "#123456"; Stroke = "#010203" } }; Snapshot = "ArchitectureDiagram.Flow.StyleOverride.expected.md" }
        @{ Name = "model-driven entities only"; Arguments = @{ ModelDrivenAppName = "ppc_ModelApp"; IncludeElements = @("Entities", "ModelDrivenApps") }; Snapshot = "ArchitectureDiagram.ModelDriven.EntitiesOnly.expected.md" }
        @{ Name = "model-driven web resources only"; Arguments = @{ ModelDrivenAppName = "ppc_ModelApp"; IncludeElements = @("WebResources", "ModelDrivenApps") }; Snapshot = "ArchitectureDiagram.ModelDriven.WebResourcesOnly.expected.md" }
        @{ Name = "selected full categories"; Arguments = @{ IncludeElements = @("Flows", "CanvasApps", "Connections", "WebResources") }; Snapshot = "ArchitectureDiagram.Full.FlowsCanvasConnectionsWebResources.expected.md" }
    )

    $graphSnapshotCases = @(
        @{ Name = "full"; Arguments = @{}; Snapshot = "ArchitectureDiagram.Full.expected.graph.json" }
        @{ Name = "desktop full"; Arguments = @{ SolutionPath = "__DESKTOP__" }; Snapshot = "ArchitectureDiagram.Desktop.expected.graph.json" }
        @{ Name = "flow TB"; Arguments = @{ FlowId = "11111111-1111-1111-1111-111111111111"; Direction = "TB" }; Snapshot = "ArchitectureDiagram.Flow.TB.expected.graph.json" }
        @{ Name = "canvas RL"; Arguments = @{ CanvasAppName = "ppc_canvas_sales_0001"; Direction = "RL" }; Snapshot = "ArchitectureDiagram.CanvasApp.RL.expected.graph.json" }
        @{ Name = "model-driven"; Arguments = @{ ModelDrivenAppName = "ppc_ModelApp" }; Snapshot = "ArchitectureDiagram.ModelDriven.expected.graph.json" }
        @{ Name = "model-driven entities only"; Arguments = @{ ModelDrivenAppName = "ppc_ModelApp"; IncludeElements = @("Entities", "ModelDrivenApps") }; Snapshot = "ArchitectureDiagram.ModelDriven.EntitiesOnly.expected.graph.json" }
        @{ Name = "model-driven web resources only"; Arguments = @{ ModelDrivenAppName = "ppc_ModelApp"; IncludeElements = @("WebResources", "ModelDrivenApps") }; Snapshot = "ArchitectureDiagram.ModelDriven.WebResourcesOnly.expected.graph.json" }
        @{ Name = "selected full categories"; Arguments = @{ IncludeElements = @("Flows", "CanvasApps", "Connections", "WebResources") }; Snapshot = "ArchitectureDiagram.Full.FlowsCanvasConnectionsWebResources.expected.graph.json" }
    )

    $scopeCases = @(
        @{ Name = "full"; Arguments = @{} }
        @{ Name = "flow"; Arguments = @{ FlowId = "11111111-1111-1111-1111-111111111111" } }
        @{ Name = "canvas"; Arguments = @{ CanvasAppName = "ppc_canvas_sales_0001" } }
        @{ Name = "model-driven"; Arguments = @{ ModelDrivenAppName = "ppc_ModelApp" } }
    )

    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
        $script:desktopSolutionPath = Get-PowerPlatformCheckerDesktopFixtureSolutionPath
        $script:graphSnapshotConverter = {
            param(
                [Parameter(Mandatory = $true)]
                [object] $Graph
            )

            $stableNodes = @($Graph.Nodes |
                Sort-Object Id |
                ForEach-Object {
                    $stableProperties = [ordered]@{}
                    foreach ($propertyName in @($_.Properties.Keys | Sort-Object)) {
                        $stableProperties[$propertyName] = $_.Properties[$propertyName]
                    }

                    [ordered]@{
                        Id = [string]$_.Id
                        Type = [string]$_.Type
                        DisplayName = [string]$_.DisplayName
                        ClassKind = [string]$_.ClassKind
                        Properties = $stableProperties
                        Members = @($_.Members | ForEach-Object { [string]$_ })
                        HasExplicitDisplayName = [bool]$_.HasExplicitDisplayName
                    }
                })

            $stableEdges = @($Graph.Edges |
                Sort-Object SourceId, TargetId, Label, EdgeType |
                ForEach-Object {
                    [ordered]@{
                        SourceId = [string]$_.SourceId
                        TargetId = [string]$_.TargetId
                        Label = [string]$_.Label
                        EdgeType = [string]$_.EdgeType
                        Metadata = [ordered]@{
                            Arrow = [string]$_.Metadata.Arrow
                        }
                    }
                })

            $stableStyles = [ordered]@{}
            foreach ($styleProperty in @($Graph.Styles.PSObject.Properties.Name | Sort-Object)) {
                $stableStyles[$styleProperty] = [string]$Graph.Styles.$styleProperty
            }

            $snapshotPayload = [ordered]@{
                Metadata = [ordered]@{
                    Direction = [string]$Graph.Metadata.Direction
                    IncludeElements = @($Graph.Metadata.IncludeElements | Sort-Object)
                    IsScopedDiagram = [bool]$Graph.Metadata.IsScopedDiagram
                    SourceFilterType = [string]$Graph.Metadata.SourceFilterType
                    SourceFilterValue = [string]$Graph.Metadata.SourceFilterValue
                    OutputFormat = [string]$Graph.Metadata.OutputFormat
                }
                Nodes = $stableNodes
                Edges = $stableEdges
                Styles = $stableStyles
                StyleOrder = @($Graph.StyleOrder | ForEach-Object { [string]$_ })
            }

            return ($snapshotPayload | ConvertTo-Json -Depth 20)
        }
    }

    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {}
    }

    Context "Scenario Snapshots" {
        It "matches expected Mermaid snapshots for <Name>" -TestCases $mermaidSnapshotCases {
            param($Name, $Arguments, $Snapshot)

            $expected = Get-PowerPlatformCheckerExpectedSnapshot -FileName $Snapshot
            $solutionPath = $script:solutionPath
            if ($Arguments.ContainsKey("SolutionPath") -and $Arguments.SolutionPath -eq "__DESKTOP__") {
                $solutionPath = $script:desktopSolutionPath
                $Arguments = @{}
            }
            $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $solutionPath @Arguments

            (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
                Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $expected)
        }

        It "matches expected Graph snapshots for <Name>" -TestCases $graphSnapshotCases {
            param($Name, $Arguments, $Snapshot)

            $expected = Get-PowerPlatformCheckerExpectedSnapshot -FileName $Snapshot
            $solutionPath = $script:solutionPath
            if ($Arguments.ContainsKey("SolutionPath") -and $Arguments.SolutionPath -eq "__DESKTOP__") {
                $solutionPath = $script:desktopSolutionPath
                $Arguments = @{}
            }
            $graph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $solutionPath -OutputFormat Graph @Arguments
            $actual = & $script:graphSnapshotConverter -Graph $graph

            (Normalize-PowerPlatformCheckerSnapshotText -Text $actual) |
                Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $expected)
        }
    }

    Context "General Behavior" {
        It "renders desktop scoped connection references when desktop flow declares connectors" {
            $desktopGraph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:desktopSolutionPath -FlowId "99999999-9999-9999-9999-999999999999" -OutputFormat Graph

            ($desktopGraph.Nodes | Where-Object { $_.ClassKind -eq "Connection" } | Select-Object -ExpandProperty Id) | Should -Contain "shared_office365"
            ($desktopGraph.Edges | Where-Object { $_.SourceId -eq "shared_office365" -and $_.TargetId -eq "flow99999999-9999-9999-9999-999999999999" }).Count | Should -BeGreaterThan 0
        }

        It "normalizes desktop manifest connection names to Mermaid-safe connector ids" {
            $desktopGraph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:desktopSolutionPath -FlowId "99999999-9999-9999-9999-999999999999" -OutputFormat Graph

            ($desktopGraph.Nodes | Where-Object { $_.ClassKind -eq "Connection" } | Select-Object -ExpandProperty Id) | Should -Not -Contain "7b435bb9579e4faeaaf922c261cee35d"
            ($desktopGraph.Nodes | Where-Object { $_.ClassKind -eq "Connection" } | Select-Object -ExpandProperty Id) | Should -Contain "shared_office365"
        }

        It "renders desktop dependency environment variables as linked env var nodes" {
            $desktopGraph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:desktopSolutionPath -FlowId "77777777-7777-7777-7777-777777777777" -OutputFormat Graph

            ($desktopGraph.Nodes | Where-Object { $_.ClassKind -eq "EnvVar" } | Select-Object -ExpandProperty Id) | Should -Contain "ppc_desktop_baseurl"
            ($desktopGraph.Edges | Where-Object { $_.SourceId -eq "ppc_desktop_baseurl" -and $_.TargetId -eq "flow77777777-7777-7777-7777-777777777777" }).Count | Should -BeGreaterThan 0
        }

        It "renders desktop input and output parameters as flow class members" {
            $desktopGraph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:desktopSolutionPath -OutputFormat Graph

            $desktopSampleFlow = $desktopGraph.Nodes | Where-Object { $_.Id -eq "flow77777777-7777-7777-7777-777777777777" } | Select-Object -First 1
            $desktopQuotedMetadataFlow = $desktopGraph.Nodes | Where-Object { $_.Id -eq "flow88888888-8888-8888-8888-888888888888" } | Select-Object -First 1

            $desktopSampleFlow.Members | Should -Contain "    [INPUT]runtimeInput"
            $desktopSampleFlow.Members | Should -Contain "    [OUTPUT]result"
            $desktopQuotedMetadataFlow.Members | Should -Contain "    [INPUT]account"
        }

        It "returns the architecture graph contract" {
            $graph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -OutputFormat Graph

            $graph.PSObject.Properties.Name | Should -Contain "Nodes"
            $graph.PSObject.Properties.Name | Should -Contain "Edges"
            $graph.PSObject.Properties.Name | Should -Contain "Styles"
            $graph.PSObject.Properties.Name | Should -Contain "Metadata"
            $graph.Metadata.OutputFormat | Should -Be "Graph"
        }

        It "surfaces trigger mode on flow nodes in graph output" {
            $graph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -OutputFormat Graph

            $webhookFlow = $graph.Nodes | Where-Object { $_.Id -eq "flow11111111-1111-1111-1111-111111111111" } | Select-Object -First 1
            $manualFlow = $graph.Nodes | Where-Object { $_.Id -eq "flow22222222-2222-2222-2222-222222222222" } | Select-Object -First 1

            $webhookFlow.Properties.TriggerMode | Should -Be "Webhook"
            $manualFlow.Properties.TriggerMode | Should -Be "ManualHttp"
        }

        It "surfaces interaction direction metadata on flow nodes in graph output" {
            $graph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -OutputFormat Graph

            $sampleFlow = $graph.Nodes | Where-Object { $_.Id -eq "flow11111111-1111-1111-1111-111111111111" } | Select-Object -First 1
            $childFlow = $graph.Nodes | Where-Object { $_.Id -eq "flow22222222-2222-2222-2222-222222222222" } | Select-Object -First 1

            $sampleFlow.Properties.InteractionDirection | Should -Be "Write"
            $sampleFlow.Properties.DirectionConfidence | Should -Be "High"
            $sampleFlow.Properties.SourceEvidence | Should -Be "OperationCatalog+Heuristic"

            $childFlow.Properties.InteractionDirection | Should -Be "Write"
            $childFlow.Properties.DirectionConfidence | Should -Be "High"
            $childFlow.Properties.SourceEvidence | Should -Be "OperationCatalog+Heuristic"
        }

        It "surfaces destination metadata on flow nodes in graph output" {
            $graph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -OutputFormat Graph

            $sampleFlow = $graph.Nodes | Where-Object { $_.Id -eq "flow11111111-1111-1111-1111-111111111111" } | Select-Object -First 1
            $childFlow = $graph.Nodes | Where-Object { $_.Id -eq "flow22222222-2222-2222-2222-222222222222" } | Select-Object -First 1

            $sampleFlow.Properties.Destination | Should -Be "api.example.test"
            $sampleFlow.Properties.DestinationType | Should -Be "Domain"
            $sampleFlow.Properties.DestinationConfidence | Should -Be "High"
            $sampleFlow.Properties.DestinationEvidence | Should -Be "FlowParameterDefault"

            $childFlow.Properties.Destination | Should -Be "office365"
            $childFlow.Properties.DestinationType | Should -Be "Service"
            $childFlow.Properties.DestinationConfidence | Should -Be "Low"
            $childFlow.Properties.DestinationEvidence | Should -Be "ConnectorGroup"
        }

        It "surfaces destination metadata on canvas app nodes in graph output" {
            $graph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -OutputFormat Graph

            $canvasNode = $graph.Nodes | Where-Object { $_.ClassKind -eq "CanvasApp" -and $_.Id -eq "ppc_canvas_sales_0001" } | Select-Object -First 1
            $canvasNode.Properties.Destination | Should -Be "dataverse"
            $canvasNode.Properties.DestinationType | Should -Be "Service"
            $canvasNode.Properties.DestinationConfidence | Should -Be "Low"
            $canvasNode.Properties.DestinationEvidence | Should -Be "ConnectionReference"
        }

        It "renders Mermaid from graph output equivalently" {
            $graph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -ModelDrivenAppName "ppc_ModelApp" -OutputFormat Graph
            $publicMermaid = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -ModelDrivenAppName "ppc_ModelApp"

            $graphMermaid = InModuleScope PowerPlatformChecker {
                param($InnerGraph)
                Convert-PowerPlatformCheckerArchitectureGraphToMermaid -Graph $InnerGraph
            } -Parameters @{ InnerGraph = $graph }

            (Normalize-PowerPlatformCheckerSnapshotText -Text $graphMermaid) |
                Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $publicMermaid)
        }

        It "has no dangling edge endpoints for <Name> scope" -TestCases $scopeCases {
            param($Name, $Arguments)

            $graph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -OutputFormat Graph @Arguments
            $nodeIds = @($graph.Nodes | ForEach-Object { [string]$_.Id })

            foreach ($edge in @($graph.Edges)) {
                [string]$edge.SourceId | Should -BeIn $nodeIds
                [string]$edge.TargetId | Should -BeIn $nodeIds
            }
        }

        It "deduplicates graph nodes and edges" {
            $graph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -OutputFormat Graph
            $nodeIds = @($graph.Nodes | ForEach-Object { [string]$_.Id })
            $edgeKeys = @($graph.Edges | ForEach-Object { "{0}|{1}|{2}|{3}" -f $_.SourceId, $_.TargetId, $_.Label, $_.EdgeType })

            $nodeIds.Count | Should -Be @($nodeIds | Select-Object -Unique).Count
            $edgeKeys.Count | Should -Be @($edgeKeys | Select-Object -Unique).Count
        }

        It "defines mutually exclusive component filter parameter sets" {
            $command = Get-Command Get-PowerPlatformCheckerArchitectureDiagram
            @($command.ParameterSets.Name | Sort-Object) | Should -Be @("FilterByCanvasApp", "FilterByFlow", "FilterByModelDrivenApp", "NoFilter")
        }

        It "defines supported output and direction values" {
            $command = Get-Command Get-PowerPlatformCheckerArchitectureDiagram
            $outputValues = ($command.Parameters.OutputFormat.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }).ValidValues
            $directionValues = ($command.Parameters.Direction.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }).ValidValues

            $outputValues | Should -Be @("Mermaid", "Graph")
            $directionValues | Should -Be @("LR", "RL", "TB", "BT")
        }

        It "sends telemetry with scope and output metadata" {
            $telemetryCalls = [System.Collections.Generic.List[object]]::new()
            Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {
                param([string]$ModuleName, [string]$EventName, [hashtable]$PropertiesHash)
                [void]$telemetryCalls.Add([pscustomobject]@{ ModuleName = $ModuleName; EventName = $EventName; PropertiesHash = $PropertiesHash })
            }

            $secretFlowId = "secret-flow-id-telemetry"
            try {
                [void](Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -FlowId $secretFlowId -OutputFormat Graph -Direction TB -IncludeElements @("Flows") -StyleOverrides @{ Flow = "#123456" })
            }
            catch {
            }

            Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerArchitectureDiagram" -ExpectedKeys @("ParameterSet", "HasFlowFilter", "HasCanvasFilter", "HasModelDrivenFilter", "Direction", "OutputFormat", "IncludeElements", "HasStyleOverrides") -ConfidentialValues @($script:solutionPath, $secretFlowId, "#123456")

            $telemetryCalls.Clear()
            [void](Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath)
            Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerArchitectureDiagram" -ExpectedKeys @("ParameterSet", "HasFlowFilter", "HasCanvasFilter", "HasModelDrivenFilter", "Direction", "OutputFormat", "IncludeElements", "HasStyleOverrides") -ConfidentialValues @($script:solutionPath)

            $telemetryCalls.Clear()
            [void](Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -CanvasAppName "secret-canvas-app")
            Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerArchitectureDiagram" -ExpectedKeys @("ParameterSet", "HasFlowFilter", "HasCanvasFilter", "HasModelDrivenFilter", "Direction", "OutputFormat", "IncludeElements", "HasStyleOverrides") -ConfidentialValues @("secret-canvas-app")

            $telemetryCalls.Clear()
            [void](Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -ModelDrivenAppName "secret-model-app")
            Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerArchitectureDiagram" -ExpectedKeys @("ParameterSet", "HasFlowFilter", "HasCanvasFilter", "HasModelDrivenFilter", "Direction", "OutputFormat", "IncludeElements", "HasStyleOverrides") -ConfidentialValues @("secret-model-app")
        }

        It "supports session-level style updates" {
            try {
                Set-PowerPlatformCheckerStyle -StyleTarget ArchitectureDiagram -Flow "#445566" | Out-Null
                $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath
                $markdown | Should -Match "classDef Flow fill:#445566,stroke:#5E5B52"
            }
            finally {
                Set-PowerPlatformCheckerStyle -StyleTarget ArchitectureDiagram -Flow "#DBE4EE" | Out-Null
            }
        }

        It "rejects unsupported style keys" {
            { Set-PowerPlatformCheckerStyle -StyleTarget ArchitectureDiagram -NotARealKey "#000000" } | Should -Throw
        }
    }
}