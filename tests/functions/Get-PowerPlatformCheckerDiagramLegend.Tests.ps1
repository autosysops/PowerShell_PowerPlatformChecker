. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerDiagramLegend" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
    }

    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {}
    }

    It "returns architecture legend markdown using style values" {
        $legend = Get-PowerPlatformCheckerDiagramLegend -DiagramType ArchitectureDiagram

        $legend | Should -Match "### Diagram Legend"
        $legend | Should -Match "Flow"
        $legend | Should -Match "CanvasApp"
    }

    It "returns external interaction legend markdown with aliases and connector codes" {
        $graph = Get-PowerPlatformCheckerExternalInteraction -SolutionPaths @($script:solutionPath) -OutputFormat Graph
        $legend = Get-PowerPlatformCheckerDiagramLegend -DiagramType ExternalInteraction -Graph $graph

        $legend | Should -Match "### Flow and App Aliases"
        $legend | Should -Match "Flow-"
        $legend | Should -Match "### Connector Codes"
        $legend | Should -Match "C[0-9]{2} ="
    }

    It "shows only relevant external diagram classes and omits the Azure DevOps note" {
        $graph = Get-PowerPlatformCheckerExternalInteraction -SolutionPaths @($script:solutionPath) -OutputFormat Graph
        $legend = Get-PowerPlatformCheckerDiagramLegend -DiagramType ExternalInteraction -Graph $graph

        $legend | Should -Match '<span style="color:#FCD757">Connection</span>'
        $legend | Should -Match '<span style="color:#f5f5fa">Solution</span>'
        $legend | Should -Match '<span style="color:#E6D3A3">ExternalDomain</span>'
        $legend | Should -Not -Match '<span style="color:[^"]+">CanvasApp</span>'
        $legend | Should -Not -Match '<span style="color:[^"]+">ModelDrivenApp</span>'
        $legend | Should -Not -Match '<span style="color:[^"]+">Entity</span>'
        $legend | Should -Not -Match '<span style="color:[^"]+">C[0-9]{2}</span>'
        $legend | Should -Match '(?m)^- C[0-9]{2} = '
        $legend | Should -Not -Match 'Azure DevOps Mermaid does not reliably support per-edge-label text colors'
    }

    It "returns structured legend object" {
        $graph = Get-PowerPlatformCheckerExternalInteraction -SolutionPaths @($script:solutionPath) -OutputFormat Graph
        $legendObject = Get-PowerPlatformCheckerDiagramLegend -DiagramType ExternalInteraction -Graph $graph -OutputFormat Object

        $legendObject.DiagramType | Should -Be "ExternalInteraction"
        @($legendObject.StyleItems).Count | Should -BeGreaterThan 0
        @($legendObject.SourceAliases).Count | Should -BeGreaterThan 0
    }

    It "sends sanitized telemetry" {
        $telemetryCalls = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {
            param([string]$ModuleName, [string]$EventName, [hashtable]$PropertiesHash)
            [void]$telemetryCalls.Add([pscustomobject]@{ ModuleName = $ModuleName; EventName = $EventName; PropertiesHash = $PropertiesHash })
        }

        [void](Get-PowerPlatformCheckerDiagramLegend -DiagramType ArchitectureDiagram)
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerDiagramLegend" -ExpectedKeys @("DiagramType", "HasGraph", "OutputFormat", "HasStyleOverrides")
    }
}
