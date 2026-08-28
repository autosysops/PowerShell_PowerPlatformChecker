function Get-PowerPlatformCheckerExternalInteractionConnectorColor {
    <#
    .SYNOPSIS
        Creates a deterministic connector color from a connector key.

    .DESCRIPTION
        Uses an MD5 hash of the connector key to produce a stable RGB color
        without hardcoded connector-to-color mappings.

    .PARAMETER ConnectorKey
        Connector identifier or display name.

    .EXAMPLE
        PS> Get-PowerPlatformCheckerExternalInteractionConnectorColor -ConnectorKey 'shared_sharepointonline'
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [string] $ConnectorKey
    )

    if ([string]::IsNullOrWhiteSpace([string]$ConnectorKey)) {
        return '#808080'
    }

    $normalizedKey = ([string]$ConnectorKey).Trim().ToLowerInvariant()
    $md5 = [System.Security.Cryptography.MD5]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($normalizedKey)
        $hashBytes = $md5.ComputeHash($bytes)
    }
    finally {
        $md5.Dispose()
    }

    $red = 70 + ([int]$hashBytes[0] % 140)
    $green = 70 + ([int]$hashBytes[1] % 140)
    $blue = 70 + ([int]$hashBytes[2] % 140)

    return '#{0:X2}{1:X2}{2:X2}' -f $red, $green, $blue
}
