. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerDesktopSubflowNameList" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:desktopFlowChartSolutionPath = (Resolve-Path (Join-Path $PSScriptRoot "..\fixtures\desktop-flowchart-solution\Managed")).Path
        $script:desktopSubflowPath = Join-Path $script:desktopFlowChartSolutionPath "Workflows\DesktopFlow-Subflows-99999999-9999-9999-9999-999999999999.json"
        $script:desktopNoSubflowPath = Join-Path $script:desktopFlowChartSolutionPath "Workflows\DesktopFlow-LoopWaitCall-cccccccc-cccc-cccc-cccc-cccccccccccc.json"
    }

    It "returns ordered distinct subflow names for desktop flows" {
        $subflows = & (Get-Module PowerPlatformChecker) {
            param($Path)
            Get-PowerPlatformCheckerDesktopSubflowNameList -Path $Path
        } $script:desktopSubflowPath

        @($subflows) | Should -Be @('ProcessOrder', 'SendAudit')
    }

    It "returns empty output when no subflow declarations exist" {
        $subflows = & (Get-Module PowerPlatformChecker) {
            param($Path)
            Get-PowerPlatformCheckerDesktopSubflowNameList -Path $Path
        } $script:desktopNoSubflowPath

        @($subflows).Count | Should -Be 0
    }
}
