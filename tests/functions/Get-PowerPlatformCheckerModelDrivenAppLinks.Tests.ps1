. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerModelDrivenAppLinks" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
    }

    It "builds flow and entity links and keeps unresolved entities as missing references" {
        InModuleScope PowerPlatformChecker {
            $modelApp = [pscustomobject]@{
                MermaidId = "app1"
                FlowIds = @("flow-a")
                Entities = @("account", "external_vendor")
                WebResources = @()
                EntityWebResources = @()
            }

            $solutionObject = [pscustomobject]@{
                Entities = @(
                    [pscustomobject]@{ Name = "account"; EntitySetName = "accounts" }
                )
            }

            $result = Get-PowerPlatformCheckerModelDrivenAppLinks -ModelApp $modelApp -SolutionObject $solutionObject -IncludeFlows:$true -IncludeEntities:$true -IncludeDefaultEntities:$true -IncludeWebResources:$false -EntitySetByReference @{ account = "accounts" } -WebResources @()

            @($result.Links) -join "`n" | Should -Match "app1 --> flowflow-a:Flow"
            @($result.Links) -join "`n" | Should -Match "app1 --> accounts:Entity"
            @($result.Links) -join "`n" | Should -Match "app1 --> external_vendor:Entity"
            @($result.ConnectedEntities) | Should -Contain "accounts"
            @($result.ConnectedDefaultEntities) | Should -Contain "external_vendor"
        }
    }

    It "avoids direct app script links for entity-owned and dependency-only scripts" {
        InModuleScope PowerPlatformChecker {
            $modelApp = [pscustomobject]@{
                MermaidId = "app2"
                FlowIds = @()
                Entities = @("account")
                WebResources = @("main.js", "shared.js")
                EntityWebResources = @(
                    [pscustomobject]@{ EntitySchemaName = "account"; WebResources = @("main.js") }
                )
            }

            $solutionObject = [pscustomobject]@{
                Entities = @(
                    [pscustomobject]@{ Name = "account"; EntitySetName = "accounts" }
                )
            }

            $webResources = @(
                [pscustomobject]@{ Name = "main.js"; MermaidId = "main_js"; Dependencies = @("shared.js") },
                [pscustomobject]@{ Name = "shared.js"; MermaidId = "shared_js"; Dependencies = @() }
            )

            $result = Get-PowerPlatformCheckerModelDrivenAppLinks -ModelApp $modelApp -SolutionObject $solutionObject -IncludeFlows:$false -IncludeEntities:$true -IncludeDefaultEntities:$true -IncludeWebResources:$true -EntitySetByReference @{ account = "accounts" } -WebResources $webResources
            $merged = @($result.Links) -join "`n"

            $merged | Should -Match "accounts --> main_js:Script"
            $merged | Should -Not -Match "app2 --> main_js:Script"
            $merged | Should -Not -Match "app2 --> shared_js:Script"
        }
    }
}
