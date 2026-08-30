function Convert-PowerPlatformCheckerDiagramGraphToOutput {
    <#
    .SYNOPSIS
        Converts a diagram graph to the requested public output format.

    .DESCRIPTION
        Centralizes the final output step for diagram commands so each public
        entry point can follow the same orchestration pattern: collect data,
        build Graph, then render that Graph or return it directly.

    .PARAMETER Graph
        Diagram graph object produced by one of the diagram graph builders.

    .PARAMETER OutputFormat
        Return the Graph object directly or convert it to Mermaid markdown.

    .EXAMPLE
        Convert a prepared diagram graph to Mermaid text.

        Convert-PowerPlatformCheckerDiagramGraphToOutput -Graph $graph -OutputFormat Mermaid
    #>

    [CmdletBinding()]
    [OutputType([string], [pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Graph,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Mermaid', 'Graph')]
        [string] $OutputFormat
    )

    if ($OutputFormat -eq 'Graph') {
        return $Graph
    }

    if ($Graph.PSObject.Properties.Name -contains 'GraphType' -and [string]$Graph.GraphType -eq 'FlowchartGraph') {
        return Convert-PowerPlatformCheckerFlowChartGraphToMermaid -Graph $Graph
    }

    return Convert-PowerPlatformCheckerArchitectureGraphToMermaid -Graph $Graph
}
