. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerAppType" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
        $script:canvasMetaPath = (Get-ChildItem -Path (Join-Path $script:solutionPath "CanvasApps") -Filter "*.meta.xml" -File | Select-Object -First 1 -ExpandProperty FullName)
        $script:modelAppPath = (Get-ChildItem -Path (Join-Path $script:solutionPath "AppModules") -Recurse -Filter "AppModule*.xml" -File | Select-Object -First 1 -ExpandProperty FullName)
    }

    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {}
    }

    It "detects app type from file path" {
        (Get-PowerPlatformCheckerAppType -Path $script:canvasMetaPath) | Should -Be "CanvasApp"
        (Get-PowerPlatformCheckerAppType -Path $script:modelAppPath) | Should -Be "ModelDrivenApp"
        (Get-PowerPlatformCheckerAppType -Path (Join-Path $script:solutionPath "Workflows\SampleFlow-11111111-1111-1111-1111-111111111111.json") -WarningAction SilentlyContinue) | Should -Be "Unknown"
    }

    It "returns Unknown for non-app file paths" {
        $warnings = @()
        (Get-PowerPlatformCheckerAppType -Path (Join-Path $script:solutionPath "Other\Customizations.xml") -WarningVariable warnings -WarningAction SilentlyContinue) | Should -Be "Unknown"
        @($warnings).Count | Should -BeGreaterThan 0
        (@($warnings) -join " `n") | Should -Match "Invalid app metadata path"
    }

    It "returns Unknown and warns for missing paths" {
        $missingPath = Join-Path $script:solutionPath "CanvasApps\missing.meta.xml"
        $warnings = @()

        (Get-PowerPlatformCheckerAppType -Path $missingPath -WarningVariable warnings -WarningAction SilentlyContinue) | Should -Be "Unknown"
        @($warnings).Count | Should -BeGreaterThan 0
        (@($warnings) -join " `n") | Should -Match "file not found"
    }

    It "returns Unknown and warns for blank paths" {
        $warnings = @()

        (Get-PowerPlatformCheckerAppType -Path "   " -WarningVariable warnings -WarningAction SilentlyContinue) | Should -Be "Unknown"
        (@($warnings) -join " `n") | Should -Match "Invalid app path"
    }

    It "sends sanitized telemetry" {
        $telemetryCalls = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {
            param([string]$ModuleName, [string]$EventName, [hashtable]$PropertiesHash)
            [void]$telemetryCalls.Add([pscustomobject]@{ ModuleName = $ModuleName; EventName = $EventName; PropertiesHash = $PropertiesHash })
        }

        [void](Get-PowerPlatformCheckerAppType -Path $script:canvasMetaPath)
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerAppType" -ExpectedKeys @() -ConfidentialValues @($script:canvasMetaPath)
    }
}
