. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerOperationData" {
    BeforeAll { Initialize-PowerPlatformCheckerTestData }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "filters by group and usage" {
        $result = Get-PowerPlatformCheckerOperationData -Group shared_office365 -Usage Action
        $result.Count | Should -Be 1
        $result[0].operationType | Should -Be "SendEmailV2"
    }
}

