. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Convert-PowerPlatformCheckerDiagramLegendToMarkdown" {
    It "renders style rows in markdown" {
        InModuleScope PowerPlatformChecker {
            $legend = [pscustomobject]@{
                DiagramType = 'ArchitectureDiagram'
                StyleItems = @(
                    [pscustomobject]@{ Type = 'Flow'; Fill = '#DBE4EE'; Stroke = '#000000'; Style = 'fill:#DBE4EE,stroke:#000000' },
                    [pscustomobject]@{ Type = 'Entity'; Fill = ''; Stroke = '#000000'; Style = 'stroke:#000000' }
                )
                SourceAliases = @()
                Connectors = @()
                Notes = @()
            }

            $markdown = Convert-PowerPlatformCheckerDiagramLegendToMarkdown -Legend $legend
            $markdown | Should -Match '### Diagram Legend'
            $markdown | Should -Match '<span style="color:#DBE4EE">Flow</span>'
            $markdown | Should -Match '- Entity'
            $markdown | Should -Not -Match '### Connector Codes'
        }
    }

    It "renders external interaction sections and deduplicates notes" {
        InModuleScope PowerPlatformChecker {
            $legend = [pscustomobject]@{
                DiagramType = 'ExternalInteraction'
                StyleItems = @([pscustomobject]@{ Type = 'Flow'; Fill = '#DBE4EE'; Stroke = '#000000'; Style = 'fill:#DBE4EE,stroke:#000000' })
                SourceAliases = @(
                    [pscustomobject]@{ Alias = 'F2'; Type = 'Flow'; DisplayName = 'Beta'; SolutionName = 'S2' },
                    [pscustomobject]@{ Alias = 'F1'; Type = 'Flow'; DisplayName = 'Alpha'; SolutionName = 'S1' }
                )
                Connectors = @(
                    [pscustomobject]@{ Code = 'C02'; DisplayName = 'SharePoint' },
                    [pscustomobject]@{ Code = 'C01'; DisplayName = 'Office 365 Outlook' }
                )
                Notes = @('Note A', 'Note A', 'Note B')
            }

            $markdown = Convert-PowerPlatformCheckerDiagramLegendToMarkdown -Legend $legend
            $markdown | Should -Match '### Flow and App Aliases'
            $markdown | Should -Match 'F1 = Flow / Alpha \(Solution: S1\)'
            $markdown | Should -Match '### Connector Codes'
            $markdown | Should -Match 'C01 = Office 365 Outlook'
            ([regex]::Matches($markdown, 'Note A').Count) | Should -Be 1
        }
    }
}
