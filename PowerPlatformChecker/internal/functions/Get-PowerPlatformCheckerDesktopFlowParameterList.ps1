function Get-PowerPlatformCheckerDesktopFlowParameterList {
    <#
    .SYNOPSIS
        Gets normalized parameters from a desktop flow metadata file.

    .DESCRIPTION
        Reads desktop flow metadata and maps environment variables or schema
        properties to the Name, Type, and SchemaName contract used by public
        flow-parameter output.

    .PARAMETER Path
        Path to the desktop flow JSON file.

    .EXAMPLE
        Get parameter rows from a desktop flow file.

        PS> Get-PowerPlatformCheckerDesktopFlowParameterList -Path "C:\Flow.json"
    #>

    [CmdLetBinding()]
    [OutputType([Object[]])]
    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [String] $Path
    )

    $parametersList = @()

    $desktopMetadata = Get-PowerPlatformCheckerDesktopFlowMeta -Path $Path
    if ($null -eq $desktopMetadata -or $null -eq $desktopMetadata.Dependencies) {
        return @()
    }

    $dependencyEnvironmentVariables = @()
    if ($null -ne $desktopMetadata.Dependencies.environmentVariables) {
        $dependencyEnvironmentVariables = @($desktopMetadata.Dependencies.environmentVariables)
    }
    elseif ($null -ne $desktopMetadata.Dependencies.EnvironmentVariables) {
        $dependencyEnvironmentVariables = @($desktopMetadata.Dependencies.EnvironmentVariables)
    }

    foreach ($environmentVariable in $dependencyEnvironmentVariables) {
        if ($null -eq $environmentVariable) {
            continue
        }

        $environmentVariableName = ""
        $environmentVariableType = ""
        $schemaName = ""

        if ($environmentVariable -is [string]) {
            $environmentVariableName = [string]$environmentVariable
            $schemaName = [string]$environmentVariable
        }
        else {
            $environmentVariableName = [string]$environmentVariable.name
            $environmentVariableType = [string]$environmentVariable.type
            $schemaName = [string]$environmentVariable.schemaName
        }

        if ([string]::IsNullOrWhiteSpace($schemaName)) {
            $schemaName = $environmentVariableName
        }

        if ([string]::IsNullOrWhiteSpace($schemaName)) {
            continue
        }

        if ([string]::IsNullOrWhiteSpace($environmentVariableName)) {
            $environmentVariableName = $schemaName
        }

        $parametersList += [pscustomobject]@{
            Name = $environmentVariableName
            Type = $environmentVariableType
            SchemaName = $schemaName
        }
    }

    return $parametersList
}

