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
            $flowLines += @(Convert-PowerPlatformCheckerArchitectureNodeToMermaid -Node $node -DiagramKind Flowchart)
        }

        foreach ($edge in @($Graph.Edges)) {
            $flowLines += (Convert-PowerPlatformCheckerArchitectureEdgeToMermaid -Edge $edge -DiagramKind Flowchart)
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

            $flowLines += (Convert-PowerPlatformCheckerArchitectureStyleToMermaid -StyleName ([string]$styleName) -StyleValue $styleValue)
        }

        $flowLines += ':::'
        return ($flowLines -join $newline)
    }

    $lines = @(":::mermaid", "classDiagram", "direction $($Graph.Metadata.Direction)")

    foreach ($node in @($Graph.Nodes)) {
        $lines += @(Convert-PowerPlatformCheckerArchitectureNodeToMermaid -Node $node -DiagramKind ClassDiagram)
    }

    foreach ($edge in @($Graph.Edges)) {
        $lines += (Convert-PowerPlatformCheckerArchitectureEdgeToMermaid -Edge $edge -DiagramKind ClassDiagram)
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

        $lines += (Convert-PowerPlatformCheckerArchitectureStyleToMermaid -StyleName ([string]$styleName) -StyleValue $styleValue)
    }

    $lines += ":::"
    return ($lines -join $newline)
}