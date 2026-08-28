. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerApp" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
    }

    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {}
    }

    It "returns both app types through one command with default-all properties" {
        $apps = Get-PowerPlatformCheckerApp -SolutionPath $script:solutionPath

        ($apps | Select-Object -ExpandProperty AppType) | Should -Contain 'CanvasApp'
        ($apps | Select-Object -ExpandProperty AppType) | Should -Contain 'ModelDrivenApp'

        $canvasApp = $apps | Where-Object AppType -eq 'CanvasApp' | Select-Object -First 1
        $modelApp = $apps | Where-Object AppType -eq 'ModelDrivenApp' | Select-Object -First 1

        $canvasApp.PSObject.Properties.Name | Should -Contain 'Dependencies'
        $modelApp.PSObject.Properties.Name | Should -Contain 'Dependencies'
        $canvasApp.Dependencies.PSObject.Properties.Name | Should -Contain 'Connections'
        $canvasApp.Dependencies.PSObject.Properties.Name | Should -Contain 'DataSources'
        $modelApp.Dependencies.PSObject.Properties.Name | Should -Contain 'Entities'
        $modelApp.Dependencies.PSObject.Properties.Name | Should -Contain 'Flows'
    }

    It "supports filtering and property selection" {
        $apps = Get-PowerPlatformCheckerApp -SolutionPath $script:solutionPath -Name 'ppc_*' -AppType ModelDrivenApp -Properties Dependencies

        @($apps).Count | Should -Be 1
        $apps[0].AppType | Should -Be 'ModelDrivenApp'
        $apps[0].PSObject.Properties.Name | Should -Contain 'Dependencies'
        $apps[0].PSObject.Properties.Name | Should -Not -Contain 'Entities'
        $apps[0].PSObject.Properties.Name | Should -Not -Contain 'FlowIds'
        $apps[0].PSObject.Properties.Name | Should -Not -Contain 'Description'
        $apps[0].Dependencies.PSObject.Properties.Name | Should -Contain 'Entities'
        $apps[0].Dependencies.PSObject.Properties.Name | Should -Contain 'Flows'
    }

    It "sends sanitized telemetry" {
        $telemetryCalls = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {
            param([string]$ModuleName, [string]$EventName, [hashtable]$PropertiesHash)
            [void]$telemetryCalls.Add([pscustomobject]@{ ModuleName = $ModuleName; EventName = $EventName; PropertiesHash = $PropertiesHash })
        }

        [void](Get-PowerPlatformCheckerApp -SolutionPath $script:solutionPath -Name 'secret_*' -AppType CanvasApp -Properties ConnectionReferences)
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName 'Get-PowerPlatformCheckerApp' -ExpectedKeys @('NameFilterUsed', 'AppTypeCount', 'PropertyCount') -ConfidentialValues @($script:solutionPath, 'secret_*')
    }
}