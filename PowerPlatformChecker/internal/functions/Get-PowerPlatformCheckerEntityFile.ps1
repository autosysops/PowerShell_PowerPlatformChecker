function Get-PowerPlatformCheckerEntityFile {
    <#
    .SYNOPSIS
        Gets the full path of entity files in a Power Platform solution.

    .DESCRIPTION
        This function retrieves the full path of entity files within a specified Power Platform solution.
        You can optionally filter the results by entity name.

    .PARAMETER SolutionPath
        The file path to the Power Platform solution.

    .PARAMETER EntityName
        The name of the entity to retrieve. If not specified, all entity files will be returned.

    .EXAMPLE
        Get the full path of all entity files in a Power Platform solution.

        PS> Get-PowerPlatformCheckerEntityFile -SolutionPath "C:\Solutions\MySolution"

    .EXAMPLE
        Get the full path of a specific entity file in a Power Platform solution.

        PS> Get-PowerPlatformCheckerEntityFile -SolutionPath "C:\Solutions\MySolution" -EntityName "MyEntity"
    #>

    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [String] $SolutionPath,

        [Parameter(Mandatory = $false, Position = 2)]
        [String] $EntityName = "*"
    )

    # Send telemetry data
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerEntityFile"

    # Get the childitems
    $files = Get-ChildItem -Path (Join-Path $SolutionPath "Entities\*\Entity.xml") | Where-Object { $_.Directory -like "$($SolutionPath)*$($EntityName)"}

    # Return the files
    return $files | Select-Object -ExpandProperty FullName
}