function Get-PowerPlatformCheckerDiagramLegend {
    <#
    .SYNOPSIS
        Generates a wiki-ready legend for PowerPlatformChecker diagram outputs.

    .DESCRIPTION
        Returns style legend rows for a diagram type and, for external interaction
        graphs, includes compact source aliases and connector code/color mappings.

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
        PS> Get-PowerPlatformCheckerDiagramLegend -DiagramType ArchitectureDiagram

    .EXAMPLE
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

    $styleRows = [System.Collections.Generic.List[object]]::new()
    $sourceAliases = @()
    $connectorLegend = @()
    $legendNotes = @()

    $styleMap = @{}
    $styleNames = @()

    if ($PSBoundParameters.ContainsKey('Graph') -and $null -ne $Graph) {
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
            Solution = "fill:$($resolvedStyle.Solution),stroke:#111111,stroke-width:2px;"
            ExternalDomain = "fill:$($resolvedStyle.ExternalDomain),stroke:$($resolvedStyle.Stroke)"
        }
        $styleNames = @($styleMap.Keys | Sort-Object)
    }

    foreach ($styleName in @($styleNames)) {
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

    $legendObject = [pscustomobject]@{
        DiagramType = $DiagramType
        StyleItems = @($styleRows)
        SourceAliases = @($sourceAliases)
        Connectors = @($connectorLegend)
        Notes = @($legendNotes)
    }

    if ($OutputFormat -eq 'Object') {
        return $legendObject
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    [void]$lines.Add('### Diagram Legend')
    foreach ($styleRow in @($legendObject.StyleItems)) {
        $fill = [string]$styleRow.Fill
        $typeName = [string]$styleRow.Type
        if ([string]::IsNullOrWhiteSpace($fill)) {
            [void]$lines.Add("- $typeName")
        }
        else {
            [void]$lines.Add("- <span style=`"color:$fill`">$typeName</span>")
        }
    }

    if ($DiagramType -eq 'ExternalInteraction') {
        if (@($legendObject.SourceAliases).Count -gt 0) {
            [void]$lines.Add('')
            [void]$lines.Add('### Flow and App Aliases')
            foreach ($sourceAlias in @($legendObject.SourceAliases | Sort-Object Alias)) {
                $displayName = [string]$sourceAlias.DisplayName
                $typeName = [string]$sourceAlias.Type
                $solutionName = [string]$sourceAlias.SolutionName
                [void]$lines.Add("- $($sourceAlias.Alias) = $typeName / $displayName (Solution: $solutionName)")
            }
        }

        if (@($legendObject.Connectors).Count -gt 0) {
            [void]$lines.Add('')
            [void]$lines.Add('### Connector Codes')
            foreach ($connector in @($legendObject.Connectors | Sort-Object Code)) {
                [void]$lines.Add("- <span style=`"color:$($connector.Color)`">$($connector.Code)</span> = $($connector.DisplayName)")
            }
        }

        if (@($legendObject.Notes).Count -gt 0) {
            [void]$lines.Add('')
            [void]$lines.Add('### Notes')
            foreach ($note in @($legendObject.Notes | Select-Object -Unique)) {
                [void]$lines.Add("- $note")
            }
        }
    }

    return ($lines -join [Environment]::NewLine)
}
