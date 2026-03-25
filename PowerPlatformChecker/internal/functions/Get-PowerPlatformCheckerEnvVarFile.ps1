function Get-PowerPlatformCheckerEnvVarFile {
    <#
    .SYNOPSIS
        Gets a Power Platform solution environment variable file or files

    .DESCRIPTION
        This function retrieves the environment variable files from a Power Platform solution. If a specific environmental variable name is provided, it will return only the file(s) matching that name.

    .PARAMETER SolutionPath
        The file path to the Power Platform solution

    .PARAMETER EnvironmentalVariableName
        The name of the environmental variable to retrieve. If not specified, all environmental variable files will be returned.

    .EXAMPLE
        Get a Power Platform solution environment variable file or files

        PS> Get-PowerPlatformCheckerEnvVarFile -SolutionPath "C:\Solutions\MySolution"

    .EXAMPLE
        Get a specific Power Platform solution environment variable file

        PS> Get-PowerPlatformCheckerEnvVarFile -SolutionPath "C:\Solutions\MySolution" -EnvironmentalVariableName "MyEnvVar"
    #>

    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [String] $SolutionPath,

        [Parameter(Mandatory = $false, Position = 2)]
        [String] $EnvironmentalVariableName
    )

    # Send telemetry data
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerEnvVarFile"

    # Get the childitems
    $filter = "*.xml"
    $files = Get-ChildItem -Path (Join-Path $SolutionPath "environmentvariabledefinitions") -Recurse -Filter $filter

    # If the name is given filter it
    if($EnvironmentalVariableName) {
        $files = $files | Where-Object { $_.BaseName -eq $EnvironmentalVariableName }
    }

    # Return the file or files
    $files | Select-Object -ExpandProperty FullName
}