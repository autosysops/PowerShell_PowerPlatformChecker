function Convert-PowerPlatformCheckerArchitectureNodeToMermaid {
    <#
    .SYNOPSIS
        Renders one architecture-graph node as Mermaid text.

    .DESCRIPTION
        Converts a normalized architecture graph node into its Mermaid class or
        flowchart declaration without requiring any further solution lookup.

    .PARAMETER Node
        Graph node to render.

    .PARAMETER DiagramKind
        Mermaid diagram kind, such as Flowchart or ClassDiagram.

    .EXAMPLE
        Render an architecture node for Mermaid output.

        Convert-PowerPlatformCheckerArchitectureNodeToMermaid -Node $node -DiagramKind Flowchart
    #>

    [CmdletBinding()]
    [OutputType([string], [string[]])]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Node,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Flowchart', 'ClassDiagram')]
        [string] $DiagramKind
    )

    if ($DiagramKind -eq 'Flowchart') {
        $nodeLabel = [string]$Node.DisplayName
        if ([string]::IsNullOrWhiteSpace($nodeLabel)) {
            $nodeLabel = [string]$Node.Id
        }

        $nodeLabel = $nodeLabel.Replace('"', "'")
        return ('{0}["{1}"]:::{2}' -f [string]$Node.Id, [string]$nodeLabel, [string]$Node.ClassKind)
    }

    $declaration = "class $($Node.Id)"
    $displayName = [string]$Node.DisplayName
    switch ([string]$Node.ClassKind) {
        'Flow' {
            if ($null -ne $Node.Properties -and $Node.Properties.ContainsKey('FlowType')) {
                $flowType = [string]$Node.Properties['FlowType']
                if (-not [string]::IsNullOrWhiteSpace($flowType)) {
                    $displayName = '[{0}] {1}' -f $flowType.ToUpper(), $displayName
                }
            }
        }
    }

    if ($Node.HasExplicitDisplayName) {
        $declaration += "[`"$displayName`"]"
    }
    $declaration += ":::$($Node.ClassKind)"

    if (@($Node.Members).Count -eq 0) {
        return $declaration
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    [void]$lines.Add($declaration + ' {')
    foreach ($member in @($Node.Members)) {
        [void]$lines.Add([string]$member)
    }
    [void]$lines.Add('}')
    return [string[]]@($lines)
}
