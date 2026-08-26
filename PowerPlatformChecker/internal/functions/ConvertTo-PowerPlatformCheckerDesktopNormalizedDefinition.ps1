function ConvertTo-PowerPlatformCheckerDesktopNormalizedDefinition {
    <#
    .SYNOPSIS
        Normalizes a desktop flow Definition string for downstream parsing.

    .DESCRIPTION
        Desktop flow metadata often stores Definition values with escaped JSON
        quotes and escaped line endings. This helper converts those persisted
        representations back into the textual script format consumed by the
        desktop parser and architecture-member extraction code.

    .PARAMETER Definition
        Raw Definition value read from the desktop workflow metadata XML.

    .EXAMPLE
        ConvertTo-PowerPlatformCheckerDesktopNormalizedDefinition -Definition '"DISPLAY Message=\"x\"\\nWRITE Text=\"y\""'

        Returns a newline-normalized script string suitable for downstream parsing.
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyString()]
        [string] $Definition
    )

    if ([string]::IsNullOrWhiteSpace($Definition)) {
        return ""
    }

    $normalizedDefinition = [string]$Definition
    if ($normalizedDefinition.StartsWith('"') -and $normalizedDefinition.EndsWith('"') -and $normalizedDefinition.Length -ge 2) {
        $normalizedDefinition = $normalizedDefinition.Substring(1, $normalizedDefinition.Length - 2)
    }

    $normalizedDefinition = $normalizedDefinition -replace '\\"', '"'
    $normalizedDefinition = $normalizedDefinition -replace "\\r\\n", "`n"
    $normalizedDefinition = $normalizedDefinition -replace "\\n", "`n"

    return $normalizedDefinition
}
