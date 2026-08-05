. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerWebResourceType" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
    }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "returns the documented SVG icon mapping" {
        InModuleScope PowerPlatformChecker {
            $result = Get-PowerPlatformCheckerWebResourceType -Type 11

            $result.Name | Should -Be "SVG"
            $result.Kind | Should -Be "Icon"
        }
    }

    It "returns the documented HTML mapping" {
        InModuleScope PowerPlatformChecker {
            $result = Get-PowerPlatformCheckerWebResourceType -Type 1

            $result.Name | Should -Be "HTML"
            $result.Kind | Should -Be "Document"
        }
    }

    It "falls back cleanly for unknown types" {
        InModuleScope PowerPlatformChecker {
            $result = Get-PowerPlatformCheckerWebResourceType -Type 999

            $result.Name | Should -Be "Other"
            $result.Kind | Should -Be "Other"
        }
    }
}