. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerFlowChartStyledGraph" {
    It "adds node and edge style classes including nested subgraphs" {
        InModuleScope PowerPlatformChecker {
            $graph = [pscustomobject]@{
                GraphType = 'FlowchartGraph'
                Direction = 'TB'
                Nodes = @(
                    [pscustomobject]@{ Id = 'action0'; Label = 'Trigger'; Shape = 'Trigger' },
                    [pscustomobject]@{ Id = 'action1'; Label = 'Check'; Shape = 'Decision' },
                    [pscustomobject]@{ Id = 'action2'; Label = 'Do'; Shape = 'Action' }
                )
                Edges = @(
                    [pscustomobject]@{ From = 'action0'; Label = 'Succeeded'; To = 'action1' },
                    [pscustomobject]@{ From = 'action1'; Label = 'Error'; To = 'action2' },
                    [pscustomobject]@{ From = 'action1'; Label = ''; To = 'action2' }
                )
                Subgraphs = @(
                    [pscustomobject]@{
                        GraphType = 'FlowchartGraph'
                        Direction = 'TB'
                        Nodes = @([pscustomobject]@{ Id = 'action3'; Label = 'Child'; Shape = 'Action' })
                        Edges = @([pscustomobject]@{ From = 'action3'; Label = 'Succeeded'; To = 'action2' })
                        Subgraphs = @()
                    }
                )
            }

            $styled = Get-PowerPlatformCheckerFlowChartStyledGraph -Graph $graph

            ($styled.Nodes | Where-Object { $_.Id -eq 'action0' } | Select-Object -First 1).ClassKind | Should -Be 'FlowTrigger'
            ($styled.Nodes | Where-Object { $_.Id -eq 'action1' } | Select-Object -First 1).ClassKind | Should -Be 'FlowDecision'
            ($styled.Nodes | Where-Object { $_.Id -eq 'action2' } | Select-Object -First 1).ClassKind | Should -Be 'FlowAction'
            ($styled.Subgraphs[0].Nodes[0]).ClassKind | Should -Be 'FlowAction'

            ($styled.Edges | Where-Object { $_.Label -eq 'Succeeded' } | Select-Object -First 1).Metadata.StyleClass | Should -Be 'FlowSuccessPath'
            ($styled.Edges | Where-Object { $_.Label -eq 'Error' } | Select-Object -First 1).Metadata.StyleClass | Should -Be 'FlowErrorPath'
            ($styled.Edges | Where-Object { $_.Label -eq '' } | Select-Object -First 1).Metadata.StyleClass | Should -Be 'FlowDefaultPath'

            $styled.Styles.ContainsKey('FlowAction') | Should -BeTrue
            $styled.Styles.ContainsKey('FlowSuccessPath') | Should -BeTrue
            @($styled.StyleOrder).Count | Should -BeGreaterThan 0
        }
    }

    It "applies style overrides" {
        InModuleScope PowerPlatformChecker {
            $graph = [pscustomobject]@{
                GraphType = 'FlowchartGraph'
                Direction = 'TB'
                Nodes = @([pscustomobject]@{ Id = 'action0'; Label = 'Do'; Shape = 'Action' })
                Edges = @([pscustomobject]@{ From = 'action0'; Label = 'Succeeded'; To = 'action0' })
                Subgraphs = @()
            }

            $styled = Get-PowerPlatformCheckerFlowChartStyledGraph -Graph $graph -StyleOverrides @{ FlowAction = '#123456'; Stroke = '#654321' }
            $styled.Styles['FlowAction'] | Should -Be 'fill:#123456,stroke:#654321'
        }
    }
}
