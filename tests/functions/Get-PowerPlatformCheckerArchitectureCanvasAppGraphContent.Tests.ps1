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
                    InteractionDirection = 'Mixed'
                    InteractionEvidence = 'SourceFormula'
                    ConnectionReferences = @([pscustomobject]@{ id = "/providers/Microsoft.PowerApps/apis/shared_sql" })
                    DomainInteractions = @(
                        [pscustomobject]@{ Domain = 'https://contoso.sharepoint.com'; DataSourceName = 'E-Learning-Content'; Direction = 'Read'; Evidence = 'SourceFormula' },
                        [pscustomobject]@{ Domain = 'https://contoso.sharepoint.com'; DataSourceName = 'E-Learning-Progress'; Direction = 'Write'; Evidence = 'SourceFormula' }
                    )
                    DataSources = [pscustomobject]@{
                        DataSources = @(
                            [pscustomobject]@{ Name = "Accounts"; entitySetName = "accounts"; logicalName = "account" },
                            [pscustomobject]@{ Name = "External"; entitySetName = $null; logicalName = "external_vendor" }
                        )
                    }
                }
            )

            $solutionObject = [pscustomobject]@{ CanvasApps = $canvasApps }
            $result = Get-PowerPlatformCheckerArchitectureCanvasAppGraphContent -SolutionObject $solutionObject -IncludeCanvasApps:$true -IncludeConnections:$true -IncludeEntities:$true -IncludeDefaultEntities:$true -IncludeExternalDomains:$true -EntitySetByReference @{ account = "accounts" } -KnownEntitySetNames @("accounts")

            @($result.Nodes | Where-Object { $_.Id -eq "app_internal" -and $_.DisplayName -eq "App Display" }).Count | Should -Be 1
            ($result.Nodes | Where-Object { $_.Id -eq "app_internal" } | Select-Object -First 1).Properties.Destination | Should -Be "sql"
            ($result.Nodes | Where-Object { $_.Id -eq "app_internal" } | Select-Object -First 1).Properties.DestinationType | Should -Be "Service"
            ($result.Nodes | Where-Object { $_.Id -eq "app_internal" } | Select-Object -First 1).Properties.DestinationConfidence | Should -Be "Low"
            ($result.Nodes | Where-Object { $_.Id -eq "app_internal" } | Select-Object -First 1).Properties.DestinationEvidence | Should -Be "ConnectionReference"
            ($result.Nodes | Where-Object { $_.Id -eq "app_internal" } | Select-Object -First 1).Properties.InteractionDirection | Should -Be "Mixed"
            ($result.Nodes | Where-Object { $_.Id -eq "app_internal" } | Select-Object -First 1).Properties.InteractionEvidence | Should -Be "SourceFormula"
            @($result.Edges | Where-Object { $_.SourceId -eq "shared_sql" -and $_.TargetId -eq "app_internal" }).Count | Should -Be 1
            @($result.Edges | Where-Object { $_.SourceId -eq "app_internal" -and $_.TargetId -eq "accounts" }).Count | Should -Be 1
            @($result.Edges | Where-Object { $_.SourceId -eq "app_internal" -and $_.TargetId -eq "external_vendor" }).Count | Should -Be 1
            @($result.Nodes | Where-Object { $_.Id -eq 'externaldomain_https_contoso_sharepoint_com' -and $_.Type -eq 'ExternalDomain' }).Count | Should -Be 1
            ($result.Nodes | Where-Object { $_.Id -eq 'externaldomain_https_contoso_sharepoint_com' } | Select-Object -First 1).DisplayName | Should -Be 'contoso.sharepoint.com'
            @($result.Edges | Where-Object { $_.SourceId -eq 'app_internal' -and $_.TargetId -eq 'externaldomain_https_contoso_sharepoint_com' -and $_.Metadata.InteractionDirection -eq 'Read' -and $_.Label -match 'GET$' }).Count | Should -Be 1
            @($result.Edges | Where-Object { $_.SourceId -eq 'app_internal' -and $_.TargetId -eq 'externaldomain_https_contoso_sharepoint_com' -and $_.Metadata.InteractionDirection -eq 'Write' -and $_.Label -match 'SET$' }).Count | Should -Be 1
            @($result.ConnectedConnections) | Should -Contain 'shared_sql'
            @($result.ConnectedEntities) | Should -Contain 'accounts'
            @($result.DefaultEntitiesInCanvasApps) | Should -Contain 'external_vendor'
            @($result.ConnectedDefaultEntities) | Should -Contain 'external_vendor'
        }
    }

    It "normalizes external domain labels by removing any protocol prefix that uses ://" {
        InModuleScope PowerPlatformChecker {
            $canvasApps = @(
                [pscustomobject]@{
                    Name = "app_protocol"
                    DisplayName = "Protocol App"
                    InteractionDirection = 'Read'
                    InteractionEvidence = 'SourceFormula'
                    ConnectionReferences = @()
                    DomainInteractions = @(
                        [pscustomobject]@{ Domain = 'ftp://files.contoso.example/archive'; DataSourceName = 'Archive'; Direction = 'Read'; Evidence = 'SourceFormula' }
                    )
                    DataSources = [pscustomobject]@{ DataSources = @() }
                }
            )

            $solutionObject = [pscustomobject]@{ CanvasApps = $canvasApps }
            $result = Get-PowerPlatformCheckerArchitectureCanvasAppGraphContent -SolutionObject $solutionObject -IncludeCanvasApps:$true -IncludeExternalDomains:$true -EntitySetByReference @{} -KnownEntitySetNames @()

            @($result.Nodes | Where-Object { $_.Id -eq 'externaldomain_ftp_files_contoso_example_archive' -and $_.Type -eq 'ExternalDomain' }).Count | Should -Be 1
            ($result.Nodes | Where-Object { $_.Id -eq 'externaldomain_ftp_files_contoso_example_archive' } | Select-Object -First 1).DisplayName | Should -Be 'files.contoso.example/archive'
        }
    }
}
