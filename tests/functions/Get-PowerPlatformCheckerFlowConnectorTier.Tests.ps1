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

        It "falls back from api name to connector key when catalog lookup misses" {
                $flowPath = Join-Path $TestDrive "ConnectorFallbackFlow.json"

                @'
{
    "properties": {
        "connectionReferences": {
            "shared_dynamicssmbsaas": {
                "api": {
                    "name": "dynamicssmbsaas"
                }
            }
        },
        "definition": {
            "actions": {}
        }
    }
}
'@ | Set-Content -Path $flowPath -Encoding utf8BOM

                Mock -CommandName Get-PowerPlatformCheckerConnectorData -ModuleName PowerPlatformChecker -ParameterFilter { $Name -eq "dynamicssmbsaas" } { return $null }
                Mock -CommandName Get-PowerPlatformCheckerConnectorData -ModuleName PowerPlatformChecker -ParameterFilter { $Name -eq "shared_dynamicssmbsaas" } {
                        [pscustomobject]@{ name = "shared_dynamicssmbsaas"; displayname = "Dynamics 365 Business Central"; tier = "Premium" }
                }

                $tiers = Get-PowerPlatformCheckerFlowConnectorTier -Path $flowPath

                $tiers.Count | Should -Be 1
                $tiers[0].DisplayName | Should -Be "Dynamics 365 Business Central"
                $tiers[0].Tier | Should -Be "Premium"
        }
}

