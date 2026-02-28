function Get-PowerPlatformCheckerOperationData {
    <#
    .SYNOPSIS
        Get data for all Power Platform Operations

    .DESCRIPTION
        Get data for all Power Platform Operations

    .PARAMETER Name
        The name of the operation

    .PARAMETER Usage
        The usage type of the operation (Trigger, Action, TriggerInAction)

    .PARAMETER Group
        The group of the operation

    .EXAMPLE
        Get the Data

        PS> Get-PowerPlatformCheckerOperationData

    .EXAMPLE
        Get the Data for Trigger Operations

        PS> Get-PowerPlatformCheckerOperationData -Usage Trigger

    .EXAMPLE
        Get the Data for Operations in the "Control" group

        PS> Get-PowerPlatformCheckerOperationData -Group "Control"
    #>

    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory = $false, Position = 1)]
        [String] $Name = "*",

        [Parameter(Mandatory = $false, Position = 2)]
        [String] $OperationType = "*",

        [Parameter(Mandatory = $false, Position = 3)]
        [ValidateSet("Trigger","Action","TriggerInAction")]
        [String] $Usage = "*",

        [Parameter(Mandatory = $false, Position = 4)]
        [String] $Group = "*"
    )

    # Send telemetry data
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerOperationData"

    # Return the data from the script variable
    return $script:operationData | Where-Object {
        $_.name -like $Name -and
        $_.operationType -like $OperationType -and
        $_.usage -like $Usage -and
        $_.group -like $Group
    }
}