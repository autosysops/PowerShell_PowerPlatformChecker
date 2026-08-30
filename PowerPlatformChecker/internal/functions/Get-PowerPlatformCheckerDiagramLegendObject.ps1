function Get-PowerPlatformCheckerDiagramLegendObject {
    <#
    .SYNOPSIS
        Builds the structured legend object for a diagram graph.

    .DESCRIPTION
        Resolves style rows plus diagram-specific alias, connector, and note
        metadata into a format-neutral legend object.

    .PARAMETER DiagramType
        Diagram legend type to build.

    .PARAMETER Graph
        Optional diagram graph object.

    .PARAMETER StyleOverrides
        Optional style overrides used when Graph is not supplied.

    .EXAMPLE
        Build the structured legend object for an architecture diagram.

        Get-PowerPlatformCheckerDiagramLegendObject -DiagramType ArchitectureDiagram
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('ArchitectureDiagram', 'ExternalInteraction')]
        [string] $DiagramType,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Graph,

        [Parameter(Mandatory = $false)]
        [hashtable] $StyleOverrides
    )

    $styleRows = [System.Collections.Generic.List[object]]::new()
    $sourceAliases = @()
    $connectorLegend = @()
    $legendNotes = @()
    $allowedStyleNames = @()

    $styleMap = @{}
    $styleNames = @()

    if ($PSBoundParameters.ContainsKey('Graph') -and $null -ne $Graph) {
        $allowedStyleNames = @($Graph.Nodes | ForEach-Object { [string]$_.ClassKind } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
        if ($Graph.Styles -is [System.Collections.IDictionary]) {
            foreach ($styleKey in @($Graph.Styles.Keys)) {
                $styleMap[[string]$styleKey] = [string]$Graph.Styles[[string]$styleKey]
            }
        }
        else {
            foreach ($styleProperty in @($Graph.Styles.PSObject.Properties)) {
                $styleMap[[string]$styleProperty.Name] = [string]$styleProperty.Value
            }
        }

        if ($Graph.StyleOrder) {
            $styleNames = @($Graph.StyleOrder)
        }
        else {
            $styleNames = @($styleMap.Keys | Sort-Object)
        }

        if ($DiagramType -eq 'ExternalInteraction' -and $Graph.Metadata) {
            $sourceAliases = @($Graph.Metadata.SourceAliases)
            $connectorLegend = @($Graph.Metadata.ConnectorLegend)
            $legendNotes = @($Graph.Metadata.LegendNotes)
        }
    }
    else {
        $resolvedStyle = Get-PowerPlatformCheckerResolvedStyle -StyleTarget 'ArchitectureDiagram' -StyleOverrides $StyleOverrides
        $styleMap = @{
            default = "fill:$($resolvedStyle.Default),stroke:$($resolvedStyle.Stroke)"
            EnvVar = "fill:$($resolvedStyle.EnvVar),stroke:$($resolvedStyle.Stroke)"
            Connection = "fill:$($resolvedStyle.Connection),stroke:$($resolvedStyle.Stroke)"
            Entity = "fill:$($resolvedStyle.Entity),stroke:$($resolvedStyle.Stroke)"
            DefaultEntity = "fill:$($resolvedStyle.DefaultEntity),stroke:$($resolvedStyle.Stroke)"
            Flow = "fill:$($resolvedStyle.Flow),stroke:$($resolvedStyle.Stroke)"
            CanvasApp = "fill:$($resolvedStyle.CanvasApp),stroke:$($resolvedStyle.Stroke)"
            ModelDrivenApp = "fill:$($resolvedStyle.ModelDrivenApp),stroke:$($resolvedStyle.Stroke)"
            WebResource = "fill:$($resolvedStyle.WebResource),stroke:$($resolvedStyle.Stroke)"
            Solution = "fill:$($resolvedStyle.Solution),stroke:$($resolvedStyle.SolutionStroke),stroke-width:2px;"
            ExternalDomain = "fill:$($resolvedStyle.ExternalDomain),stroke:$($resolvedStyle.Stroke)"
        }
        $styleNames = @($styleMap.Keys | Sort-Object)
    }

    foreach ($styleName in @($styleNames)) {
        if ($DiagramType -eq 'ExternalInteraction' -and @($allowedStyleNames).Count -gt 0) {
            if ([string]$styleName -eq 'default') {
                continue
            }

            if (@($allowedStyleNames) -notcontains [string]$styleName) {
                continue
            }
        }

        if (-not $styleMap.ContainsKey([string]$styleName)) {
            continue
        }

        $styleValue = [string]$styleMap[[string]$styleName]
        if ([string]::IsNullOrWhiteSpace($styleValue)) {
            continue
        }

        $fillMatch = [regex]::Match($styleValue, '(?i)fill:(?<fill>#[0-9a-f]{3,8}|[a-z]+)')
        $strokeMatch = [regex]::Match($styleValue, '(?i)stroke:(?<stroke>#[0-9a-f]{3,8}|[a-z]+)')

        $fillColor = if ($fillMatch.Success) { [string]$fillMatch.Groups['fill'].Value } else { '' }
        $strokeColor = if ($strokeMatch.Success) { [string]$strokeMatch.Groups['stroke'].Value } else { '' }

        [void]$styleRows.Add([pscustomobject]@{
                Type = [string]$styleName
                Fill = $fillColor
                Stroke = $strokeColor
                Style = $styleValue
            })
    }

    return [pscustomobject]@{
        DiagramType = $DiagramType
        StyleItems = @($styleRows)
        SourceAliases = @($sourceAliases)
        Connectors = @($connectorLegend)
        Notes = @($legendNotes)
    }
}
