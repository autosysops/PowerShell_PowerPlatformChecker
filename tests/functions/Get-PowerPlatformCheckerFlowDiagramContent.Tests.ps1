. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerFlowDiagramContent" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
    }

    It "renders flow class content and tracks connected references" {
        InModuleScope PowerPlatformChecker {
            $flows = @([pscustomobject]@{ Id = "f1"; Name = "Flow 1" })
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

            $result = Get-PowerPlatformCheckerFlowDiagramContent -FlowsToRender $flows -SolutionPath "C:\dummy" -SolutionObject $solutionObject -IncludeFlows:$true -IncludeEnvironmentVariables:$true -IncludeConnections:$true -IncludeEntities:$true -HasFlowFilter:$false -FlowId "" -EntitySetByReference @{ account = "accounts" } -NewLine "`n"

            $result.DiagramText | Should -Match 'class flowf1\["Flow 1"\]:::Flow \{'
            (@($result.Links) -join "`n") | Should -Match 'ppc_env \.\.> flowf1:ppc_env'
            (@($result.Links) -join "`n") | Should -Match 'flowf1 --> flowf2:Run_child'
            (@($result.Links) -join "`n") | Should -Match 'shared_sql --> flowf1:shared_sql'
            (@($result.Links) -join "`n") | Should -Match 'flowf1 --> accounts:account'
            @($result.ConnectedEnvVars) | Should -Contain 'ppc_env'
            @($result.ConnectedConnections) | Should -Contain 'shared_sql'
            @($result.ConnectedEntities) | Should -Contain 'accounts'
        }
    }

    It "renders compact class when no members are discovered" {
        InModuleScope PowerPlatformChecker {
            $flows = @([pscustomobject]@{ Id = "f1"; Name = "Flow 1" })
            $solutionObject = [pscustomobject]@{ Workflows = @([pscustomobject]@{ Id = "f1"; Name = "Flow 1" }) }

            Mock -CommandName Get-PowerPlatformCheckerFlowParameter -ModuleName PowerPlatformChecker -MockWith { @() }
            Mock -CommandName Get-PowerPlatformCheckerFlowActionList -ModuleName PowerPlatformChecker -MockWith { @() }

            $result = Get-PowerPlatformCheckerFlowDiagramContent -FlowsToRender $flows -SolutionPath "C:\dummy" -SolutionObject $solutionObject -IncludeFlows:$true -IncludeEnvironmentVariables:$false -IncludeConnections:$false -IncludeEntities:$false -HasFlowFilter:$false -FlowId "" -EntitySetByReference @{} -NewLine "`n"
            $result.DiagramText | Should -Be ('class flowf1["Flow 1"]:::Flow' + "`n")
        }
    }
}
