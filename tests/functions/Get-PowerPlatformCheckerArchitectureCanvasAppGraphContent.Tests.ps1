. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerArchitectureCanvasAppGraphContent" {
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

            $solutionObject = [pscustomobject]@{ CanvasApps = $canvasApps }
            $result = Get-PowerPlatformCheckerArchitectureCanvasAppGraphContent -SolutionObject $solutionObject -IncludeCanvasApps:$true -IncludeConnections:$true -IncludeEntities:$true -IncludeDefaultEntities:$true -EntitySetByReference @{ account = "accounts" } -KnownEntitySetNames @("accounts")

            @($result.Nodes | Where-Object { $_.Id -eq "app_internal" -and $_.DisplayName -eq "App Display" }).Count | Should -Be 1
            @($result.Edges | Where-Object { $_.SourceId -eq "shared_sql" -and $_.TargetId -eq "app_internal" }).Count | Should -Be 1
            @($result.Edges | Where-Object { $_.SourceId -eq "app_internal" -and $_.TargetId -eq "accounts" }).Count | Should -Be 1
            @($result.Edges | Where-Object { $_.SourceId -eq "app_internal" -and $_.TargetId -eq "external_vendor" }).Count | Should -Be 1
            @($result.ConnectedConnections) | Should -Contain 'shared_sql'
            @($result.ConnectedEntities) | Should -Contain 'accounts'
            @($result.DefaultEntitiesInCanvasApps) | Should -Contain 'external_vendor'
            @($result.ConnectedDefaultEntities) | Should -Contain 'external_vendor'
        }
    }
}
