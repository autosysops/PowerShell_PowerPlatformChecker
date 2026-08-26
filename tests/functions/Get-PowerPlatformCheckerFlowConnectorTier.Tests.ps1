. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerFlowConnectorTier" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
        $script:desktopSolutionPath = Get-PowerPlatformCheckerDesktopFixtureSolutionPath
        $script:connectorTierEdgePath = (Resolve-Path (Join-Path $PSScriptRoot "..\fixtures\connector-tier-edge\Managed\Workflows")).Path
        $script:flowPath = Join-Path $script:solutionPath "Workflows\SampleFlow-11111111-1111-1111-1111-111111111111.json"
        $script:desktopFlowPath = Join-Path $script:desktopSolutionPath "Workflows\DesktopFlow-77777777-7777-7777-7777-777777777777.json"
        $script:desktopManifestFlowPath = Join-Path $script:desktopSolutionPath "Workflows\DesktopFlow-99999999-9999-9999-9999-999999999999.json"
        $script:desktopFallbackMapFlowPath = Join-Path $script:connectorTierEdgePath "DesktopFallbackMap-12121212-1212-1212-1212-121212121212.json"
        $script:desktopFallbackArrayFlowPath = Join-Path $script:connectorTierEdgePath "DesktopFallbackArray-13131313-1313-1313-1313-131313131313.json"
        $script:connectorFallbackFlowPath = Join-Path $script:connectorTierEdgePath "ConnectorFallbackFlow-24242424-2424-2424-2424-242424242424.json"
        $script:invalidFlowPath = Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..\fixtures\flow-type-edge\Managed\Workflows")).Path "InvalidDesktopFlow-07070707-0707-0707-0707-070707070707.json"
    }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "returns connector tiers" {
        $tiers = Get-PowerPlatformCheckerFlowConnectorTier -Path $script:flowPath
        $tiers.Count | Should -Be 2
        ($tiers | Where-Object Name -eq "shared_office365").Tier | Should -Be "Standard"
    }

    It "keeps cloud connector contract for sample flow" {
        $tiers = Get-PowerPlatformCheckerFlowConnectorTier -Path $script:flowPath

        ($tiers | Select-Object -ExpandProperty Name | Sort-Object) | Should -Be @("shared_commondataserviceforapps", "shared_office365")
    }

    It "returns desktop connector tiers from desktop flow fixture" {
        $tiers = Get-PowerPlatformCheckerFlowConnectorTier -Path $script:desktopFlowPath

        ($tiers | Select-Object -ExpandProperty Name) | Should -Contain "shared_desktopautomation"
        ($tiers | Where-Object Name -eq "shared_desktopautomation" | Select-Object -First 1).Tier | Should -Be "Premium"
    }

    It "falls back to desktop metadata connectionReferences object map" {
                $tiers = Get-PowerPlatformCheckerFlowConnectorTier -Path $script:desktopFallbackMapFlowPath -Connector "shared_map*"

                $tiers.Count | Should -Be 1
                $tiers[0].Name | Should -Be "shared_mapconnector"
                $tiers[0].Tier | Should -Be "Standard"
        }

    It "falls back to desktop metadata connectionReferences array" {
                $tiers = Get-PowerPlatformCheckerFlowConnectorTier -Path $script:desktopFallbackArrayFlowPath -Connector "shared_array*"

                $tiers.Count | Should -Be 1
                $tiers[0].Name | Should -Be "shared_arrayconnector"
                $tiers[0].DisplayName | Should -Be "Array Connector"
                $tiers[0].Tier | Should -Be "Premium"
        }

    It "falls back from api name to connector key when catalog lookup misses" {
                Mock -CommandName Get-PowerPlatformCheckerConnectorData -ModuleName PowerPlatformChecker -ParameterFilter { $Name -eq "dynamicssmbsaas" } { return $null }
                Mock -CommandName Get-PowerPlatformCheckerConnectorData -ModuleName PowerPlatformChecker -ParameterFilter { $Name -eq "shared_dynamicssmbsaas" } {
                        [pscustomobject]@{ name = "shared_dynamicssmbsaas"; displayname = "Dynamics 365 Business Central"; tier = "Premium" }
                }

                $tiers = Get-PowerPlatformCheckerFlowConnectorTier -Path $script:connectorFallbackFlowPath

                $tiers.Count | Should -Be 1
                $tiers[0].DisplayName | Should -Be "Dynamics 365 Business Central"
                $tiers[0].Tier | Should -Be "Premium"
        }

    It "resolves desktop manifest connection references to known connector tiers" {
        $tiers = Get-PowerPlatformCheckerFlowConnectorTier -Path $script:desktopManifestFlowPath

        $tiers.Count | Should -BeGreaterThan 0
        ($tiers | Select-Object -ExpandProperty Name) | Should -Contain "shared_office365"
        ($tiers | Where-Object Name -eq "shared_office365" | Select-Object -First 1).Tier | Should -Be "Standard"
    }

    It "returns empty tiers and warns for invalid flow input" {
        $warnings = @()
        $tiers = Get-PowerPlatformCheckerFlowConnectorTier -Path $script:invalidFlowPath -WarningVariable warnings -WarningAction SilentlyContinue

        @($tiers).Count | Should -Be 0
        (@($warnings) -join " `n") | Should -Match "Invalid flow input"
    }

    It "sends sanitized telemetry for filtered and unfiltered connector lookup" {
        $telemetryCalls = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {
            param([string]$ModuleName, [string]$EventName, [hashtable]$PropertiesHash)
            [void]$telemetryCalls.Add([pscustomobject]@{ ModuleName = $ModuleName; EventName = $EventName; PropertiesHash = $PropertiesHash })
        }

        $secretConnector = "secret_connector"
        [void](Get-PowerPlatformCheckerFlowConnectorTier -Path $script:flowPath -Connector $secretConnector)
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerFlowConnectorTier" -ExpectedKeys @("ConnectorFiltered") -ConfidentialValues @($script:flowPath, $secretConnector)

        $telemetryCalls.Clear()
        [void](Get-PowerPlatformCheckerFlowConnectorTier -Path $script:flowPath)
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerFlowConnectorTier" -ExpectedKeys @("ConnectorFiltered") -ConfidentialValues @($script:flowPath)
    }
}

