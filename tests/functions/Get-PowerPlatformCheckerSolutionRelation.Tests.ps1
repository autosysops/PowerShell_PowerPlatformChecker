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

    It "returns empty when the relationship folder does not exist" {
        $testRoot = Join-Path $TestDrive "NoRelationships"
        New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

        { Get-PowerPlatformCheckerSolutionRelation -SolutionPath $testRoot -ErrorAction Stop } | Should -Not -Throw
        @(Get-PowerPlatformCheckerSolutionRelation -SolutionPath $testRoot).Count | Should -Be 0
    }
}

