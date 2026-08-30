. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Convert-PowerPlatformCheckerArchitectureNodeToMermaid" {
    It "renders flowchart node labels and escapes double quotes" {
        InModuleScope PowerPlatformChecker {
            $node = [pscustomobject]@{ Id = 'n1'; DisplayName = 'Hello "World"'; ClassKind = 'Flow' }
            $result = Convert-PowerPlatformCheckerArchitectureNodeToMermaid -Node $node -DiagramKind Flowchart
            $result | Should -Be 'n1["Hello ''World''"]:::Flow'
        }
    }

    It "renders class diagram flow nodes with flow type prefix" {
        InModuleScope PowerPlatformChecker {
            $node = [pscustomobject]@{
                Id = 'flow1'
                DisplayName = 'My Flow'
                ClassKind = 'Flow'
                HasExplicitDisplayName = $true
                Properties = @{ FlowType = 'Cloud' }
                Members = @()
            }

            $result = Convert-PowerPlatformCheckerArchitectureNodeToMermaid -Node $node -DiagramKind ClassDiagram
            $result | Should -Be 'class flow1["[CLOUD] My Flow"]:::Flow'
        }
    }

    It "renders class diagram members when present" {
        InModuleScope PowerPlatformChecker {
            $node = [pscustomobject]@{
                Id = 'entity1'
                DisplayName = 'Entity'
                ClassKind = 'Entity'
                HasExplicitDisplayName = $true
                Properties = @{}
                Members = @('fieldA', 'fieldB')
            }

            $result = Convert-PowerPlatformCheckerArchitectureNodeToMermaid -Node $node -DiagramKind ClassDiagram
            @($result).Count | Should -Be 4
            $result[0] | Should -Be 'class entity1["Entity"]:::Entity {'
            $result[3] | Should -Be '}'
        }
    }
}
