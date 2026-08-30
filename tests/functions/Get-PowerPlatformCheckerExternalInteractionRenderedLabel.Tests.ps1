. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerExternalInteractionRenderedLabel" {
    It "keeps compact source labels with connector code for unresolved source-kind labels" {
        InModuleScope PowerPlatformChecker {
            $parts = [pscustomobject]@{
                Kind = 'Source'
                CompactSourceAlias = 'App-01'
                SourceType = 'CanvasApp'
                SourceDisplayName = 'Learning App'
                DetailParts = @()
                Interaction = 'GET'
                DomainUnresolved = $true
                ConnectorCode = 'C01'
                ConnectorName = 'SharePoint'
            }

            $compact = Get-PowerPlatformCheckerExternalInteractionRenderedLabel -LabelParts $parts -Compact
            $compact | Should -Be 'App-01 GET C01 DomainUnresolved'
        }
    }

    It "keeps connector code but omits connector name from compact flow-action labels" {
        InModuleScope PowerPlatformChecker {
            $parts = [pscustomobject]@{
                Kind = 'FlowAction'
                CompactSourceAlias = 'Flow-01'
                SourceType = 'Flow'
                SourceDisplayName = 'Sample Flow'
                DetailParts = @()
                Interaction = 'SET'
                ActionName = 'Populate_a_Microsoft_Word_template'
                OperationName = 'Populate a Microsoft Word template'
                ConnectorName = 'Word Online Business'
                ConnectorCode = 'C03'
                Protocol = 'https'
                TriggerAuthenticationDescription = ''
                DomainUnresolved = $false
            }

            $compact = Get-PowerPlatformCheckerExternalInteractionRenderedLabel -LabelParts $parts -Compact
            $compact | Should -Be 'Flow-01 SET C03 Populate_a_Microsoft_Word_template_https'
            $compact | Should -Match '\bC03\b'
            $compact | Should -Not -Match 'Word Online Business'
        }
    }
}
