function Get-PowerPlatformCheckerExternalDomainDisplayName {
    <#
    .SYNOPSIS
        Normalizes an external target label for diagram node display.

    .DESCRIPTION
        Keeps the external target path and host while removing any leading
        protocol prefix that uses the :// delimiter so Azure DevOps Mermaid
        rendering does not treat labels as markdown links.

    .PARAMETER DomainValue
        Candidate external domain or URL value.

    .EXAMPLE
        Remove protocol prefix from an external URL for diagram display.

        PS> Get-PowerPlatformCheckerExternalDomainDisplayName -DomainValue 'https://contoso.sharepoint.com/sites/ops'
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [string] $DomainValue
    )

    $displayValue = [string]$DomainValue
    if ([string]::IsNullOrWhiteSpace($displayValue)) {
        return ''
    }

    $displayValue = $displayValue.Trim()
    if ($displayValue.StartsWith('//')) {
        return $displayValue.Substring(2)
    }

    $protocolSplit = $displayValue.Split('://', 2, [System.StringSplitOptions]::None)
    if ($protocolSplit.Count -eq 2 -and -not [string]::IsNullOrWhiteSpace([string]$protocolSplit[0])) {
        return [string]$protocolSplit[1]
    }

    return $displayValue
}
