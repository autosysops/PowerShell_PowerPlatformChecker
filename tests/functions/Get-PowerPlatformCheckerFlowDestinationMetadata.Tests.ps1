. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerFlowDestinationProfile" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
        $script:sampleFlowPath = Join-Path $script:solutionPath "Workflows\SampleFlow-11111111-1111-1111-1111-111111111111.json"
    }

    It "extracts destination domain from flow parameter defaults" {
        $actions = @(
            [pscustomobject]@{ Name = "Create_orderline"; Type = "CreateRecord"; Group = "shared_commondataserviceforapps"; IsTrigger = $false; Entities = @("ppc_orderlines") }
        )

        InModuleScope PowerPlatformChecker {
            param($Path, $InnerActions)
            Get-PowerPlatformCheckerFlowDestinationProfile -Path $Path -Actions $InnerActions
        } -Parameters @{ Path = $script:sampleFlowPath; InnerActions = $actions } | ForEach-Object {
            $_.Destination | Should -Be "api.example.test"
            $_.DestinationType | Should -Be "Domain"
            $_.DestinationConfidence | Should -Be "High"
            $_.DestinationEvidence | Should -Be "FlowParameterDefault"
        }
    }

    It "falls back to dataverse entity destination when no URL destination exists" {
        $actions = @(
            [pscustomobject]@{ Name = "Create_orderline"; Type = "CreateRecord"; Group = "shared_commondataserviceforapps"; IsTrigger = $false; Entities = @("ppc_orderlines") }
        )

        InModuleScope PowerPlatformChecker {
            param($InnerActions)
            Get-PowerPlatformCheckerFlowDestinationProfile -Actions $InnerActions
        } -Parameters @{ InnerActions = $actions } | ForEach-Object {
            $_.Destination | Should -Be "ppc_orderlines"
            $_.DestinationType | Should -Be "DataverseEntity"
            $_.DestinationConfidence | Should -Be "Medium"
            $_.DestinationEvidence | Should -Be "ActionEntity"
        }
    }

    It "falls back to connector service destination when only connector group is known" {
        $actions = @(
            [pscustomobject]@{ Name = "Notify"; Type = "SendEmailV2"; Group = "shared_office365"; IsTrigger = $false; Entities = @() }
        )

        InModuleScope PowerPlatformChecker {
            param($InnerActions)
            Get-PowerPlatformCheckerFlowDestinationProfile -Actions $InnerActions
        } -Parameters @{ InnerActions = $actions } | ForEach-Object {
            $_.Destination | Should -Be "office365"
            $_.DestinationType | Should -Be "Service"
            $_.DestinationConfidence | Should -Be "Low"
            $_.DestinationEvidence | Should -Be "ConnectorGroup"
        }
    }
}
