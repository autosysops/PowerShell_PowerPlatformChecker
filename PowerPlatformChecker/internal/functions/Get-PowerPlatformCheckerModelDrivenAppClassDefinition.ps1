function Get-PowerPlatformCheckerModelDrivenAppClassDefinition {
    <#
    .SYNOPSIS
        Builds Mermaid class definition text for a model-driven app node.

    .DESCRIPTION
        Converts model-driven app metadata into Mermaid class syntax, including
        app component rows when available.

    .PARAMETER ModelApp
        Model-driven app metadata object.

    .PARAMETER NewLine
        Line separator to use when composing the Mermaid block.

    .EXAMPLE
        Build class text for one model-driven app node.

        PS> Get-PowerPlatformCheckerModelDrivenAppClassDefinition -ModelApp $app

        Returns Mermaid class text with component lines when component metadata exists.
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [object] $ModelApp,

        [Parameter(Mandatory = $false)]
        [string] $NewLine = [Environment]::NewLine
    )

    $componentLines = @()
    foreach ($component in @($ModelApp.Components)) {
        if (-not $component) { continue }

        $componentValue = if (-not [string]::IsNullOrWhiteSpace([string]$component.SchemaName)) {
            [string]$component.SchemaName
        }
        elseif (-not [string]::IsNullOrWhiteSpace([string]$component.Id)) {
            ([string]$component.Id).Trim('{}')
        }
        else {
            continue
        }

        $componentLines += "  [$($component.ComponentTypeName)]$componentValue$NewLine"
    }

    if ($componentLines.Count -gt 0) {
        $block = "class $($ModelApp.MermaidId)[`"$($ModelApp.DisplayName)`"]:::ModelDrivenApp {$NewLine"
        foreach ($componentLine in ($componentLines | Select-Object -Unique)) {
            $block += $componentLine
        }
        $block += "}$NewLine"
        return $block
    }

    return "class $($ModelApp.MermaidId)[`"$($ModelApp.DisplayName)`"]:::ModelDrivenApp$NewLine"
}
