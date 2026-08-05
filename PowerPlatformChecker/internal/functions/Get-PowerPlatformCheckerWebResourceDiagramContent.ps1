function Get-PowerPlatformCheckerWebResourceDiagramContent {
    <#
    .SYNOPSIS
        Builds Mermaid class blocks and dependency links for script web resources.

    .DESCRIPTION
        Renders script web resource class blocks with method rows and dependency
        links for architecture diagrams. Missing dependency resources are declared
        as placeholder web resource classes so links stay visible.

    .PARAMETER WebResources
        Web resource metadata records to render.

    .PARAMETER IncludeWebResources
        Indicates whether web resource rendering is enabled.

    .PARAMETER NewLine
        Line separator used when composing Mermaid output.

    .EXAMPLE
        Build web resource class and dependency content.

        PS> Get-PowerPlatformCheckerWebResourceDiagramContent -WebResources $scripts -IncludeWebResources

        Returns Mermaid class text and dependency links for the supplied script resources.
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)]
        [object[]] $WebResources = @(),

        [Parameter(Mandatory = $false)]
        [switch] $IncludeWebResources,

        [Parameter(Mandatory = $false)]
        [string] $NewLine = [Environment]::NewLine
    )

    if (-not $IncludeWebResources.IsPresent) {
        return [pscustomobject]@{
            DiagramText = ""
            Links = @()
        }
    }

    $diagram = ""
    $links = @()

    foreach ($webResource in @($WebResources)) {
        $diagram += "class $($webResource.MermaidId)[`"$($webResource.DisplayName)`"]:::WebResource {$NewLine"
        $diagram += "  [$($webResource.Kind)]$($webResource.Type)$NewLine"
        foreach ($methodName in @($webResource.Methods)) {
            $diagram += "  [$($webResource.Kind)]$methodName$NewLine"
        }
        $diagram += "}$NewLine"

        foreach ($dependency in @($webResource.Dependencies)) {
            if (-not $dependency) {
                continue
            }

            $dependencyResource = $WebResources | Where-Object { $_.Name -eq $dependency } | Select-Object -First 1
            if ($dependencyResource) {
                $links += "$($webResource.MermaidId) --> $($dependencyResource.MermaidId):Dependency$NewLine"
                continue
            }

            $dependencyId = Convert-PowerPlatformCheckerMermaidId -InputString $dependency
            $diagram += "class $dependencyId[`"$dependency`"]:::WebResource$NewLine"
        }
    }

    return [pscustomobject]@{
        DiagramText = $diagram
        Links = @($links)
    }
}
