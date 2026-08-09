function Get-PowerPlatformCheckerArchitectureDiagramGraph {
    <#
    .SYNOPSIS
        Builds a normalized Power Platform architecture graph.

    .DESCRIPTION
        Deduplicates contributed nodes and edges, removes edges with undeclared
        endpoints, resolves enabled styles, and attaches diagram metadata.

    .PARAMETER Nodes
        Node contributions collected from architecture domain helpers.

    .PARAMETER Edges
        Edge contributions collected from architecture domain helpers.

    .PARAMETER Direction
        Diagram layout direction.

    .PARAMETER IncludeElements
        Element groups requested for the diagram.

    .PARAMETER IncludePolicy
        Resolved include policy used to select style classes.

    .PARAMETER Style
        Resolved architecture color map.

    .PARAMETER IsScopedDiagram
        Indicates whether the graph is scoped to a selected component.

    .PARAMETER SourceFilterType
        Selected component type, or None for a full graph.

    .PARAMETER SourceFilterValue
        Selected component identifier, or an empty string for a full graph.

    .OUTPUTS
        System.Management.Automation.PSCustomObject. Returns Metadata, Nodes,
        Edges, Styles, and StyleOrder for rendering or direct graph output.

    .EXAMPLE
        Normalize collected architecture contributions.

        PS> Get-PowerPlatformCheckerArchitectureDiagramGraph -Nodes $nodes -Edges $edges -Direction LR -IncludeElements $includeElements -IncludePolicy $policy -Style $style -IsScopedDiagram:$false -SourceFilterType None -SourceFilterValue ""
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object[]] $Nodes = @(),

        [Parameter(Mandatory = $false)]
        [object[]] $Edges = @(),

        [Parameter(Mandatory = $true)]
        [ValidateSet("LR", "RL", "TB", "BT")]
        [string] $Direction,

        [Parameter(Mandatory = $true)]
        [string[]] $IncludeElements,

        [Parameter(Mandatory = $true)]
        [object] $IncludePolicy,

        [Parameter(Mandatory = $true)]
        [hashtable] $Style,

        [Parameter(Mandatory = $true)]
        [bool] $IsScopedDiagram,

        [Parameter(Mandatory = $true)]
        [string] $SourceFilterType,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $SourceFilterValue
    )

    $uniqueNodes = [System.Collections.Generic.List[object]]::new()
    $nodeIds = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($node in $Nodes) {
        if ($nodeIds.Add([string]$node.Id)) { [void]$uniqueNodes.Add($node) }
    }

    $uniqueEdges = [System.Collections.Generic.List[object]]::new()
    $edgeKeys = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($edge in $Edges) {
        if (-not $nodeIds.Contains([string]$edge.SourceId) -or -not $nodeIds.Contains([string]$edge.TargetId)) { continue }
        $edgeKey = "{0}|{1}|{2}|{3}" -f $edge.SourceId, $edge.TargetId, $edge.Label, $edge.EdgeType
        if ($edgeKeys.Add($edgeKey)) { [void]$uniqueEdges.Add($edge) }
    }

    $styles = [ordered]@{ default = "fill:$($Style.Default),stroke:$($Style.Stroke)" }
    if ($IncludePolicy.IncludeEnvironmentVariables) { $styles.EnvVar = "fill:$($Style.EnvVar),stroke:$($Style.Stroke)" }
    if ($IncludePolicy.IncludeConnections) { $styles.Connection = "fill:$($Style.Connection),stroke:$($Style.Stroke)" }
    if ($IncludePolicy.IncludeEntities) { $styles.Entity = "fill:$($Style.Entity),stroke:$($Style.Stroke)" }
    if ($IncludePolicy.IncludeDefaultEntities) { $styles.DefaultEntity = "fill:$($Style.DefaultEntity),stroke:$($Style.Stroke)" }
    if ($IncludePolicy.IncludeFlows) { $styles.Flow = "fill:$($Style.Flow),stroke:$($Style.Stroke)" }
    if ($IncludePolicy.IncludeCanvasApps) { $styles.CanvasApp = "fill:$($Style.CanvasApp),stroke:$($Style.Stroke)" }
    if ($IncludePolicy.IncludeModelDrivenApps) { $styles.ModelDrivenApp = "fill:$($Style.ModelDrivenApp),stroke:$($Style.Stroke)" }
    if ($IncludePolicy.IncludeWebResources) { $styles.WebResource = "fill:$($Style.WebResource),stroke:$($Style.Stroke)" }

    return [pscustomobject]@{
        Metadata = [pscustomobject]@{
            Direction = $Direction
            IncludeElements = @($IncludeElements)
            IsScopedDiagram = $IsScopedDiagram
            SourceFilterType = $SourceFilterType
            SourceFilterValue = $SourceFilterValue
            OutputFormat = "Graph"
        }
        Nodes = @($uniqueNodes)
        Edges = @($uniqueEdges)
        Styles = [pscustomobject]$styles
        StyleOrder = @($styles.Keys)
    }
}