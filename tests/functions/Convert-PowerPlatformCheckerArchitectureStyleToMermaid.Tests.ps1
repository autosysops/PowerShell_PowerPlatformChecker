. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Convert-PowerPlatformCheckerArchitectureStyleToMermaid" {
    It "renders classDef style lines" {
        InModuleScope PowerPlatformChecker {
            $result = Convert-PowerPlatformCheckerArchitectureStyleToMermaid -StyleName 'Flow' -StyleValue 'fill:#DBE4EE,stroke:#111111'
            $result | Should -Be 'classDef Flow fill:#DBE4EE,stroke:#111111'
        }
    }
}
