. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerFlowDescription" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
    }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "returns description by flow name" {
        $description = Get-PowerPlatformCheckerFlowDescription -SolutionPath $script:solutionPath -FlowName "Sample Flow"
        $description | Should -Be "An anonymized test flow for architecture and flowchart output."
    }

    It "returns description by flow id" {
        $description = Get-PowerPlatformCheckerFlowDescription -SolutionPath $script:solutionPath -FlowId "22222222-2222-2222-2222-222222222222"
        $description | Should -Be "Child flow used for workflow reference testing."
    }
}

