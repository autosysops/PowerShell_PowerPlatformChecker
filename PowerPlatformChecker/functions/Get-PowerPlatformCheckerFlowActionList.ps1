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

    .PARAMETER References
        A switch to indicate if action references should be included in the list

    .EXAMPLE
        Get a list of actions in a Power Platform flow

        PS> Get-PowerPlatformCheckerFlowActionList -Actions $flowdata.definition.actions

    .EXAMPLE
        Get a list of actions in a Power Platform flow including nested actions

        PS> Get-PowerPlatformCheckerFlowActionList -Actions $flowdata.definition.actions -Recurse
    #>

    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Path', Position = 1)]
        [String] $Path,

        [Parameter(Mandatory = $true, ParameterSetName = 'Actions', Position = 1)]
        [Object] $Actions,

        [Parameter(Mandatory = $false, ParameterSetName = 'Actions', Position = 2)]
        [Parameter(Mandatory = $false, ParameterSetName = 'Path', Position = 2)]
        [Switch] $Recurse,

        [Parameter(Mandatory = $false, ParameterSetName = 'Actions', Position = 3)]
        [Parameter(Mandatory = $false, ParameterSetName = 'Path', Position = 3)]
        [Switch] $References
    )

    # Send telemetry data
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerFlowActionList"

    # Import the flow data
    if ($Path) {
        $flowdata = Import-PowerPlatformCheckerFlow -Path $Path
        $actions = $flowdata.properties.definition.actions
    }

    # Loop through the actions and get the information of the actions, if there are nested actions then loop through those as well
    $actionsList = $actions | Get-Member -MemberType NoteProperty | ForEach-Object {
        if ($actions.$($_.Name).actions -and $Recurse) {
            Get-PowerPlatformCheckerFlowActionList -Actions $actions.$($_.Name).actions -Recurse -References:$References
        }
        else {
            $type = $actions.$($_.Name).type
            $group = "*"
            if ($type -eq "OpenApiConnection") {
                $type = $actions.$($_.Name).inputs.host.operationId
                $group = $actions.$($_.Name).inputs.host.apiId.split("/")[-1]
            }

            $actionObject = [pscustomobject]@{
                Name  = $_.Name
                Type  = $type
                Group = $group
            }

            if ($References) {
                $reference = ""

                if ($type -eq "Workflow") {
                    $reference = $actions.$($_.Name).inputs.host.workflowReferenceName
                }

                $actionObject | Add-Member -MemberType NoteProperty -Name "Reference" -Value $reference
            }

            $actionObject
        }
    }

    # Return the list of actions
    return $actionsList
}