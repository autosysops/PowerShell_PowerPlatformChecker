. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerFlowTriggerMode" {
    $triggerModeCases = @(
        @{
            Name = "recurrence trigger"
            Actions = @([pscustomobject]@{ IsTrigger = $true; Type = "Recurrence"; Group = "*" })
            ExpectedMode = "Polling"
        }
        @{
            Name = "webhook trigger"
            Actions = @([pscustomobject]@{ IsTrigger = $true; Type = "SubscribeWebhookTrigger"; Group = "shared_commondataserviceforapps" })
            ExpectedMode = "Webhook"
        }
        @{
            Name = "manual request trigger"
            Actions = @([pscustomobject]@{ IsTrigger = $true; Type = "Request"; Group = "*" })
            ExpectedMode = "ManualHttp"
        }
        @{
            Name = "unknown trigger"
            Actions = @([pscustomobject]@{ IsTrigger = $true; Type = "CustomTrigger"; Group = "*" })
            ExpectedMode = "Unknown"
        }
        @{
            Name = "no trigger action"
            Actions = @([pscustomobject]@{ IsTrigger = $false; Type = "Compose"; Group = "*" })
            ExpectedMode = "Unknown"
        }
    )

    It "classifies trigger mode for <Name>" -TestCases $triggerModeCases {
        param($Name, $Actions, $ExpectedMode)

        InModuleScope PowerPlatformChecker {
            param($InnerActions)

            Get-PowerPlatformCheckerFlowTriggerMode -Actions $InnerActions
        } -Parameters @{
            InnerActions = $Actions
        } | Should -Be $ExpectedMode
    }
}
