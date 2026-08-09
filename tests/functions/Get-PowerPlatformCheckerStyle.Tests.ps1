. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerStyle" {
    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {}
    }

    It "returns style values as a hashtable" {
        $style = Get-PowerPlatformCheckerStyle -StyleTarget ArchitectureDiagram

        $style.GetType().Name | Should -Be "Hashtable"
        $style.ContainsKey("Flow") | Should -BeTrue
        $style.ContainsKey("Stroke") | Should -BeTrue
    }

    It "returns expected key values directly" {
        $style = Get-PowerPlatformCheckerStyle -StyleTarget ArchitectureDiagram

        $style.Flow | Should -Not -BeNullOrEmpty
        $style.Stroke | Should -Be "#5E5B52"
    }
}