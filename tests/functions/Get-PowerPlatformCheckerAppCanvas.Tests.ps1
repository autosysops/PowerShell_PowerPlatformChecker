. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerCanvasApp" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
        $script:invalidAppPath = (Resolve-Path (Join-Path $PSScriptRoot "..\fixtures\invalid-app-edge\Managed")).Path
    }
    It "returns canvas app metadata" {
        InModuleScope PowerPlatformChecker {
            param($SolutionPath)
            $apps = Get-PowerPlatformCheckerCanvasApp -SolutionPath $SolutionPath
            $apps.Count | Should -Be 1
            $apps[0].DisplayName | Should -Be "Sales Canvas App"
            $apps[0].ConnectionReferences.Count | Should -Be 2
        } -Parameters @{ SolutionPath = $script:solutionPath }
    }

    It "handles invalid canvas metadata fixtures gracefully" {
        InModuleScope PowerPlatformChecker {
            param($SolutionPath)
            $warnings = @()
            $apps = Get-PowerPlatformCheckerCanvasApp -SolutionPath $SolutionPath -WarningVariable warnings -WarningAction SilentlyContinue

            @($apps).Count | Should -Be 0
            (@($warnings) -join " `n") | Should -Match "Invalid canvas app"
        } -Parameters @{ SolutionPath = $script:invalidAppPath }
    }

    It "returns empty set when CanvasApps folder is missing" {
        $emptySolutionPath = Join-Path $TestDrive "NoCanvasApps"
        New-Item -Path $emptySolutionPath -ItemType Directory -Force | Out-Null

        InModuleScope PowerPlatformChecker {
            param($SolutionPath)
            $apps = Get-PowerPlatformCheckerCanvasApp -SolutionPath $SolutionPath
            @($apps).Count | Should -Be 0
        } -Parameters @{ SolutionPath = $emptySolutionPath }
    }

    It "captures invalid connection reference payload warnings" {
        InModuleScope PowerPlatformChecker {
            param($SolutionPath)
            $warnings = @()
            [void](Get-PowerPlatformCheckerCanvasApp -SolutionPath $SolutionPath -Name "Invalid Canvas Connection" -WarningVariable warnings -WarningAction SilentlyContinue)

            (@($warnings) -join " `n") | Should -Match "Invalid canvas app connection reference payload"
        } -Parameters @{ SolutionPath = $script:invalidAppPath }
    }
}

