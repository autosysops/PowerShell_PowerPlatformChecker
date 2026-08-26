. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerCanvasDestinationProfile" {
    It "derives canvas destination from Office 365 connector reference" {
        $canvasApp = [pscustomobject]@{
            ConnectionReferences = @(
                [pscustomobject]@{ id = "/providers/Microsoft.PowerApps/apis/shared_office365" }
            )
            DataSources = [pscustomobject]@{ DataSources = @() }
        }

        InModuleScope PowerPlatformChecker {
            param($Canvas)
            Get-PowerPlatformCheckerCanvasDestinationProfile -CanvasApp $Canvas
        } -Parameters @{ Canvas = $canvasApp } | ForEach-Object {
            $_.Destination | Should -Be "office365"
            $_.DestinationType | Should -Be "Service"
            $_.DestinationConfidence | Should -Be "Low"
            $_.DestinationEvidence | Should -Be "ConnectionReference"
        }
    }

    It "falls back to unknown when no destination signal exists" {
        $canvasApp = [pscustomobject]@{
            ConnectionReferences = @()
            DataSources = [pscustomobject]@{ DataSources = @() }
        }

        InModuleScope PowerPlatformChecker {
            param($Canvas)
            Get-PowerPlatformCheckerCanvasDestinationProfile -CanvasApp $Canvas
        } -Parameters @{ Canvas = $canvasApp } | ForEach-Object {
            $_.Destination | Should -Be ""
            $_.DestinationType | Should -Be "Unknown"
            $_.DestinationConfidence | Should -Be "Low"
            $_.DestinationEvidence | Should -Be "NoDestinationSignal"
        }
    }
}
