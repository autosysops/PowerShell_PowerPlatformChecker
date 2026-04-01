function Get-PowerPlatformCheckerRelationFile {
    <#
    .SYNOPSIS
        This function retrieves the relationship files from a Power Platform solution. If a specific relation target name is provided, it will return only the file(s) matching that name.

    .DESCRIPTION
        This function retrieves the relationship files from a Power Platform solution. If a specific relation target name is provided, it will return only the file(s) matching that name.

    .PARAMETER SolutionPath
        The file path to the Power Platform solution

    .PARAMETER RelationTarget
        The name of the relation target to retrieve. If not specified, all relationship files will be returned. The relation target is the name of the file without the extension.

    .EXAMPLE
        Get a Power Platform solution relationship file or files

        PS> Get-PowerPlatformCheckerRelationFile -SolutionPath "C:\Solutions\MySolution"

    .EXAMPLE
        Get a specific Power Platform solution relationship file

        PS> Get-PowerPlatformCheckerRelationFile -SolutionPath "C:\Solutions\MySolution" -RelationTarget "BusinessUnit"

    #>

    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [String] $SolutionPath,

        [Parameter(Mandatory = $false, Position = 2)]
        [String] $RelationTarget
    )

    # Send telemetry data
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerRelationFile"

    # Get the childitems
    $filter = "*.xml"
    if(Test-Path -Path (Join-Path $SolutionPath "Other\Relationships")) {
        $files = Get-ChildItem -Path (Join-Path $SolutionPath "Other\Relationships") -Recurse -Filter $filter
    }

    # If the name is given filter it
    if($RelationTarget) {
        $files = $files | Where-Object { $_.BaseName -eq $RelationTarget }
    }

    # Return the file or files
    $files | Select-Object -ExpandProperty FullName
}