function Convert-PowerPlatformCheckerArchitectureGraphToMermaid {
    <#
    .SYNOPSIS
        Converts an architecture graph to Mermaid markdown.

    .DESCRIPTION
        Renders the normalized nodes, class members, edges, and styles produced
        for a Power Platform architecture diagram.

    .PARAMETER Graph
        Architecture graph containing Metadata, Nodes, Edges, and Styles.

    .OUTPUTS
        System.String. Returns Mermaid class diagram markdown.

    .EXAMPLE
        Render a previously generated architecture graph.

        PS> Convert-PowerPlatformCheckerArchitectureGraphToMermaid -Graph $graph
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Graph
    )

    $newline = [Environment]::NewLine
    $lines = @(":::mermaid", "classDiagram", "direction $($Graph.Metadata.Direction)")

    foreach ($node in @($Graph.Nodes)) {
        $declaration = "class $($node.Id)"
        $displayName = [string]$node.DisplayName
        if ($node.ClassKind -eq "Flow" -and $null -ne $node.Properties -and $node.Properties.ContainsKey("FlowType")) {
            $flowType = [string]$node.Properties["FlowType"]
            if (-not [string]::IsNullOrWhiteSpace($flowType)) {
                $displayName = "[{0}] {1}" -f $flowType.ToUpper(), $displayName
            }
        }
        if ($node.HasExplicitDisplayName) {
            $declaration += "[`"$displayName`"]"
        }
        $declaration += ":::$($node.ClassKind)"

        if (@($node.Members).Count -eq 0) {
            $lines += $declaration
            continue
        }

        $lines += "$declaration {"
        $lines += @($node.Members)
        $lines += "}"
    }

    foreach ($edge in @($Graph.Edges)) {
        $arrow = if ($edge.Metadata.Arrow) { [string]$edge.Metadata.Arrow } elseif ($edge.EdgeType -eq "Reference") { "..>" } else { "-->" }
        $edgeLine = "$($edge.SourceId) $arrow $($edge.TargetId)"
        if (-not [string]::IsNullOrWhiteSpace([string]$edge.Label)) {
            $edgeLine += ":$($edge.Label)"
        }
        $lines += $edgeLine
    }

    $styleNames = if (@($Graph.StyleOrder).Count -gt 0) { @($Graph.StyleOrder) } else { @($Graph.Styles.PSObject.Properties.Name) }
    foreach ($styleName in $styleNames) {
        $lines += "classDef $styleName $($Graph.Styles.$styleName)"
    }

    $lines += ":::"
    return ($lines -join $newline)
}