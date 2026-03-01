function Get-PowerPlatformCheckerFlowActionDefaultName {
    <#
    .SYNOPSIS
        Get the default name of an action in a Power Platform flow

    .DESCRIPTION
        Get the default name of an action in a Power Platform flow

    .PARAMETER Type
        The type of the action

    .PARAMETER Group
        The group of the action

    .EXAMPLE
        Get the default name of an action in a flow

        PS> Get-PowerPlatformCheckerFlowActionDefaultName -Type "Http" -Group "*"
    #>

    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)]
        [String] $Type,

        [Parameter(Mandatory = $true, Position = 2, ValueFromPipelineByPropertyName = $true)]
        [String] $Group
    )

    Process {
        # Send telemetry data
        Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerFlowActionDefaultName"

        # Get the operation data
        if ($Group -ne "*") {
            $opdata = Get-PowerPlatformCheckerOperationData -Name $Type -Group $Group
        }
        else {
            $opdata = Get-PowerPlatformCheckerOperationData -OperationType $Type -Group $Group
        }

        # Check if multiple entries are returned, if so try to find the one that is marked as default
        if ($opdata.count -gt 1) {
            $opdata = $opdata | Where-Object { $_.builtin -eq $true }
        }

        # Return the summary of the operation data
        return $opdata.summary
    }
}