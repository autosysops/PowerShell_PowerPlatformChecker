function Convert-PowerPlatformCheckerDiagramLegendToMarkdown {
    <#
    .SYNOPSIS
        Converts a structured diagram legend object to Markdown.

    .DESCRIPTION
        Renders the legend content for supported diagram types without reparsing
        Mermaid output.

    .PARAMETER Legend
        Structured legend object.

    .EXAMPLE
        Render a structured legend object as Markdown.

        Convert-PowerPlatformCheckerDiagramLegendToMarkdown -Legend $legend
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Legend
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    [void]$lines.Add('### Diagram Legend')
    foreach ($styleRow in @($Legend.StyleItems)) {
        $fill = [string]$styleRow.Fill
        $typeName = [string]$styleRow.Type
        if ([string]::IsNullOrWhiteSpace($fill)) {
            [void]$lines.Add("- $typeName")
        }
        else {
            [void]$lines.Add("- <span style=`"color:$fill`">$typeName</span>")
        }
    }

    if ([string]$Legend.DiagramType -eq 'ExternalInteraction') {
        if (@($Legend.SourceAliases).Count -gt 0) {
            [void]$lines.Add('')
            [void]$lines.Add('### Flow and App Aliases')
            foreach ($sourceAlias in @($Legend.SourceAliases | Sort-Object Alias)) {
                $displayName = [string]$sourceAlias.DisplayName
                $typeName = [string]$sourceAlias.Type
                $solutionName = [string]$sourceAlias.SolutionName
                [void]$lines.Add("- $($sourceAlias.Alias) = $typeName / $displayName (Solution: $solutionName)")
            }
        }

        if (@($Legend.Connectors).Count -gt 0) {
            [void]$lines.Add('')
            [void]$lines.Add('### Connector Codes')
            foreach ($connector in @($Legend.Connectors | Sort-Object Code)) {
                [void]$lines.Add("- $($connector.Code) = $($connector.DisplayName)")
            }
        }

        if (@($Legend.Notes).Count -gt 0) {
            [void]$lines.Add('')
            [void]$lines.Add('### Notes')
            foreach ($note in @($Legend.Notes | Select-Object -Unique)) {
                [void]$lines.Add("- $note")
            }
        }
    }

    return ($lines -join [Environment]::NewLine)
}
