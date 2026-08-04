. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerCanvasApp" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
    }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "returns canvas app metadata" {
        $apps = Get-PowerPlatformCheckerCanvasApp -SolutionPath $script:solutionPath
        $apps.Count | Should -Be 1
        $apps[0].DisplayName | Should -Be "Sales Canvas App"
        $apps[0].ConnectionReferences.Count | Should -Be 2
    }
}

