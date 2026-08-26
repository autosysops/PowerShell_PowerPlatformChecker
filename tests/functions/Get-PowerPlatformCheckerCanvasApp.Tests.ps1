. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerCanvasApp" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
        $script:invalidAppPath = (Resolve-Path (Join-Path $PSScriptRoot "..\fixtures\invalid-app-edge\Managed")).Path
    }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "returns canvas app metadata" {
        $apps = Get-PowerPlatformCheckerCanvasApp -SolutionPath $script:solutionPath
        $apps.Count | Should -Be 1
        $apps[0].DisplayName | Should -Be "Sales Canvas App"
        $apps[0].ConnectionReferences.Count | Should -Be 2
    }

    It "handles invalid canvas metadata fixtures gracefully" {
        $warnings = @()
        $apps = Get-PowerPlatformCheckerCanvasApp -SolutionPath $script:invalidAppPath -WarningVariable warnings -WarningAction SilentlyContinue

        @($apps).Count | Should -Be 0
        (@($warnings) -join " `n") | Should -Match "Invalid canvas app"
    }

    It "returns empty set when CanvasApps folder is missing" {
        $emptySolutionPath = Join-Path $TestDrive "NoCanvasApps"
        New-Item -Path $emptySolutionPath -ItemType Directory -Force | Out-Null

        $apps = Get-PowerPlatformCheckerCanvasApp -SolutionPath $emptySolutionPath

        @($apps).Count | Should -Be 0
    }

    It "captures invalid connection reference payload warnings" {
        $warnings = @()
        [void](Get-PowerPlatformCheckerCanvasApp -SolutionPath $script:invalidAppPath -CanvasAppDisplayName "Invalid Canvas Connection" -WarningVariable warnings -WarningAction SilentlyContinue)

        (@($warnings) -join " `n") | Should -Match "Invalid canvas app connection reference payload"
    }

    It "sends sanitized telemetry for filtered and unfiltered calls" {
        $telemetryCalls = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {
            param([string]$ModuleName, [string]$EventName, [hashtable]$PropertiesHash)
            [void]$telemetryCalls.Add([pscustomobject]@{ ModuleName = $ModuleName; EventName = $EventName; PropertiesHash = $PropertiesHash })
        }

        $secretName = "secret-canvas-app"
        [void](Get-PowerPlatformCheckerCanvasApp -SolutionPath $script:solutionPath -CanvasAppDisplayName $secretName)
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerCanvasApp" -ExpectedKeys @("CanvasAppFilterUsed") -ConfidentialValues @($script:solutionPath, $secretName)

        $telemetryCalls.Clear()
        [void](Get-PowerPlatformCheckerCanvasApp -SolutionPath $script:solutionPath)
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerCanvasApp" -ExpectedKeys @("CanvasAppFilterUsed") -ConfidentialValues @($script:solutionPath)
    }
}

