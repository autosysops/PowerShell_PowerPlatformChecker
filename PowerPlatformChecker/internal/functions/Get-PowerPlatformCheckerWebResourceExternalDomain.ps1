function Get-PowerPlatformCheckerWebResourceExternalDomain {
    <#
    .SYNOPSIS
        Extracts external domains referenced by JavaScript web resource content.

    .DESCRIPTION
        Detects static absolute and protocol-relative URLs and returns normalized
        external hostnames. Localhost and loopback addresses are excluded.

    .PARAMETER SourcePath
        Path to the JavaScript source file.

    .EXAMPLE
        Extract external domains from a JavaScript web resource file.

        PS> Get-PowerPlatformCheckerWebResourceExternalDomain -SourcePath "C:\Solution\WebResources\script.js"
    #>

    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourcePath
    )

    if (-not (Test-Path -Path $SourcePath)) {
        return [string[]]@()
    }

    try {
        $sourceText = Get-Content -Path $SourcePath -Raw -ErrorAction Stop
    }
    catch {
        return [string[]]@()
    }

    $urlMatches = [regex]::Matches($sourceText, '(?i)(https?://[^"''\s)]+|//[^"''\s)]+)')
    $domains = @()

    foreach ($match in @($urlMatches)) {
        $domain = ConvertTo-PowerPlatformCheckerDomain -Value ([string]$match.Value)
        if ([string]::IsNullOrWhiteSpace($domain)) {
            continue
        }

        if ($domain -eq 'localhost' -or $domain -eq '127.0.0.1' -or $domain -eq '::1') {
            continue
        }

        $domains += $domain
    }

    return [string[]]@($domains | Sort-Object -Unique)
}


