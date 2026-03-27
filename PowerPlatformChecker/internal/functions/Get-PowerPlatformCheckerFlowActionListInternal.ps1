function Get-PowerPlatformCheckerFlowActionListInternal {
    <#
    .SYNOPSIS
        Gets a list of actions in a Power Platform flow

    .DESCRIPTION
        Gets a list of actions in a Power Platform flow, if the flow contains nested actions it will get those as well if the recurse switch is used

    .PARAMETER Path
        The file path to the flow json file

    .PARAMETER Actions
        The actions object from the flow json file

    .PARAMETER ParentAction
        The name of the parent action if the current actions are nested

    .PARAMETER Recurse
        A switch to indicate if nested actions should be included in the list

    .PARAMETER IncludeTrigger
        A switch to indicate if the trigger should be included in the list

    .PARAMETER Properties
        A list of additional properties to include in the output, options are References, RunAfter, and ParentAction

    .PARAMETER IsTrigger
        A switch to indicate if the current actions are triggers, used in combination with the IncludeTrigger switch

    .PARAMETER Depth
        An integer to indicate how deep the action is nested, used for internal purposes when calling recursively

    .EXAMPLE
        Get a list of actions in a Power Platform flow

        PS> Get-PowerPlatformCheckerFlowActionListInternal -Actions $flowdata.definition.actions

    .EXAMPLE
        Get a list of actions in a Power Platform flow including nested actions

        PS> Get-PowerPlatformCheckerFlowActionListInternal -Actions $flowdata.definition.actions -Recurse

    .EXAMPLE
        Get a list of actions in a Power Platform flow including the references of the actions

        PS> Get-PowerPlatformCheckerFlowActionListInternal -Actions $flowdata.definition.actions -Properties References

    .EXAMPLE
        Get a list of actions in a Power Platform flow including the actions that run after each action

        PS> Get-PowerPlatformCheckerFlowActionListInternal -Actions $flowdata.definition.actions -Properties RunAfter

    .EXAMPLE
        Get a list of actions in a Power Platform flow including the parent action of each action

        PS> Get-PowerPlatformCheckerFlowActionListInternal -Actions $flowdata.definition.actions -Properties ParentAction

    .EXAMPLE
        Get a list of actions in a Power Platform flow with a specific parent action

        PS> Get-PowerPlatformCheckerFlowActionListInternal -Actions $flowdata.definition.actions -Properties ParentAction -ParentAction "Apply_to_each"

    .EXAMPLE
        Get a list including the triggers in a Power Platform flow

        PS> Get-PowerPlatformCheckerFlowActionListInternal -Path C:\Path\To\Flow -IncludeTrigger

    .EXAMPLE
        Get a list including the triggers in a Power Platform flow where the actions are set to be a trigger

        PS> Get-PowerPlatformCheckerFlowActionListInternal -Actions $flowdata.definition.triggers -IncludeTrigger -IsTrigger

    .EXAMPLE
        Get a list of actions in a Power Platform flow by providing the path to the flow file

        PS> Get-PowerPlatformCheckerFlowActionListInternal -Path C:\Path\To\Flow

    .EXAMPLE
        Get a list of action and add a specific depth value to the output

        PS> Get-PowerPlatformCheckerFlowActionListInternal -Actions $flowdata.definition.actions -Recurse -Properties ParentAction -Depth 2
    #>

    [CmdLetBinding(defaultParameterSetName = "Path")]
    Param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Path', Position = 1)]
        [String] $Path,

        [Parameter(Mandatory = $true, ParameterSetName = 'Actions', Position = 1)]
        [Object] $Actions,

        [Parameter(Mandatory = $false, ParameterSetName = 'Actions', Position = 2)]
        [Parameter(Mandatory = $false, ParameterSetName = 'Path', Position = 2)]
        [Object] $ParentAction = $null,

        [Parameter(Mandatory = $false, ParameterSetName = 'Actions', Position = 3)]
        [Parameter(Mandatory = $false, ParameterSetName = 'Path', Position = 3)]
        [Switch] $Recurse,

        [Parameter(Mandatory = $false, ParameterSetName = 'Actions', Position = 4)]
        [Parameter(Mandatory = $false, ParameterSetName = 'Path', Position = 4)]
        [Switch] $IncludeTrigger,

        [Parameter(Mandatory = $false, ParameterSetName = 'Actions', Position = 5)]
        [Parameter(Mandatory = $false, ParameterSetName = 'Path', Position = 5)]
        [ValidateSet("References", "Entities", "RunAfter", "ParentAction")]
        [String[]] $Properties,

        [Parameter(Mandatory = $false, ParameterSetName = 'Actions', Position = 6)]
        [Parameter(Mandatory = $false, ParameterSetName = 'Path', Position = 6)]
        [Switch] $IsTrigger,

        [Parameter(Mandatory = $false, ParameterSetName = 'Actions', Position = 7)]
        [Parameter(Mandatory = $false, ParameterSetName = 'Path', Position = 7)]
        [int] $Depth = 0
    )

    # Send telemetry data
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerFlowActionListInternal"

    # Import the flow data
    if ($Path) {
        $flowdata = Import-PowerPlatformCheckerFlow -Path $Path
        $actions = $flowdata.properties.definition.actions
    }

    # Create an empty actionList
    $actionsList = @()

    # If the trigger is included call this recursivly to add the trigger as well
    if ($IncludeTrigger -and $ParentAction -eq $null) {
        $actionsList += Get-PowerPlatformCheckerFlowActionListInternal -Actions $flowdata.properties.definition.triggers -ParentAction "Trigger" -Recurse:$Recurse -Properties $Properties -IncludeTrigger -IsTrigger -Depth $Depth
    }

    # Loop through the actions and get the information of the actions, if there are nested actions then loop through those as well
    $actionsList += $actions | Get-Member -MemberType NoteProperty | ForEach-Object {
        if ($actions.$($_.Name).actions -and $Recurse) {
            Get-PowerPlatformCheckerFlowActionListInternal -Actions $actions.$($_.Name).actions -ParentAction @{"Name" = $($_.Name); "Type" = "actions"} -Recurse -IncludeTrigger:$IncludeTrigger -Properties $Properties -Depth ($Depth + 1)

            # Check if there is an else statement and loop through those actions as well
            if ($actions.$($_.Name).else -and $Recurse) {
                Get-PowerPlatformCheckerFlowActionListInternal -Actions $actions.$($_.Name).else.actions -ParentAction @{"Name" = $($_.Name); "Type" = "else"} -Recurse -IncludeTrigger:$IncludeTrigger -Properties $Properties -Depth ($Depth + 1)
            }
        }
        # Store the data from the action
        $type = $actions.$($_.Name).type
        $group = "*"
        if ($type -eq "OpenApiConnection" -or $type -eq "OpenApiConnectionWebhook") {
            $type = $actions.$($_.Name).inputs.host.operationId
            $group = $actions.$($_.Name).inputs.host.apiId.split("/")[-1]
        }

        $actionObject = [pscustomobject]@{
            Name  = $_.Name
            Type  = $type
            Group = $group
        }

        if ($Properties -contains "References") {
            $reference = ""

            if ($type -eq "Workflow") {
                $reference = $actions.$($_.Name).inputs.host.workflowReferenceName
            }

            $actionObject | Add-Member -MemberType NoteProperty -Name "Reference" -Value $reference
        }

        if ($Properties -contains "RunAfter") {
            # Triggers never have a runafter so make sure it's set to empty
            if($IsTrigger) {
                $runAfterActions = ""
            }
            else {
                $runAfterActions = $actions.$($_.Name).runAfter | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
            }
            $actionObject | Add-Member -MemberType NoteProperty -Name "RunAfter" -Value $runAfterActions
        }

        if ($Properties -contains "ParentAction") {
            # To make sure no infinite loop occurs the parent action is filled when calling recursively for a trigger, here we empty it if looking for a trigger
            if($IsTrigger) {
                $ParentAction = $null
            }
            $actionObject | Add-Member -MemberType NoteProperty -Name "ParentAction" -Value $ParentAction

            # Also add a depth property to indicate how deep the action is nested
            $actionObject | Add-Member -MemberType NoteProperty -Name "Depth" -Value $Depth
        }

        if ($IncludeTrigger) {
            $actionObject | Add-Member -MemberType NoteProperty -Name "IsTrigger" -Value $IsTrigger.IsPresent
        }

        if ($Properties -contains "Entities") {
            $entities = @()

            if ($actions.$($_.Name).inputs.parameters) {
                if($actions.$($_.Name).inputs.parameters.entityName) {
                    $entities += $actions.$($_.Name).inputs.parameters.entityName
                }

                if($actions.$($_.Name).inputs.parameters."subscriptionRequest/entityname") {
                    $entities += $actions.$($_.Name).inputs.parameters."subscriptionRequest/entityname"
                }
            }

            $actionObject | Add-Member -MemberType NoteProperty -Name "Entities" -Value ($entities | Sort-Object -Unique)
        }

        $actionObject
    }

    # Return the list of actions
    return $actionsList
}