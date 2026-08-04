. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerFlowParameter" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
        $script:flowPath = Join-Path $script:solutionPath "Workflows\SampleFlow-11111111-1111-1111-1111-111111111111.json"
    }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "returns custom parameters only" {
        $parameters = Get-PowerPlatformCheckerFlowParameter -Path $script:flowPath
        $parameters.Count | Should -Be 1
        $parameters[0].SchemaName | Should -Be "ppc_ApiBaseUrl"
    }
}

