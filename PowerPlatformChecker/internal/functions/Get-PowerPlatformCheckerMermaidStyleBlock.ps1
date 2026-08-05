function Get-PowerPlatformCheckerMermaidStyleBlock {
    <#
    .SYNOPSIS
        Generates Mermaid classDef style lines for enabled architecture diagram element types.

    .DESCRIPTION
        Produces the style section using the resolved style map and include policy.

    .PARAMETER Style
        Resolved style color map.

    .PARAMETER IncludePolicy
        Include/exclude policy object.

    .PARAMETER NewLine
        Line separator used by the caller.

    .EXAMPLE
        Get-PowerPlatformCheckerMermaidStyleBlock -Style $style -IncludePolicy $policy

        Produces classDef lines for only the enabled diagram element groups.
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $Style,

        [Parameter(Mandatory = $true)]
        [object] $IncludePolicy,

        [Parameter(Mandatory = $false)]
        [string] $NewLine = [Environment]::NewLine
    )

    $styleBlock = ""
    $styleBlock += "classDef default fill:$($Style.Default),stroke:$($Style.Stroke)$NewLine"
    if ($IncludePolicy.IncludeEnvironmentVariables) { $styleBlock += "classDef EnvVar fill:$($Style.EnvVar),stroke:$($Style.Stroke)$NewLine" }
    if ($IncludePolicy.IncludeConnections) { $styleBlock += "classDef Connection fill:$($Style.Connection),stroke:$($Style.Stroke)$NewLine" }
    if ($IncludePolicy.IncludeEntities) { $styleBlock += "classDef Entity fill:$($Style.Entity),stroke:$($Style.Stroke)$NewLine" }
    if ($IncludePolicy.IncludeDefaultEntities) { $styleBlock += "classDef DefaultEntity fill:$($Style.DefaultEntity),stroke:$($Style.Stroke)$NewLine" }
    if ($IncludePolicy.IncludeFlows) { $styleBlock += "classDef Flow fill:$($Style.Flow),stroke:$($Style.Stroke)$NewLine" }
    if ($IncludePolicy.IncludeCanvasApps) { $styleBlock += "classDef CanvasApp fill:$($Style.CanvasApp),stroke:$($Style.Stroke)$NewLine" }
    if ($IncludePolicy.IncludeModelDrivenApps) { $styleBlock += "classDef ModelDrivenApp fill:$($Style.ModelDrivenApp),stroke:$($Style.Stroke)$NewLine" }
    if ($IncludePolicy.IncludeWebResources) { $styleBlock += "classDef WebResource fill:$($Style.WebResource),stroke:$($Style.Stroke)$NewLine" }

    return $styleBlock
}
