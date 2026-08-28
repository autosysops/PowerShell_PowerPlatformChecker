Describe "Get-PowerPlatformCheckerTriggerAuthenticationDescription" {
    $cases = @(
        @{ Name = 'Tenant'; AuthType = 'Tenant'; Expected = 'Any user in my tenant' }
        @{ Name = 'Anyone'; AuthType = 'Anyone'; Expected = 'Anyone' }
        @{ Name = 'SpecificAccounts'; AuthType = 'SpecificAccounts'; Expected = 'Specific users in my tenant' }
        @{ Name = 'Unknown fallback'; AuthType = 'MyCustomAuth'; Expected = 'MyCustomAuth' }
        @{ Name = 'Empty'; AuthType = ''; Expected = '' }
    )

    It "maps <Name>" -TestCases $cases {
        param($AuthType, $Expected)

        InModuleScope PowerPlatformChecker {
            param($InnerAuthType)
            Get-PowerPlatformCheckerTriggerAuthenticationDescription -AuthenticationType $InnerAuthType
        } -Parameters @{ InnerAuthType = $AuthType } | Should -Be $Expected
    }
}
