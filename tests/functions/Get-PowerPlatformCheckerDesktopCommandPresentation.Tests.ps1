. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerDesktopCommandPresentation" {
    $cases = @(
        @{
            Name = 'CALL labels with the called target'
            CommandName = 'CALL'
            Segment = 'CALL Subflow_SendErrorEmail'
            ExpectedType = 'Call'
            ExpectedDisplay = 'CALL Subflow_SendErrorEmail'
        }
        @{
            Name = 'WAIT duration labels'
            CommandName = 'WAIT'
            Segment = 'WAIT 5'
            ExpectedType = 'Wait'
            ExpectedDisplay = 'WAIT for 5 seconds'
        }
        @{
            Name = 'known web wait labels'
            CommandName = 'WAIT'
            Segment = 'WAIT (WebAutomation.WaitForWebPageContent.WebPageToContainElement BrowserInstance: Browser)'
            ExpectedType = 'Wait'
            ExpectedDisplay = 'WAIT for web page content (contain element)'
        }
        @{
            Name = 'unknown web wait labels'
            CommandName = 'WAIT'
            Segment = 'WAIT (WebAutomation.WaitForWebPageContent.WebPageToHaveRainbow BrowserInstance: Browser)'
            ExpectedType = 'Wait'
            ExpectedDisplay = 'WAIT for web page content'
        }
        @{
            Name = 'plain WAIT fallback'
            CommandName = 'WAIT'
            Segment = 'WAIT something unexpected'
            ExpectedType = 'Wait'
            ExpectedDisplay = 'WAIT'
        }
        @{
            Name = 'connector operation labels'
            CommandName = 'External.InvokeCloudConnector'
            Segment = "External.InvokeCloudConnector ConnectorId: '/providers/Microsoft.PowerApps/apis/shared_office365' OperationId: 'SendEmailV2'"
            ExpectedType = 'External.InvokeCloudConnector'
            ExpectedDisplay = 'External.InvokeCloudConnector (shared_office365.SendEmailV2)'
        }
        @{
            Name = 'connector labels with only the operation id'
            CommandName = 'External.InvokeCloudConnector'
            Segment = "External.InvokeCloudConnector OperationId: 'SendEmailV2'"
            ExpectedType = 'External.InvokeCloudConnector'
            ExpectedDisplay = 'External.InvokeCloudConnector (SendEmailV2)'
        }
        @{
            Name = 'connector labels with only the connector id'
            CommandName = 'External.InvokeCloudConnector'
            Segment = "External.InvokeCloudConnector ConnectorId: '/providers/Microsoft.PowerApps/apis/shared_office365'"
            ExpectedType = 'External.InvokeCloudConnector'
            ExpectedDisplay = 'External.InvokeCloudConnector (shared_office365)'
        }
    )

    It "formats desktop command labels for <Name>" -TestCases $cases {
        param($Name, $CommandName, $Segment, $ExpectedType, $ExpectedDisplay)

        $presentation = InModuleScope PowerPlatformChecker {
            param($InnerCommandName, $InnerSegment)

            Get-PowerPlatformCheckerDesktopCommandPresentation -CommandName $InnerCommandName -Segment $InnerSegment
        } -Parameters @{
            InnerCommandName = $CommandName
            InnerSegment = $Segment
        }

        $presentation.ActionType | Should -Be $ExpectedType -Because $Name
        $presentation.DisplayName | Should -Be $ExpectedDisplay -Because $Name
    }
}
