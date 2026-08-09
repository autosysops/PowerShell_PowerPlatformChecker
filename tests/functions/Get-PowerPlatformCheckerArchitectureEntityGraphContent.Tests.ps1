. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerArchitectureEntityGraphContent" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
    }

    It "renders entity class, relation links, form script links, and icon links" {
        InModuleScope PowerPlatformChecker {
            $entities = @(
                [pscustomobject]@{
                    Name = "account"
                    EntitySetName = "accounts"
                    Attributes = @([pscustomobject]@{ Name = "name"; Type = "nvarchar" })
                    Relations = @([pscustomobject]@{ Source = "account"; Target = "contact"; Type = "OneToMany" })
                    FormWebResources = @("form.js")
                    IconResources = @([pscustomobject]@{ WebResourceName = "icon.svg"; FieldName = "IconVectorName" })
                }
            )

            $entityByLogicalName = @{
                account = [pscustomobject]@{ EntitySetName = "accounts" }
                contact = [pscustomobject]@{ EntitySetName = "contacts" }
            }

            $webResources = @([pscustomobject]@{ Name = "form.js"; MermaidId = "form_js" })
            $iconResources = @([pscustomobject]@{ Name = "icon.svg"; MermaidId = "icon_svg"; DisplayName = "Icon"; Type = "SVG" })

            $solutionObject = [pscustomobject]@{ Entities = $entities }
            $result = Get-PowerPlatformCheckerArchitectureEntityGraphContent -SolutionObject $solutionObject -IncludeEntities:$true -DefaultFields @() -IsScopedDiagram:$false -IncludeDefaultEntities:$true -IncludeWebResources:$true -EntityByLogicalName $entityByLogicalName -WebResources $webResources -IconResources $iconResources

            @($result.Nodes | Where-Object { $_.Id -eq "accounts" }).Count | Should -Be 1
            $result.Nodes[0].Members | Should -Contain "    [nvarchar]name"
            @($result.Edges | Where-Object { $_.SourceId -eq "accounts" -and $_.TargetId -eq "contacts" -and $_.Label -eq "account-OneToMany" }).Count | Should -Be 1
            @($result.Edges | Where-Object { $_.TargetId -eq "form_js" -and $_.Label -eq "Script" }).Count | Should -Be 1
            @($result.Edges | Where-Object { $_.TargetId -eq "icon_svg" -and $_.Label -eq "IconVectorName" }).Count | Should -Be 1
            @($result.IconNodes | Where-Object { $_.Id -eq "icon_svg" }).Count | Should -Be 1
            @($result.RenderedEntityNodeIds) | Should -Contain 'accounts'
            @($result.ConnectedIconResources) | Should -Contain 'icon.svg'
        }
    }

    It "keeps unresolved relation targets as default-entity references" {
        InModuleScope PowerPlatformChecker {
            $entities = @(
                [pscustomobject]@{
                    Name = "account"
                    EntitySetName = "accounts"
                    Attributes = @()
                    Relations = @([pscustomobject]@{ Source = "account"; Target = "external_vendor"; Type = "ManyToOne" })
                    FormWebResources = @()
                    IconResources = @()
                }
            )

            $entityByLogicalName = @{
                account = [pscustomobject]@{ EntitySetName = "accounts" }
            }

            $solutionObject = [pscustomobject]@{ Entities = $entities }
            $result = Get-PowerPlatformCheckerArchitectureEntityGraphContent -SolutionObject $solutionObject -IncludeEntities:$true -DefaultFields @() -IsScopedDiagram:$false -IncludeDefaultEntities:$true -IncludeWebResources:$false -EntityByLogicalName $entityByLogicalName -WebResources @() -IconResources @()
            @($result.Edges | Where-Object { $_.SourceId -eq "accounts" -and $_.TargetId -eq "external_vendor" -and $_.Label -eq "ManyToOne" }).Count | Should -Be 1
            @($result.ConnectedDefaultEntities) | Should -Contain 'external_vendor'
        }
    }
}
