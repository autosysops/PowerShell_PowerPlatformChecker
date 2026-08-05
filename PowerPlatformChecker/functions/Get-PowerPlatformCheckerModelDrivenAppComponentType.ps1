function Get-PowerPlatformCheckerModelDrivenAppComponentType {
    <#
    .SYNOPSIS
        Resolves AppModule component type numbers to friendly labels.

    .DESCRIPTION
        Maps Dataverse AppModuleComponent component type codes to readable names so
        model-driven app parsing can classify component links consistently.

    .PARAMETER Type
        Numeric AppModule component type code.

    .EXAMPLE
        Resolve a component type number.

        PS> Get-PowerPlatformCheckerModelDrivenAppComponentType -Type 29
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, Position = 1)]
        [int] $Type
    )

    switch ($Type) {
        1 { return "Entities" }
        26 { return "Views" }
        29 { return "Business Process Flows" }
        48 { return "Command (Ribbon)" }
        59 { return "Charts" }
        60 { return "Forms" }
        # Web resources appear in exported solution metadata even though the current Learn page
        # does not list 61 in the documented ComponentType option set.
        61 { return "Web Resources" }
        62 { return "Sitemap" }
        default { return "Unknown ($Type)" }
    }
}
