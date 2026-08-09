. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerArchitectureDiagram" {
    $mermaidSnapshotCases = @(
        @{ Name = "full"; Arguments = @{}; Snapshot = "ArchitectureDiagram.Full.expected.md" }
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
            $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath @Arguments

            (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
                Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $expected)
        }

        It "matches expected Graph snapshots for <Name>" -TestCases $graphSnapshotCases {
            param($Name, $Arguments, $Snapshot)

            $expected = Get-PowerPlatformCheckerExpectedSnapshot -FileName $Snapshot
            $graph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -OutputFormat Graph @Arguments
            $actual = & $script:graphSnapshotConverter -Graph $graph

            (Normalize-PowerPlatformCheckerSnapshotText -Text $actual) |
                Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $expected)
        }
    }

    Context "General Behavior" {
        It "returns the architecture graph contract" {
            $graph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -OutputFormat Graph

            $graph.PSObject.Properties.Name | Should -Contain "Nodes"
            $graph.PSObject.Properties.Name | Should -Contain "Edges"
            $graph.PSObject.Properties.Name | Should -Contain "Styles"
            $graph.PSObject.Properties.Name | Should -Contain "Metadata"
            $graph.Metadata.OutputFormat | Should -Be "Graph"
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
            [void](Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -FlowId "11111111-1111-1111-1111-111111111111" -OutputFormat Graph)

            Should -Invoke -CommandName Send-THEvent -ModuleName PowerPlatformChecker -Times 1 -Exactly -ParameterFilter {
                $EventName -eq "Get-PowerPlatformCheckerArchitectureDiagram" -and
                $PropertiesHash.ParameterSet -eq "FilterByFlow" -and
                $PropertiesHash.OutputFormat -eq "Graph"
            }
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