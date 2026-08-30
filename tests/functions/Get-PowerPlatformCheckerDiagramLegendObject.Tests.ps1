. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerDiagramLegendObject" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
    }

    It "builds style rows from resolved architecture style when no graph is supplied" {
        InModuleScope PowerPlatformChecker {
            $legend = Get-PowerPlatformCheckerDiagramLegendObject -DiagramType ArchitectureDiagram
            $legend.DiagramType | Should -Be 'ArchitectureDiagram'
            @($legend.StyleItems | ForEach-Object Type) | Should -Contain 'Flow'
            @($legend.StyleItems | ForEach-Object Type) | Should -Contain 'Connection'
        }
    }

    It "uses graph metadata and filters external interaction styles to used classes" {
        InModuleScope PowerPlatformChecker {
            $graph = [pscustomobject]@{
                Nodes = @(
                    [pscustomobject]@{ ClassKind = 'Flow' },
                    [pscustomobject]@{ ClassKind = 'ExternalDomain' }
                )
                Styles = [ordered]@{
                    default = 'fill:#ffffff,stroke:#111111'
                    Flow = 'fill:#000001,stroke:#111111'
                    ExternalDomain = 'fill:#000002,stroke:#111111'
                    Unused = 'fill:#000003,stroke:#111111'
                }
                StyleOrder = @('default', 'Flow', 'ExternalDomain', 'Unused')
                Metadata = [pscustomobject]@{
                    SourceAliases = @([pscustomobject]@{ Alias = 'F1'; Type = 'Flow'; DisplayName = 'Main'; SolutionName = 'Energy' })
                    ConnectorLegend = @([pscustomobject]@{ Code = 'C01'; DisplayName = 'Office 365 Outlook' })
                    LegendNotes = @('Legend note')
                }
            }

            $legend = Get-PowerPlatformCheckerDiagramLegendObject -DiagramType ExternalInteraction -Graph $graph

            @($legend.StyleItems | ForEach-Object Type) | Should -Be @('Flow', 'ExternalDomain')
            @($legend.SourceAliases).Count | Should -Be 1
            @($legend.Connectors).Count | Should -Be 1
            @($legend.Notes).Count | Should -Be 1
        }
    }
}
