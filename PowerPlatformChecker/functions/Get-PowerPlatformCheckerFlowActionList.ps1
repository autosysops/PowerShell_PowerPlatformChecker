function Get-PowerPlatformCheckerFlowActionList {
    <#
    .SYNOPSIS
        Gets a list of actions in a Power Platform flow

    .DESCRIPTION
        Gets a list of actions in a Power Platform flow, if the flow contains nested actions it will get those as well if the recurse switch is used

    .PARAMETER Path
        The file path to the flow json file

    .PARAMETER Actions
        The actions object from the flow json file

    .PARAMETER Recurse
        A switch to indicate if nested actions should be included in the list

    .PARAMETER IncludeTrigger
        A switch to indicate if the trigger should be included in the list

    .PARAMETER Properties
        A list of additional properties to include in the output, options are References, Entities, RunAfter, and ParentAction

    .EXAMPLE
        Get a list of actions in a Power Platform flow

        PS> Get-PowerPlatformCheckerFlowActionList -Actions $flowdata.definition.actions

    .EXAMPLE
        Get a list of actions in a Power Platform flow including nested actions

        PS> Get-PowerPlatformCheckerFlowActionList -Actions $flowdata.definition.actions -Recurse

    .EXAMPLE
        Get a list of actions in a Power Platform flow including the references of the actions

        PS> Get-PowerPlatformCheckerFlowActionList -Actions $flowdata.definition.actions -Properties References

    .EXAMPLE
        Get a list of actions in a Power Platform flow including the actions that run after each action

        PS> Get-PowerPlatformCheckerFlowActionList -Actions $flowdata.definition.actions -Properties RunAfter

    .EXAMPLE
        Get a list of actions in a Power Platform flow including the parent action of each action

        PS> Get-PowerPlatformCheckerFlowActionList -Actions $flowdata.definition.actions -Properties ParentAction

    .EXAMPLE
        Get a list including the triggers in a Power Platform flow

        PS> Get-PowerPlatformCheckerFlowActionList -Path C:\Path\To\Flow -IncludeTrigger
    #>

    [CmdLetBinding(defaultParameterSetName = "Path")]
    Param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Path', Position = 1)]
        [String] $Path,

        [Parameter(Mandatory = $true, ParameterSetName = 'Actions', Position = 1)]
        [Object] $Actions,

        [Parameter(Mandatory = $false, ParameterSetName = 'Actions', Position = 3)]
        [Parameter(Mandatory = $false, ParameterSetName = 'Path', Position = 3)]
        [Switch] $Recurse,

        [Parameter(Mandatory = $false, ParameterSetName = 'Actions', Position = 4)]
        [Parameter(Mandatory = $false, ParameterSetName = 'Path', Position = 4)]
        [Switch] $IncludeTrigger,

        [Parameter(Mandatory = $false, ParameterSetName = 'Actions', Position = 5)]
        [Parameter(Mandatory = $false, ParameterSetName = 'Path', Position = 5)]
        [ValidateSet("References", "Entities", "RunAfter", "ParentAction")]
        [String[]] $Properties
    )

    # Send telemetry data
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerFlowActionList"

    # Call the internal function to get the list of actions
    if($Path) {
        return Get-PowerPlatformCheckerFlowActionListInternal -Path $Path -Recurse:$Recurse -IncludeTrigger:$IncludeTrigger -Properties $Properties
    }
    if ($Actions) {
        return Get-PowerPlatformCheckerFlowActionListInternal -Actions $Actions -Recurse:$Recurse -IncludeTrigger:$IncludeTrigger -Properties $Properties
    }
}