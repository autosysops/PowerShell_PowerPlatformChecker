. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerArchitectureFlowGraphContent" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
    }

    It "renders flow class content and tracks connected references" {
        InModuleScope PowerPlatformChecker {
            $solutionObject = [pscustomobject]@{
                Workflows = @(
                    [pscustomobject]@{ Id = "f1"; Name = "Flow 1" },
                    [pscustomobject]@{ Id = "f2"; Name = "Flow 2" }
                )
            }

            Mock -CommandName Get-PowerPlatformCheckerFlowParameter -ModuleName PowerPlatformChecker -MockWith {
                @([pscustomobject]@{ Type = "string"; SchemaName = "ppc_env" })
            }
            Mock -CommandName Get-PowerPlatformCheckerFlowType -ModuleName PowerPlatformChecker -MockWith { "Cloud" }
            Mock -CommandName Get-PowerPlatformCheckerFlowActionList -ModuleName PowerPlatformChecker -MockWith {
                @(
                    [pscustomobject]@{ Name = "Run child"; Group = "shared_sql"; Entities = @("account"); Reference = "f2" }
                )
            }

            $result = Get-PowerPlatformCheckerArchitectureFlowGraphContent -SolutionPath "C:\dummy" -SolutionObject $solutionObject -IncludeFlows:$true -IncludeEnvironmentVariables:$true -IncludeConnections:$true -IncludeEntities:$true -HasFlowFilter:$false -HasModelDrivenFilter:$true -ModelDrivenFlowFilter @("f1") -FlowId "" -EntitySetByReference @{ account = "accounts" }

            @($result.Nodes).Count | Should -Be 1
            $result.Nodes[0].Id | Should -Be "flowf1"
            @($result.Nodes[0].Members).Count | Should -Be 3
            @($result.Edges | Where-Object { $_.SourceId -eq "ppc_env" -and $_.TargetId -eq "flowf1" -and $_.EdgeType -eq "Reference" }).Count | Should -Be 1
            @($result.Edges | Where-Object { $_.SourceId -eq "flowf1" -and $_.TargetId -eq "accounts" }).Count | Should -Be 1
            @($result.Edges | Where-Object { $_.SourceId -eq "flowf1" -and $_.TargetId -eq "flowf2" -and $_.Label -eq "Run_child" }).Count | Should -Be 1
            @($result.Edges | Where-Object { $_.SourceId -eq "shared_sql" -and $_.TargetId -eq "flowf1" }).Count | Should -Be 1
            @($result.ConnectedEnvVars) | Should -Contain 'ppc_env'
            @($result.ConnectedConnections) | Should -Contain 'shared_sql'
            @($result.ConnectedEntities) | Should -Contain 'accounts'
        }
    }

    It "renders compact class when no members are discovered" {
        InModuleScope PowerPlatformChecker {
            $solutionObject = [pscustomobject]@{ Workflows = @([pscustomobject]@{ Id = "f1"; Name = "Flow 1" }) }

            Mock -CommandName Get-PowerPlatformCheckerFlowParameter -ModuleName PowerPlatformChecker -MockWith { @() }
            Mock -CommandName Get-PowerPlatformCheckerFlowType -ModuleName PowerPlatformChecker -MockWith { "Cloud" }
            Mock -CommandName Get-PowerPlatformCheckerFlowActionList -ModuleName PowerPlatformChecker -MockWith { @() }

            $result = Get-PowerPlatformCheckerArchitectureFlowGraphContent -SolutionPath "C:\dummy" -SolutionObject $solutionObject -IncludeFlows:$true -IncludeEnvironmentVariables:$false -IncludeConnections:$false -IncludeEntities:$false -HasFlowFilter:$false -FlowId "" -EntitySetByReference @{}
            @($result.Nodes).Count | Should -Be 1
            @($result.Nodes[0].Members).Count | Should -Be 0
        }
    }

    It "adds trigger mode classification to flow node properties" {
        InModuleScope PowerPlatformChecker {
            $solutionObject = [pscustomobject]@{ Workflows = @([pscustomobject]@{ Id = "f1"; Name = "Flow 1" }) }

            Mock -CommandName Get-PowerPlatformCheckerFlowType -ModuleName PowerPlatformChecker -MockWith { "Cloud" }
            Mock -CommandName Get-PowerPlatformCheckerFlowParameter -ModuleName PowerPlatformChecker -MockWith { @() }
            Mock -CommandName Get-PowerPlatformCheckerFlowActionList -ModuleName PowerPlatformChecker -MockWith {
                @(
                    [pscustomobject]@{ Name = "When_a_row_is_added"; Type = "SubscribeWebhookTrigger"; Group = "shared_commondataserviceforapps"; IsTrigger = $true; Entities = @(); Reference = "" },
                    [pscustomobject]@{ Name = "Create_orderline"; Type = "CreateRecord"; Group = "shared_commondataserviceforapps"; IsTrigger = $false; Entities = @(); Reference = "" }
                )
            }

            $result = Get-PowerPlatformCheckerArchitectureFlowGraphContent -SolutionPath "C:\dummy" -SolutionObject $solutionObject -IncludeFlows:$true -IncludeEnvironmentVariables:$false -IncludeConnections:$true -IncludeEntities:$false -HasFlowFilter:$false -FlowId "" -EntitySetByReference @{}

            @($result.Nodes).Count | Should -Be 1
            $result.Nodes[0].Properties.TriggerMode | Should -Be "Webhook"
        }
    }

    It "adds interaction direction metadata to flow node properties" {
        InModuleScope PowerPlatformChecker {
            $solutionObject = [pscustomobject]@{ Workflows = @([pscustomobject]@{ Id = "f1"; Name = "Flow 1" }) }

            Mock -CommandName Get-PowerPlatformCheckerFlowType -ModuleName PowerPlatformChecker -MockWith { "Cloud" }
            Mock -CommandName Get-PowerPlatformCheckerFlowParameter -ModuleName PowerPlatformChecker -MockWith { @() }
            Mock -CommandName Get-PowerPlatformCheckerFlowActionList -ModuleName PowerPlatformChecker -MockWith {
                @(
                    [pscustomobject]@{ Name = "When_a_row_is_added"; Type = "SubscribeWebhookTrigger"; Group = "shared_commondataserviceforapps"; IsTrigger = $true; Entities = @(); Reference = "" },
                    [pscustomobject]@{ Name = "Create_orderline"; Type = "CreateRecord"; Group = "shared_commondataserviceforapps"; IsTrigger = $false; Entities = @(); Reference = "" },
                    [pscustomobject]@{ Name = "Update_row"; Type = "UpdateOnlyRecord"; Group = "shared_commondataserviceforapps"; IsTrigger = $false; Entities = @(); Reference = "" }
                )
            }

            $result = Get-PowerPlatformCheckerArchitectureFlowGraphContent -SolutionPath "C:\dummy" -SolutionObject $solutionObject -IncludeFlows:$true -IncludeEnvironmentVariables:$false -IncludeConnections:$true -IncludeEntities:$false -HasFlowFilter:$false -FlowId "" -EntitySetByReference @{}

            @($result.Nodes).Count | Should -Be 1
            $result.Nodes[0].Properties.InteractionDirection | Should -Be "Write"
            $result.Nodes[0].Properties.DirectionConfidence | Should -Be "High"
            $result.Nodes[0].Properties.SourceEvidence | Should -Be "OperationCatalog+Heuristic"
        }
    }

    It "adds destination metadata to flow node properties" {
        InModuleScope PowerPlatformChecker {
            $solutionObject = [pscustomobject]@{ Workflows = @([pscustomobject]@{ Id = "f1"; Name = "Flow 1" }) }

            Mock -CommandName Get-PowerPlatformCheckerFlowType -ModuleName PowerPlatformChecker -MockWith { "Cloud" }
            Mock -CommandName Get-PowerPlatformCheckerFlowParameter -ModuleName PowerPlatformChecker -MockWith { @() }
            Mock -CommandName Get-PowerPlatformCheckerFlowActionList -ModuleName PowerPlatformChecker -MockWith {
                @(
                    [pscustomobject]@{ Name = "Create_orderline"; Type = "CreateRecord"; Group = "shared_commondataserviceforapps"; IsTrigger = $false; Entities = @("ppc_orderlines"); Reference = "" }
                )
            }

            $result = Get-PowerPlatformCheckerArchitectureFlowGraphContent -SolutionPath "C:\dummy" -SolutionObject $solutionObject -IncludeFlows:$true -IncludeEnvironmentVariables:$false -IncludeConnections:$true -IncludeEntities:$true -HasFlowFilter:$false -FlowId "" -EntitySetByReference @{ ppc_orderlines = "ppc_orderlines" }

            @($result.Nodes).Count | Should -Be 1
            $result.Nodes[0].Properties.Destination | Should -Be "ppc_orderlines"
            $result.Nodes[0].Properties.DestinationType | Should -Be "DataverseEntity"
            $result.Nodes[0].Properties.DestinationConfidence | Should -Be "Medium"
            $result.Nodes[0].Properties.DestinationEvidence | Should -Be "ActionEntity"
        }
    }
}
