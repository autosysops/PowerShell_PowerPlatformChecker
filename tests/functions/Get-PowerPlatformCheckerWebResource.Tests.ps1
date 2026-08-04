. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerWebResource" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
    }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "returns javascript resources and dependencies" {
        $resources = Get-PowerPlatformCheckerWebResource -SolutionPath $script:solutionPath -JavaScriptOnly

        $resources.Count | Should -Be 1
        $resources[0].Name | Should -Be "ppc_script/OrderForm.js"
        $resources[0].Type | Should -Be "JavaScript"
        $resources[0].Dependencies | Should -Contain "ppc_script/Shared.js"
    }
}

