. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerFlowType" {
    $classificationCases = @(
        @{
            Name = "cloud flow JSON shape"
            FileName = "CloudFlow-01010101-0101-0101-0101-010101010101.json"
            Expected = "Cloud"
        }
        @{
            Name = "desktop workflow metadata"
            FileName = "DesktopFlow-02020202-0202-0202-0202-020202020202.json"
            Expected = "Desktop"
        }
        @{
            Name = "desktop workflow category"
            FileName = "DesktopFlowByCategory-03030303-0303-0303-0303-030303030303.json"
            Expected = "Desktop"
        }
        @{
            Name = "desktop workflow UIFlowType"
            FileName = "DesktopFlowByUiFlowType-04040404-0404-0404-0404-040404040404.json"
            Expected = "Desktop"
        }
        @{
            Name = "malformed JSON with desktop metadata"
            FileName = "DesktopFlowMalformedJson-05050505-0505-0505-0505-050505050505.json"
            Expected = "Desktop"
        }
        @{
            Name = "unclassified flow JSON"
            FileName = "UnknownFlow-06060606-0606-0606-0606-060606060606.json"
            Expected = "Unknown"
        }
        @{
            Name = "invalid companion XML"
            FileName = "InvalidDesktopFlow-07070707-0707-0707-0707-070707070707.json"
            Expected = "Unknown"
        }
    )

    BeforeAll {
        $script:flowTypeEdgePath = (Resolve-Path (Join-Path $PSScriptRoot "..\fixtures\flow-type-edge\Managed\Workflows")).Path
    }

    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {}
    }

  Context "Classification" {
        It "classifies flows from JSON/XML fixtures" -TestCases $classificationCases {
          param($Name, $FileName, $Expected)

          $flowPath = Join-Path $script:flowTypeEdgePath $FileName

            $flowType = Get-PowerPlatformCheckerFlowType -Path $flowPath -WarningAction SilentlyContinue

            $flowType | Should -Be $Expected
        }

        It "returns Unknown when path does not exist" {
                    $warnings = @()
                      $flowType = Get-PowerPlatformCheckerFlowType -Path (Join-Path $script:flowTypeEdgePath "MissingFlow.json") -WarningVariable warnings -WarningAction SilentlyContinue
            $flowType | Should -Be "Unknown"
                        @($warnings).Count | Should -BeGreaterThan 0
                        (@($warnings) -join " `n") | Should -Match "file not found"
                }

                It "warns for malformed json and still classifies desktop from metadata" {
                        $warnings = @()
                        $flowPath = Join-Path $script:flowTypeEdgePath "DesktopFlowMalformedJson-05050505-0505-0505-0505-050505050505.json"

                        $flowType = Get-PowerPlatformCheckerFlowType -Path $flowPath -WarningVariable warnings -WarningAction SilentlyContinue

                        $flowType | Should -Be "Desktop"
                        (@($warnings) -join " `n") | Should -Match "Invalid flow JSON payload"
        }
    }

    Context "Telemetry" {
        It "sends telemetry without sensitive values" {
        $flowPath = Join-Path $script:flowTypeEdgePath "CloudFlow-01010101-0101-0101-0101-010101010101.json"
        $missingPath = Join-Path $script:flowTypeEdgePath "MissingFlowTelemetry.json"
        $telemetryCalls = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {
          param([string]$ModuleName, [string]$EventName, [hashtable]$PropertiesHash)
          [void]$telemetryCalls.Add([pscustomobject]@{ ModuleName = $ModuleName; EventName = $EventName; PropertiesHash = $PropertiesHash })
        }

            [void](Get-PowerPlatformCheckerFlowType -Path $flowPath -WarningAction SilentlyContinue)
            Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerFlowType" -ExpectedKeys @() -ConfidentialValues @($flowPath)

            $telemetryCalls.Clear()
            [void](Get-PowerPlatformCheckerFlowType -Path $missingPath -WarningAction SilentlyContinue)
            Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerFlowType" -ExpectedKeys @() -ConfidentialValues @($missingPath)
        }
    }
}
