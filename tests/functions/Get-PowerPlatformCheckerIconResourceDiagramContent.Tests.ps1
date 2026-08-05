. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerIconResourceDiagramContent" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
    }

    It "renders icon classes in non-scoped diagrams" {
        InModuleScope PowerPlatformChecker {
            $icons = @(
                [pscustomobject]@{
                    Name = "icon.svg"
                    MermaidId = "icon_svg"
                    DisplayName = "Icon"
                    Type = "SVG"
                }
            )

            $result = Get-PowerPlatformCheckerIconResourceDiagramContent -IconResources $icons -IncludeWebResources:$true -IsScopedDiagram:$false -ConnectedIconResources @() -NewLine "`n"
            $result | Should -Match 'class icon_svg\["Icon"\]:::WebResource \{'
            $result | Should -Match '\[Icon\]SVG'
        }
    }

    It "filters icons by connected set in scoped diagrams" {
        InModuleScope PowerPlatformChecker {
            $icons = @(
                [pscustomobject]@{ Name = "icon-a.svg"; MermaidId = "icon_a"; DisplayName = "Icon A"; Type = "SVG" },
                [pscustomobject]@{ Name = "icon-b.svg"; MermaidId = "icon_b"; DisplayName = "Icon B"; Type = "SVG" }
            )

            $result = Get-PowerPlatformCheckerIconResourceDiagramContent -IconResources $icons -IncludeWebResources:$true -IsScopedDiagram:$true -ConnectedIconResources @("icon-a.svg") -NewLine "`n"
            $result | Should -Match 'class icon_a\["Icon A"\]:::WebResource \{'
            $result | Should -Not -Match 'class icon_b\["Icon B"\]:::WebResource \{'
        }
    }
}
