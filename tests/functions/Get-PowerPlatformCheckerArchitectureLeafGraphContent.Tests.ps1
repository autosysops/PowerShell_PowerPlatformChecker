. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Architecture leaf graph content" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
    }

    It "builds only connected environment-variable nodes for scoped diagrams" {
        InModuleScope PowerPlatformChecker {
            $solutionObject = [pscustomobject]@{
                EnvironmentVariables = @(
                    [pscustomobject]@{ Name = "a" },
                    [pscustomobject]@{ Name = "b" }
                )
            }
            $policy = [pscustomobject]@{ IncludeEnvironmentVariables = $true }

            $result = Get-PowerPlatformCheckerArchitectureEnvironmentVariableGraphContent -SolutionObject $solutionObject -IncludePolicy $policy -IsScopedDiagram -ConnectedNames @("b")

            @($result.Nodes).Id | Should -Be @("b")
            $result.Nodes[0].Type | Should -Be "EnvVar"
        }
    }

    It "builds only connected connection nodes for scoped diagrams" {
        InModuleScope PowerPlatformChecker {
            $solutionObject = [pscustomobject]@{
                ConnectionReferences = @(
                    [pscustomobject]@{ ConnectorId = "/providers/x/one"; DisplayName = "One" },
                    [pscustomobject]@{ ConnectorId = "/providers/x/two"; DisplayName = "Two" }
                )
            }
            $policy = [pscustomobject]@{ IncludeConnections = $true }

            $result = Get-PowerPlatformCheckerArchitectureConnectionGraphContent -SolutionObject $solutionObject -IncludePolicy $policy -IsScopedDiagram -ConnectedConnectorNames @("two")

            @($result.Nodes).Id | Should -Be @("two")
            $result.Nodes[0].Members | Should -Contain "  Two()"
        }
    }

    It "builds unresolved default nodes and suppresses rendered entities" {
        InModuleScope PowerPlatformChecker {
            $policy = [pscustomobject]@{ IncludeDefaultEntities = $true }
            $entitySetByReference = @{ account = "accounts" }

            $result = Get-PowerPlatformCheckerArchitectureDefaultEntityGraphContent -IncludePolicy $policy -IsScopedDiagram -DefaultEntitiesInCanvasApps @("account", "systemuser") -ConnectedDefaultEntities @("systemuser") -EntitySetByReference $entitySetByReference -RenderedEntityNodeIds @("accounts")

            @($result.Nodes).Id | Should -Be @("systemuser")
            $result.Nodes[0].Type | Should -Be "DefaultEntity"
        }
    }

    It "expands scoped reachability to linked in-solution entities" {
        InModuleScope PowerPlatformChecker {
            $entityBySetName = @{
                hanab_products = [pscustomobject]@{
                    Name = "hanab_product"
                    Relations = @([pscustomobject]@{ Source = "hanab_product"; Target = "hanab_supplier"; Type = "OneToMany" })
                }
            }
            $entityByLogicalName = @{
                hanab_product = [pscustomobject]@{ EntitySetName = "hanab_products" }
                hanab_supplier = [pscustomobject]@{ EntitySetName = "hanab_suppliers" }
            }

            $result = Expand-PowerPlatformCheckerScopedReachability -ConnectedEntities @("hanab_products") -ConnectedDefaultEntities @() -EntityBySetName $entityBySetName -EntityByLogicalName $entityByLogicalName -IncludeDefaultEntities

            @($result.ConnectedEntities) | Should -Contain "hanab_products"
            @($result.ConnectedEntities) | Should -Contain "hanab_suppliers"
        }
    }

    It "expands scoped reachability to unresolved default entities" {
        InModuleScope PowerPlatformChecker {
            $entityBySetName = @{
                hanab_products = [pscustomobject]@{
                    Name = "hanab_product"
                    Relations = @([pscustomobject]@{ Source = "hanab_product"; Target = "systemuser"; Type = "OneToMany" })
                }
            }
            $entityByLogicalName = @{
                hanab_product = [pscustomobject]@{ EntitySetName = "hanab_products" }
            }

            $result = Expand-PowerPlatformCheckerScopedReachability -ConnectedEntities @("hanab_products") -ConnectedDefaultEntities @() -EntityBySetName $entityBySetName -EntityByLogicalName $entityByLogicalName -IncludeDefaultEntities

            @($result.ConnectedDefaultEntities) | Should -Contain "systemuser"
        }
    }
}