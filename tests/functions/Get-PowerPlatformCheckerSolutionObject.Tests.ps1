. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerSolutionObject" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
    }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "returns all expected sections" {
        $solution = Get-PowerPlatformCheckerSolutionObject -SolutionPath $script:solutionPath

        $solution.Workflows.Count | Should -Be 2
        $solution.EnvironmentVariables.Count | Should -Be 2
        $solution.ConnectionReferences.Count | Should -Be 3
        $solution.Entities.Count | Should -Be 2
        $solution.CanvasApps.Count | Should -Be 1
        $solution.ModelDrivenApps.Count | Should -Be 1
        $solution.WebResources.Count | Should -Be 1
    }
}

