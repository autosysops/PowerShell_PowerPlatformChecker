function Test-PowerPlatformCheckerFlowOperationName {
    <#
    .SYNOPSIS
        This function tests if the action name of a flow action is the same as the default name of the action.

    .DESCRIPTION
        This function tests if the action name of a flow action is the same as the default name of the action. This is important because if the action name is changed, it can cause issues with the flow and make it harder to maintain.

    .PARAMETER Path
        The path to the flow json file

    .EXAMPLE
        This command tests if the action name of the flow actions in the MyFlow.json file is the same as the default name of the action.

        Test-PowerPlatformCheckerFlowOperationName -Path "C:\Flows\MyFlow.json"
    #>

    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [String] $Path
    )

    # Send telemetry data
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Test-PowerPlatformCheckerFlowOperationName"

    # Get the list of actions in the flow
    $actionlist = Get-PowerPlatformCheckerFlowActionList -Path $Path -Recurse

    # Loop through the actions and get the default name of the action
    $testedactionlist = foreach ($action in $actionlist) {
        $defaultname = $action | Get-PowerPlatformCheckerFlowActionDefaultName
        # It's possible there are more default names for some build in flows so loop through the default names
        $equal = $false
        foreach($dn in $defaultname) {
            # Spaces in the action name are replaced with underscores in the default name, so replace those back to spaces before comparing
            # If multiple of the same action exists a number is added to the end of the action name, so remove that before comparing
            $actionname = $action.Name -replace "_", " " -replace "\s\d+$", ""
            if ($dn -eq $actionname) {
                $equal = $true
            }
        }
        # Create a object with the result
        [PSCustomObject] @{
            ActionName = $action.Name
            DefaultName = $defaultname -join ", "
            Equal = $equal
        }
    }

    # Return the list of actions with the result
    return $testedactionlist
}