. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Architecture diagram retrieval helpers" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
    }

    It "Get-PowerPlatformCheckerDiagramFlows returns empty when flows are excluded" {
        InModuleScope PowerPlatformChecker {
            $solutionObject = [pscustomobject]@{
                Workflows = @([pscustomobject]@{ Id = "f1"; Name = "Flow 1" })
            }

            $policy = [pscustomobject]@{ IncludeFlows = $false }
            $result = Get-PowerPlatformCheckerDiagramFlows -SolutionObject $solutionObject -IncludePolicy $policy -HasCanvasFilter:$false -HasFlowFilter:$false -HasModelDrivenFilter:$false -FlowId "" -ModelDrivenFlowFilter @()

            @($result).Count | Should -Be 0
        }
    }

    It "Get-PowerPlatformCheckerDiagramFlows applies FlowId and model-driven flow filter" {
        InModuleScope PowerPlatformChecker {
            $solutionObject = [pscustomobject]@{
                Workflows = @(
                    [pscustomobject]@{ Id = "f1"; Name = "Flow 1" },
                    [pscustomobject]@{ Id = "f2"; Name = "Flow 2" }
                )
            }

            $policy = [pscustomobject]@{ IncludeFlows = $true }
            $result = Get-PowerPlatformCheckerDiagramFlows -SolutionObject $solutionObject -IncludePolicy $policy -HasCanvasFilter:$false -HasFlowFilter:$false -HasModelDrivenFilter:$true -FlowId "" -ModelDrivenFlowFilter @("f2")
            @($result).Id | Should -Be @("f2")

            $result2 = Get-PowerPlatformCheckerDiagramFlows -SolutionObject $solutionObject -IncludePolicy $policy -HasCanvasFilter:$false -HasFlowFilter:$true -HasModelDrivenFilter:$false -FlowId "f1" -ModelDrivenFlowFilter @()
            @($result2).Id | Should -Be @("f1")
        }
    }

    It "Get-PowerPlatformCheckerDiagramCanvasApps honors scope gates and name filter" {
        InModuleScope PowerPlatformChecker {
            $solutionObject = [pscustomobject]@{
                CanvasApps = @(
                    [pscustomobject]@{ Name = "A"; DisplayName = "App A" },
                    [pscustomobject]@{ Name = "B"; DisplayName = "App B" }
                )
            }

            $policy = [pscustomobject]@{ IncludeCanvasApps = $true }
            $result = Get-PowerPlatformCheckerDiagramCanvasApps -SolutionObject $solutionObject -IncludePolicy $policy -HasFlowFilter:$true -HasModelDrivenFilter:$false -CanvasAppName ""
            @($result).Count | Should -Be 0

            $result2 = Get-PowerPlatformCheckerDiagramCanvasApps -SolutionObject $solutionObject -IncludePolicy $policy -HasFlowFilter:$false -HasModelDrivenFilter:$false -CanvasAppName "B"
            @($result2).Name | Should -Be @("B")
        }
    }

    It "Get-PowerPlatformCheckerDiagramModelDrivenApps honors include gates and name filter" {
        InModuleScope PowerPlatformChecker {
            $policy = [pscustomobject]@{ IncludeModelDrivenApps = $true }
            Mock -CommandName Get-PowerPlatformCheckerModelDrivenApp -ModuleName PowerPlatformChecker -MockWith {
                @(
                    [pscustomobject]@{ UniqueName = "App1" },
                    [pscustomobject]@{ UniqueName = "App2" }
                )
            }

            $result = Get-PowerPlatformCheckerDiagramModelDrivenApps -SolutionPath "C:\dummy" -IncludePolicy $policy -HasFlowFilter:$true -HasCanvasFilter:$false -ModelDrivenAppName ""
            @($result).Count | Should -Be 0

            $result2 = Get-PowerPlatformCheckerDiagramModelDrivenApps -SolutionPath "C:\dummy" -IncludePolicy $policy -HasFlowFilter:$false -HasCanvasFilter:$false -ModelDrivenAppName "App2"
            @($result2).UniqueName | Should -Be @("App2")
        }
    }

    It "Get-PowerPlatformCheckerDiagramEnvironmentVariables returns scoped subset" {
        InModuleScope PowerPlatformChecker {
            $solutionObject = [pscustomobject]@{
                EnvironmentVariables = @(
                    [pscustomobject]@{ Name = "a" },
                    [pscustomobject]@{ Name = "b" }
                )
            }
            $policy = [pscustomobject]@{ IncludeEnvironmentVariables = $true }

            $result = Get-PowerPlatformCheckerDiagramEnvironmentVariables -SolutionObject $solutionObject -IncludePolicy $policy -IsScopedDiagram:$true -ConnectedNames @("b")
            @($result).Name | Should -Be @("b")
        }
    }

    It "Get-PowerPlatformCheckerDiagramConnections and Entities return scoped subsets" {
        InModuleScope PowerPlatformChecker {
            $solutionObject = [pscustomobject]@{
                ConnectionReferences = @(
                    [pscustomobject]@{ ConnectorId = "/providers/x/one" },
                    [pscustomobject]@{ ConnectorId = "/providers/x/two" }
                )
                Entities = @(
                    [pscustomobject]@{ EntitySetName = "ones" },
                    [pscustomobject]@{ EntitySetName = "twos" }
                )
            }

            $policy = [pscustomobject]@{ IncludeConnections = $true; IncludeEntities = $true }

            $connections = Get-PowerPlatformCheckerDiagramConnections -SolutionObject $solutionObject -IncludePolicy $policy -IsScopedDiagram:$true -ConnectedConnectorNames @("two")
            @($connections | ForEach-Object { Convert-PowerPlatformCheckerMermaidId -InputString $_.ConnectorId.Split("/")[-1] }) | Should -Be @("two")

            $entities = Get-PowerPlatformCheckerDiagramEntities -SolutionObject $solutionObject -IncludePolicy $policy -IsScopedDiagram:$true -ConnectedEntitySetNames @("twos")
            @($entities).EntitySetName | Should -Be @("twos")
        }
    }

    It "Get-PowerPlatformCheckerDiagramDefaultEntities keeps connected unresolved defaults and skips rendered entity ids" {
        InModuleScope PowerPlatformChecker {
            $policy = [pscustomobject]@{ IncludeDefaultEntities = $true }
            $entitySetByReference = @{ "account" = "accounts" }
            $result = Get-PowerPlatformCheckerDiagramDefaultEntities -IncludePolicy $policy -IsScopedDiagram:$true -DefaultEntitiesInCanvasApps @("account", "systemuser") -ConnectedDefaultEntities @("systemuser") -EntitySetByReference $entitySetByReference -RenderedEntityNodeIds @("accounts")
            @($result) | Should -Be @("systemuser")
        }
    }

    It "Get-PowerPlatformCheckerDiagramWebResources returns JavaScript resources and icon resources when enabled" {
        InModuleScope PowerPlatformChecker {
            $policy = [pscustomobject]@{ IncludeWebResources = $true }
            $solutionObject = [pscustomobject]@{
                Entities = @(
                    [pscustomobject]@{ IconVectorName = "icon_svg" }
                )
            }

            Mock -CommandName Get-PowerPlatformCheckerWebResource -ModuleName PowerPlatformChecker -MockWith {
                param([string]$SolutionPath, [switch]$JavaScriptOnly, [string]$Name)
                if ($JavaScriptOnly.IsPresent) {
                    return @(
                        [pscustomobject]@{ Name = "a.js"; MermaidId = "a_js"; Dependencies = @("b.js") },
                        [pscustomobject]@{ Name = "b.js"; MermaidId = "b_js"; Dependencies = @() }
                    )
                }
                if ($Name -eq "icon_svg") {
                    return [pscustomobject]@{ Name = "icon_svg"; MermaidId = "icon_svg"; DisplayName = "Icon"; Type = "SVG" }
                }
            }

            $result = Get-PowerPlatformCheckerDiagramWebResources -SolutionPath "C:\dummy" -SolutionObject $solutionObject -IncludePolicy $policy -HasModelDrivenFilter:$false -ModelApps @()
            @($result.WebResources).Count | Should -Be 2
            @($result.IconResources).Count | Should -Be 1
        }
    }

    It "Get-PowerPlatformCheckerDiagramWebResources applies model-driven dependency closure" {
        InModuleScope PowerPlatformChecker {
            $policy = [pscustomobject]@{ IncludeWebResources = $true }
            $solutionObject = [pscustomobject]@{ Entities = @() }
            $modelApps = @(
                [pscustomobject]@{
                    WebResources = @("a.js")
                    EntityWebResources = @([pscustomobject]@{ WebResources = @("a.js") })
                }
            )

            Mock -CommandName Get-PowerPlatformCheckerWebResource -ModuleName PowerPlatformChecker -MockWith {
                param([string]$SolutionPath, [switch]$JavaScriptOnly, [string]$Name)
                if ($JavaScriptOnly.IsPresent) {
                    return @(
                        [pscustomobject]@{ Name = "a.js"; MermaidId = "a_js"; Dependencies = @("b.js") },
                        [pscustomobject]@{ Name = "b.js"; MermaidId = "b_js"; Dependencies = @() },
                        [pscustomobject]@{ Name = "c.js"; MermaidId = "c_js"; Dependencies = @() }
                    )
                }
            }

            $result = Get-PowerPlatformCheckerDiagramWebResources -SolutionPath "C:\dummy" -SolutionObject $solutionObject -IncludePolicy $policy -HasModelDrivenFilter:$true -ModelApps $modelApps
            @($result.WebResources).Name | Sort-Object | Should -Be @("a.js", "b.js")
        }
    }

    It "Expand-PowerPlatformCheckerScopedReachability adds linked in-solution entities" {
        InModuleScope PowerPlatformChecker {
            $entityBySetName = @{
                "hanab_products" = [pscustomobject]@{
                    Name = "hanab_product"
                    Relations = @(
                        [pscustomobject]@{ Source = "hanab_product"; Target = "hanab_supplier"; Type = "OneToMany" }
                    )
                }
            }
            $entityByLogicalName = @{
                "hanab_product" = [pscustomobject]@{ EntitySetName = "hanab_products" }
                "hanab_supplier" = [pscustomobject]@{ EntitySetName = "hanab_suppliers" }
            }

            $result = Expand-PowerPlatformCheckerScopedReachability -ConnectedEntities @("hanab_products") -ConnectedDefaultEntities @() -EntityBySetName $entityBySetName -EntityByLogicalName $entityByLogicalName -IncludeDefaultEntities:$true

            @($result.ConnectedEntities) | Should -Contain "hanab_products"
            @($result.ConnectedEntities) | Should -Contain "hanab_suppliers"
        }
    }

    It "Expand-PowerPlatformCheckerScopedReachability adds default entities for unresolved relation targets" {
        InModuleScope PowerPlatformChecker {
            $entityBySetName = @{
                "hanab_products" = [pscustomobject]@{
                    Name = "hanab_product"
                    Relations = @(
                        [pscustomobject]@{ Source = "hanab_product"; Target = "systemuser"; Type = "OneToMany" }
                    )
                }
            }
            $entityByLogicalName = @{
                "hanab_product" = [pscustomobject]@{ EntitySetName = "hanab_products" }
            }

            $result = Expand-PowerPlatformCheckerScopedReachability -ConnectedEntities @("hanab_products") -ConnectedDefaultEntities @() -EntityBySetName $entityBySetName -EntityByLogicalName $entityByLogicalName -IncludeDefaultEntities:$true

            @($result.ConnectedDefaultEntities) | Should -Contain "systemuser"
        }
    }
}
