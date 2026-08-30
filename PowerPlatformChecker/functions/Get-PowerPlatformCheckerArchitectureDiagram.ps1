function Get-PowerPlatformCheckerArchitectureDiagram {
    <#
    .SYNOPSIS
        Generates a Mermaid class diagram for a Power Platform solution.

    .DESCRIPTION
        Produces markdown containing a Mermaid classDiagram based on flows, environment variables,
        connection references, entities, canvas apps, model-driven apps, and JavaScript web resources.
        When a flow, canvas app, or model-driven app filter is used, the diagram is scoped to the
        directly connected components for that selected item.

    .PARAMETER SolutionPath
        The root path of the unpacked solution.

    .PARAMETER FlowId
        Optional flow id filter.

    .PARAMETER CanvasAppName
        Optional canvas app internal name filter.

    .PARAMETER ModelDrivenAppName
        Optional model-driven app unique name filter.

    .PARAMETER Direction
        Mermaid layout direction. Default is Left-to-Right (`LR`).

    .PARAMETER IncludeElements
        Which diagram element groups to include. Defaults to all groups.

    .PARAMETER OutputFormat
        Output format to return: Mermaid markdown text (default) or parsed Graph object.

    .PARAMETER StyleOverrides
        Optional hashtable that overrides recognized diagram color keys for this call only.
        Values set with Set-PowerPlatformCheckerStyle provide the session baseline;
        values supplied here take precedence without changing that baseline.

    .OUTPUTS
        System.String when OutputFormat is Mermaid. Returns Azure DevOps-flavored Mermaid
        markdown containing a classDiagram.

        System.Management.Automation.PSCustomObject when OutputFormat is Graph. The graph
        contains Metadata, Nodes, Edges, Styles, and StyleOrder. Metadata describes direction,
        included element groups, and source filtering. Each node contains Id, Type, DisplayName,
        ClassKind, Properties, Members, and HasExplicitDisplayName. Each edge contains SourceId,
        TargetId, Label, EdgeType, and Metadata.Arrow. Styles maps class names to Mermaid style
        declarations; StyleOrder preserves deterministic rendering order.

    .EXAMPLE
        Generate a full architecture diagram markdown block for a solution.

        PS> Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath "C:\Solutions\MySolution"

    .EXAMPLE
        Generate an architecture diagram scoped to a single flow.

        PS> Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath "C:\Solutions\MySolution" -FlowId "00000000-0000-0000-0000-000000000000"

    .EXAMPLE
        Generate an architecture diagram with top-to-bottom layout.

        PS> Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath "C:\Solutions\MySolution" -Direction TB

    .EXAMPLE
        Generate a flow-only architecture view (exclude apps/entities/connections).

        PS> Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath "C:\Solutions\MySolution" -IncludeElements Flows

    .EXAMPLE
        Override diagram colors for this call only.

        PS> $style = @{ Flow = '#4CC9F0'; Connection = '#FFD166'; Stroke = '#2B2D42' }
        PS> Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath "C:\Solutions\MySolution" -StyleOverrides $style
    #>

    [CmdletBinding(DefaultParameterSetName = "NoFilter")]
    [OutputType([string], [pscustomobject])]
    param(
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "NoFilter")]
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "FilterByFlow")]
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "FilterByCanvasApp")]
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "FilterByModelDrivenApp")]
        [string] $SolutionPath,

        [Parameter(Mandatory = $true, Position = 2, ParameterSetName = "FilterByFlow")]
        [string] $FlowId,

        [Parameter(Mandatory = $true, Position = 2, ParameterSetName = "FilterByCanvasApp")]
        [string] $CanvasAppName,

        [Parameter(Mandatory = $true, Position = 2, ParameterSetName = "FilterByModelDrivenApp")]
        [string] $ModelDrivenAppName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("LR", "RL", "TB", "BT")]
        [string] $Direction = "LR",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Flows", "CanvasApps", "ModelDrivenApps", "EnvironmentVariables", "Connections", "Entities", "DefaultEntities", "WebResources", "ExternalDomains")]
        [string[]] $IncludeElements = @("Flows", "CanvasApps", "ModelDrivenApps", "EnvironmentVariables", "Connections", "Entities", "DefaultEntities", "WebResources", "ExternalDomains"),

        [Parameter(Mandatory = $false)]
        [ValidateSet("Mermaid", "Graph")]
        [string] $OutputFormat = "Mermaid",

        [Parameter(Mandatory = $false)]
        [hashtable] $StyleOverrides
    )

    $telemetryProperties = @{
        ParameterSet = $PSCmdlet.ParameterSetName
        HasFlowFilter = $PSBoundParameters.ContainsKey("FlowId")
        HasCanvasFilter = $PSBoundParameters.ContainsKey("CanvasAppName")
        HasModelDrivenFilter = $PSBoundParameters.ContainsKey("ModelDrivenAppName")
        Direction = $Direction
        OutputFormat = $OutputFormat
        IncludeElements = (($IncludeElements | Sort-Object -Unique) -join ",")
        HasStyleOverrides = $PSBoundParameters.ContainsKey("StyleOverrides")
    }
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerArchitectureDiagram" -PropertiesHash $telemetryProperties

    $graph = Get-PowerPlatformCheckerArchitectureDiagramInternal `
        -SolutionPath $SolutionPath `
        -FlowId $FlowId `
        -CanvasAppName $CanvasAppName `
        -ModelDrivenAppName $ModelDrivenAppName `
        -Direction $Direction `
        -IncludeElements $IncludeElements `
        -StyleOverrides $StyleOverrides

    return Convert-PowerPlatformCheckerDiagramGraphToOutput -Graph $graph -OutputFormat $OutputFormat
}


