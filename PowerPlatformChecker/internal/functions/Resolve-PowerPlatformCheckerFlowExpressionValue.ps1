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

    $match = [regex]::Match($textValue, 'parameters\(''(?<name>[^'']+)''\)')
    if (-not $match.Success) {
        return $textValue
    }

    $parameterName = [string]$match.Groups['name'].Value
    if ([string]::IsNullOrWhiteSpace($parameterName)) {
        return $textValue
    }

    try {
        $parameterObject = $DefinitionParameters.$parameterName
        if ($null -ne $parameterObject -and $parameterObject.PSObject.Properties.Name -contains 'defaultValue') {
            $defaultValue = [string]$parameterObject.defaultValue
            if (-not [string]::IsNullOrWhiteSpace($defaultValue)) {
                return $defaultValue
            }
        }
    }
    catch {
        return $textValue
    }

    return $textValue
}
