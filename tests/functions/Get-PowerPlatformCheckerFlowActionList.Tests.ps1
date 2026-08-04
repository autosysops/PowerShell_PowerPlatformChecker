. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerFlowActionList" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
        $script:flowPath = Join-Path $script:solutionPath "Workflows\SampleFlow-11111111-1111-1111-1111-111111111111.json"
    }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "returns recursive actions, trigger, and parent metadata" {
        $actions = Get-PowerPlatformCheckerFlowActionList -Path $script:flowPath -Recurse -IncludeTrigger -Properties References,Entities,RunAfter,ParentAction

        ($actions | Where-Object IsTrigger).Count | Should -Be 1
        ($actions | Where-Object Name -EQ "Send_an_email").ParentAction.Type | Should -Be "actions"
        ($actions | Where-Object Name -EQ "Update_row").ParentAction.Type | Should -Be "else"
        ($actions | Where-Object Name -EQ "Call_Child_Workflow").Reference | Should -Be "22222222-2222-2222-2222-222222222222"
        ($actions | Where-Object Name -EQ "Create_orderline").Entities | Should -Contain "ppc_orderlines"
    }
}

