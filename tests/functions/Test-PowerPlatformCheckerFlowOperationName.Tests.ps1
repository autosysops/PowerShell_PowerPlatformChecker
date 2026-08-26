Describe "Test-PowerPlatformCheckerFlowOperationName" {
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "marks action names that match default names" {
        Mock -CommandName Get-PowerPlatformCheckerFlowActionList -ModuleName PowerPlatformChecker {
            @(
                [pscustomobject]@{ Name = "Create_orderline"; Type = "CreateRecord"; Group = "*" },
                [pscustomobject]@{ Name = "NonDefaultAction"; Type = "SendEmailV2"; Group = "*" }
            )
        }

        Mock -CommandName Get-PowerPlatformCheckerFlowActionDefaultName -ModuleName PowerPlatformChecker {
            param($Type, $Group)
            if ($Type -eq "CreateRecord") { return "Create orderline" }
            return "Send an email"
        }

        $result = Test-PowerPlatformCheckerFlowOperationName -Path "dummy"

        ($result | Where-Object ActionName -eq "Create_orderline").Equal | Should -Be $true
        ($result | Where-Object ActionName -eq "NonDefaultAction").Equal | Should -Be $false
    }

    It "sends invocation telemetry without flow paths or comparison results" {
        Mock -CommandName Get-PowerPlatformCheckerFlowActionList -ModuleName PowerPlatformChecker {
            @(
                [pscustomobject]@{ Name = "Create_orderline"; Type = "CreateRecord"; Group = "*" },
                [pscustomobject]@{ Name = "NonDefaultAction"; Type = "SendEmailV2"; Group = "*" }
            )
        }

        Mock -CommandName Get-PowerPlatformCheckerFlowActionDefaultName -ModuleName PowerPlatformChecker {
            param($Type, $Group)
            if ($Type -eq "CreateRecord") { return "Create orderline" }
            return "Send an email"
        }

        $telemetryCalls = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {
            param([string]$ModuleName, [string]$EventName, [hashtable]$PropertiesHash)
            [void]$telemetryCalls.Add([pscustomobject]@{ ModuleName = $ModuleName; EventName = $EventName; PropertiesHash = $PropertiesHash })
        }

        [void](Test-PowerPlatformCheckerFlowOperationName -Path "dummy")
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Test-PowerPlatformCheckerFlowOperationName" -ExpectedKeys @() -ConfidentialValues @("dummy", "Create_orderline", "NonDefaultAction")
    }
}

