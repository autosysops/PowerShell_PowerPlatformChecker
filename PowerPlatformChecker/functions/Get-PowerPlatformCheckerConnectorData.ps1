function Get-PowerPlatformCheckerConnectorData {
    <#
    .SYNOPSIS
        Get data for all Power Platform Connectors

    .DESCRIPTION
        Get data for all Power Platform Connectors

    .PARAMETER Name
        The name of the connector

    .PARAMETER Tier
        The tier of the connector (Standard, Premium)

    .PARAMETER ReleaseTag
        The release tag of the connector (Production, Preview)

    .PARAMETER Publisher
        The publisher of the connector

    .EXAMPLE
        Get the Data

        PS> Get-PowerPlatformCheckerConnectorData

    .EXAMPLE
        Get the Data for Standard Connectors

        PS> Get-PowerPlatformCheckerConnectorData -Tier Standard

    .EXAMPLE
        Get the Data for Connectors in Preview

        PS> Get-PowerPlatformCheckerConnectorData -ReleaseTag Preview

    .EXAMPLE
        Get the Data for Connectors from Microsoft

        PS> Get-PowerPlatformCheckerConnectorData -Publisher Microsoft
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