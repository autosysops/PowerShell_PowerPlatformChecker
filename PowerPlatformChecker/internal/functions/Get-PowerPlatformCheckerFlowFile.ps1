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

    .PARAMETER FlowId
        The id of the flow to retrieve. If not specified, all flow files will be returned

    .PARAMETER Type
        The type of flow file to retrieve, either json, xml, or all. Default is json

    .EXAMPLE
        Get a Power Platform solution flow file or files

        PS> Get-PowerPlatformCheckerFlowFile -SolutionPath "C:\Solutions\MySolution"

    .EXAMPLE
        Get a specific Power Platform solution flow file

        PS> Get-PowerPlatformCheckerFlowFile -SolutionPath "C:\Solutions\MySolution" -FlowName "MyFlow"

    .EXAMPLE
        Get a specific Power Platform solution flow file in xml format

        PS> Get-PowerPlatformCheckerFlowFile -SolutionPath "C:\Solutions\MySolution" -FlowName "MyFlow" -Type "xml"

    .EXAMPLE
        Get a specific Power Platform solution flow file by id

        PS> Get-PowerPlatformCheckerFlowFile -SolutionPath "C:\Solutions\MySolution" -FlowId "00000000-0000-0000-0000-000000000000"

    .EXAMPLE
        Get a specific Power Platform solution flow file in any format

        PS> Get-PowerPlatformCheckerFlowFile -SolutionPath "C:\Solutions\MySolution" -FlowId "00000000-0000-0000-0000-000000000000" -Type "all"
    #>

    [CmdLetBinding(defaultParameterSetName = "ByName")]
    Param (
        [Parameter(Mandatory = $true, ParameterSetName = "ByName", Position = 1)]
        [Parameter(Mandatory = $true, ParameterSetName = "ById", Position = 1)]
        [String] $SolutionPath,

        [Parameter(Mandatory = $false, ParameterSetName = "ByName", Position = 2)]
        [String] $FlowName,

        [Parameter(Mandatory = $false, ParameterSetName = "ById", Position = 2)]
        [String] $FlowId,

        [Parameter(Mandatory = $false, ParameterSetName = "ByName", Position = 3)]
        [Parameter(Mandatory = $false, ParameterSetName = "ById", Position = 3)]
        [ValidateSet("json", "xml", "all")]
        [String] $Type = "json"
    )

    # Send telemetry data
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerFlowFile"

    # Get the childitems
    $files = Get-ChildItem -Path (Join-Path $SolutionPath "Workflows")

    # If the name is given filter it
    if ($FlowName -or $FlowId) {
        $files = foreach ($file in ($files | Where-Object {$_.Extension -eq ".xml"}) ){
            $flowXml = Select-Xml -Path $file.FullName -XPath "*"
            if ($FlowName -eq $flowXml.Node.Name -or $FlowId -eq $flowXml.Node.WorkflowId.replace("{", "").replace("}", "")) {
                $files | Where-Object { $_.BaseName -eq $file.BaseName -or $_.BaseName -eq ($file.BaseName.replace(".json.data", "")) }
            }
        }
    }

    # Filter for the right extension
    $filter = "*.json"
    if ($Type -eq "xml") {
        $filter = "*.json.data.xml"
    } elseif ($Type -eq "all") {
        $filter = "*.*"
    }

    # Filter the files for the right type
    $files = $files | Where-Object { $_.Name -like $filter }

    # Return the file or files
    $files | Select-Object -ExpandProperty FullName
}