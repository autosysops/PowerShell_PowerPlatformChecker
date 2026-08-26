. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "ConvertTo-PowerPlatformCheckerDesktopDefinitionSegmentList" {
    $tripleQuotedDefinition = @"
External.InvokeCloudConnector OperationId: 'SendEmailV2' @'emailMessage/Body': $'''Line one
Line two
Line three'''
Logging.LogMessage Message: 'Done'
"@

    $escapedSelectorDefinition = @"
WAIT (WebAutomation.WaitForWebPageContent.WebPageToContainElement BrowserInstance: Browser Control: appmask['Web Page \\'h ... eload=true\\' 2']['Input password  ... elecom.com\\''])
WebAutomation.Focus.Focus BrowserInstance: Browser
WRITE Text='Done'
"@

    It "splits desktop definitions into expected segments" -ForEach @(
        @{
            Name = 'blank definitions'
            Definition = '   '
            ExpectedSegments = @()
        }
        @{
            Name = 'semicolon-delimited statements outside quoted literals'
            Definition = "DISPLAY Message='Bob''s; note';WRITE Text='ok'"
            ExpectedSegments = @("DISPLAY Message='Bob''s; note'", "WRITE Text='ok'")
        }
        @{
            Name = 'multiline triple-single-quoted payloads'
            Definition = $tripleQuotedDefinition
            ExpectedSegments = @(
                "External.InvokeCloudConnector OperationId: 'SendEmailV2' @'emailMessage/Body': $'''Line one`nLine two`nLine three'''"
                "Logging.LogMessage Message: 'Done'"
            )
        }
        @{
            Name = 'newline-separated statements'
            Definition = "DISPLAY Message='x'`n`nWRITE Text='y'"
            ExpectedSegments = @("DISPLAY Message='x'", "WRITE Text='y'")
        }
        @{
            Name = 'escaped selector literals with trailing commands'
            Definition = $escapedSelectorDefinition
            ExpectedSegments = @(
                "WAIT (WebAutomation.WaitForWebPageContent.WebPageToContainElement BrowserInstance: Browser Control: appmask['Web Page \\'h ... eload=true\\' 2']['Input password  ... elecom.com\\''])"
                "WebAutomation.Focus.Focus BrowserInstance: Browser"
                "WRITE Text='Done'"
            )
        }
    ) {
        InModuleScope PowerPlatformChecker {
            $segments = ConvertTo-PowerPlatformCheckerDesktopDefinitionSegmentList -Definition $Definition

            $segments | Should -Be $ExpectedSegments
        }
    }
}
