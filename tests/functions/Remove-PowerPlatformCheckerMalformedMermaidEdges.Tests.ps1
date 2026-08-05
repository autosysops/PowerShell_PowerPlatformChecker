. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Remove-PowerPlatformCheckerMalformedMermaidEdges" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
    }

    It "removes targetless edge lines" {
        InModuleScope PowerPlatformChecker {
            $input = @"
:::mermaid
classDiagram
a -->
a --> b:ok
:::
"@
            $cleaned = Remove-PowerPlatformCheckerMalformedMermaidEdges -MermaidText $input

            $cleaned | Should -Not -Match "(?m)^a\s*-->\s*$"
            $cleaned | Should -Match "a --> b:ok"
        }
    }

    It "keeps non-edge lines untouched" {
        InModuleScope PowerPlatformChecker {
            $input = @"
class x[""X""]:::Entity
classDef Entity fill:#B56784,stroke:#5E5B52
"@
            $cleaned = Remove-PowerPlatformCheckerMalformedMermaidEdges -MermaidText $input

            $cleaned | Should -Be $input
        }
    }
}
