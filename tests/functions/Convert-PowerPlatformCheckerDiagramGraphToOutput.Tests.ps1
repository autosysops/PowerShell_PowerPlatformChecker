. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Convert-PowerPlatformCheckerDiagramGraphToOutput" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
    }

    It "returns the original graph object for Graph output" {
        InModuleScope PowerPlatformChecker {
            $graph = [pscustomobject]@{ GraphType = 'ArchitectureGraph'; Marker = 'keep' }
            $result = Convert-PowerPlatformCheckerDiagramGraphToOutput -Graph $graph -OutputFormat Graph
            $result | Should -BeExactly $graph
        }
    }

    It "routes FlowchartGraph output to flowchart Mermaid converter" {
        InModuleScope PowerPlatformChecker {
            Mock Convert-PowerPlatformCheckerFlowChartGraphToMermaid { return 'FLOW-MERMAID' }
            Mock Convert-PowerPlatformCheckerArchitectureGraphToMermaid { throw 'Unexpected architecture converter call.' }

            $graph = [pscustomobject]@{ GraphType = 'FlowchartGraph' }
            $result = Convert-PowerPlatformCheckerDiagramGraphToOutput -Graph $graph -OutputFormat Mermaid

            $result | Should -Be 'FLOW-MERMAID'
        }
    }

    It "routes non-flowchart graphs to architecture Mermaid converter" {
        InModuleScope PowerPlatformChecker {
            Mock Convert-PowerPlatformCheckerFlowChartGraphToMermaid { throw 'Unexpected flowchart converter call.' }
            Mock Convert-PowerPlatformCheckerArchitectureGraphToMermaid { return 'ARCH-MERMAID' }

            $graph = [pscustomobject]@{ Metadata = [pscustomobject]@{ Direction = 'LR' } }
            $result = Convert-PowerPlatformCheckerDiagramGraphToOutput -Graph $graph -OutputFormat Mermaid

            $result | Should -Be 'ARCH-MERMAID'
        }
    }
}
