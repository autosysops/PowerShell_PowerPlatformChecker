. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerSolutionObject" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
    }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "returns all expected sections" {
        $solution = Get-PowerPlatformCheckerSolutionObject -SolutionPath $script:solutionPath

        $solution.Workflows.Count | Should -Be 3
        $solution.EnvironmentVariables.Count | Should -Be 2
        $solution.ConnectionReferences.Count | Should -Be 3
        $solution.Entities.Count | Should -Be 5
        $solution.CanvasApps.Count | Should -Be 1
        $solution.ModelDrivenApps.Count | Should -Be 1
        $solution.WebResources.Count | Should -Be 2
    }

    It "supports property filtering while defaulting to all sections" {
        $filtered = Get-PowerPlatformCheckerSolutionObject -SolutionPath $script:solutionPath -Properties Workflows,Entities

        $filtered.PSObject.Properties.Name | Should -Contain 'Workflows'
        $filtered.PSObject.Properties.Name | Should -Contain 'Entities'
        $filtered.PSObject.Properties.Name | Should -Not -Contain 'EnvironmentVariables'
        $filtered.PSObject.Properties.Name | Should -Not -Contain 'ConnectionReferences'
        $filtered.PSObject.Properties.Name | Should -Not -Contain 'CanvasApps'
        $filtered.PSObject.Properties.Name | Should -Not -Contain 'ModelDrivenApps'
        $filtered.PSObject.Properties.Name | Should -Not -Contain 'WebResources'
    }

    It "sends invocation telemetry without solution paths or result counts" {
        $telemetryCalls = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {
            param([string]$ModuleName, [string]$EventName, [hashtable]$PropertiesHash)
            [void]$telemetryCalls.Add([pscustomobject]@{ ModuleName = $ModuleName; EventName = $EventName; PropertiesHash = $PropertiesHash })
        }

        [void](Get-PowerPlatformCheckerSolutionObject -SolutionPath $script:solutionPath)
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerSolutionObject" -ExpectedKeys @() -ConfidentialValues @($script:solutionPath)
    }
}

