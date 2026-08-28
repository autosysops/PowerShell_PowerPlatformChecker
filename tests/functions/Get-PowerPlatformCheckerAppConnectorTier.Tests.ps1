. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerAppConnectorTier" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
    }

    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {}
    }

    It "returns canvas app connector tiers" {
        $rows = Get-PowerPlatformCheckerAppConnectorTier -SolutionPath $script:solutionPath

        $rows.Count | Should -BeGreaterThan 0
        ($rows | Select-Object -ExpandProperty AppType -Unique) | Should -Contain "CanvasApp"
        (($rows | Select-Object -ExpandProperty AppType -Unique) -contains "Unknown") | Should -BeFalse
        ($rows | Select-Object -ExpandProperty ConnectorName) | Should -Contain "shared_commondataserviceforapps"
    }

    It "supports wildcard app filtering" {
        $allRows = @(Get-PowerPlatformCheckerAppConnectorTier -SolutionPath $script:solutionPath)
        $allRows.Count | Should -BeGreaterThan 0

        $firstName = [string]$allRows[0].AppName
        $prefixLength = [Math]::Min(8, $firstName.Length)
        $nameFilter = "{0}*" -f $firstName.Substring(0, $prefixLength)

        $rows = Get-PowerPlatformCheckerAppConnectorTier -SolutionPath $script:solutionPath -Name $nameFilter

        $rows.Count | Should -BeGreaterThan 0
        ($rows | Select-Object -ExpandProperty AppName -Unique) | Should -Contain $firstName
    }

    It "sends sanitized telemetry" {
        $telemetryCalls = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {
            param([string]$ModuleName, [string]$EventName, [hashtable]$PropertiesHash)
            [void]$telemetryCalls.Add([pscustomobject]@{ ModuleName = $ModuleName; EventName = $EventName; PropertiesHash = $PropertiesHash })
        }

        [void](Get-PowerPlatformCheckerAppConnectorTier -SolutionPath $script:solutionPath -Name "contoso_canvasapp_*")
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerAppConnectorTier" -ExpectedKeys @("AppNameFilterUsed") -ConfidentialValues @($script:solutionPath)
    }

    It "includes model-driven connectors from referenced flows" {
        $testSolution = Join-Path $TestDrive "ModelAppConnectorTier"
        Mock -CommandName Get-ChildItem -ModuleName PowerPlatformChecker -MockWith {
            @([pscustomobject]@{ BaseName = 'Flow-aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'; FullName = 'C:\mock\Flow-aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa.json' })
        }

        Mock -CommandName Get-PowerPlatformCheckerApp -ModuleName PowerPlatformChecker -MockWith {
            @([pscustomobject]@{ AppType = 'ModelDrivenApp'; Name = 'model_app_1'; DisplayName = 'Model App 1'; FlowIds = @('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') })
        }
        Mock -CommandName Get-PowerPlatformCheckerFlowConnectorTier -ModuleName PowerPlatformChecker -MockWith {
            @([pscustomobject]@{ Name = 'shared_office365'; DisplayName = 'Office 365 Outlook'; Tier = 'Standard' })
        }

        $rows = Get-PowerPlatformCheckerAppConnectorTier -SolutionPath $testSolution -Name 'model_app_*'

        $rows.Count | Should -Be 1
        $rows[0].AppType | Should -Be 'ModelDrivenApp'
        $rows[0].Source | Should -Be 'ReferencedFlow'
        $rows[0].ConnectorName | Should -Be 'shared_office365'
    }

    It "falls back from shared_ api name when direct connector lookup misses" {
        Mock -CommandName Get-PowerPlatformCheckerApp -ModuleName PowerPlatformChecker -MockWith {
            @([pscustomobject]@{
                    AppType = 'CanvasApp'
                    Name = 'canvas_1'
                    DisplayName = 'Canvas 1'
                    ConnectionReferences = @([pscustomobject]@{ id = 'shared_customapi'; displayName = 'Custom API' })
                })
        }
        Mock -CommandName Get-PowerPlatformCheckerConnectorData -ModuleName PowerPlatformChecker -ParameterFilter { $Name -eq 'shared_customapi' } { $null }
        Mock -CommandName Get-PowerPlatformCheckerConnectorData -ModuleName PowerPlatformChecker -ParameterFilter { $Name -eq 'customapi' } {
            [pscustomobject]@{ displayname = 'Custom API'; tier = 'Premium' }
        }

        $rows = Get-PowerPlatformCheckerAppConnectorTier -SolutionPath $script:solutionPath

        ($rows | Where-Object ConnectorName -eq 'shared_customapi').Count | Should -Be 1
        ($rows | Where-Object ConnectorName -eq 'shared_customapi' | Select-Object -First 1).Tier | Should -Be 'Premium'
    }

    It "ignores null and non-matching app entries gracefully" {
        Mock -CommandName Get-ChildItem -ModuleName PowerPlatformChecker -MockWith { @() }
        Mock -CommandName Get-PowerPlatformCheckerApp -ModuleName PowerPlatformChecker -MockWith {
            @(
                [pscustomobject]@{ AppType = 'CanvasApp'; Name = 'nonmatch'; DisplayName = 'nonmatch'; ConnectionReferences = @([pscustomobject]@{ id = ''; displayName = 'Empty' }) }
            )
        }

        $rows = Get-PowerPlatformCheckerAppConnectorTier -SolutionPath $script:solutionPath -Name 'expected_*'

        @($rows).Count | Should -Be 0
    }

    It "normalizes /apis/ connector ids and falls back to reference display names" {
        Mock -CommandName Get-ChildItem -ModuleName PowerPlatformChecker -MockWith { @() }
        Mock -CommandName Get-PowerPlatformCheckerApp -ModuleName PowerPlatformChecker -MockWith {
            @([pscustomobject]@{
                    AppType = 'CanvasApp'
                    Name = 'expected_canvas'
                    DisplayName = 'Expected Canvas'
                    ConnectionReferences = @([pscustomobject]@{ id = '/providers/Microsoft.PowerApps/apis/shared_customapi2'; displayName = 'Custom API 2' })
                })
        }
        Mock -CommandName Get-PowerPlatformCheckerConnectorData -ModuleName PowerPlatformChecker -MockWith { $null }

        $rows = Get-PowerPlatformCheckerAppConnectorTier -SolutionPath $script:solutionPath -Name 'expected_*'

        $rows.Count | Should -Be 1
        $rows[0].ConnectorName | Should -Be 'shared_customapi2'
        $rows[0].ConnectorDisplayName | Should -Be 'Custom API 2'
        $rows[0].Tier | Should -Be ''
    }
}
