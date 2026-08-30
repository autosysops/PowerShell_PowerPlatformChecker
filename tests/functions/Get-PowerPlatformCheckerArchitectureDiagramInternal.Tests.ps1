. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerArchitectureDiagramInternal" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
    }

    It "returns a scoped graph when FlowId filter is used" {
        InModuleScope PowerPlatformChecker {
            param($Path)

            Get-PowerPlatformCheckerArchitectureDiagramInternal `
                -SolutionPath $Path `
                -FlowId '11111111-1111-1111-1111-111111111111' `
                -Direction 'LR' `
                -IncludeElements @('Flows', 'Entities', 'WebResources')
        } -Parameters @{ Path = $script:solutionPath } | ForEach-Object {
            $_.Metadata.IsScopedDiagram | Should -BeTrue
            $_.Metadata.SourceFilterType | Should -Be 'Flow'
            $_.Metadata.SourceFilterValue | Should -Be '11111111-1111-1111-1111-111111111111'
            @($_.Nodes).Count | Should -BeGreaterThan 0
            @($_.Nodes | Where-Object { $_.ClassKind -eq 'WebResource' }).Count | Should -Be 0
        }
    }

    It "returns an unscoped graph when no source filter is provided" {
        InModuleScope PowerPlatformChecker {
            param($Path)

            Get-PowerPlatformCheckerArchitectureDiagramInternal `
                -SolutionPath $Path `
                -Direction 'TB' `
                -IncludeElements @('Flows', 'Connections')
        } -Parameters @{ Path = $script:solutionPath } | ForEach-Object {
            $_.Metadata.IsScopedDiagram | Should -BeFalse
            $_.Metadata.SourceFilterType | Should -Be 'None'
            $_.Metadata.Direction | Should -Be 'TB'
            @($_.Nodes).Count | Should -BeGreaterThan 0
        }
    }
}
