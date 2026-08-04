. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerFlowChart" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
        $script:flowPath = Join-Path $script:solutionPath "Workflows\SampleFlow-11111111-1111-1111-1111-111111111111.json"
        $script:childFlowPath = Join-Path $script:solutionPath "Workflows\ChildFlow-22222222-2222-2222-2222-222222222222.json"
        $script:expectedFlowChart = Get-PowerPlatformCheckerExpectedSnapshot -FileName "FlowChart.SampleFlow.expected.md"
        $script:expectedSampleLr = Get-PowerPlatformCheckerExpectedSnapshot -FileName "FlowChart.SampleFlow.LR.expected.md"
        $script:expectedSampleRl = Get-PowerPlatformCheckerExpectedSnapshot -FileName "FlowChart.SampleFlow.RL.expected.md"
        $script:expectedChildBt = Get-PowerPlatformCheckerExpectedSnapshot -FileName "FlowChart.ChildFlow.BT.expected.md"
        $script:expectedEmptyRl = Get-PowerPlatformCheckerExpectedSnapshot -FileName "FlowChart.Empty.RL.expected.md"

        $script:sampleActions = Get-PowerPlatformCheckerFlowActionList -Path $script:flowPath -Recurse -IncludeTrigger -Properties References,Entities,RunAfter,ParentAction
        $script:childActions = Get-PowerPlatformCheckerFlowActionList -Path $script:childFlowPath -Recurse -IncludeTrigger -Properties References,Entities,RunAfter,ParentAction
    }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "matches the expected flowchart snapshot" {
        $markdown = Get-PowerPlatformCheckerFlowChart -Actions $script:sampleActions

        (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedFlowChart)
    }

    It "matches expected sample-flow chart in LR direction" {
        $markdown = Get-PowerPlatformCheckerFlowChart -Actions $script:sampleActions -Direction LR

        (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedSampleLr)
    }

    It "matches expected sample-flow chart in RL direction" {
        $markdown = Get-PowerPlatformCheckerFlowChart -Actions $script:sampleActions -Direction RL

        (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedSampleRl)
    }

    It "matches expected child-flow chart in BT direction" {
        $markdown = Get-PowerPlatformCheckerFlowChart -Actions $script:childActions -Direction BT

        (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedChildBt)
    }

    It "matches expected empty-input chart in RL direction" {
        $markdown = Get-PowerPlatformCheckerFlowChart -Actions @() -Direction RL

        (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
            Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $script:expectedEmptyRl)
    }
}

