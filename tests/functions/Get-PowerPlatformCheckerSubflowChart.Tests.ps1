. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerSubflowChart" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:desktopFlowChartSolutionPath = (Resolve-Path (Join-Path $PSScriptRoot "..\fixtures\desktop-flowchart-solution\Managed")).Path
        $script:desktopSubflowPath = Join-Path $script:desktopFlowChartSolutionPath "Workflows\DesktopFlow-Subflows-99999999-9999-9999-9999-999999999999.json"
        $script:flowGraphSnapshotNormalizer = {
            param(
                [Parameter(Mandatory = $true)]
                [object] $Graph
            )

            return [ordered]@{
                GraphType = [string]$Graph.GraphType
                Id = if ($null -eq $Graph.Id) { $null } else { [string]$Graph.Id }
                ActionName = if ($null -eq $Graph.ActionName) { $null } else { [string]$Graph.ActionName }
                Title = if ($null -eq $Graph.Title) { $null } else { [string]$Graph.Title }
                Direction = [string]$Graph.Direction
                IsEmpty = [bool]$Graph.IsEmpty
                Nodes = @($Graph.Nodes | ForEach-Object {
                        [ordered]@{
                            Id = [string]$_.Id
                            Label = [string]$_.Label
                            Shape = [string]$_.Shape
                        }
                    })
                Edges = @($Graph.Edges | ForEach-Object {
                        [ordered]@{
                            From = [string]$_.From
                            Label = [string]$_.Label
                            To = [string]$_.To
                        }
                    })
                Subgraphs = @($Graph.Subgraphs | ForEach-Object {
                        & $script:flowGraphSnapshotNormalizer -Graph $_
                    })
            }
        }
        $script:flowGraphSnapshotConverter = {
            param(
                [Parameter(Mandatory = $true)]
                [object] $Graph
            )

            return (& $script:flowGraphSnapshotNormalizer -Graph $Graph | ConvertTo-Json -Depth 30)
        }
    }

    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {}
    }

    It "returns Mermaid flowchart output for a subflow" {
        $expected = Get-PowerPlatformCheckerExpectedSnapshot -FileName "FlowChart.DesktopSubflow.ProcessOrder.expected.md"
        $markdown = Get-PowerPlatformCheckerSubflowChart -Path $script:desktopSubflowPath -SubflowName "ProcessOrder"

        (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $expected)
    }

    It "returns graph output when requested" {
        $expected = Get-PowerPlatformCheckerExpectedSnapshot -FileName "FlowChart.DesktopSubflow.ProcessOrder.expected.graph.json"
        $graph = Get-PowerPlatformCheckerSubflowChart -Path $script:desktopSubflowPath -SubflowName "ProcessOrder" -OutputFormat Graph
        $actual = & $script:flowGraphSnapshotConverter -Graph $graph

        $graph.GraphType | Should -Be "FlowchartGraph"
        (Normalize-PowerPlatformCheckerSnapshotText -Text $actual) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $expected)
    }

    It "supports style emission in Mermaid output" {
        $markdown = Get-PowerPlatformCheckerSubflowChart -Path $script:desktopSubflowPath -SubflowName "ProcessOrder" -IncludeStyles

        $markdown | Should -Match "classDef"
        $markdown | Should -Match "linkStyle"
    }
}
