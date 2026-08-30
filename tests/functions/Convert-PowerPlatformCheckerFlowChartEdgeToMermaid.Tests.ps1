. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Convert-PowerPlatformCheckerFlowChartEdgeToMermaid" {
    It "renders unlabeled edges with default arrow" {
        InModuleScope PowerPlatformChecker {
            $edge = [pscustomobject]@{ From = 'A1'; To = 'A2'; Label = '' }
            $result = Convert-PowerPlatformCheckerFlowChartEdgeToMermaid -Edge $edge
            $result | Should -Be 'A1 --> A2'
        }
    }

    It "renders labeled edges with inline text" {
        InModuleScope PowerPlatformChecker {
            $edge = [pscustomobject]@{ From = 'A1'; To = 'A2'; Label = 'Yes' }
            $result = Convert-PowerPlatformCheckerFlowChartEdgeToMermaid -Edge $edge
            $result | Should -Be 'A1 -- Yes --> A2'
        }
    }
}
