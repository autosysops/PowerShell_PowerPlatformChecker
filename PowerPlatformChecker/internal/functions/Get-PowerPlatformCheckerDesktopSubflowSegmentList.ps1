function Get-PowerPlatformCheckerDesktopSubflowSegmentList {
    <#
    .SYNOPSIS
        Extracts one desktop FUNCTION body as a segment list.

    .DESCRIPTION
        Scans normalized desktop definition segments and returns only the body
        segments of the requested FUNCTION block. The returned list excludes
        FUNCTION/END FUNCTION markers and preserves original segment order.

    .PARAMETER Segments
        Normalized desktop definition segments.

    .PARAMETER SubflowName
        Target FUNCTION name to extract.

    .EXAMPLE
        Extract the ProcessOrder subflow body segments.

        PS> Get-PowerPlatformCheckerDesktopSubflowSegmentList -Segments $segments -SubflowName 'ProcessOrder'
    #>

    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [object[]] $Segments,

        [Parameter(Mandatory = $true)]
        [string] $SubflowName
    )

    $targetName = [string]$SubflowName
    if ([string]::IsNullOrWhiteSpace($targetName)) {
        return @()
    }

    $targetName = $targetName.Trim()
    $collecting = $false
    $depth = 0
    $result = [System.Collections.Generic.List[object]]::new()

    foreach ($segment in @($Segments)) {
        $trimmedSegment = [string]$segment
        if ([string]::IsNullOrWhiteSpace($trimmedSegment)) {
            continue
        }

        $trimmedSegment = $trimmedSegment.TrimStart()

        if ($trimmedSegment -match '^FUNCTION\s+(?<name>[^\s]+)') {
            $functionName = [string]$matches['name']
            if ($collecting) {
                $depth++
                continue
            }

            if ($functionName.Equals($targetName, [System.StringComparison]::OrdinalIgnoreCase)) {
                $collecting = $true
                $depth = 1
            }
            continue
        }

        if ($trimmedSegment -match '^END\s+FUNCTION\b') {
            if (-not $collecting) {
                continue
            }

            $depth--
            if ($depth -le 0) {
                return @($result)
            }
            continue
        }

        if ($collecting) {
            [void]$result.Add($segment)
        }
    }

    return @()
}

