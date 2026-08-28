. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerFlow" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
        $script:desktopSolutionPath = Get-PowerPlatformCheckerDesktopFixtureSolutionPath
    }

    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {}
    }

    It "returns flow metadata with default-all properties" {
        $cloudFlows = @(Get-PowerPlatformCheckerFlow -SolutionPath $script:solutionPath)
        $desktopFlows = @(Get-PowerPlatformCheckerFlow -SolutionPath $script:desktopSolutionPath)

        ($cloudFlows | Select-Object -ExpandProperty Name) | Should -Contain 'Sample Flow'
        ($desktopFlows | Select-Object -ExpandProperty FlowType) | Should -Contain 'Desktop'
        $cloudFlows[0].PSObject.Properties.Name | Should -Contain 'Parameters'
        $cloudFlows[0].PSObject.Properties.Name | Should -Contain 'Actions'
        $cloudFlows[0].PSObject.Properties.Name | Should -Contain 'ConnectorTiers'
        $cloudFlows[0].PSObject.Properties.Name | Should -Contain 'Trigger'
    }

    It "supports name or id based selection and property filtering" {
        $byName = @(Get-PowerPlatformCheckerFlow -SolutionPath $script:solutionPath -Name 'Sample Flow' -Properties Parameters,Trigger)
        $byId = @(Get-PowerPlatformCheckerFlow -SolutionPath $script:solutionPath -Id '22222222-2222-2222-2222-222222222222' -Properties ConnectorTiers)

        @($byName).Count | Should -Be 1
        $byName[0].PSObject.Properties.Name | Should -Contain 'Parameters'
        $byName[0].PSObject.Properties.Name | Should -Contain 'Trigger'
        $byName[0].PSObject.Properties.Name | Should -Not -Contain 'Actions'
        $byName[0].PSObject.Properties.Name | Should -Not -Contain 'ConnectorTiers'
        @($byId).Count | Should -Be 1
        $byId[0].PSObject.Properties.Name | Should -Contain 'ConnectorTiers'
        $byId[0].PSObject.Properties.Name | Should -Not -Contain 'Parameters'
        $byId[0].PSObject.Properties.Name | Should -Not -Contain 'Actions'
        $byId[0].PSObject.Properties.Name | Should -Not -Contain 'Trigger'

        $triggerRow = @($byName[0].Trigger | Select-Object -First 1)
        @($triggerRow).Count | Should -Be 1
        $triggerRow[0].PSObject.Properties.Name | Should -Contain 'TriggerAuthenticationType'
        $triggerRow[0].PSObject.Properties.Name | Should -Contain 'TriggerAuthenticationDescription'
        $triggerRow[0].PSObject.Properties.Name | Should -Contain 'TriggerOperationId'
    }

    It "sends sanitized telemetry" {
        $telemetryCalls = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {
            param([string]$ModuleName, [string]$EventName, [hashtable]$PropertiesHash)
            [void]$telemetryCalls.Add([pscustomobject]@{ ModuleName = $ModuleName; EventName = $EventName; PropertiesHash = $PropertiesHash })
        }

        [void](Get-PowerPlatformCheckerFlow -SolutionPath $script:solutionPath -Name 'secret flow' -Properties Parameters,Actions)
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName 'Get-PowerPlatformCheckerFlow' -ExpectedKeys @('ParameterSet', 'NameFilterUsed', 'PropertyCount') -ConfidentialValues @($script:solutionPath, 'secret flow')
    }
}