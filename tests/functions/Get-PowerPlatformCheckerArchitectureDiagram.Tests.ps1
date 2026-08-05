. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerArchitectureDiagram" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:graphSnapshotConverter = {
            param(
                [Parameter(Mandatory = $true)]
                [object] $Graph
            )

            $stableNodes = @($Graph.Nodes |
                Sort-Object Id |
                ForEach-Object {
                    [ordered]@{
                        Id = [string]$_.Id
                        Type = [string]$_.Type
                        DisplayName = [string]$_.DisplayName
                        ClassKind = [string]$_.ClassKind
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
                    }
                })

            $styleProperties = @($Graph.Styles.PSObject.Properties.Name | Sort-Object)
            $stableStyles = [ordered]@{}
            foreach ($styleProperty in $styleProperties) {
                $stableStyles[$styleProperty] = [string]$Graph.Styles.$styleProperty
            }

            $stableMetadata = [ordered]@{
                Direction = [string]$Graph.Metadata.Direction
                IncludeElements = @($Graph.Metadata.IncludeElements | Sort-Object)
                IsScopedDiagram = [bool]$Graph.Metadata.IsScopedDiagram
                SourceFilterType = [string]$Graph.Metadata.SourceFilterType
                SourceFilterValue = [string]$Graph.Metadata.SourceFilterValue
                OutputFormat = [string]$Graph.Metadata.OutputFormat
            }

            $snapshotPayload = [ordered]@{
                Metadata = $stableMetadata
                Nodes = $stableNodes
                Edges = $stableEdges
                Styles = $stableStyles
            }

            return ($snapshotPayload | ConvertTo-Json -Depth 20)
        }

        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
        $script:expectedFull = Get-PowerPlatformCheckerExpectedSnapshot -FileName "ArchitectureDiagram.Full.expected.md"
        $script:expectedModelDriven = Get-PowerPlatformCheckerExpectedSnapshot -FileName "ArchitectureDiagram.ModelDriven.expected.md"
        $script:expectedFlowDirectionTb = Get-PowerPlatformCheckerExpectedSnapshot -FileName "ArchitectureDiagram.Flow.TB.expected.md"
        $script:expectedCanvasDirectionRl = Get-PowerPlatformCheckerExpectedSnapshot -FileName "ArchitectureDiagram.CanvasApp.RL.expected.md"
        $script:expectedModelDrivenDirectionBt = Get-PowerPlatformCheckerExpectedSnapshot -FileName "ArchitectureDiagram.ModelDriven.BT.expected.md"
        $script:expectedFlowsOnly = Get-PowerPlatformCheckerExpectedSnapshot -FileName "ArchitectureDiagram.FlowsOnly.expected.md"
        $script:expectedFlowStyleOverride = Get-PowerPlatformCheckerExpectedSnapshot -FileName "ArchitectureDiagram.Flow.StyleOverride.expected.md"
        $script:expectedModelDrivenEntitiesOnly = Get-PowerPlatformCheckerExpectedSnapshot -FileName "ArchitectureDiagram.ModelDriven.EntitiesOnly.expected.md"
        $script:expectedModelDrivenWebResourcesOnly = Get-PowerPlatformCheckerExpectedSnapshot -FileName "ArchitectureDiagram.ModelDriven.WebResourcesOnly.expected.md"
        $script:expectedFullFlowsCanvasConnectionsWebResources = Get-PowerPlatformCheckerExpectedSnapshot -FileName "ArchitectureDiagram.Full.FlowsCanvasConnectionsWebResources.expected.md"

        $script:expectedGraphFull = Get-PowerPlatformCheckerExpectedSnapshot -FileName "ArchitectureDiagram.Full.expected.graph.json"
        $script:expectedGraphFlowTb = Get-PowerPlatformCheckerExpectedSnapshot -FileName "ArchitectureDiagram.Flow.TB.expected.graph.json"
        $script:expectedGraphCanvasRl = Get-PowerPlatformCheckerExpectedSnapshot -FileName "ArchitectureDiagram.CanvasApp.RL.expected.graph.json"
        $script:expectedGraphModelDriven = Get-PowerPlatformCheckerExpectedSnapshot -FileName "ArchitectureDiagram.ModelDriven.expected.graph.json"
        $script:expectedGraphModelDrivenEntitiesOnly = Get-PowerPlatformCheckerExpectedSnapshot -FileName "ArchitectureDiagram.ModelDriven.EntitiesOnly.expected.graph.json"
        $script:expectedGraphModelDrivenWebResourcesOnly = Get-PowerPlatformCheckerExpectedSnapshot -FileName "ArchitectureDiagram.ModelDriven.WebResourcesOnly.expected.graph.json"
        $script:expectedGraphFullFlowsCanvasConnectionsWebResources = Get-PowerPlatformCheckerExpectedSnapshot -FileName "ArchitectureDiagram.Full.FlowsCanvasConnectionsWebResources.expected.graph.json"
    }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "matches the expected full architecture diagram snapshot" {
        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath

        (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedFull)
    }

    It "full diagram contains multiple resource categories" {
        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath

        $markdown | Should -Match ":::Flow"
        $markdown | Should -Match ":::CanvasApp"
        $markdown | Should -Match ":::ModelDrivenApp"
        $markdown | Should -Match ":::Connection"
        $markdown | Should -Match ":::Entity"
        $markdown | Should -Match ":::WebResource"
        $markdown | Should -Not -Match "ppc_ModelApp --> ppc_script_OrderForm_js:Script"
        $markdown | Should -Match "ppc_orders --> ppc_script_OrderForm_js:Script"
        $markdown | Should -Match "onLoad"
        $markdown | Should -Match "ppc_script_OrderForm_js --> ppc_script_Shared_js:Dependency"
        $markdown | Should -Match "\[Business Process Flows\]11111111-1111-1111-1111-111111111111"
    }

    It "supports flow filtering" {
        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -FlowId "11111111-1111-1111-1111-111111111111"
        $markdown | Should -Match "flow11111111-1111-1111-1111-111111111111"
        $markdown | Should -Not -Match "flow22222222-2222-2222-2222-222222222222"
        $markdown | Should -Not -Match "class ppc_canvas_sales_0001"
        $markdown | Should -Not -Match "class ppc_ModelApp"
        $markdown | Should -Match "ppc_script_OrderForm_js"
    }

    It "returns graph output for full architecture diagrams" {
        $graph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -OutputFormat Graph

        $graph | Should -Not -BeNullOrEmpty
        $graph.PSObject.Properties.Name | Should -Contain "Nodes"
        $graph.PSObject.Properties.Name | Should -Contain "Edges"
        @($graph.Nodes).Count | Should -BeGreaterThan 0
        @($graph.Edges).Count | Should -BeGreaterThan 0
    }

    It "returns graph output for flow-scoped architecture diagrams" {
        $graph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -FlowId "11111111-1111-1111-1111-111111111111" -OutputFormat Graph

        $graph | Should -Not -BeNullOrEmpty
        @($graph.Nodes | Where-Object { $_.Type -eq "Flow" }).Count | Should -BeGreaterThan 0
        @($graph.Edges | Where-Object { $_.Label -eq "ppc_order" }).Count | Should -BeGreaterThan 0
    }

    It "returns graph output for model-driven scoped architecture diagrams" {
        $graph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -ModelDrivenAppName "ppc_ModelApp" -OutputFormat Graph

        $graph | Should -Not -BeNullOrEmpty
        @($graph.Nodes | Where-Object { $_.Type -eq "ModelDrivenApp" }).Count | Should -BeGreaterThan 0
        @($graph.Edges | Where-Object { $_.Label -eq "Entity" }).Count | Should -BeGreaterThan 0
    }

    It "supports canvas app filtering" {
        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -CanvasAppName "ppc_canvas_sales_0001"
        $markdown | Should -Match "class ppc_canvas_sales_0001"
        $markdown | Should -Not -Match "class ppc_ModelApp"
        $markdown | Should -Not -Match "flow11111111-1111-1111-1111-111111111111"
        $markdown | Should -Not -Match ([regex]::Escape('class [""]'))
    }

    It "matches the expected model-driven filtered architecture snapshot" {
        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -ModelDrivenAppName "ppc_ModelApp"

        (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedModelDriven)

        $markdown | Should -Match "class ppc_ModelApp"
        $markdown | Should -Not -Match "class ppc_canvas_sales_0001"
        $markdown | Should -Not -Match "ppc_NotificationEmail"
        $markdown | Should -Not -Match "class shared_todo"
    }

    It "normalizes flow entity references to known entity set names" {
        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -FlowId "11111111-1111-1111-1111-111111111111"

        $markdown | Should -Match "flow11111111-1111-1111-1111-111111111111 --> ppc_orders:ppc_order"
        $markdown | Should -Not -Match "flow11111111-1111-1111-1111-111111111111 --> ppc_order:ppc_order"
    }

    It "matches expected flow-scoped diagram with custom direction" {
        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -FlowId "11111111-1111-1111-1111-111111111111" -Direction TB

        (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedFlowDirectionTb)
    }

    It "matches expected canvas-scoped diagram with custom direction" {
        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -CanvasAppName "ppc_canvas_sales_0001" -Direction RL

        (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedCanvasDirectionRl)
    }

    It "matches expected model-driven scoped diagram with custom direction" {
        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -ModelDrivenAppName "ppc_ModelApp" -Direction BT

        (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedModelDrivenDirectionBt)
    }

    It "matches expected include-element filtered diagram" {
        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -IncludeElements Flows

        (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedFlowsOnly)
    }

    It "matches expected style-override diagram" {
        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -FlowId "22222222-2222-2222-2222-222222222222" -StyleOverrides @{ Flow = "#123456"; Stroke = "#010203" }

        (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedFlowStyleOverride)
    }

    It "includes related hanab entities and system default entities in scoped flow diagrams" {
        $mockFlowId = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"

        $mockSupplierEntity = [pscustomobject]@{
            Name = "hanab_supplier"
            EntitySetName = "hanab_suppliers"
            Attributes = @(
                [pscustomobject]@{ Name = "hanab_suppliername"; Type = "nvarchar" }
            )
            Relations = @()
            FormWebResources = @()
            IconResources = @()
        }

        $mockProductEntity = [pscustomobject]@{
            Name = "hanab_product"
            EntitySetName = "hanab_products"
            Attributes = @(
                [pscustomobject]@{ Name = "hanab_name"; Type = "nvarchar" }
            )
            Relations = @(
                [pscustomobject]@{ Source = "hanab_product"; Target = "hanab_supplier"; Type = "OneToMany" },
                [pscustomobject]@{ Source = "hanab_product"; Target = "systemuser"; Type = "OneToMany" }
            )
            FormWebResources = @()
            IconResources = @()
        }

        $mockSolutionObject = [pscustomobject]@{
            Workflows = @(
                [pscustomobject]@{ Id = $mockFlowId; Name = "Scheduled - Approval" }
            )
            EnvironmentVariables = @()
            ConnectionReferences = @(
                [pscustomobject]@{ ConnectorId = "/providers/Microsoft.PowerApps/apis/shared_commondataserviceforapps"; DisplayName = "Dataverse - Test" }
            )
            # Keep supplier first to reproduce the historical ordering bug in scoped diagrams.
            Entities = @($mockSupplierEntity, $mockProductEntity)
            CanvasApps = @()
        }

        Mock -CommandName Get-PowerPlatformCheckerSolutionObject -ModuleName PowerPlatformChecker -MockWith {
            $mockSolutionObject
        }
        Mock -CommandName Get-PowerPlatformCheckerFlowParameter -ModuleName PowerPlatformChecker -MockWith {
            @()
        }
        Mock -CommandName Get-PowerPlatformCheckerFlowActionList -ModuleName PowerPlatformChecker -MockWith {
            @(
                [pscustomobject]@{
                    Name = "List_rows"
                    Group = "shared_commondataserviceforapps"
                    Entities = @("hanab_product")
                    Reference = ""
                }
            )
        }
        Mock -CommandName Get-PowerPlatformCheckerWebResource -ModuleName PowerPlatformChecker -MockWith {
            @()
        }

        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath "C:\does-not-matter" -FlowId $mockFlowId -IncludeElements Flows,Connections,Entities,DefaultEntities

        $markdown | Should -Match ([regex]::Escape('class hanab_suppliers["hanab_supplier"]:::Entity'))
        $markdown | Should -Match "hanab_products --> hanab_suppliers:hanab_product-OneToMany"
        $markdown | Should -Match "class systemuser:::DefaultEntity"
    }

    It "includes related hanab entities and system default entities in scoped canvas diagrams" {
        $mockSupplierEntity = [pscustomobject]@{
            Name = "hanab_supplier"
            EntitySetName = "hanab_suppliers"
            Attributes = @(
                [pscustomobject]@{ Name = "hanab_suppliername"; Type = "nvarchar" }
            )
            Relations = @()
            FormWebResources = @()
            IconResources = @()
        }

        $mockProductEntity = [pscustomobject]@{
            Name = "hanab_product"
            EntitySetName = "hanab_products"
            Attributes = @(
                [pscustomobject]@{ Name = "hanab_name"; Type = "nvarchar" }
            )
            Relations = @(
                [pscustomobject]@{ Source = "hanab_product"; Target = "hanab_supplier"; Type = "OneToMany" },
                [pscustomobject]@{ Source = "hanab_product"; Target = "systemuser"; Type = "OneToMany" }
            )
            FormWebResources = @()
            IconResources = @()
        }

        $mockSolutionObject = [pscustomobject]@{
            Workflows = @()
            EnvironmentVariables = @()
            ConnectionReferences = @(
                [pscustomobject]@{ ConnectorId = "/providers/Microsoft.PowerApps/apis/shared_commondataserviceforapps"; DisplayName = "Dataverse - Test" }
            )
            Entities = @($mockSupplierEntity, $mockProductEntity)
            CanvasApps = @(
                [pscustomobject]@{
                    Name = "hanab_canvas"
                    DisplayName = "Hanab Canvas"
                    ConnectionReferences = @(
                        [pscustomobject]@{ id = "/providers/Microsoft.PowerApps/apis/shared_commondataserviceforapps" }
                    )
                    DataSources = [pscustomobject]@{
                        DataSources = @(
                            [pscustomobject]@{
                                Name = "Products"
                                entitySetName = "hanab_products"
                                logicalName = "hanab_product"
                            }
                        )
                    }
                }
            )
        }

        Mock -CommandName Get-PowerPlatformCheckerSolutionObject -ModuleName PowerPlatformChecker -MockWith {
            $mockSolutionObject
        }
        Mock -CommandName Get-PowerPlatformCheckerWebResource -ModuleName PowerPlatformChecker -MockWith {
            @()
        }

        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath "C:\does-not-matter" -CanvasAppName "hanab_canvas" -IncludeElements CanvasApps,Connections,Entities,DefaultEntities

        $markdown | Should -Match ([regex]::Escape('class hanab_suppliers["hanab_supplier"]:::Entity'))
        $markdown | Should -Match "hanab_products --> hanab_suppliers:hanab_product-OneToMany"
        $markdown | Should -Match "class systemuser:::DefaultEntity"
    }

    It "includes related hanab entities and system default entities in scoped model-driven diagrams" {
        $mockSupplierEntity = [pscustomobject]@{
            Name = "hanab_supplier"
            EntitySetName = "hanab_suppliers"
            Attributes = @(
                [pscustomobject]@{ Name = "hanab_suppliername"; Type = "nvarchar" }
            )
            Relations = @()
            FormWebResources = @()
            IconResources = @()
        }

        $mockProductEntity = [pscustomobject]@{
            Name = "hanab_product"
            EntitySetName = "hanab_products"
            Attributes = @(
                [pscustomobject]@{ Name = "hanab_name"; Type = "nvarchar" }
            )
            Relations = @(
                [pscustomobject]@{ Source = "hanab_product"; Target = "hanab_supplier"; Type = "OneToMany" },
                [pscustomobject]@{ Source = "hanab_product"; Target = "systemuser"; Type = "OneToMany" }
            )
            FormWebResources = @()
            IconResources = @()
        }

        $mockSolutionObject = [pscustomobject]@{
            Workflows = @()
            EnvironmentVariables = @()
            ConnectionReferences = @()
            Entities = @($mockSupplierEntity, $mockProductEntity)
            CanvasApps = @()
        }

        $mockModelApp = [pscustomobject]@{
            UniqueName = "hanab_ModelApp"
            MermaidId = "hanab_ModelApp"
            DisplayName = "Hanab Model App"
            Components = @()
            FlowIds = @()
            Entities = @("hanab_product")
            WebResources = @()
            EntityWebResources = @()
        }

        Mock -CommandName Get-PowerPlatformCheckerSolutionObject -ModuleName PowerPlatformChecker -MockWith {
            $mockSolutionObject
        }
        Mock -CommandName Get-PowerPlatformCheckerModelDrivenApp -ModuleName PowerPlatformChecker -MockWith {
            @($mockModelApp)
        }
        Mock -CommandName Get-PowerPlatformCheckerWebResource -ModuleName PowerPlatformChecker -MockWith {
            @()
        }

        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath "C:\does-not-matter" -ModelDrivenAppName "hanab_ModelApp" -IncludeElements ModelDrivenApps,Entities,DefaultEntities

        $markdown | Should -Match ([regex]::Escape('class hanab_suppliers["hanab_supplier"]:::Entity'))
        $markdown | Should -Match "hanab_products --> hanab_suppliers:hanab_product-OneToMany"
        $markdown | Should -Match "class systemuser:::DefaultEntity"
    }

    It "keeps unresolved flow action entity references as missing nodes" {
        $mockFlowId = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"

        $mockSolutionObject = [pscustomobject]@{
            Workflows = @(
                [pscustomobject]@{ Id = $mockFlowId; Name = "External Entity Flow" }
            )
            EnvironmentVariables = @()
            ConnectionReferences = @(
                [pscustomobject]@{ ConnectorId = "/providers/Microsoft.PowerApps/apis/shared_commondataserviceforapps"; DisplayName = "Dataverse - Test" }
            )
            Entities = @()
            CanvasApps = @()
        }

        Mock -CommandName Get-PowerPlatformCheckerSolutionObject -ModuleName PowerPlatformChecker -MockWith {
            $mockSolutionObject
        }
        Mock -CommandName Get-PowerPlatformCheckerFlowParameter -ModuleName PowerPlatformChecker -MockWith {
            @()
        }
        Mock -CommandName Get-PowerPlatformCheckerFlowActionList -ModuleName PowerPlatformChecker -MockWith {
            @(
                [pscustomobject]@{
                    Name = "List_rows"
                    Group = "shared_commondataserviceforapps"
                    Entities = @("external_vendor")
                    Reference = ""
                }
            )
        }
        Mock -CommandName Get-PowerPlatformCheckerWebResource -ModuleName PowerPlatformChecker -MockWith {
            @()
        }

        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath "C:\does-not-matter" -FlowId $mockFlowId -IncludeElements Flows,Connections,Entities,DefaultEntities

        $markdown | Should -Match "flow${mockFlowId} --> external_vendor:external_vendor"
        $markdown | Should -Match "class external_vendor:::DefaultEntity"
    }

    It "keeps unresolved model-driven entity references as missing nodes" {
        $mockSolutionObject = [pscustomobject]@{
            Workflows = @()
            EnvironmentVariables = @()
            ConnectionReferences = @()
            Entities = @()
            CanvasApps = @()
        }

        $mockModelApp = [pscustomobject]@{
            UniqueName = "external_ModelApp"
            MermaidId = "external_ModelApp"
            DisplayName = "External Model App"
            Components = @()
            FlowIds = @()
            Entities = @("external_vendor")
            WebResources = @()
            EntityWebResources = @()
        }

        Mock -CommandName Get-PowerPlatformCheckerSolutionObject -ModuleName PowerPlatformChecker -MockWith {
            $mockSolutionObject
        }
        Mock -CommandName Get-PowerPlatformCheckerModelDrivenApp -ModuleName PowerPlatformChecker -MockWith {
            @($mockModelApp)
        }
        Mock -CommandName Get-PowerPlatformCheckerWebResource -ModuleName PowerPlatformChecker -MockWith {
            @()
        }

        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath "C:\does-not-matter" -ModelDrivenAppName "external_ModelApp" -IncludeElements ModelDrivenApps,Entities,DefaultEntities

        $markdown | Should -Match "external_ModelApp --> external_vendor:Entity"
        $markdown | Should -Match "class external_vendor:::DefaultEntity"
    }

    It "keeps unresolved canvas datasource references as missing nodes" {
        $mockSolutionObject = [pscustomobject]@{
            Workflows = @()
            EnvironmentVariables = @()
            ConnectionReferences = @()
            Entities = @()
            CanvasApps = @(
                [pscustomobject]@{
                    Name = "external_canvas"
                    DisplayName = "External Canvas"
                    ConnectionReferences = @()
                    DataSources = [pscustomobject]@{
                        DataSources = @(
                            [pscustomobject]@{
                                Name = "External"
                                entitySetName = ""
                                logicalName = "external_vendor"
                            }
                        )
                    }
                }
            )
        }

        Mock -CommandName Get-PowerPlatformCheckerSolutionObject -ModuleName PowerPlatformChecker -MockWith {
            $mockSolutionObject
        }
        Mock -CommandName Get-PowerPlatformCheckerWebResource -ModuleName PowerPlatformChecker -MockWith {
            @()
        }

        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath "C:\does-not-matter" -CanvasAppName "external_canvas" -IncludeElements CanvasApps,Entities,DefaultEntities

        $markdown | Should -Match "external_canvas --> external_vendor:External"
        $markdown | Should -Match "class external_vendor:::DefaultEntity"
    }

    It "matches expected model-driven entities-only diagram" {
        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -ModelDrivenAppName "ppc_ModelApp" -IncludeElements Entities,ModelDrivenApps

        (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedModelDrivenEntitiesOnly)
    }

    It "matches expected model-driven webresources-only diagram" {
        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -ModelDrivenAppName "ppc_ModelApp" -IncludeElements WebResources,ModelDrivenApps

        (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedModelDrivenWebResourcesOnly)
    }

    It "matches expected full diagram for flows canvas connections and webresources only" {
        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -IncludeElements Flows,CanvasApps,Connections,WebResources

        (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedFullFlowsCanvasConnectionsWebResources)
    }

    It "matches expected full architecture graph snapshot" {
        $graph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -OutputFormat Graph
        $graphSnapshot = & $script:graphSnapshotConverter -Graph $graph

        (Normalize-PowerPlatformCheckerSnapshotText -Text $graphSnapshot) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedGraphFull)
    }

    It "matches expected flow-scoped architecture graph snapshot" {
        $graph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -FlowId "11111111-1111-1111-1111-111111111111" -Direction TB -OutputFormat Graph
        $graphSnapshot = & $script:graphSnapshotConverter -Graph $graph

        (Normalize-PowerPlatformCheckerSnapshotText -Text $graphSnapshot) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedGraphFlowTb)
    }

    It "matches expected canvas-scoped architecture graph snapshot" {
        $graph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -CanvasAppName "ppc_canvas_sales_0001" -Direction RL -OutputFormat Graph
        $graphSnapshot = & $script:graphSnapshotConverter -Graph $graph

        (Normalize-PowerPlatformCheckerSnapshotText -Text $graphSnapshot) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedGraphCanvasRl)
    }

    It "matches expected model-driven architecture graph snapshot" {
        $graph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -ModelDrivenAppName "ppc_ModelApp" -OutputFormat Graph
        $graphSnapshot = & $script:graphSnapshotConverter -Graph $graph

        (Normalize-PowerPlatformCheckerSnapshotText -Text $graphSnapshot) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedGraphModelDriven)
    }

    It "matches expected model-driven entities-only architecture graph snapshot" {
        $graph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -ModelDrivenAppName "ppc_ModelApp" -IncludeElements Entities,ModelDrivenApps -OutputFormat Graph
        $graphSnapshot = & $script:graphSnapshotConverter -Graph $graph

        (Normalize-PowerPlatformCheckerSnapshotText -Text $graphSnapshot) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedGraphModelDrivenEntitiesOnly)
    }

    It "matches expected model-driven webresources-only architecture graph snapshot" {
        $graph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -ModelDrivenAppName "ppc_ModelApp" -IncludeElements WebResources,ModelDrivenApps -OutputFormat Graph
        $graphSnapshot = & $script:graphSnapshotConverter -Graph $graph

        (Normalize-PowerPlatformCheckerSnapshotText -Text $graphSnapshot) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedGraphModelDrivenWebResourcesOnly)
    }

    It "matches expected full filtered architecture graph snapshot" {
        $graph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -IncludeElements Flows,CanvasApps,Connections,WebResources -OutputFormat Graph
        $graphSnapshot = & $script:graphSnapshotConverter -Graph $graph

        (Normalize-PowerPlatformCheckerSnapshotText -Text $graphSnapshot) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedGraphFullFlowsCanvasConnectionsWebResources)
    }

    It "ensures all graph edge endpoints reference existing nodes" {
        $graph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -OutputFormat Graph
        $nodeIds = @($graph.Nodes | ForEach-Object { [string]$_.Id })

        foreach ($edge in @($graph.Edges)) {
            [string]$edge.SourceId | Should -BeIn $nodeIds
            [string]$edge.TargetId | Should -BeIn $nodeIds
        }
    }

    It "ensures graph node ids are unique" {
        $graph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -OutputFormat Graph
        $nodeIds = @($graph.Nodes | ForEach-Object { [string]$_.Id })
        $uniqueNodeIds = @($nodeIds | Select-Object -Unique)

        $nodeIds.Count | Should -Be $uniqueNodeIds.Count
    }

    It "ensures graph edges are unique by source target label and edge type" {
        $graph = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -OutputFormat Graph
        $edgeKeys = @($graph.Edges | ForEach-Object { "{0}|{1}|{2}|{3}" -f $_.SourceId, $_.TargetId, $_.Label, $_.EdgeType })
        $uniqueEdgeKeys = @($edgeKeys | Select-Object -Unique)

        $edgeKeys.Count | Should -Be $uniqueEdgeKeys.Count
    }

        It "renders entity icons as separate webresource nodes" {
                $testRoot = Join-Path $TestDrive "ArchitectureIconFixture"
                New-Item -ItemType Directory -Path (Join-Path $testRoot "Entities\sample_account") -Force | Out-Null
                New-Item -ItemType Directory -Path (Join-Path $testRoot "WebResources\sample_icon") -Force | Out-Null
                New-Item -ItemType Directory -Path (Join-Path $testRoot "Workflows") -Force | Out-Null
                New-Item -ItemType Directory -Path (Join-Path $testRoot "Other") -Force | Out-Null
                Set-Content -Path (Join-Path $testRoot "Other\Customizations.xml") -Value "<Customizations />" -Encoding utf8BOM

                Set-Content -Path (Join-Path $testRoot "Entities\sample_account\Entity.xml") -Encoding utf8BOM -Value @"
<Entity>
    <Name LocalizedName="Account" OriginalName="Account">sample_account</Name>
    <EntityInfo>
        <entity Name="sample_account">
            <EntitySetName>sample_accounts</EntitySetName>
            <IconVectorName>sample_icon/product.svg</IconVectorName>
            <attributes>
                <attribute><Name>sample_name</Name><Type>string</Type><displaynames><displayname description="Name" /></displaynames><descriptions><description description="Name" /></descriptions></attribute>
            </attributes>
        </entity>
    </EntityInfo>
</Entity>
"@

                Set-Content -Path (Join-Path $testRoot "WebResources\sample_icon\product.svg.data.xml") -Encoding utf8BOM -Value @"
<WebResource>
    <Name>sample_icon/product.svg</Name>
    <DisplayName>Product</DisplayName>
    <WebResourceType>11</WebResourceType>
    <DependencyXml></DependencyXml>
    <FileName>/WebResources/sample_iconproductsvg11111111-1111-1111-1111-111111111111</FileName>
</WebResource>
"@

                $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $testRoot

                $markdown | Should -Match "sample_accounts --> sample_icon_product_svg:IconVectorName"
                $markdown | Should -Match ([regex]::Escape('class sample_icon_product_svg["Product"]:::WebResource'))
    }

    It "supports session-level style updates via Set-PowerPlatformCheckerDiagramStyle" {
        try {
            Set-PowerPlatformCheckerDiagramStyle -ColorMap @{ Flow = "#445566" } | Out-Null
            $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath
            $markdown | Should -Match "classDef Flow fill:#445566,stroke:#5E5B52"
        }
        finally {
            Set-PowerPlatformCheckerDiagramStyle -ColorMap @{ Flow = "#DBE4EE" } | Out-Null
        }
    }

    It "rejects unsupported style keys" {
        { Set-PowerPlatformCheckerDiagramStyle -ColorMap @{ NotARealKey = "#000000" } } | Should -Throw
    }
}

