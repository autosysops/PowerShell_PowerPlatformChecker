function Convert-PowerPlatformCheckerMermaidToGraph {
    <#
    .SYNOPSIS
        Converts a Mermaid class diagram string to graph collections.

    .DESCRIPTION
        Parses Mermaid class diagram text and produces normalized node, edge,
        and style collections used by Graph output mode.

    .PARAMETER MermaidText
        Mermaid markdown content.

    .EXAMPLE
        Parse Mermaid diagram text into graph objects.

        PS> Convert-PowerPlatformCheckerMermaidToGraph -MermaidText $diagram

        Returns node, edge, and style collections derived from class diagram lines.
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string] $MermaidText
    )

    $nodeMap = @{}
    $edgeList = @()
    $styleMap = @{}
    $diagramLines = @($MermaidText -split "`r?`n")

    foreach ($line in $diagramLines) {
        # Parse class declarations first to build node metadata.
        if ($line -match '^\s*class\s+(?<id>[^\[\s:]+)(?:\["(?<display>.*)"\])?:::(?<type>[A-Za-z0-9_]+)') {
            $nodeId = [string]$matches.id
            $displayName = if ($matches.display) { [string]$matches.display } else { [string]$nodeId }
            $nodeType = [string]$matches.type

            if (-not $nodeMap.ContainsKey($nodeId)) {
                $nodeMap[$nodeId] = [pscustomobject]@{
                    Id = $nodeId
                    Type = $nodeType
                    DisplayName = $displayName
                    ClassKind = $nodeType
                    Properties = @{}
                }
            }
            continue
        }

        # Parse edge lines with arrow metadata so caller can distinguish link vs reference.
        if ($line -match '^\s*(?<source>[A-Za-z0-9_\-]+)\s+(?<arrow>-->|\.\.>)\s+(?<target>[A-Za-z0-9_\-]+)(?::(?<label>.*))?\s*$') {
            $edgeList += [pscustomobject]@{
                SourceId = [string]$matches.source
                TargetId = [string]$matches.target
                Label = if ($matches.label) { [string]$matches.label } else { "" }
                EdgeType = if ($matches.arrow -eq "..>") { "Reference" } else { "Link" }
                Metadata = @{ Arrow = [string]$matches.arrow }
            }
            continue
        }

        # Preserve class style definitions for downstream consumers of graph output.
        if ($line -match '^\s*classDef\s+(?<className>[A-Za-z0-9_]+)\s+(?<style>.+)$') {
            $styleMap[[string]$matches.className] = [string]$matches.style
            continue
        }
    }

    return [pscustomobject]@{
        Nodes = @($nodeMap.Values)
        Edges = @($edgeList)
        Styles = [pscustomobject]$styleMap
    }
}
