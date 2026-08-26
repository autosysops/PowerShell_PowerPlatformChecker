. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "ConvertTo-PowerPlatformCheckerDesktopActionObject" {
    $cases = @(
        @{
            Name = 'minimal metadata'
            BaseName = 'WRITE'
            ActionType = 'WRITE'
            RequestedProperties = @()
            ExpectedName = 'WRITE'
            ExpectRunAfter = $false
            ExpectParent = $false
            ExpectDisplayName = $false
            ExpectTrigger = $false
        }
        @{
            Name = 'empty runafter metadata'
            BaseName = 'SET'
            ActionType = 'SET'
            RequestedProperties = @('RunAfter', 'ParentAction')
            ExpectedName = 'SET'
            ExpectRunAfter = $true
            ExpectParent = $true
            ExpectDisplayName = $false
            ExpectTrigger = $false
        }
    )

    It "builds desktop action objects for metadata combinations" {
        foreach ($case in $cases) {
            $action = & (Get-Module PowerPlatformChecker) {
                param($baseName, $actionType, $requestedProperties)
                ConvertTo-PowerPlatformCheckerDesktopActionObject -ActionNameCount @{} -BaseName $baseName -ActionType $actionType -RequestedProperties $requestedProperties
            } $case.BaseName $case.ActionType $case.RequestedProperties

            $action.Name | Should -Be $case.ExpectedName -Because $case.Name

            if ($case.ExpectDisplayName) {
                $action.PSObject.Properties.Name | Should -Contain 'DisplayName' -Because $case.Name
            }
            else {
                $action.PSObject.Properties.Name | Should -Not -Contain 'DisplayName' -Because $case.Name
            }

            if ($case.ExpectRunAfter) {
                $action.RunAfter | Should -Be @() -Because $case.Name
                $action.RunAfterStatus | Should -BeNullOrEmpty -Because $case.Name
            }
            else {
                $action.PSObject.Properties.Name | Should -Not -Contain 'RunAfter' -Because $case.Name
            }

            if ($case.ExpectParent) {
                $action.ParentAction | Should -BeNullOrEmpty -Because $case.Name
                $action.Depth | Should -Be 0 -Because $case.Name
                $action.IsErrorHandler | Should -BeFalse -Because $case.Name
            }
            else {
                $action.PSObject.Properties.Name | Should -Not -Contain 'ParentAction' -Because $case.Name
            }

            if ($case.ExpectTrigger) {
                $action.PSObject.Properties.Name | Should -Contain 'IsTrigger' -Because $case.Name
            }
            else {
                $action.PSObject.Properties.Name | Should -Not -Contain 'IsTrigger' -Because $case.Name
            }
        }
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
