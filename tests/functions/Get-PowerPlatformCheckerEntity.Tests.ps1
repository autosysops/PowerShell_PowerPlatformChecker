. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerEntity" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
    }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "returns entities and relations" {
        $entities = Get-PowerPlatformCheckerEntity -SolutionPath $script:solutionPath -Relations
        $entities.Count | Should -Be 2
        ($entities | Where-Object Name -eq "ppc_Order").Relations.Count | Should -BeGreaterThan 0
    }
}

