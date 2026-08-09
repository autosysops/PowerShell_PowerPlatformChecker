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
            Mock -CommandName Get-PowerPlatformCheckerFlowActionList -ModuleName PowerPlatformChecker -MockWith { @() }

            $result = Get-PowerPlatformCheckerArchitectureFlowGraphContent -SolutionPath "C:\dummy" -SolutionObject $solutionObject -IncludeFlows:$true -IncludeEnvironmentVariables:$false -IncludeConnections:$false -IncludeEntities:$false -HasFlowFilter:$false -FlowId "" -EntitySetByReference @{}
            @($result.Nodes).Count | Should -Be 1
            @($result.Nodes[0].Members).Count | Should -Be 0
        }
    }
}
