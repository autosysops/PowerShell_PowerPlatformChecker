function ConvertTo-PowerPlatformCheckerDomain {
    <#
    .SYNOPSIS
        Converts a URL-like string to a normalized domain.

    .DESCRIPTION
        Accepts absolute and protocol-relative URLs and returns a lowercase host
        name without surrounding whitespace.

    .PARAMETER Value
        Input value that may contain a URL.

    .EXAMPLE
        Normalize a URL to its host name.

        PS> ConvertTo-PowerPlatformCheckerDomain -Value "https://api.example.test/path"
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [string] $Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ''
    }

    $trimmedValue = [string]$Value.Trim()
    if ($trimmedValue.StartsWith('//')) {
        $trimmedValue = "https:$trimmedValue"
    }

    try {
        $uri = [System.Uri]$trimmedValue
        if ($uri -and -not [string]::IsNullOrWhiteSpace([string]$uri.Host)) {
            return ([string]$uri.Host).ToLowerInvariant()
        }
    }
    catch {
        return ''
    }

    return ''
}


