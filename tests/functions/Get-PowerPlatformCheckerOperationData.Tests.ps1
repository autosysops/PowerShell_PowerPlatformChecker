. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerOperationData" {
    BeforeAll { Initialize-PowerPlatformCheckerTestData }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "filters by group and usage" {
        $result = Get-PowerPlatformCheckerOperationData -Group shared_office365 -Usage Action
        $result.Count | Should -Be 1
        $result[0].operationType | Should -Be "SendEmailV2"
    }

    It "sends sanitized telemetry for filter usage" {
        $telemetryCalls = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {
            param([string]$ModuleName, [string]$EventName, [hashtable]$PropertiesHash)
            [void]$telemetryCalls.Add([pscustomobject]@{ ModuleName = $ModuleName; EventName = $EventName; PropertiesHash = $PropertiesHash })
        }

        $secretName = "secret operation"
        $secretGroup = "secret-group"
        [void](Get-PowerPlatformCheckerOperationData -Name $secretName -OperationType "SendEmailV2" -Usage "Action" -Group $secretGroup)

        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerOperationData" -ExpectedKeys @("NameFiltered", "OperationTypeFiltered", "UsageFiltered", "GroupFiltered") -ConfidentialValues @($secretName, $secretGroup)
    }
}

