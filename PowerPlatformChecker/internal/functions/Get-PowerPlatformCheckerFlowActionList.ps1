function Get-PowerPlatformCheckerFlowActionList {
    <#
    .SYNOPSIS
        Gets a list of actions in a Power Platform flow

    .DESCRIPTION
        Gets a list of actions in a Power Platform flow, if the flow contains nested actions it will get those as well if the recurse switch is used

    .PARAMETER Actions
        The actions object from the flow json file

    .PARAMETER Recurse
        A switch to indicate if nested actions should be included in the list

    .EXAMPLE
        Get a list of actions in a Power Platform flow

        PS> Get-PowerPlatformCheckerFlowActionList -Actions $flowdata.definition.actions

    .EXAMPLE
        Get a list of actions in a Power Platform flow including nested actions

        PS> Get-PowerPlatformCheckerFlowActionList -Actions $flowdata.definition.actions -Recurse
    #>

    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [Object] $Actions,

        [Parameter(Mandatory = $false, Position = 2)]
        [Switch] $Recurse
    )

    # Send telemetry data
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerFlowActionList"

    # Loop through the actions and get the information of the actions, if there are nested actions then loop through those as well
    $ActionsList = $Actions | Get-Member -MemberType NoteProperty | ForEach-Object {
        if ($Actions.$($_.Name).actions -and $Recurse) {
            Get-PowerPlatformCheckerFlowActionList -Actions $Actions.$($_.Name).actions -Recurse
        }
        else {
            $type = $Actions.$($_.Name).type
            $group = "*"
            if($type -eq "OpenApiConnection") {
                $type = $Actions.$($_.Name).inputs.host.operationId
                $group = $Actions.$($_.Name).inputs.host.connectionName
            }

            [pscustomobject]@{
                Name = $_.Name
                Type = $type
                Group = $group
            }
        }
    }

    # Return the list of actions
    return $ActionsList
}