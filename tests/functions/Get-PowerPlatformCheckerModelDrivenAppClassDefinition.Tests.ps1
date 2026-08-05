. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerModelDrivenAppClassDefinition" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
    }

    It "renders compact class line when no components exist" {
        InModuleScope PowerPlatformChecker {
            $modelApp = [pscustomobject]@{
                MermaidId = "app1"
                DisplayName = "App One"
                Components = @()
            }

            $block = Get-PowerPlatformCheckerModelDrivenAppClassDefinition -ModelApp $modelApp -NewLine "`n"
            $expected = 'class app1["App One"]:::ModelDrivenApp' + "`n"
            $block | Should -Be $expected
        }
    }

    It "renders component lines using schema name or id and deduplicates lines" {
        InModuleScope PowerPlatformChecker {
            $modelApp = [pscustomobject]@{
                MermaidId = "app2"
                DisplayName = "App Two"
                Components = @(
                    [pscustomobject]@{ ComponentTypeName = "Entities"; SchemaName = "account"; Id = "" },
                    [pscustomobject]@{ ComponentTypeName = "Entities"; SchemaName = "account"; Id = "" },
                    [pscustomobject]@{ ComponentTypeName = "Sitemap"; SchemaName = ""; Id = "{abc-123}" }
                )
            }

            $block = Get-PowerPlatformCheckerModelDrivenAppClassDefinition -ModelApp $modelApp -NewLine "`n"
            $block | Should -Match 'class app2\["App Two"\]:::ModelDrivenApp \{'
            $block | Should -Match '\[Entities\]account'
            $block | Should -Match '\[Sitemap\]abc-123'
            (@($block -split "`n" | Where-Object { $_ -match '\[Entities\]account' })).Count | Should -Be 1
        }
    }
}
