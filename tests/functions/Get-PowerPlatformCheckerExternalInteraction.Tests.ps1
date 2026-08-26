. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerExternalInteraction" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
    }

    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {}
    }

    It "returns a combined graph for multiple solution inputs" {
        $graph = Get-PowerPlatformCheckerExternalInteraction -SolutionPaths @($script:solutionPath, $script:solutionPath) -OutputFormat Graph

        $graph.Metadata.SourceSolutionCount | Should -Be 1
        ($graph.Nodes | Where-Object Type -eq 'Solution').Count | Should -Be 1
        ($graph.Nodes | Where-Object { $_.Type -in @('Flow', 'CanvasApp', 'ModelDrivenApp', 'Entity', 'WebResource') }).Count | Should -Be 0
        $graph.Edges.Count | Should -BeGreaterThan 0
        (($graph.Edges | Select-Object -ExpandProperty SourceId | Sort-Object -Unique).Count) | Should -Be 1
        (($graph.Edges | Select-Object -ExpandProperty Label) -contains 'SET') | Should -BeTrue
    }

    It "supports include and exclude folder filters" {
        $parent = Split-Path $script:solutionPath -Parent
        $folderName = Split-Path $script:solutionPath -Leaf

        $included = Get-PowerPlatformCheckerExternalInteraction -SolutionPaths @($parent) -IncludeSolutionFolders @($folderName) -OutputFormat Graph
        $excluded = Get-PowerPlatformCheckerExternalInteraction -SolutionPaths @($parent) -ExcludeSolutionFolders @($folderName) -OutputFormat Graph

        $included.Metadata.SourceSolutionCount | Should -BeGreaterThan 0
        $excluded.Metadata.SourceSolutionCount | Should -Be 0
    }

    It "supports recursive discovery and mermaid output" {
        $parent = Split-Path $script:solutionPath -Parent
        $folderName = Split-Path $script:solutionPath -Leaf

        $markdown = Get-PowerPlatformCheckerExternalInteraction -SolutionPaths @($parent) -Recurse -IncludeSolutionFolders @($folderName) -OutputFormat Mermaid

        $markdown | Should -Match ":::mermaid"
        $markdown | Should -Match "classDiagram"
    }

    It "emits condensed directional edges toward external targets" {
        $graph = Get-PowerPlatformCheckerExternalInteraction -SolutionPaths @($script:solutionPath) -OutputFormat Graph
        $solutionNode = $graph.Nodes | Where-Object Type -eq 'Solution' | Select-Object -First 1

        $solutionNode | Should -Not -BeNullOrEmpty
        ($graph.Edges | Where-Object { $_.SourceId -eq $solutionNode.Id }).Count | Should -BeGreaterThan 0
        (($graph.Edges | Select-Object -ExpandProperty Label) | Where-Object { $_ -in @('GET', 'SET', 'GET/SET', 'Unknown') }).Count | Should -BeGreaterThan 0
    }

    It "creates synthetic destination nodes from flow destination metadata" {
        $graph = Get-PowerPlatformCheckerExternalInteraction -SolutionPaths @($script:solutionPath) -OutputFormat Graph

        ($graph.Nodes | Where-Object { $_.Type -eq 'ExternalDomain' -and $_.DisplayName -eq 'api.contoso.example' }).Count | Should -BeGreaterThan 0
        ($graph.Nodes | Where-Object { $_.Type -eq 'Connection' -and $_.DisplayName -eq 'office365' }).Count | Should -BeGreaterThan 0
    }

    It "sends sanitized telemetry" {
        $telemetryCalls = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {
            param([string]$ModuleName, [string]$EventName, [hashtable]$PropertiesHash)
            [void]$telemetryCalls.Add([pscustomobject]@{ ModuleName = $ModuleName; EventName = $EventName; PropertiesHash = $PropertiesHash })
        }

        [void](Get-PowerPlatformCheckerExternalInteraction -SolutionPaths @($script:solutionPath) -OutputFormat Graph)
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerExternalInteraction" -ExpectedKeys @("PathCount", "Recurse", "IncludeFilterCount", "ExcludeFilterCount", "Direction", "OutputFormat") -ConfidentialValues @($script:solutionPath)
    }

}
