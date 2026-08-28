function Get-PowerPlatformCheckerExternalInteractionConnectorProfile {
    <#
    .SYNOPSIS
        Registers or retrieves a connector legend profile.

    .DESCRIPTION
        Assigns compact connector codes (for example C01) and deterministic colors
        to connector keys for readable external-interaction edge labels and legends.

    .PARAMETER ConnectorKey
        Connector key used as deterministic identity.

    .PARAMETER ConnectorDisplayName
        Human-friendly connector name.

    .PARAMETER ConnectorByKey
        Mutable hashtable cache keyed by normalized connector key.

    .PARAMETER ConnectorLegend
        Optional mutable list to receive connector legend rows.

    .EXAMPLE
        Register connector metadata used by the external-interaction legend.

        PS> Get-PowerPlatformCheckerExternalInteractionConnectorProfile -ConnectorKey 'shared_sharepointonline' -ConnectorByKey $map
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)]
        [string] $ConnectorKey,

        [Parameter(Mandatory = $false)]
        [string] $ConnectorDisplayName,

        [Parameter(Mandatory = $true)]
        [hashtable] $ConnectorByKey,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [System.Collections.Generic.List[object]] $ConnectorLegend
    )

    if ([string]::IsNullOrWhiteSpace([string]$ConnectorKey)) {
        return $null
    }

    $normalizedKey = ([string]$ConnectorKey).Trim().ToLowerInvariant()
    if ($ConnectorByKey.ContainsKey($normalizedKey)) {
        return $ConnectorByKey[$normalizedKey]
    }

    $displayName = [string]$ConnectorDisplayName
    if ([string]::IsNullOrWhiteSpace($displayName)) {
        $displayName = [string]$ConnectorKey
    }

    $connectorCode = 'C{0:d2}' -f (@($ConnectorByKey.Keys).Count + 1)
    $connectorColor = Get-PowerPlatformCheckerExternalInteractionConnectorColor -ConnectorKey $normalizedKey

    $connectorProfile = [pscustomobject]@{
        ConnectorKey = $normalizedKey
        DisplayName = $displayName
        Code = $connectorCode
        Color = $connectorColor
    }

    $ConnectorByKey[$normalizedKey] = $connectorProfile
    if ($null -ne $ConnectorLegend) {
        [void]$ConnectorLegend.Add($connectorProfile)
    }

    return $connectorProfile
}
