function Get-PowerPlatformCheckerCanvasAppFile {
    <#
    .SYNOPSIS
        This function retrieves the file path of canvas app files in a Power Platform solution. If a specific canvas app display name is provided, it will return only the file(s) matching that name.

    .DESCRIPTION
        This function retrieves the file path of canvas app files in a Power Platform solution. If a specific canvas app display name is provided, it will return only the file(s) matching that name.

    .PARAMETER SolutionPath
        The file path to the Power Platform solution

    .PARAMETER CanvasAppInternalName
        The internal name of the canvas app to retrieve. If not specified, all canvas app files will be returned. The canvas app internal name is the name of the canvas app as used internally in the solution files.

    .EXAMPLE
        Get a Power Platform solution canvas app file or files

        PS> Get-PowerPlatformCheckerCanvasAppFile -SolutionPath "C:\Solutions\MySolution"

    .EXAMPLE
        Get a specific Power Platform solution canvas app file

        PS> Get-PowerPlatformCheckerCanvasAppFile -SolutionPath "C:\Solutions\MySolution" -CanvasAppInternalName "MyCanvasApp"
    #>

    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [String] $SolutionPath,

        [Parameter(Mandatory = $false, Position = 2)]
        [String] $CanvasAppInternalName = "*"
    )

    # Send telemetry data
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerCanvasAppFile"

    # Get the childitems
    if(Test-Path -Path (Join-Path $SolutionPath "CanvasApps")) {
        $files = Get-ChildItem -Path (Join-Path $SolutionPath "CanvasApps\$CanvasAppInternalName.meta.xml")
    }

    # Return the files
    return $files | Select-Object -ExpandProperty FullName
}