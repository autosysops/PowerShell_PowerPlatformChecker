function Test-PowerPlatformCheckerExternalDomainToken {
    <#
    .SYNOPSIS
        Determines whether a value is valid for an external-domain target node.

    .DESCRIPTION
        Filters out empty values and common non-domain tokens so external
        interaction graphs do not render noisy or misleading target nodes.

    .PARAMETER DomainValue
        Candidate value to validate.

    .EXAMPLE
        Validate a SharePoint hostname.

        PS> Test-PowerPlatformCheckerExternalDomainToken -DomainValue 'contoso.sharepoint.com'
    #>

    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $false)]
        [string] $DomainValue
    )

    $domain = [string]$DomainValue
    if ([string]::IsNullOrWhiteSpace($domain)) {
        return $false
    }

    $normalizedDomain = $domain.Trim().ToLowerInvariant()
    if ($normalizedDomain -in @('unknown', 'get', 'set', 'read', 'write', 'true', 'false', 'null')) {
        return $false
    }

    if ($normalizedDomain -eq 'internet') {
        return $true
    }

    if ($normalizedDomain -match '^\d{1,3}(\.\d{1,3}){3}$') {
        return $true
    }

    return $normalizedDomain.Contains('.')
}
