function Import-PowerPlatformCheckerFlow {
    <#
    .SYNOPSIS
        Import a Power Automate flow json file as a PowerShell object

    .DESCRIPTION
        Import a Power Automate flow json file as a PowerShell object

    .PARAMETER Path
        The path to the flow json file

    .EXAMPLE
        Import a flow

        PS> Import-PowerPlatformCheckerFlow -Path "C:\MyFlow.json"
    #>

    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [String] $Path
    )

    # Send telemetry data
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Import-PowerPlatformCheckerFlow"

    # Import the json file as a PowerShell object
    $flowData = Get-Content -Path $Path -Raw | ConvertFrom-Json

    # Validate that the file contains a connectionReferences and definitions node
    if (-not $flowData.properties.connectionReferences) {
        throw "The flow json file does not contain a connectionReferences node."
    }
    if (-not $flowData.properties.definition) {
        throw "The flow json file does not contain a definition node."
    }

    # Return the data
    return $flowData
}