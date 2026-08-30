function Get-PowerPlatformCheckerDesktopSubflowNameList {
    <#
    .SYNOPSIS
        Returns the declared FUNCTION names for a desktop flow.

    .DESCRIPTION
        Reads desktop flow metadata and extracts distinct subflow/function names
        from the Definition script in declaration order.

    .PARAMETER Path
        Path to a desktop flow JSON file.

    .EXAMPLE
        Get-PowerPlatformCheckerDesktopSubflowNameList -Path 'C:\Flow.json'

        Returns distinct desktop FUNCTION names in declaration order.
    #>

    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $meta = Get-PowerPlatformCheckerDesktopFlowMeta -Path $Path
    if ($null -eq $meta -or [string]::IsNullOrWhiteSpace([string]$meta.Definition)) {
        return [string[]]@()
    }

    $segments = @(ConvertTo-PowerPlatformCheckerDesktopDefinitionSegmentList -Definition ([string]$meta.Definition))
    if (@($segments).Count -eq 0) {
        return [string[]]@()
    }

    $subflowNames = [System.Collections.Generic.List[string]]::new()
    foreach ($segment in @($segments)) {
        $trimmedSegment = [string]$segment
        if ([string]::IsNullOrWhiteSpace($trimmedSegment)) {
            continue
        }

        $trimmedSegment = $trimmedSegment.TrimStart()
        if ($trimmedSegment -match '^FUNCTION\s+(?<name>[^\s]+)') {
            $subflowName = [string]$matches['name']
            if ([string]::IsNullOrWhiteSpace($subflowName)) {
                continue
            }

            if (-not $subflowNames.Contains($subflowName)) {
                [void]$subflowNames.Add($subflowName)
            }
        }
    }

    return $subflowNames.ToArray()
}

