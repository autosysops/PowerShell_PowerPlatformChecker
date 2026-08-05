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

    # Send telemetry data (tracks option usage only).
    $telemetryProperties = @{
        ConnectorFiltered = ($Connector -ne "*")
    }
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerFlowConnectorTier" -PropertiesHash $telemetryProperties

    # Import the flow data
    $flowdata = Import-PowerPlatformCheckerFlow -Path $Path

    # Get the connectors used in the flow
    $connectors = $flowdata.properties.connectionReferences | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -like $Connector } | Select-Object -ExpandProperty Name

    # For each connector retrieve the tier
    $cdata = foreach($c in $connectors) {
        $connectorApiName = [string]$flowdata.properties.connectionReferences.$c.api.name
        $connectorData = Get-PowerPlatformCheckerConnectorData -Name $connectorApiName

        # Some exports may expose aliases; fall back to stripped shared_ prefix and then connector key name.
        if (-not $connectorData -and $connectorApiName -like "shared_*") {
            $connectorData = Get-PowerPlatformCheckerConnectorData -Name ($connectorApiName -replace '^shared_', '')
        }
        if (-not $connectorData) {
            $connectorData = Get-PowerPlatformCheckerConnectorData -Name $c
        }

        $connectorDisplayName = if ($connectorData) { $connectorData.displayname } else { $null }
        $connectorTier = if ($connectorData) { $connectorData.tier } else { $null }

        [PSCustomObject]@{
            Name = $c
            DisplayName = $connectorDisplayName
            Tier = $connectorTier
        }
    }

    # Return the data
    return $cdata
}