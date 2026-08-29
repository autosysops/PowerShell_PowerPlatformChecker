function Get-PowerPlatformCheckerStyle {
    <#
    .SYNOPSIS
        Gets style information for a PowerPlatformChecker style target.

    .DESCRIPTION
        Returns the current style key/value map for the selected target.

    .PARAMETER StyleTarget
        Style target to read. Currently only ArchitectureDiagram is supported.

    .OUTPUTS
        System.Collections.Hashtable. Returns the current style map for the selected target.

    .EXAMPLE
        Get the current architecture diagram style map.

        PS> Get-PowerPlatformCheckerStyle -StyleTarget ArchitectureDiagram

    #>

    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('ArchitectureDiagram')]
        [string] $StyleTarget = 'ArchitectureDiagram'
    )

    $styleStore = $script:PowerPlatformCheckerDiagramStyles

    if (-not $styleStore.ContainsKey($StyleTarget)) {
        throw "Unsupported style target '$StyleTarget'."
    }

    $telemetryProperties = @{
        StyleTargetExplicit = $PSBoundParameters.ContainsKey('StyleTarget')
    }
    Send-THEvent -ModuleName 'PowerPlatformChecker' -EventName 'Get-PowerPlatformCheckerStyle' -PropertiesHash $telemetryProperties

    return $styleStore[$StyleTarget].Clone()
}