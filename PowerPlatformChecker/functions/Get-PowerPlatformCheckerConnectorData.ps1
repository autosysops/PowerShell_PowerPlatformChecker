function Get-PowerPlatformCheckerConnectorData {
    <#
    .SYNOPSIS
        Get data for all Power Platform Connectors

    .DESCRIPTION
        Get data for all Power Platform Connectors

    .EXAMPLE
        Get the Data

        PS> Get-PowerPlatformCheckerConnectorData
    #>

    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory = $false, Position = 1)]
        [String] $Name = "*",

        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateSet("Standard","Premium")]
        [String] $Tier = "*",

        [Parameter(Mandatory = $false, Position = 3)]
        [ValidateSet("Production","Preview","preview")]
        [String] $ReleaseTag = "*",

        [Parameter(Mandatory = $false, Position = 4)]
        [String] $Publisher = "*"
    )

    # Send telemetry data
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerConnectorData"

    # Return the data from the script variable
    return $script:connectorData | Where-Object {
        $_.name -like $Name -and
        $_.tier -like $Tier -and
        $_.releaseTag -like $ReleaseTag -and
        $_.publisher -like $Publisher
    }
}