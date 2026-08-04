. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerArchitectureDiagram" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
        $script:expectedFull = Get-PowerPlatformCheckerExpectedSnapshot -FileName "ArchitectureDiagram.Full.expected.md"
        $script:expectedModelDriven = Get-PowerPlatformCheckerExpectedSnapshot -FileName "ArchitectureDiagram.ModelDriven.expected.md"
        $script:expectedFlowDirectionTb = Get-PowerPlatformCheckerExpectedSnapshot -FileName "ArchitectureDiagram.Flow.TB.expected.md"
        $script:expectedCanvasDirectionRl = Get-PowerPlatformCheckerExpectedSnapshot -FileName "ArchitectureDiagram.CanvasApp.RL.expected.md"
        $script:expectedModelDrivenDirectionBt = Get-PowerPlatformCheckerExpectedSnapshot -FileName "ArchitectureDiagram.ModelDriven.BT.expected.md"
        $script:expectedFlowsOnly = Get-PowerPlatformCheckerExpectedSnapshot -FileName "ArchitectureDiagram.FlowsOnly.expected.md"
        $script:expectedFlowStyleOverride = Get-PowerPlatformCheckerExpectedSnapshot -FileName "ArchitectureDiagram.Flow.StyleOverride.expected.md"
    }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "matches the expected full architecture diagram snapshot" {
        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath

        (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedFull)
    }

    It "full diagram contains multiple resource categories" {
        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath

        $markdown | Should -Match ":::Flow"
        $markdown | Should -Match ":::CanvasApp"
        $markdown | Should -Match ":::ModelDrivenApp"
        $markdown | Should -Match ":::Connection"
        $markdown | Should -Match ":::Entity"
        $markdown | Should -Match ":::WebResource"
    }

    It "supports flow filtering" {
        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -FlowId "11111111-1111-1111-1111-111111111111"
        $markdown | Should -Match "flow11111111-1111-1111-1111-111111111111"
        $markdown | Should -Not -Match "flow22222222-2222-2222-2222-222222222222"
        $markdown | Should -Not -Match "class ppc_canvas_sales_0001"
    }

    It "supports canvas app filtering" {
        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -CanvasAppName "ppc_canvas_sales_0001"
        $markdown | Should -Match "class ppc_canvas_sales_0001"
        $markdown | Should -Not -Match "class ppc_ModelApp"
        $markdown | Should -Not -Match "flow11111111-1111-1111-1111-111111111111"
        $markdown | Should -Not -Match ([regex]::Escape('class [""]'))
    }

    It "matches the expected model-driven filtered architecture snapshot" {
        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -ModelDrivenAppName "ppc_ModelApp"

        (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedModelDriven)

        $markdown | Should -Match "class ppc_ModelApp"
        $markdown | Should -Not -Match "class ppc_canvas_sales_0001"
    }

    It "matches expected flow-scoped diagram with custom direction" {
        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -FlowId "11111111-1111-1111-1111-111111111111" -Direction TB

        (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedFlowDirectionTb)
    }

    It "matches expected canvas-scoped diagram with custom direction" {
        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -CanvasAppName "ppc_canvas_sales_0001" -Direction RL

        (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedCanvasDirectionRl)
    }

    It "matches expected model-driven scoped diagram with custom direction" {
        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -ModelDrivenAppName "ppc_ModelApp" -Direction BT

        (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedModelDrivenDirectionBt)
    }

    It "matches expected include-element filtered diagram" {
        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -IncludeElements Flows

        (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedFlowsOnly)
    }

    It "matches expected style-override diagram" {
        $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath -FlowId "22222222-2222-2222-2222-222222222222" -StyleOverrides @{ Flow = "#123456"; Stroke = "#010203" }

        (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedFlowStyleOverride)
    }

    It "supports session-level style updates via Set-PowerPlatformCheckerDiagramStyle" {
        try {
            Set-PowerPlatformCheckerDiagramStyle -ColorMap @{ Flow = "#445566" } | Out-Null
            $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath $script:solutionPath
            $markdown | Should -Match "classDef Flow fill:#445566,stroke:#5E5B52"
        }
        finally {
            Set-PowerPlatformCheckerDiagramStyle -ColorMap @{ Flow = "#DBE4EE" } | Out-Null
        }
    }

    It "rejects unsupported style keys" {
        { Set-PowerPlatformCheckerDiagramStyle -ColorMap @{ NotARealKey = "#000000" } } | Should -Throw
    }
}

