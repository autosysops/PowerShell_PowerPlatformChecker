function Resolve-PowerPlatformCheckerFlowExpressionValue {
    <#
    .SYNOPSIS
        Resolves simple flow parameter expressions to concrete values.

    .DESCRIPTION
        Supports common parameter expression forms used in action URL fields,
        such as @parameters('x') and @{parameters('x')}. If no match can be
        resolved from defaults, returns the original value.

    .PARAMETER Value
        Raw action value to resolve.

    .PARAMETER DefinitionParameters
        Flow definition parameters object with defaultValue fields.

    .EXAMPLE
        Resolve a flow expression that references definition parameter defaults.

        PS> Resolve-PowerPlatformCheckerFlowExpressionValue -Value "@parameters('baseUrl')" -DefinitionParameters $params
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Value,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $DefinitionParameters
    )

    $textValue = [string]$Value
    if ([string]::IsNullOrWhiteSpace($textValue)) {
        return ""
    }

    if ($null -eq $DefinitionParameters) {
        return $textValue
    }

    # Handle exact expression forms first so values resolve cleanly for
    # connector parameters that store bare parameter references.
    $exactPatterns = @(
        '^\s*@?parameters\(''(?<name>[^'']+)''\)\s*$',
        '^\s*@\{\s*parameters\(''(?<name>[^'']+)''\)\s*\}\s*$'
    )
    foreach ($pattern in $exactPatterns) {
        $exactMatch = [regex]::Match($textValue, $pattern)
        if ($exactMatch.Success) {
            $resolved = Get-PowerPlatformCheckerFlowParameterDefaultValue -DefinitionParameters $DefinitionParameters -ParameterName ([string]$exactMatch.Groups['name'].Value)
            if (-not [string]::IsNullOrWhiteSpace([string]$resolved)) {
                return [string]$resolved
            }
            return $textValue
        }
    }

    # Resolve inline interpolation in strings such as:
    # https://@{parameters('host')}/api/@{parameters('version')}
    $resolvedText = $textValue
    $inlineMatches = [regex]::Matches($textValue, '@\{\s*parameters\(''(?<name>[^'']+)''\)\s*\}')
    foreach ($inlineMatch in @($inlineMatches)) {
        $parameterName = [string]$inlineMatch.Groups['name'].Value
        $replacement = Get-PowerPlatformCheckerFlowParameterDefaultValue -DefinitionParameters $DefinitionParameters -ParameterName $parameterName
        if (-not [string]::IsNullOrWhiteSpace([string]$replacement)) {
            $resolvedText = $resolvedText.Replace([string]$inlineMatch.Value, [string]$replacement)
        }
    }

    $directMatches = [regex]::Matches($resolvedText, '@?parameters\(''(?<name>[^'']+)''\)')
    foreach ($directMatch in @($directMatches)) {
        $parameterName = [string]$directMatch.Groups['name'].Value
        $replacement = Get-PowerPlatformCheckerFlowParameterDefaultValue -DefinitionParameters $DefinitionParameters -ParameterName $parameterName
        if (-not [string]::IsNullOrWhiteSpace([string]$replacement)) {
            $resolvedText = $resolvedText.Replace([string]$directMatch.Value, [string]$replacement)
        }
    }

    return $resolvedText
}
