function Get-PowerPlatformCheckerFlowConnectorTier {
    <#
    .SYNOPSIS
        Get the tier of connectors used in a Power Automate flow

    .DESCRIPTION
        Get the tier of connectors used in a Power Automate flow

    .PARAMETER Path
        The path to the flow json file

    .PARAMETER Connector
        The name of the connector to filter on, supports wildcards, default is all connectors

    .EXAMPLE
        Get the tier of connectors used in a flow

        PS> Get-PowerPlatformCheckerFlowConnectorTier -Path "C:\MyFlow.json"

    .EXAMPLE
        Get the tier of connectors used in a flow for connectors with "SharePoint" in the name

        PS> Get-PowerPlatformCheckerFlowConnectorTier -Path "C:\MyFlow.json" -Connector "*SharePoint*"
    #>

    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [String] $Path,

        [Parameter(Mandatory = $false, Position = 2)]
        [String] $Connector = "*"
    )

    # Send telemetry data
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerFlowConnectorTier"

    # Import the flow data
    $flowdata = Import-PowerPlatformCheckerFlow -Path $Path

    # Get the connectors used in the flow
    $connectors = $flowdata.properties.connectionReferences | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -like $Connector } | Select-Object -ExpandProperty Name

    # For each connector retrieve the tier
    $cdata = foreach($c in $connectors) {
        $connectorData = Get-PowerPlatformCheckerConnectorData -Name $flowdata.properties.connectionReferences.$c.api.name
        [PSCustomObject]@{
            Name = $c
            DisplayName = $connectorData.displayname
            Tier = $connectorData.tier
        }
    }

    # Return the data
    return $cdata
}