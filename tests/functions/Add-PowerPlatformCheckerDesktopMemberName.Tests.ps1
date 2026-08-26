. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Add-PowerPlatformCheckerDesktopMemberName" {
    It "adds unique trimmed member names only once" {
        InModuleScope PowerPlatformChecker {
            $names = [System.Collections.Generic.List[string]]::new()
            $seen = [System.Collections.Generic.HashSet[string]]::new()

            Add-PowerPlatformCheckerDesktopMemberName -MemberNames $names -SeenMemberNames $seen -Name '  var_Input  '
            Add-PowerPlatformCheckerDesktopMemberName -MemberNames $names -SeenMemberNames $seen -Name 'var_Input'
            Add-PowerPlatformCheckerDesktopMemberName -MemberNames $names -SeenMemberNames $seen -Name ''

            @($names) | Should -Be @('var_Input')
        }
    }
}
