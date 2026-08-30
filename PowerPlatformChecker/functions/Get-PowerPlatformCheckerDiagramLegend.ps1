function Get-PowerPlatformCheckerDiagramLegend {
    <#
    .SYNOPSIS
        Generates a wiki-ready legend for PowerPlatformChecker diagram outputs.

    .DESCRIPTION
        Returns style legend rows for a diagram type and, for external interaction
        graphs, includes compact source aliases and connector code mappings.

    .PARAMETER DiagramType
        Diagram legend type to generate.

    .PARAMETER Graph
        Optional graph object returned by diagram commands. When supplied, style
        and metadata are derived from the graph payload.

    .PARAMETER OutputFormat
        Return markdown text or a structured object.

    .PARAMETER StyleOverrides
        Optional per-call style overrides used when Graph is not supplied.

    .EXAMPLE
        Return the architecture-diagram legend using resolved default styles.

        PS> Get-PowerPlatformCheckerDiagramLegend -DiagramType ArchitectureDiagram

    .EXAMPLE
        Build an external-interaction legend from a graph payload, including aliases.

        PS> $graph = Get-PowerPlatformCheckerExternalInteraction -SolutionPaths $path -OutputFormat Graph
        PS> Get-PowerPlatformCheckerDiagramLegend -DiagramType ExternalInteraction -Graph $graph
    #>

    [CmdletBinding()]
    [OutputType([string], [pscustomobject])]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('ArchitectureDiagram', 'ExternalInteraction')]
        [string] $DiagramType = 'ArchitectureDiagram',

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Graph,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Markdown', 'Object')]
        [string] $OutputFormat = 'Markdown',

        [Parameter(Mandatory = $false)]
        [hashtable] $StyleOverrides
    )

    $telemetryProperties = @{
        DiagramType = $DiagramType
        HasGraph = $PSBoundParameters.ContainsKey('Graph')
        OutputFormat = $OutputFormat
        HasStyleOverrides = $PSBoundParameters.ContainsKey('StyleOverrides')
    }
    Send-THEvent -ModuleName 'PowerPlatformChecker' -EventName 'Get-PowerPlatformCheckerDiagramLegend' -PropertiesHash $telemetryProperties

    $legendObject = Get-PowerPlatformCheckerDiagramLegendObject -DiagramType $DiagramType -Graph $Graph -StyleOverrides $StyleOverrides

    if ($OutputFormat -eq 'Object') {
        return $legendObject
    }

    return Convert-PowerPlatformCheckerDiagramLegendToMarkdown -Legend $legendObject
}
