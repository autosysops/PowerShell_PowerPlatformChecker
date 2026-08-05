. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerEntityDiagramContent" {
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
            $iconResources = @([pscustomobject]@{ Name = "icon.svg"; MermaidId = "icon_svg" })

            $result = Get-PowerPlatformCheckerEntityDiagramContent -EntitiesToRender $entities -DefaultFields @() -IsScopedDiagram:$false -IncludeDefaultEntities:$true -IncludeWebResources:$true -EntityByLogicalName $entityByLogicalName -WebResources $webResources -IconResources $iconResources -NewLine "`n"

            $result.DiagramText | Should -Match 'class accounts\["account"\]:::Entity \{'
            (@($result.Links) -join "`n") | Should -Match 'accounts --> contacts:account-OneToMany'
            (@($result.Links) -join "`n") | Should -Match 'accounts --> form_js:Script'
            (@($result.Links) -join "`n") | Should -Match 'accounts --> icon_svg:IconVectorName'
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

            $result = Get-PowerPlatformCheckerEntityDiagramContent -EntitiesToRender $entities -DefaultFields @() -IsScopedDiagram:$false -IncludeDefaultEntities:$true -IncludeWebResources:$false -EntityByLogicalName $entityByLogicalName -WebResources @() -IconResources @() -NewLine "`n"
            (@($result.Links) -join "`n") | Should -Match 'accounts --> external_vendor:ManyToOne'
            @($result.ConnectedDefaultEntities) | Should -Contain 'external_vendor'
        }
    }
}
