function Get-PowerPlatformCheckerFlowParameter {
    <#
    .SYNOPSIS
        Retrieves the parameters of a Power Platform flow.

    .DESCRIPTION
        This function imports a Power Platform flow from the specified path and returns a list of its parameters, including their names, types, and schema names

    .PARAMETER Path
        The file path to the Power Platform flow JSON file.

    .EXAMPLE
        Get the parameters of a Power Platform flow from a JSON file.

        PS> Get-PowerPlatformCheckerFlowParameter -Path "C:\Flows\MyFlow.json"
    #>

    [CmdLetBinding()]
    [OutputType([Object[]])]
    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [String] $Path
    )

    # Create an array to return
    $parametersList = @()
    $telemetryProperties = @{}

    $flowType = Get-PowerPlatformCheckerFlowType -Path $Path
    if ($flowType -eq "Desktop") {
        $parametersList = @(Get-PowerPlatformCheckerDesktopFlowParameterList -Path $Path)
        Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerFlowParameter" -PropertiesHash $telemetryProperties
        return $parametersList
    }

    # Import the flow data
    try {
        $flowdata = Import-PowerPlatformCheckerFlow -Path $Path
    }
    catch {
        Write-Warning "Invalid flow input. Unable to resolve parameters."
        Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerFlowParameter" -PropertiesHash $telemetryProperties
        return @()
    }

    # Cloud flow parameters live in definition.parameters. Skip Power Automate's
    # internal $-prefixed entries so callers only receive user-meaningful input.
    $flowdata.properties.definition.parameters | Get-Member -MemberType NoteProperty | Where-Object {-not $_.Name.StartsWith("$")} | Foreach-Object {
        $parametersList += [pscustomobject]@{
            Name = $_.Name
            Type = $flowdata.properties.definition.parameters.($_.Name).type
            SchemaName = $flowdata.properties.definition.parameters.($_.Name).metadata.schemaName
        }
    }

    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerFlowParameter" -PropertiesHash $telemetryProperties

    # Return the list
    return $parametersList
}
