. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerMermaidStyleBlock" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        InModuleScope PowerPlatformChecker {
            if (-not $script:PowerPlatformCheckerDiagramColors) {
                $script:PowerPlatformCheckerDiagramColors = @{
                    Default = "red"
                    EnvVar = "#DF9A57"
                    Connection = "#FCD757"
                    Entity = "#B56784"
                    DefaultEntity = "#71374D"
                    Flow = "#DBE4EE"
                    CanvasApp = "#8BC34A"
                    ModelDrivenApp = "#7BAFD4"
                    WebResource = "#D7C8F3"
                    Stroke = "#5E5B52"
                }
            }
        }
    }

    It "renders only enabled classDef lines" {
        InModuleScope PowerPlatformChecker {
            $style = @{
                Default = "red"
                EnvVar = "#DF9A57"
                Connection = "#FCD757"
                Entity = "#B56784"
                DefaultEntity = "#71374D"
                Flow = "#DBE4EE"
                CanvasApp = "#8BC34A"
                ModelDrivenApp = "#7BAFD4"
                WebResource = "#D7C8F3"
                Stroke = "#5E5B52"
            }

            $policy = [pscustomobject]@{
                IncludeFlows = $true
                IncludeCanvasApps = $false
                IncludeModelDrivenApps = $false
                IncludeEnvironmentVariables = $true
                IncludeConnections = $true
                IncludeEntities = $true
                IncludeDefaultEntities = $true
                IncludeWebResources = $false
            }

            $styleBlock = Get-PowerPlatformCheckerMermaidStyleBlock -Style $style -IncludePolicy $policy

            $styleBlock | Should -Match "classDef default fill:red,stroke:#5E5B52"
            $styleBlock | Should -Match "classDef Flow fill:#DBE4EE,stroke:#5E5B52"
            $styleBlock | Should -Not -Match "classDef CanvasApp"
            $styleBlock | Should -Not -Match "classDef WebResource"
        }
    }
}
