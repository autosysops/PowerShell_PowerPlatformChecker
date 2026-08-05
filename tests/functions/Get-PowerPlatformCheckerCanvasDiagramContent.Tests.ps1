. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerCanvasDiagramContent" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
    }

    It "renders canvas app node and links for connections, entities, and unresolved defaults" {
        InModuleScope PowerPlatformChecker {
            $canvasApps = @(
                [pscustomobject]@{
                    Name = "app_internal"
                    DisplayName = "App Display"
                    ConnectionReferences = @([pscustomobject]@{ id = "/providers/Microsoft.PowerApps/apis/shared_sql" })
                    DataSources = [pscustomobject]@{
                        DataSources = @(
                            [pscustomobject]@{ Name = "Accounts"; entitySetName = "accounts"; logicalName = "account" },
                            [pscustomobject]@{ Name = "External"; entitySetName = $null; logicalName = "external_vendor" }
                        )
                    }
                }
            )

            $result = Get-PowerPlatformCheckerCanvasDiagramContent -CanvasAppsToRender $canvasApps -IncludeConnections:$true -IncludeEntities:$true -IncludeDefaultEntities:$true -EntitySetByReference @{ account = "accounts" } -KnownEntitySetNames @("accounts") -NewLine "`n"

            $result.DiagramText | Should -Match 'class app_internal\["App Display"\]:::CanvasApp'
            (@($result.Links) -join "`n") | Should -Match 'shared_sql --> app_internal:shared_sql'
            (@($result.Links) -join "`n") | Should -Match 'app_internal --> accounts:Accounts'
            (@($result.Links) -join "`n") | Should -Match 'app_internal --> external_vendor:External'
            @($result.ConnectedConnections) | Should -Contain 'shared_sql'
            @($result.ConnectedEntities) | Should -Contain 'accounts'
            @($result.DefaultEntitiesInCanvasApps) | Should -Contain 'external_vendor'
            @($result.ConnectedDefaultEntities) | Should -Contain 'external_vendor'
        }
    }
}
