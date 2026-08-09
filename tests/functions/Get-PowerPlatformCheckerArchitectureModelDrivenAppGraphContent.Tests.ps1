. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerArchitectureModelDrivenAppGraphContent" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
    }

    It "builds flow and entity links and keeps unresolved entities as missing references" {
        InModuleScope PowerPlatformChecker {
            $modelApp = [pscustomobject]@{
                MermaidId = "app1"
                DisplayName = "App 1"
                Components = @()
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

            $result = Get-PowerPlatformCheckerArchitectureModelDrivenAppGraphContent -ModelApp $modelApp -SolutionObject $solutionObject -IncludeFlows:$true -IncludeEntities:$true -IncludeDefaultEntities:$true -IncludeWebResources:$false -EntitySetByReference @{ account = "accounts" } -WebResources @()

            @($result.Edges | Where-Object { $_.SourceId -eq "app1" -and $_.TargetId -eq "flowflow-a" }).Count | Should -Be 1
            @($result.Nodes | Where-Object { $_.Id -eq "app1" -and $_.DisplayName -eq "App 1" }).Count | Should -Be 1
            @($result.Edges | Where-Object { $_.SourceId -eq "app1" -and $_.TargetId -eq "accounts" }).Count | Should -Be 1
            @($result.Edges | Where-Object { $_.SourceId -eq "app1" -and $_.TargetId -eq "external_vendor" }).Count | Should -Be 1
            @($result.ConnectedEntities) | Should -Contain "accounts"
            @($result.ConnectedDefaultEntities) | Should -Contain "external_vendor"
        }
    }

    It "avoids direct app script links for entity-owned and dependency-only scripts" {
        InModuleScope PowerPlatformChecker {
            $modelApp = [pscustomobject]@{
                MermaidId = "app2"
                DisplayName = "App 2"
                Components = @()
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

            $result = Get-PowerPlatformCheckerArchitectureModelDrivenAppGraphContent -ModelApp $modelApp -SolutionObject $solutionObject -IncludeFlows:$false -IncludeEntities:$true -IncludeDefaultEntities:$true -IncludeWebResources:$true -EntitySetByReference @{ account = "accounts" } -WebResources $webResources
            @($result.Edges | Where-Object { $_.SourceId -eq "accounts" -and $_.TargetId -eq "main_js" }).Count | Should -Be 1
            @($result.Edges | Where-Object { $_.SourceId -eq "app2" -and $_.TargetId -in @("main_js", "shared_js") }).Count | Should -Be 0
        }
    }
}
