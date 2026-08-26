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

    It "sends sanitized telemetry for option usage" {
        $telemetryCalls = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {
            param([string]$ModuleName, [string]$EventName, [hashtable]$PropertiesHash)
            [void]$telemetryCalls.Add([pscustomobject]@{ ModuleName = $ModuleName; EventName = $EventName; PropertiesHash = $PropertiesHash })
        }

        $secretName = "secret-connector-name"
        $secretPublisher = "secret-publisher"
        [void](Get-PowerPlatformCheckerConnectorData -Name $secretName -Tier "Premium" -ReleaseTag "Production" -Publisher $secretPublisher)

        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerConnectorData" -ExpectedKeys @("NameFiltered", "TierFiltered", "ReleaseTagFiltered", "PublisherFiltered") -ConfidentialValues @($secretName, $secretPublisher)
    }
}

