. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerSolutionRelation" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
    }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "returns relation records" {
        $relations = Get-PowerPlatformCheckerSolutionRelation -SolutionPath $script:solutionPath
        $relations.Count | Should -Be 4
        ($relations | Where-Object Name -eq "ppc_Order_ppc_OrderLine").Type | Should -Be "OneToMany"
    }
}

