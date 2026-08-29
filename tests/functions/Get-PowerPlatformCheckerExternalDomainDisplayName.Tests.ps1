. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerExternalDomainDisplayName" {
    $displayNameCases = @(
        @{
            Name = 'empty input'
            DomainValue = ''
            ExpectedDisplayName = ''
        }
        @{
            Name = 'protocol relative input'
            DomainValue = '//portal.contoso.test/path'
            ExpectedDisplayName = 'portal.contoso.test/path'
        }
        @{
            Name = 'https input'
            DomainValue = 'https://api.contoso.test/v1/orders'
            ExpectedDisplayName = 'api.contoso.test/v1/orders'
        }
        @{
            Name = 'non-http protocol input'
            DomainValue = 'ftp://files.contoso.test/archive'
            ExpectedDisplayName = 'files.contoso.test/archive'
        }
        @{
            Name = 'already normalized input'
            DomainValue = 'contoso.sharepoint.com/sites/ops'
            ExpectedDisplayName = 'contoso.sharepoint.com/sites/ops'
        }
    )

    It "normalizes display text for <Name>" -TestCases $displayNameCases {
        param($Name, $DomainValue, $ExpectedDisplayName)

        InModuleScope PowerPlatformChecker {
            param($InnerDomainValue)

            Get-PowerPlatformCheckerExternalDomainDisplayName -DomainValue $InnerDomainValue
        } -Parameters @{
            InnerDomainValue = $DomainValue
        } | Should -Be $ExpectedDisplayName
    }
}