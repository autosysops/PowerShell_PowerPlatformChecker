function Get-PowerPlatformCheckerFlowFile {
    <#
    .SYNOPSIS
        Gets a Power Platform solution flow file or files

    .DESCRIPTION
        This function retrieves the flow files from a Power Platform solution. If a specific flow name is provided, it will return only the file(s) matching that name.

    .PARAMETER SolutionPath
        The file path to the Power Platform solution

    .PARAMETER FlowName
        The name of the flow to retrieve. If not specified, all flow files will be returned

    .PARAMETER Type
        The type of flow file to retrieve, either json or xml. Default is json

    .EXAMPLE
        Get a Power Platform solution flow file or files

        PS> Get-PowerPlatformCheckerFlowFile -SolutionPath "C:\Solutions\MySolution"

    .EXAMPLE
        Get a specific Power Platform solution flow file

        PS> Get-PowerPlatformCheckerFlowFile -SolutionPath "C:\Solutions\MySolution" -FlowName "MyFlow"

    .EXAMPLE
        Get a specific Power Platform solution flow file in xml format

        PS> Get-PowerPlatformCheckerFlowFile -SolutionPath "C:\Solutions\MySolution" -FlowName "MyFlow" -Type "xml"
    #>

    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [String] $SolutionPath,

        [Parameter(Mandatory = $false, Position = 2)]
        [String] $FlowName,

        [Parameter(Mandatory = $false, Position = 3)]
        [ValidateSet("json","xml")]
        [String] $Type = "json"
    )

    # Send telemetry data
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerFlowFile"

    # Get the childitems
    $filter = "*.json"
    if($Type -eq "xml") {
        $filter = "*.json.data.xml"
    }
    $files = Get-ChildItem -Path (Join-Path $SolutionPath "Workflows") -Filter $filter

    # If the name is given filter it
    if($FlowName) {
        if($Type -eq "xml") {
            $FlowName += ".json.data"
        }
        $files = $files | Where-Object { $_.BaseName -eq $FlowName }
    }

    # Return the file or files
    $files | Select-Object -ExpandProperty FullName
}