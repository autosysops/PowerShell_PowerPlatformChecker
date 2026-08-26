. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerFlowDescription" {
    $descriptionCases = @(
        @{
            Name = "flow name"
            Parameters = @{ FlowName = "Sample Flow" }
            SolutionPath = { $script:solutionPath }
            Expected = "An anonymized test flow for architecture and flowchart output."
        }
        @{
            Name = "flow id"
            Parameters = @{ FlowId = "22222222-2222-2222-2222-222222222222" }
            SolutionPath = { $script:solutionPath }
            Expected = "Child flow used for workflow reference testing."
        }
        @{
            Name = "desktop flow id"
            Parameters = @{ FlowId = "77777777-7777-7777-7777-777777777777" }
            SolutionPath = { $script:desktopSolutionPath }
            Expected = "An anonymized desktop flow fixture for parser and diagram tests."
        }
    )

    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
        $script:desktopSolutionPath = Get-PowerPlatformCheckerDesktopFixtureSolutionPath
    }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "returns known flow descriptions" -TestCases $descriptionCases {
        param($Name, $Parameters, $SolutionPath, $Expected)

        $description = Get-PowerPlatformCheckerFlowDescription -SolutionPath (& $SolutionPath) @Parameters
        $description | Should -Be $Expected
    }

    It "returns empty string when description is missing" {
        Mock -CommandName Get-PowerPlatformCheckerFlowFile -ModuleName PowerPlatformChecker -MockWith { "C:\dummy\Flow.xml" }
        Mock -CommandName Select-Xml -ModuleName PowerPlatformChecker -MockWith {
            [pscustomobject]@{
                Node = [pscustomobject]@{}
            }
        }

        $description = Get-PowerPlatformCheckerFlowDescription -SolutionPath "C:\dummy" -FlowName "NoDescriptionFlow"

        $description | Should -Be ""
    }

    It "sends sanitized telemetry for both parameter sets" {
        $telemetryCalls = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {
            param([string]$ModuleName, [string]$EventName, [hashtable]$PropertiesHash)
            [void]$telemetryCalls.Add([pscustomobject]@{ ModuleName = $ModuleName; EventName = $EventName; PropertiesHash = $PropertiesHash })
        }

        $secretFlowName = "secret flow name"
        Mock -CommandName Get-PowerPlatformCheckerFlowFile -ModuleName PowerPlatformChecker -MockWith { "C:\dummy\Flow.xml" }
        Mock -CommandName Select-Xml -ModuleName PowerPlatformChecker -MockWith {
            [pscustomobject]@{ Node = [pscustomobject]@{ Description = "" } }
        }

        [void](Get-PowerPlatformCheckerFlowDescription -SolutionPath "C:\dummy" -FlowName $secretFlowName)
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerFlowDescription" -ExpectedKeys @("ParameterSet") -ConfidentialValues @("C:\dummy", $secretFlowName)

        $telemetryCalls.Clear()
        $secretFlowId = "secret-flow-id-telemetry"
        [void](Get-PowerPlatformCheckerFlowDescription -SolutionPath "C:\dummy" -FlowId $secretFlowId)
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerFlowDescription" -ExpectedKeys @("ParameterSet") -ConfidentialValues @("C:\dummy", $secretFlowId)
    }
}

