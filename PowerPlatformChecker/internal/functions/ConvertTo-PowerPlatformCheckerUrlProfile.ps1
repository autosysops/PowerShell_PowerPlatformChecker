function ConvertTo-PowerPlatformCheckerUrlProfile {
    <#
    .SYNOPSIS
        Converts a URL-like value to normalized URL profile fields.

    .DESCRIPTION
        Returns normalized URL, protocol, domain, and main-domain fields for
        absolute or protocol-relative URL values. If conversion fails, returns
        unknown fields.

    .PARAMETER Value
        URL-like input value.

    .EXAMPLE
        Parse an absolute URL and return normalized protocol/domain metadata.

        PS> ConvertTo-PowerPlatformCheckerUrlProfile -Value "https://api.contoso.com/path"
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)]
        [string] $Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return [pscustomobject]@{
            FullUrl = ""
            Protocol = "Unknown"
            Domain = "Unknown"
            MainDomain = "Unknown"
            ResolutionState = "Unknown"
        }
    }

    $normalized = [string]$Value.Trim()
    if ($normalized.StartsWith('//')) {
        $normalized = "https:$normalized"
    }

    try {
        $uri = [System.Uri]$normalized
        if ($uri -and -not [string]::IsNullOrWhiteSpace([string]$uri.Host)) {
            $domain = ([string]$uri.Host).ToLowerInvariant()
            $domainParts = @($domain -split '\.')
            $mainDomain = $domain
            if ($domainParts.Count -ge 2) {
                $lastIndex = $domainParts.Count - 1
                $mainDomain = ($domainParts[($lastIndex - 1)..$lastIndex] -join '.')
            }

            return [pscustomobject]@{
                FullUrl = $uri.AbsoluteUri
                Protocol = $uri.Scheme
                Domain = $domain
                MainDomain = $mainDomain
                ResolutionState = "Resolved"
            }
        }
    }
    catch {
        Write-Verbose "Unable to parse URL value for profile conversion: $normalized"
    }

    return [pscustomobject]@{
        FullUrl = ""
        Protocol = "Unknown"
        Domain = "Unknown"
        MainDomain = "Unknown"
        ResolutionState = "Unknown"
    }
}
