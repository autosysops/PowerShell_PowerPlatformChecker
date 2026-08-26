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
    [OutputType([Object[]])]
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

    $flowType = Get-PowerPlatformCheckerFlowType -Path $Path
    if ($flowType -eq "Desktop") {
        $desktopConnectorCandidates = [System.Collections.Generic.List[object]]::new()

        $addDesktopConnector = {
            param(
                [string] $Name,
                [string] $DisplayName,
                [string] $Tier
            )

            $normalizedName = [string]$Name
            if ($normalizedName -like "*/apis/*") {
                $normalizedName = $normalizedName.Split("/")[-1]
            }

            if ([string]::IsNullOrWhiteSpace($normalizedName) -or $normalizedName -notlike $Connector) {
                return
            }

            [void]$desktopConnectorCandidates.Add([PSCustomObject]@{
                Name = [string]$normalizedName
                DisplayName = [string]$DisplayName
                Tier = [string]$Tier
            })
        }

        $addConnectionReferences = {
            param(
                [object] $ConnectionReferences
            )

            if ($null -eq $ConnectionReferences) {
                return
            }

            $referenceItems = @()
            if ($ConnectionReferences -is [array]) {
                $referenceItems = @($ConnectionReferences)
            }
            elseif (($ConnectionReferences.PSObject.Properties.Name -contains "api") -or ($ConnectionReferences.PSObject.Properties.Name -contains "name")) {
                $referenceItems = @($ConnectionReferences)
            }

            if (@($referenceItems).Count -gt 0) {
                foreach ($connectionReference in @($referenceItems)) {
                    if ($null -eq $connectionReference) {
                        continue
                    }

                    $referenceName = ""
                    if ($null -ne $connectionReference.api -and -not [string]::IsNullOrWhiteSpace([string]$connectionReference.api.name)) {
                        $referenceName = [string]$connectionReference.api.name
                    }
                    elseif (-not [string]::IsNullOrWhiteSpace([string]$connectionReference.connectorId)) {
                        $referenceName = [string]$connectionReference.connectorId
                    }
                    elseif (-not [string]::IsNullOrWhiteSpace([string]$connectionReference.name)) {
                        $referenceName = [string]$connectionReference.name
                    }

                    $referenceDisplayName = [string]$connectionReference.displayName
                    if ([string]::IsNullOrWhiteSpace($referenceDisplayName)) {
                        $referenceDisplayName = [string]$connectionReference.connectionDisplayName
                    }

                    & $addDesktopConnector -Name $referenceName -DisplayName $referenceDisplayName -Tier ([string]$connectionReference.tier)
                }

                return
            }

            foreach ($connectionProperty in @($ConnectionReferences | Get-Member -MemberType NoteProperty)) {
                $entry = $ConnectionReferences.($connectionProperty.Name)
                $entryDisplayName = [string]$entry.displayName
                if ([string]::IsNullOrWhiteSpace($entryDisplayName)) {
                    $entryDisplayName = [string]$connectionProperty.Name
                }

                & $addDesktopConnector -Name ([string]$connectionProperty.Name) -DisplayName $entryDisplayName -Tier ([string]$entry.tier)
            }
        }

        foreach ($binary in @(Get-PowerPlatformCheckerDesktopFlowBinary -Path $Path -Type "ConnectorDefinition")) {
            $binaryData = $binary.Data
            if ($binary.PSObject.Properties.Name -contains "DataPath" -and -not [string]::IsNullOrWhiteSpace([string]$binary.DataPath) -and (Test-Path -Path $binary.DataPath)) {
                try {
                    $binaryData = Get-Content -Path $binary.DataPath -Raw | ConvertFrom-Json
                }
                catch {
                    $binaryData = $binary.Data
                }
            }

            if ($null -eq $binaryData -or $null -eq $binaryData.Definition -or $null -eq $binaryData.Definition.Properties) {
                continue
            }

            $connectorName = [string]$binaryData.Definition.Name
            if ([string]::IsNullOrWhiteSpace($connectorName)) {
                $connectorName = [string]$binaryData.ConnectorId
            }

            $connectorDisplayName = [string]$binaryData.Definition.Properties.DisplayName
            if ([string]::IsNullOrWhiteSpace($connectorDisplayName) -and $null -ne $binaryData.Definition.Properties.Swagger) {
                $connectorDisplayName = [string]$binaryData.Definition.Properties.Swagger.info.title
            }

            & $addDesktopConnector -Name $connectorName -DisplayName $connectorDisplayName -Tier ([string]$binaryData.Definition.Properties.Tier)
        }

        foreach ($manifestBinary in @(Get-PowerPlatformCheckerDesktopFlowBinary -Path $Path -Type "ManifestFile")) {
            if ($null -eq $manifestBinary.Data) {
                continue
            }

            $manifestData = $manifestBinary.Data
            if ($manifestData.PSObject.Properties.Name -contains "ConnectionReferences") {
                & $addConnectionReferences -ConnectionReferences $manifestData.ConnectionReferences
            }
            elseif ($manifestData.PSObject.Properties.Name -contains "connectionReferences") {
                & $addConnectionReferences -ConnectionReferences $manifestData.connectionReferences
            }
            elseif (($manifestData.PSObject.Properties.Name -contains "manifest") -and $null -ne $manifestData.manifest) {
                if ($manifestData.manifest.PSObject.Properties.Name -contains "ConnectionReferences") {
                    & $addConnectionReferences -ConnectionReferences $manifestData.manifest.ConnectionReferences
                }
                elseif ($manifestData.manifest.PSObject.Properties.Name -contains "connectionReferences") {
                    & $addConnectionReferences -ConnectionReferences $manifestData.manifest.connectionReferences
                }
            }
        }

        $desktopMetadata = Get-PowerPlatformCheckerDesktopFlowMeta -Path $Path
        if ($null -ne $desktopMetadata -and $null -ne $desktopMetadata.ConnectionReferences) {
            & $addConnectionReferences -ConnectionReferences $desktopMetadata.ConnectionReferences
        }

        $resolvedDesktopConnectors = @()
        foreach ($connectorName in @(@($desktopConnectorCandidates).Name | Where-Object { $_ } | Select-Object -Unique)) {
            $itemsForConnector = @(@($desktopConnectorCandidates) | Where-Object { $_.Name -eq $connectorName })
            $resolvedDisplayName = [string]($itemsForConnector | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.DisplayName) } | Select-Object -First 1 -ExpandProperty DisplayName)
            $resolvedTier = [string]($itemsForConnector | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.Tier) } | Select-Object -First 1 -ExpandProperty Tier)
            $connectorData = $null

            if ([string]::IsNullOrWhiteSpace($resolvedDisplayName) -or [string]::IsNullOrWhiteSpace($resolvedTier)) {
                $connectorData = @(Get-PowerPlatformCheckerConnectorData -Name $connectorName) | Select-Object -First 1
                if (-not $connectorData -and $connectorName -like "shared_*") {
                    $connectorData = @(Get-PowerPlatformCheckerConnectorData -Name ($connectorName -replace '^shared_', '')) | Select-Object -First 1
                }
            }

            if ([string]::IsNullOrWhiteSpace($resolvedDisplayName) -and $connectorData) {
                $resolvedDisplayName = [string]$connectorData.displayname
            }
            if ([string]::IsNullOrWhiteSpace($resolvedTier) -and $connectorData) {
                $resolvedTier = [string]$connectorData.tier
            }

            $resolvedDesktopConnectors += [PSCustomObject]@{
                Name = [string]$connectorName
                DisplayName = $resolvedDisplayName
                Tier = $resolvedTier
            }
        }

        return @($resolvedDesktopConnectors | Sort-Object Name -Unique)

    }

    # Import the flow data
    try {
        $flowdata = Import-PowerPlatformCheckerFlow -Path $Path
    }
    catch {
        Write-Warning "Invalid flow input. Unable to resolve connector tiers."
        return @()
    }

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