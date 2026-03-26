function Get-PowerPlatformCheckerFlowDescription {
    <#
    .SYNOPSIS
        Gets the description of a flow from a Power Platform solution.

    .DESCRIPTION
        This function retrieves the description of a flow from a Power Platform solution. It reads the flow XML file and returns the description of the flow.

    .PARAMETER SolutionPath
        The file path to the Power Platform solution.

    .PARAMETER FlowName
        The name of the flow to retrieve the description for. If not specified, the description for all flows will be returned.

    .PARAMETER FlowId
        The id of the flow to retrieve the description for. If not specified, the description for all flows will be returned.

    .EXAMPLE
        Get the description of a flow from a Power Platform solution.

        PS> Get-PowerPlatformCheckerFlowDescription -SolutionPath "C:\Solutions\MySolution" -FlowName "MyFlow"

    .EXAMPLE
        Get the description of a flow from a Power Platform solution by id.

        PS> Get-PowerPlatformCheckerFlowDescription -SolutionPath "C:\Solutions\MySolution" -FlowId "00000000-0000-0000-0000-000000000000"
    #>

    [CmdLetBinding()]
    [OutputType([String])]
    Param (
        [Parameter(Mandatory = $true, ParameterSetName = "ByName", Position = 1)]
        [Parameter(Mandatory = $true, ParameterSetName = "ById", Position = 1)]
        [String] $SolutionPath,

        [Parameter(Mandatory = $true, ParameterSetName = "ByName", Position = 2)]
        [String] $FlowName,

        [Parameter(Mandatory = $true, ParameterSetName = "ById", Position = 2)]
        [String] $FlowId
    )

    # Send telemetry data
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerFlowDescription"

    # Get the right file
    if($FlowName) {
        $flowxml = Select-Xml -Path (Get-PowerPlatformCheckerFlowFile -SolutionPath $SolutionPath -FlowName $FlowName -Type "xml") -XPath "*"
    }

    if($FlowId) {
        $flowxml = Select-Xml -Path (Get-PowerPlatformCheckerFlowFile -SolutionPath $SolutionPath -FlowId $FlowId -Type "xml") -XPath "*"
    }

    # Return the Description
    if($flowxml.Node.Description) {
        return $flowxml.Node.Description
    }

    return ""
}