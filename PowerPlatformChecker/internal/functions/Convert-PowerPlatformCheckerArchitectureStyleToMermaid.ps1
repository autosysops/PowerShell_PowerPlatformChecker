function Convert-PowerPlatformCheckerArchitectureStyleToMermaid {
    <#
    .SYNOPSIS
        Renders one style entry as Mermaid text.

    .DESCRIPTION
        Converts a style name and Mermaid style payload into a classDef line.

    .PARAMETER StyleName
        Mermaid style/class name.

    .PARAMETER StyleValue
        Mermaid style payload.

    .EXAMPLE
        Render a Mermaid classDef line from one style entry.

        Convert-PowerPlatformCheckerArchitectureStyleToMermaid -StyleName Flow -StyleValue 'fill:#fff,stroke:#000'
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $StyleName,

        [Parameter(Mandatory = $true)]
        [string] $StyleValue
    )

    return "classDef $StyleName $StyleValue"
}
