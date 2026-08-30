. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Convert-PowerPlatformCheckerArchitectureEdgeToMermaid" {
    It "renders flowchart references with Mermaid-safe labels" {
        InModuleScope PowerPlatformChecker {
            $edge = [pscustomobject]@{
                SourceId = 'A'
                TargetId = 'B'
                Label = 'Label:Raw'
                EdgeType = 'Reference'
                Metadata = [pscustomobject]@{ MermaidLabel = 'Do|Thing:(x)'; Arrow = '..>' }
            }

            $result = Convert-PowerPlatformCheckerArchitectureEdgeToMermaid -Edge $edge -DiagramKind Flowchart
            $result | Should -Be 'A -.->|Do/Thing x| B'
        }
    }

    It "renders classDiagram edges with label suffix" {
        InModuleScope PowerPlatformChecker {
            $edge = [pscustomobject]@{
                SourceId = 'Flow1'
                TargetId = 'Conn1'
                Label = 'Uses'
                EdgeType = 'Association'
                Metadata = [pscustomobject]@{ Arrow = '-->' }
            }

            $result = Convert-PowerPlatformCheckerArchitectureEdgeToMermaid -Edge $edge -DiagramKind ClassDiagram
            $result | Should -Be 'Flow1 --> Conn1:Uses'
        }
    }
}
