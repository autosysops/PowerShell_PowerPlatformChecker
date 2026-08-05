function Get-PowerPlatformCheckerIconResourceDiagramContent {
    <#
    .SYNOPSIS
        Builds Mermaid class blocks for icon web resources.

    .DESCRIPTION
        Renders icon web resource classes used by entities. In scoped diagrams,
        only connected icon resources are emitted.

    .PARAMETER IconResources
        Icon web resource records to evaluate for rendering.

    .PARAMETER IncludeWebResources
        Indicates whether web resource rendering is enabled.

    .PARAMETER IsScopedDiagram
        Indicates whether the current diagram is scoped to selected components.

    .PARAMETER ConnectedIconResources
        Icon resource names that are linked by rendered entities in scoped mode.

    .PARAMETER NewLine
        Line separator used when composing Mermaid output.

    .EXAMPLE
        Render icon class blocks for a scoped architecture view.

        PS> Get-PowerPlatformCheckerIconResourceDiagramContent -IconResources $icons -IncludeWebResources -IsScopedDiagram -ConnectedIconResources $connected

        Produces Mermaid class text for icon resources included in the current projection.
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [object[]] $IconResources = @(),

        [Parameter(Mandatory = $false)]
        [switch] $IncludeWebResources,

        [Parameter(Mandatory = $false)]
        [switch] $IsScopedDiagram,

        [Parameter(Mandatory = $false)]
        [string[]] $ConnectedIconResources = @(),

        [Parameter(Mandatory = $false)]
        [string] $NewLine = [Environment]::NewLine
    )

    if (-not $IncludeWebResources.IsPresent) {
        return ""
    }

    $diagram = ""
    foreach ($iconResource in @($IconResources)) {
        if (-not $iconResource) { continue }
        if ($IsScopedDiagram.IsPresent -and $iconResource.Name -notin $ConnectedIconResources) { continue }

        $diagram += "class $($iconResource.MermaidId)[`"$($iconResource.DisplayName)`"]:::WebResource {$NewLine"
        $diagram += "  [Icon]$($iconResource.Type)$NewLine"
        $diagram += "}$NewLine"
    }

    return $diagram
}
