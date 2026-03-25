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

    # Send telemetry data
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerFlowParameter"

    # Create an array to return
    $parametersList = @()

    # Import the flow data
    $flowdata = Import-PowerPlatformCheckerFlow -Path $Path

    # Get the parameters
    $flowdata.properties.definition.parameters | Get-Member -MemberType NoteProperty | Where-Object {-not $_.Name.StartsWith("$")} | Foreach-Object {
        $parametersList += [pscustomobject]@{
            Name = $_.Name
            Type = $flowdata.properties.definition.parameters.($_.Name).type
            SchemaName = $flowdata.properties.definition.parameters.($_.Name).metadata.schemaName
        }
    }

    # Return the list
    return $parametersList
}