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

    if ($Graph.Metadata -and [string]$Graph.Metadata.DiagramKind -eq 'Flowchart') {
        $flowDirection = [string]$Graph.Metadata.Direction
        if ([string]::IsNullOrWhiteSpace($flowDirection)) {
            $flowDirection = 'LR'
        }

        $flowLines = @(':::mermaid', "graph $flowDirection;")

        foreach ($node in @($Graph.Nodes)) {
            $nodeLabel = [string]$node.DisplayName
            if ([string]::IsNullOrWhiteSpace($nodeLabel)) {
                $nodeLabel = [string]$node.Id
            }
            $nodeLabel = $nodeLabel.Replace('"', "'")
            $flowLines += ('{0}["{1}"]:::{2}' -f [string]$node.Id, [string]$nodeLabel, [string]$node.ClassKind)
        }

        foreach ($edge in @($Graph.Edges)) {
            $arrow = if ($edge.Metadata.Arrow) { [string]$edge.Metadata.Arrow } elseif ($edge.EdgeType -eq 'Reference') { '..>' } else { '-->' }
            if ($arrow -eq '..>') {
                $arrow = '-.->'
            }

            $edgeLabel = [string]$edge.Label
            if ($edge.Metadata -and $edge.Metadata.PSObject.Properties.Name -contains 'MermaidLabel' -and -not [string]::IsNullOrWhiteSpace([string]$edge.Metadata.MermaidLabel)) {
                $edgeLabel = [string]$edge.Metadata.MermaidLabel
            }
            if (-not [string]::IsNullOrWhiteSpace($edgeLabel)) {
                $safeEdgeLabel = $edgeLabel
                $safeEdgeLabel = $safeEdgeLabel.Replace('|', '/')
                $safeEdgeLabel = $safeEdgeLabel.Replace('"', "'")
                # Mermaid flowchart edge labels are sensitive to punctuation used by node syntax.
                # Keep labels plain text to avoid parse errors in wiki renderers.
                $safeEdgeLabel = $safeEdgeLabel -replace '[\(\)\[\]\{\}]', ' '
                $safeEdgeLabel = $safeEdgeLabel -replace '[:;,]', ' '
                $safeEdgeLabel = $safeEdgeLabel -replace '\s{2,}', ' '
                $safeEdgeLabel = $safeEdgeLabel.Trim()
                $flowLines += "$($edge.SourceId) $arrow|$safeEdgeLabel| $($edge.TargetId)"
            }
            else {
                $flowLines += "$($edge.SourceId) $arrow $($edge.TargetId)"
            }
        }

        $styleNames = if (@($Graph.StyleOrder).Count -gt 0) { @($Graph.StyleOrder) } else { @($Graph.Styles.PSObject.Properties.Name) }
        foreach ($styleName in $styleNames) {
            $styleValue = ''
            if ($Graph.Styles -is [System.Collections.IDictionary]) {
                $styleValue = [string]$Graph.Styles[[string]$styleName]
            }
            else {
                $styleProperty = $Graph.Styles.PSObject.Properties[[string]$styleName]
                if ($null -ne $styleProperty) {
                    $styleValue = [string]$styleProperty.Value
                }
            }

            if ([string]::IsNullOrWhiteSpace([string]$styleName) -or [string]::IsNullOrWhiteSpace($styleValue)) {
                continue
            }

            $flowLines += "classDef $styleName $styleValue"
        }

        $flowLines += ':::'
        return ($flowLines -join $newline)
    }

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
        $styleValue = ''
        if ($Graph.Styles -is [System.Collections.IDictionary]) {
            $styleValue = [string]$Graph.Styles[[string]$styleName]
        }
        else {
            $styleProperty = $Graph.Styles.PSObject.Properties[[string]$styleName]
            if ($null -ne $styleProperty) {
                $styleValue = [string]$styleProperty.Value
            }
        }

        if ([string]::IsNullOrWhiteSpace([string]$styleName) -or [string]::IsNullOrWhiteSpace($styleValue)) {
            continue
        }

        $lines += "classDef $styleName $styleValue"
    }

    $lines += ":::"
    return ($lines -join $newline)
}