function Test-PowerPlatformCheckerConnectorDomainMatch {
    <#
    .SYNOPSIS
        Tests whether a resolved domain likely belongs to a connector category.

    .DESCRIPTION
        Applies conservative connector-to-domain heuristics so connection fallback
        edges can be hidden when a concrete domain is already known.

    .PARAMETER ConnectorKey
        Connector id or display name.

    .PARAMETER DomainValue
        Candidate resolved domain value.

    .EXAMPLE
        PS> Test-PowerPlatformCheckerConnectorDomainMatch -ConnectorKey 'shared_sharepointonline' -DomainValue 'contoso.sharepoint.com'
    #>

    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $false)]
        [string] $ConnectorKey,

        [Parameter(Mandatory = $false)]
        [string] $DomainValue
    )

    if ([string]::IsNullOrWhiteSpace([string]$ConnectorKey) -or [string]::IsNullOrWhiteSpace([string]$DomainValue)) {
        return $false
    }

    $connector = ([string]$ConnectorKey).Trim().ToLowerInvariant()
    $domain = ([string]$DomainValue).Trim().ToLowerInvariant()

    if ($connector -match 'sharepoint') {
        return $domain -match '(^|\.)sharepoint\.com$'
    }

    if ($connector -match 'office365users|office365|microsoft365') {
        return $domain -match '(^|\.)graph\.microsoft\.com$|(^|\.)office\.com$|(^|\.)office365\.com$|(^|\.)outlook\.office365\.com$|(^|\.)outlook\.com$'
    }

    if ($connector -match 'onedrive') {
        return $domain -match '(^|\.)sharepoint\.com$|(^|\.)onedrive\.com$'
    }

    return $false
}
