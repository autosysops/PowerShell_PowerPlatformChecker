. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerFlow" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
        $script:desktopSolutionPath = Get-PowerPlatformCheckerDesktopFixtureSolutionPath
        $script:desktopFlowChartSolutionPath = (Resolve-Path (Join-Path $PSScriptRoot "..\fixtures\desktop-flowchart-solution\Managed")).Path
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
        $cloudFlows[0].PSObject.Properties.Name | Should -Contain 'Subflows'
    }

    It "supports name or id based selection and property filtering" {
        $byName = @(Get-PowerPlatformCheckerFlow -SolutionPath $script:solutionPath -Name 'Sample Flow' -Properties Parameters,Trigger)
        $byId = @(Get-PowerPlatformCheckerFlow -SolutionPath $script:solutionPath -Id '22222222-2222-2222-2222-222222222222' -Properties ConnectorTiers)

        @($byName).Count | Should -Be 1
        $byName[0].PSObject.Properties.Name | Should -Contain 'Parameters'
        $byName[0].PSObject.Properties.Name | Should -Contain 'Trigger'
        $byName[0].PSObject.Properties.Name | Should -Not -Contain 'Actions'
        $byName[0].PSObject.Properties.Name | Should -Not -Contain 'ConnectorTiers'
        $byName[0].PSObject.Properties.Name | Should -Not -Contain 'Subflows'
        @($byId).Count | Should -Be 1
        $byId[0].PSObject.Properties.Name | Should -Contain 'ConnectorTiers'
        $byId[0].PSObject.Properties.Name | Should -Not -Contain 'Parameters'
        $byId[0].PSObject.Properties.Name | Should -Not -Contain 'Actions'
        $byId[0].PSObject.Properties.Name | Should -Not -Contain 'Trigger'
        $byId[0].PSObject.Properties.Name | Should -Not -Contain 'Subflows'

        $triggerRow = @($byName[0].Trigger | Select-Object -First 1)
        @($triggerRow).Count | Should -Be 1
        $triggerRow[0].PSObject.Properties.Name | Should -Contain 'TriggerAuthenticationType'
        $triggerRow[0].PSObject.Properties.Name | Should -Contain 'TriggerAuthenticationDescription'
        $triggerRow[0].PSObject.Properties.Name | Should -Contain 'TriggerOperationId'
    }

    It "returns subflow names for desktop flows when requested" {
        $desktopSubflowFlow = @(Get-PowerPlatformCheckerFlow -SolutionPath $script:desktopFlowChartSolutionPath -Name 'Desktop Subflows Flow' -Properties Subflows)

        @($desktopSubflowFlow).Count | Should -Be 1
        $desktopSubflowFlow[0].PSObject.Properties.Name | Should -Contain 'Subflows'
        $desktopSubflowFlow[0].Subflows | Should -Contain 'ProcessOrder'
        $desktopSubflowFlow[0].Subflows | Should -Contain 'SendAudit'
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