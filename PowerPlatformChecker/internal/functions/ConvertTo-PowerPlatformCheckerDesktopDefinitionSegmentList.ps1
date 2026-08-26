function ConvertTo-PowerPlatformCheckerDesktopDefinitionSegmentList {
    <#
    .SYNOPSIS
        Splits a desktop flow Definition into parser-ready script segments.

    .DESCRIPTION
        The PAD Definition format mixes command lines, metadata directives,
        semicolon-separated statements, and multiline triple-single-quoted
        values. This helper preserves multiline values while still emitting one
        segment per executable statement for the chart parser.

    .PARAMETER Definition
        Raw or normalized desktop Definition text.

    .EXAMPLE
        ConvertTo-PowerPlatformCheckerDesktopDefinitionSegmentList -Definition "DISPLAY Message='x';WRITE Text='y'"

        Splits the definition into parser-ready command segments.
    #>

    [CmdletBinding()]
    [OutputType([Object[]])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyString()]
        [string] $Definition
    )

    $normalizedDefinition = ConvertTo-PowerPlatformCheckerDesktopNormalizedDefinition -Definition $Definition
    if ([string]::IsNullOrWhiteSpace($normalizedDefinition)) {
        return @()
    }

    $segments = @()
    $buffer = ""
    $inSingleQuote = $false
    $inTripleSingleQuote = $false

    for ($characterIndex = 0; $characterIndex -lt $normalizedDefinition.Length; $characterIndex++) {
        if (($characterIndex + 2) -lt $normalizedDefinition.Length) {
            $tripleQuoteCandidate = $normalizedDefinition.Substring($characterIndex, 3)
            $isBackslashEscaped = $characterIndex -gt 0 -and $normalizedDefinition[$characterIndex - 1] -eq '\\'
            if ($tripleQuoteCandidate -eq "'''" -and -not $isBackslashEscaped) {
                if ($inTripleSingleQuote) {
                    $inTripleSingleQuote = $false
                    $buffer += "'''"
                    $characterIndex += 2
                    continue
                }

                $previousChar = if ($characterIndex -gt 0) { [string]$normalizedDefinition[$characterIndex - 1] } else { '' }
                if ($previousChar -eq '$') {
                    $inTripleSingleQuote = $true
                    $buffer += "'''"
                    $characterIndex += 2
                    continue
                }
            }
        }

        $character = $normalizedDefinition[$characterIndex]
        if ($inTripleSingleQuote) {
            $buffer += $character
            continue
        }

        if ($character -eq "'") {
            $isBackslashEscaped = $characterIndex -gt 0 -and $normalizedDefinition[$characterIndex - 1] -eq '\\'
            if ($isBackslashEscaped) {
                $buffer += $character
                continue
            }

            if ($inSingleQuote -and ($characterIndex + 1) -lt $normalizedDefinition.Length -and $normalizedDefinition[$characterIndex + 1] -eq "'") {
                $buffer += "''"
                $characterIndex++
                continue
            }

            $inSingleQuote = -not $inSingleQuote
            $buffer += $character
            continue
        }

        $isLineBreak = $character -eq "`n" -or $character -eq "`r"
        $isSegmentSeparator = $isLineBreak -or ($character -eq ';' -and -not $inSingleQuote)
        if ($isSegmentSeparator) {
            $segment = $buffer.Trim()
            if (-not [string]::IsNullOrWhiteSpace($segment)) {
                $segments += $segment
            }

            $buffer = ""
            continue
        }

        $buffer += $character
    }

    $segment = $buffer.Trim()
    if (-not [string]::IsNullOrWhiteSpace($segment)) {
        $segments += $segment
    }

    return @($segments | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}
