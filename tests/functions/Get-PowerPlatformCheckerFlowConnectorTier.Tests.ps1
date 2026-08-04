. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerFlowConnectorTier" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
        $script:flowPath = Join-Path $script:solutionPath "Workflows\SampleFlow-11111111-1111-1111-1111-111111111111.json"
    }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "returns connector tiers" {
        $tiers = Get-PowerPlatformCheckerFlowConnectorTier -Path $script:flowPath
        $tiers.Count | Should -Be 2
        ($tiers | Where-Object Name -eq "shared_office365").Tier | Should -Be "Standard"
    }
}

