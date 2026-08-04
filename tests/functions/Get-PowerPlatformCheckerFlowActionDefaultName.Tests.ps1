. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerFlowActionDefaultName" {
    BeforeAll { Initialize-PowerPlatformCheckerTestData }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "resolves by operation type when group is wildcard" {
        $summary = Get-PowerPlatformCheckerFlowActionDefaultName -Type "CreateRecord" -Group "*"
        $summary | Should -Be "Create orderline"
    }

    It "resolves by explicit group" {
        $summary = Get-PowerPlatformCheckerFlowActionDefaultName -Type "Send an email" -Group "shared_office365"
        $summary | Should -Be "Send an email"
    }
}

