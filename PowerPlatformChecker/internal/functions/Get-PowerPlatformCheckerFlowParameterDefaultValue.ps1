function Get-PowerPlatformCheckerFlowParameterDefaultValue {
    <#
    .SYNOPSIS
        Resolves a flow definition parameter default value.

    .DESCRIPTION
        Returns the non-empty defaultValue string for a named definition
        parameter when available; otherwise returns null.

    .PARAMETER DefinitionParameters
        Flow definition parameter object.

    .PARAMETER ParameterName
        Name of the parameter to resolve.

    .EXAMPLE
        PS> Get-PowerPlatformCheckerFlowParameterDefaultValue -DefinitionParameters $params -ParameterName 'baseUrl'
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $DefinitionParameters,

        [Parameter(Mandatory = $false)]
        [string] $ParameterName
    )

    if ($null -eq $DefinitionParameters -or [string]::IsNullOrWhiteSpace($ParameterName)) {
        return $null
    }

    try {
        $parameterObject = $DefinitionParameters.$ParameterName
        if ($null -eq $parameterObject) {
            return $null
        }

        if ($parameterObject.PSObject.Properties.Name -contains 'defaultValue') {
            $defaultValue = [string]$parameterObject.defaultValue
            if (-not [string]::IsNullOrWhiteSpace($defaultValue)) {
                return $defaultValue
            }
        }
    }
    catch {
        return $null
    }

    return $null
}
