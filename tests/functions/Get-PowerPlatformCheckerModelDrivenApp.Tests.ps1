. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerModelDrivenApp" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
    }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "returns app metadata from appmodule and sitemap" {
        $apps = Get-PowerPlatformCheckerModelDrivenApp -SolutionPath $script:solutionPath

        $apps.Count | Should -Be 1
        $apps[0].UniqueName | Should -Be "ppc_ModelApp"
        $apps[0].DisplayName | Should -Be "Sales Model App"
        $apps[0].Entities | Should -Contain "ppc_order"
        $apps[0].FlowIds | Should -Contain "11111111-1111-1111-1111-111111111111"
    }
}

