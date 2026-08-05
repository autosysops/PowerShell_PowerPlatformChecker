. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Convert-PowerPlatformCheckerMermaidToGraph" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
    }

    It "parses nodes edges and styles from a mermaid class diagram" {
        InModuleScope PowerPlatformChecker {
            $mermaid = @"
:::mermaid
classDiagram
class app[""My App""]:::ModelDrivenApp
class accounts[""account""]:::Entity
app --> accounts:Entity
classDef Entity fill:#B56784,stroke:#5E5B52
:::
"@

            $graph = Convert-PowerPlatformCheckerMermaidToGraph -MermaidText $mermaid

            @($graph.Nodes).Count | Should -Be 2
            @($graph.Edges).Count | Should -Be 1
            @($graph.Nodes | Where-Object { $_.Id -eq "app" }).Count | Should -Be 1
            @($graph.Edges | Where-Object { $_.SourceId -eq "app" -and $_.TargetId -eq "accounts" -and $_.Label -eq "Entity" }).Count | Should -Be 1
            $graph.Styles.Entity | Should -Be "fill:#B56784,stroke:#5E5B52"
        }
    }

    It "deduplicates repeated node declarations" {
        InModuleScope PowerPlatformChecker {
            $mermaid = @"
classDiagram
class a[""A""]:::Entity
class a[""A""]:::Entity
a --> b:Link
class b[""B""]:::DefaultEntity
"@
            $graph = Convert-PowerPlatformCheckerMermaidToGraph -MermaidText $mermaid
            @($graph.Nodes | Where-Object { $_.Id -eq "a" }).Count | Should -Be 1
        }
    }
}
