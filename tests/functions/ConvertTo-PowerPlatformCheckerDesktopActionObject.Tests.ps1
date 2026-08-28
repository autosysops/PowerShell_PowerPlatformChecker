. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "ConvertTo-PowerPlatformCheckerDesktopActionObject" {
    It "builds desktop action objects for metadata combinations" {
        $minimalAction = InModuleScope PowerPlatformChecker {
            ConvertTo-PowerPlatformCheckerDesktopActionObject -ActionNameCount @{} -BaseName 'WRITE' -ActionType 'WRITE' -RequestedProperties @()
        }

        $minimalAction.Name | Should -Be 'WRITE'
        $minimalAction.PSObject.Properties.Name | Should -Not -Contain 'DisplayName'
        $minimalAction.PSObject.Properties.Name | Should -Not -Contain 'RunAfter'
        $minimalAction.PSObject.Properties.Name | Should -Not -Contain 'ParentAction'
        $minimalAction.PSObject.Properties.Name | Should -Not -Contain 'IsTrigger'

        $runAfterAction = InModuleScope PowerPlatformChecker {
            ConvertTo-PowerPlatformCheckerDesktopActionObject -ActionNameCount @{} -BaseName 'SET' -ActionType 'SET' -RequestedProperties @('RunAfter', 'ParentAction')
        }

        $runAfterAction.Name | Should -Be 'SET'
        $runAfterAction.RunAfter | Should -Be @()
        $runAfterAction.RunAfterStatus | Should -BeNullOrEmpty
        $runAfterAction.ParentAction | Should -BeNullOrEmpty
        $runAfterAction.Depth | Should -Be 0
        $runAfterAction.IsErrorHandler | Should -BeFalse
    }

    It "adds optional flowchart metadata and de-duplicates names" {
        InModuleScope PowerPlatformChecker {
            $nameCount = @{}
            $first = ConvertTo-PowerPlatformCheckerDesktopActionObject -ActionNameCount $nameCount -BaseName 'WAIT' -ActionType 'Wait' -DisplayName 'WAIT for 5 seconds' -RequestedProperties RunAfter,ParentAction,References,Entities -IncludeTrigger
            $second = ConvertTo-PowerPlatformCheckerDesktopActionObject -ActionNameCount $nameCount -BaseName 'WAIT' -ActionType 'Wait' -RunAfterSourceName 'WAIT' -RunAfterLabel 'Succeeded' -ParentAction ([pscustomobject]@{ Name = 'Scope' }) -Depth 1 -IsErrorHandler $true -RequestedProperties RunAfter,ParentAction

            $first.Name | Should -Be 'WAIT'
            $first.DisplayName | Should -Be 'WAIT for 5 seconds'
            $first.IsTrigger | Should -BeFalse
            $second.Name | Should -Be 'WAIT_2'
            $second.RunAfter | Should -Be @('WAIT')
            $second.ParentAction.Name | Should -Be 'Scope'
            $second.Depth | Should -Be 1
            $second.IsErrorHandler | Should -BeTrue
        }
    }
}
