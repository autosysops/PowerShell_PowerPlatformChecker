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

    It "prefers builtin operation metadata when multiple matches are returned" {
        Mock -CommandName Get-PowerPlatformCheckerOperationData -ModuleName PowerPlatformChecker {
            @(
                [pscustomobject]@{ summary = "Custom summary"; builtin = $false },
                [pscustomobject]@{ summary = "Built-in summary"; builtin = $true }
            )
        }

        $summary = Get-PowerPlatformCheckerFlowActionDefaultName -Type "CreateRecord" -Group "*"

        $summary | Should -Be "Built-in summary"
    }

    It "sends sanitized telemetry for wildcard and explicit group invocation" {
        $telemetryCalls = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {
            param([string]$ModuleName, [string]$EventName, [hashtable]$PropertiesHash)
            [void]$telemetryCalls.Add([pscustomobject]@{ ModuleName = $ModuleName; EventName = $EventName; PropertiesHash = $PropertiesHash })
        }

        $secretType = "CreateRecord"
        [void](Get-PowerPlatformCheckerFlowActionDefaultName -Type $secretType -Group "*")
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerFlowActionDefaultName" -ExpectedKeys @("UsesWildcardGroup") -ConfidentialValues @($secretType)

        $telemetryCalls.Clear()
        [void](Get-PowerPlatformCheckerFlowActionDefaultName -Type "Send an email" -Group "shared_office365")
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerFlowActionDefaultName" -ExpectedKeys @("UsesWildcardGroup") -ConfidentialValues @("shared_office365")
    }
}

