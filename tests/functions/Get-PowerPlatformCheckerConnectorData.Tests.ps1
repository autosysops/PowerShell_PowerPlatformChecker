. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerConnectorData" {
    BeforeAll { Initialize-PowerPlatformCheckerTestData }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "filters by tier and release tag" {
        $result = Get-PowerPlatformCheckerConnectorData -Tier Standard -ReleaseTag Production
        $result.Count | Should -Be 1
        $result[0].name | Should -Be "shared_office365"
    }

    It "filters by wildcard name" {
        $result = Get-PowerPlatformCheckerConnectorData -Name "shared_*dataservice*"
        $result.Count | Should -Be 1
        $result[0].tier | Should -Be "Premium"
    }
}

