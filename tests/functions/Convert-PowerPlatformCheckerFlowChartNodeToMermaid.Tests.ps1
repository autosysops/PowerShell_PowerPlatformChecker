. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Convert-PowerPlatformCheckerFlowChartNodeToMermaid" {
    It "renders trigger nodes with rounded shape" {
        InModuleScope PowerPlatformChecker {
            $node = [pscustomobject]@{ Id = 'A1'; Label = 'Start'; Shape = 'Trigger' }
            $result = Convert-PowerPlatformCheckerFlowChartNodeToMermaid -Node $node
            $result | Should -Be 'A1(["Start"])'
        }
    }

    It "renders decision nodes with diamond shape" {
        InModuleScope PowerPlatformChecker {
            $node = [pscustomobject]@{ Id = 'A2'; Label = 'Ready?'; Shape = 'Decision' }
            $result = Convert-PowerPlatformCheckerFlowChartNodeToMermaid -Node $node
            $result | Should -Be 'A2{"Ready?"}'
        }
    }

    It "renders default nodes with rectangle shape" {
        InModuleScope PowerPlatformChecker {
            $node = [pscustomobject]@{ Id = 'A3'; Label = 'Step'; Shape = 'Action' }
            $result = Convert-PowerPlatformCheckerFlowChartNodeToMermaid -Node $node
            $result | Should -Be 'A3["Step"]'
        }
    }
}
