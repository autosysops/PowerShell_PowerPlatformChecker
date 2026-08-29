function Get-PowerPlatformCheckerExternalInteractionConnectorProfile {
    <#
    .SYNOPSIS
        Registers or retrieves connector lookup metadata for external interaction diagrams.

    .DESCRIPTION
        Assigns deterministic connector codes and resolves connector display names
        so Mermaid output can use compact lookup tokens while Graph output keeps
        descriptive connector names.

    .PARAMETER ConnectorKey
        Connector identity used as the deterministic lookup key.

    .PARAMETER ConnectorDisplayName
        Optional display name to use when the catalog has no better match.

    .PARAMETER ConnectorByKey
        Mutable hashtable cache keyed by normalized connector key.

    .PARAMETER ConnectorLegend
        Optional mutable list to receive connector legend rows.

    .EXAMPLE
        Get-PowerPlatformCheckerExternalInteractionConnectorProfile -ConnectorKey 'shared_sharepointonline' -ConnectorByKey $map
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
    $catalogEntry = @($script:connectorData | Where-Object { $_.name -eq $normalizedKey } | Select-Object -First 1)
    if (@($catalogEntry).Count -gt 0 -and -not [string]::IsNullOrWhiteSpace([string]$catalogEntry[0].displayname)) {
        $displayName = [string]$catalogEntry[0].displayname
    }
    elseif ([string]::IsNullOrWhiteSpace($displayName)) {
        $displayName = [string]$ConnectorKey
    }

    $connectorCode = 'C{0:d2}' -f (@($ConnectorByKey.Keys).Count + 1)
    $connectorProfile = [pscustomobject]@{
        ConnectorKey = $normalizedKey
        DisplayName = $displayName
        Code = $connectorCode
    }

    $ConnectorByKey[$normalizedKey] = $connectorProfile
    if ($null -ne $ConnectorLegend) {
        [void]$ConnectorLegend.Add($connectorProfile)
    }

    return $connectorProfile
}
