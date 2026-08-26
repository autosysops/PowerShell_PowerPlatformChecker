. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerFlowParameter" {
    $desktopParameterEdgeCases = @(
        @{
            Name = "dependencies without environment variables"
            FileName = "DesktopSchemaParams-14141414-1414-1414-1414-141414141414.json"
            ExpectedCount = 0
            ExpectedSchemaName = $null
            ExcludedSchemaName = $null
        }
        @{
            Name = "metadata without inputs"
            FileName = "DesktopNoInputs-15151515-1515-1515-1515-151515151515.json"
            ExpectedCount = 0
            ExpectedSchemaName = $null
            ExcludedSchemaName = $null
        }
        @{
            Name = "dependencies override runtime-only inputs"
            FileName = "DesktopDependenciesPriority-16161616-1616-1616-1616-161616161616.json"
            ExpectedCount = 1
            ExpectedSchemaName = "ppc_api_url"
            ExcludedSchemaName = "runtime_only_input"
        }
        @{
            Name = "malformed outputs JSON"
            FileName = "DesktopMalformedOutputs-18181818-1818-1818-1818-181818181818.json"
            ExpectedCount = 1
            ExpectedSchemaName = "ppc_api_url"
            ExcludedSchemaName = $null
        }
    )

    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
        $script:desktopSolutionPath = Get-PowerPlatformCheckerDesktopFixtureSolutionPath
        $script:flowParameterEdgePath = (Resolve-Path (Join-Path $PSScriptRoot "..\fixtures\flow-parameter-edge\Managed\Workflows")).Path
        $script:flowPath = Join-Path $script:solutionPath "Workflows\SampleFlow-11111111-1111-1111-1111-111111111111.json"
        $script:desktopFlowPath = Join-Path $script:desktopSolutionPath "Workflows\DesktopFlow-77777777-7777-7777-7777-777777777777.json"
        $script:invalidFlowPath = Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..\fixtures\flow-type-edge\Managed\Workflows")).Path "InvalidDesktopFlow-07070707-0707-0707-0707-070707070707.json"
    }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "returns custom parameters only" {
        $parameters = Get-PowerPlatformCheckerFlowParameter -Path $script:flowPath
        $parameters.Count | Should -Be 1
        $parameters[0].SchemaName | Should -Be "ppc_ApiBaseUrl"
    }

    It "keeps cloud parameter contract for sample flow" {
        $parameters = Get-PowerPlatformCheckerFlowParameter -Path $script:flowPath

        $parameters[0].Name | Should -Be "Api_Base_Url (ppc_ApiBaseUrl)"
        $parameters[0].Type | Should -Be "string"
        $parameters[0].SchemaName | Should -Be "ppc_ApiBaseUrl"
    }

    It "returns desktop parameters from desktop flow fixture" {
        $parameters = Get-PowerPlatformCheckerFlowParameter -Path $script:desktopFlowPath

        $parameters.Count | Should -BeGreaterThan 0
        $desktopParameter = $parameters | Where-Object SchemaName -eq "ppc_desktop_baseurl" | Select-Object -First 1

        $desktopParameter | Should -Not -BeNullOrEmpty
        $desktopParameter.PSObject.Properties.Name | Should -Contain "Name"
        $desktopParameter.PSObject.Properties.Name | Should -Contain "Type"
        $desktopParameter.PSObject.Properties.Name | Should -Contain "SchemaName"
        $desktopParameter.Type | Should -Be "string"
    }

    It "handles desktop parameter edge cases" -TestCases $desktopParameterEdgeCases {
        param($Name, $FileName, $ExpectedCount, $ExpectedSchemaName, $ExcludedSchemaName)

        $flowPath = Join-Path $script:flowParameterEdgePath $FileName

        $parameters = Get-PowerPlatformCheckerFlowParameter -Path $flowPath

        @($parameters).Count | Should -Be $ExpectedCount
        if ($null -ne $ExpectedSchemaName) {
            $parameters[0].SchemaName | Should -Be $ExpectedSchemaName
        }
        if ($null -ne $ExcludedSchemaName) {
            ($parameters | Select-Object -ExpandProperty SchemaName) | Should -Not -Contain $ExcludedSchemaName
        }
    }

    It "returns empty parameters and warns for invalid flow input" {
        $warnings = @()
        $parameters = Get-PowerPlatformCheckerFlowParameter -Path $script:invalidFlowPath -WarningVariable warnings -WarningAction SilentlyContinue

        @($parameters).Count | Should -Be 0
        (@($warnings) -join " `n") | Should -Match "Invalid flow input"
    }

    It "sends invocation telemetry without result data" {
        $telemetryCalls = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {
            param([string]$ModuleName, [string]$EventName, [hashtable]$PropertiesHash)
            [void]$telemetryCalls.Add([pscustomobject]@{ ModuleName = $ModuleName; EventName = $EventName; PropertiesHash = $PropertiesHash })
        }

        [void](Get-PowerPlatformCheckerFlowParameter -Path $script:desktopFlowPath)
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerFlowParameter" -ExpectedKeys @() -ConfidentialValues @($script:desktopFlowPath)

        $telemetryCalls.Clear()
        [void](Get-PowerPlatformCheckerFlowParameter -Path $script:flowPath)
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerFlowParameter" -ExpectedKeys @() -ConfidentialValues @($script:flowPath)
    }
}

