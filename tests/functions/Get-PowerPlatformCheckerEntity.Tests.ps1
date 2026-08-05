. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerEntity" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
    }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "returns entities and relations" {
        $entities = Get-PowerPlatformCheckerEntity -SolutionPath $script:solutionPath -Relations
        $entities.Count | Should -Be 5
        ($entities | Where-Object Name -eq "ppc_Order").Relations.Count | Should -BeGreaterThan 0
        ($entities | Where-Object Name -eq "ppc_Order" | Select-Object -First 1).FormWebResources | Should -Contain "ppc_script/OrderForm.js"
        ($entities | Where-Object Name -eq "ppc_Order" | Select-Object -First 1).IconVectorName | Should -BeNullOrEmpty
        @(($entities | Where-Object Name -eq "ppc_Order" | Select-Object -First 1).IconResources).Count | Should -Be 0
        ($entities | Where-Object Name -eq "ppc_Supplier" | Select-Object -First 1).EntitySetName | Should -Be "ppc_suppliers"
    }
}

