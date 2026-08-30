. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerSubflowActionList" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:desktopFlowChartSolutionPath = (Resolve-Path (Join-Path $PSScriptRoot "..\fixtures\desktop-flowchart-solution\Managed")).Path
        $script:desktopSubflowPath = Join-Path $script:desktopFlowChartSolutionPath "Workflows\DesktopFlow-Subflows-99999999-9999-9999-9999-999999999999.json"
    }

    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {}
    }

    It "returns actions for a selected desktop subflow" {
        $actions = Get-PowerPlatformCheckerSubflowActionList -Path $script:desktopSubflowPath -SubflowName "ProcessOrder" -Properties RunAfter,ParentAction

        @($actions).Count | Should -Be 3
        ($actions | Select-Object -ExpandProperty Name) | Should -Contain "SET"
        ($actions | Select-Object -ExpandProperty Name) | Should -Contain "External.InvokeCloudConnector"
        ($actions | Select-Object -ExpandProperty Name) | Should -Contain "CALL"
        ($actions | Select-Object -ExpandProperty Name) | Should -Not -Contain "@INPUT"
    }

    It "returns empty output for a missing subflow name" {
        $warnings = @()
        $actions = Get-PowerPlatformCheckerSubflowActionList -Path $script:desktopSubflowPath -SubflowName "DoesNotExist" -WarningVariable warnings -WarningAction SilentlyContinue

        @($actions).Count | Should -Be 0
        (@($warnings) -join " `n") | Should -Match "subflow"
    }

    It "sends telemetry with option-only payload" {
        $telemetryCalls = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {
            param([string]$ModuleName, [string]$EventName, [hashtable]$PropertiesHash)
            [void]$telemetryCalls.Add([pscustomobject]@{ ModuleName = $ModuleName; EventName = $EventName; PropertiesHash = $PropertiesHash })
        }

        [void](Get-PowerPlatformCheckerSubflowActionList -Path $script:desktopSubflowPath -SubflowName "ProcessOrder")
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerSubflowActionList" -ExpectedKeys @("PropertyCount", "IncludeTrigger") -ConfidentialValues @("ProcessOrder", $script:desktopSubflowPath)
    }
}
