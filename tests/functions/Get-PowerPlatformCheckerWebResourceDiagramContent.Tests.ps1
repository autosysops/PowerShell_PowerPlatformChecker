. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerWebResourceDiagramContent" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
    }

    It "renders script classes with methods and dependency links" {
        InModuleScope PowerPlatformChecker {
            $webResources = @(
                [pscustomobject]@{
                    Name = "main.js"
                    MermaidId = "main_js"
                    DisplayName = "Main"
                    Kind = "Script"
                    Type = "JavaScript"
                    Methods = @("onLoad")
                    Dependencies = @("shared.js")
                },
                [pscustomobject]@{
                    Name = "shared.js"
                    MermaidId = "shared_js"
                    DisplayName = "Shared"
                    Kind = "Script"
                    Type = "JavaScript"
                    Methods = @()
                    Dependencies = @()
                }
            )

            $result = Get-PowerPlatformCheckerWebResourceDiagramContent -WebResources $webResources -IncludeWebResources:$true -NewLine "`n"

            $result.DiagramText | Should -Match 'class main_js\["Main"\]:::WebResource \{'
            $result.DiagramText | Should -Match '\[Script\]onLoad'
            (@($result.Links) -join "`n") | Should -Match 'main_js --> shared_js:Dependency'
        }
    }

    It "keeps unresolved dependencies visible as missing webresource nodes" {
        InModuleScope PowerPlatformChecker {
            $webResources = @(
                [pscustomobject]@{
                    Name = "main.js"
                    MermaidId = "main_js"
                    DisplayName = "Main"
                    Kind = "Script"
                    Type = "JavaScript"
                    Methods = @()
                    Dependencies = @("external.js")
                }
            )

            $result = Get-PowerPlatformCheckerWebResourceDiagramContent -WebResources $webResources -IncludeWebResources:$true -NewLine "`n"

            $result.DiagramText | Should -Match 'class external_js\["external\.js"\]:::WebResource'
        }
    }
}
