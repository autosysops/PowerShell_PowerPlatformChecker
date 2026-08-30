function Get-PowerPlatformCheckerSubflowChart {
    <#
    .SYNOPSIS
        Generates a Mermaid flowchart for one desktop subflow.

    .DESCRIPTION
        Retrieves actions from a selected desktop FUNCTION/subflow and renders
        the result as Mermaid or graph output using the existing flowchart pipeline.

    .PARAMETER Path
        Path to a desktop flow JSON file.

    .PARAMETER SubflowName
        Name of the desktop FUNCTION/subflow to render.

    .PARAMETER Direction
        Mermaid flow direction. Default Top-to-Bottom (`TB`).

    .PARAMETER OutputFormat
        Output format to return: Mermaid markdown text (default) or graph object.

    .PARAMETER IncludeStyles
        Includes flowchart style metadata and Mermaid style declarations.

    .EXAMPLE
        Render a desktop subflow as Mermaid.

        PS> Get-PowerPlatformCheckerSubflowChart -Path 'C:\Flow.json' -SubflowName 'ProcessOrder'
    #>

    [CmdletBinding()]
    [OutputType([string], [pscustomobject])]
    param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $Path,

        [Parameter(Mandatory = $true, Position = 2)]
        [string] $SubflowName,

        [Parameter(Mandatory = $false)]
        [ValidateSet('TB', 'BT', 'LR', 'RL')]
        [string] $Direction = 'TB',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Mermaid', 'Graph')]
        [string] $OutputFormat = 'Mermaid',

        [Parameter(Mandatory = $false)]
        [switch] $IncludeStyles
    )

    $telemetryProperties = @{
        Direction = $Direction
        OutputFormat = $OutputFormat
        IncludeStyles = $IncludeStyles.IsPresent
    }
    Send-THEvent -ModuleName 'PowerPlatformChecker' -EventName 'Get-PowerPlatformCheckerSubflowChart' -PropertiesHash $telemetryProperties

    $actions = @(Get-PowerPlatformCheckerSubflowActionList -Path $Path -SubflowName $SubflowName -Properties RunAfter,ParentAction)
    return Get-PowerPlatformCheckerFlowChart -Actions $actions -Direction $Direction -OutputFormat $OutputFormat -IncludeStyles:$IncludeStyles
}

