function Get-PowerPlatformCheckerWebResourceType {
    <#
    .SYNOPSIS
        Resolves Dataverse web resource type codes to friendly labels and diagram kinds.

    .DESCRIPTION
        Maps the documented WebResourceType choice values to a normalized label and
        a broader kind used by the architecture diagram.

    .PARAMETER Type
        Numeric WebResourceType code from web resource metadata.

    .EXAMPLE
        Resolve a Dataverse web resource type code.

        PS> Get-PowerPlatformCheckerWebResourceType -Type 3

        Returns a normalized object for JavaScript resources used by diagram rendering.
    #>

    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory = $true, Position = 1)]
        [int] $Type
    )

    switch ($Type) {
        1 { return [PSCustomObject]@{ Name = 'HTML'; Kind = 'Document' } }
        2 { return [PSCustomObject]@{ Name = 'CSS'; Kind = 'Style' } }
        3 { return [PSCustomObject]@{ Name = 'JavaScript'; Kind = 'Script' } }
        4 { return [PSCustomObject]@{ Name = 'XML'; Kind = 'Data' } }
        5 { return [PSCustomObject]@{ Name = 'PNG'; Kind = 'Image' } }
        6 { return [PSCustomObject]@{ Name = 'JPG'; Kind = 'Image' } }
        7 { return [PSCustomObject]@{ Name = 'GIF'; Kind = 'Image' } }
        8 { return [PSCustomObject]@{ Name = 'XAP'; Kind = 'Binary' } }
        9 { return [PSCustomObject]@{ Name = 'XSL'; Kind = 'Style' } }
        10 { return [PSCustomObject]@{ Name = 'ICO'; Kind = 'Image' } }
        11 { return [PSCustomObject]@{ Name = 'SVG'; Kind = 'Icon' } }
        12 { return [PSCustomObject]@{ Name = 'RESX'; Kind = 'Resource' } }
        default { return [PSCustomObject]@{ Name = 'Other'; Kind = 'Other' } }
    }
}