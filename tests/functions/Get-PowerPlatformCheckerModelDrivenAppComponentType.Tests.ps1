Describe "Get-PowerPlatformCheckerModelDrivenAppComponentType" {
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "resolves known appmodule component types" -TestCases @(
        @{ Type = 1; Expected = "Entities" }
        @{ Type = 26; Expected = "Views" }
        @{ Type = 29; Expected = "Business Process Flows" }
        @{ Type = 48; Expected = "Command (Ribbon)" }
        @{ Type = 59; Expected = "Charts" }
        @{ Type = 60; Expected = "Forms" }
        @{ Type = 61; Expected = "Web Resources" }
        @{ Type = 62; Expected = "Sitemap" }
    ) {
        param($Type, $Expected)

        (Get-PowerPlatformCheckerModelDrivenAppComponentType -Type $Type) | Should -Be $Expected
    }

    It "returns unknown for unmapped type" {
        (Get-PowerPlatformCheckerModelDrivenAppComponentType -Type 999) | Should -Be "Unknown (999)"
    }

    It "sends invocation telemetry without echoing the input type code" {
        $telemetryCalls = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {
            param([string]$ModuleName, [string]$EventName, [hashtable]$PropertiesHash)
            [void]$telemetryCalls.Add([pscustomobject]@{ ModuleName = $ModuleName; EventName = $EventName; PropertiesHash = $PropertiesHash })
        }

        [void](Get-PowerPlatformCheckerModelDrivenAppComponentType -Type 29)
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerModelDrivenAppComponentType" -ExpectedKeys @() -ConfidentialValues @("29")
    }
}
