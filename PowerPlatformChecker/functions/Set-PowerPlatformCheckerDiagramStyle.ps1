function Set-PowerPlatformCheckerDiagramStyle {
    <#
    .SYNOPSIS
        Updates default architecture diagram colors for the current module session.

    .DESCRIPTION
        Merges a key/value color map into the module-scoped default style palette used by
        Get-PowerPlatformCheckerArchitectureDiagram. Only known keys are accepted.

    .PARAMETER ColorMap
        Hashtable with keys from: Default, EnvVar, Connection, Entity, DefaultEntity,
        Flow, CanvasApp, ModelDrivenApp, WebResource, Stroke.

    .PARAMETER WhatIf
        Shows what would happen if the command runs. No color changes are applied.

    .PARAMETER Confirm
        Prompts for confirmation before applying color changes.

    .EXAMPLE
        Update flow and connector colors for the current session.

        PS> Set-PowerPlatformCheckerDiagramStyle -ColorMap @{ Flow = '#00AEEF'; Connection = '#FFD166' }

    .EXAMPLE
        Update only the common stroke color.

        PS> Set-PowerPlatformCheckerDiagramStyle -ColorMap @{ Stroke = '#222222' }
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $ColorMap
    )

    $telemetryProperties = @{
        ColorKeyCount = @($ColorMap.Keys).Count
        ColorKeys = (@($ColorMap.Keys | ForEach-Object { [string]$_ } | Sort-Object -Unique) -join ",")
    }
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Set-PowerPlatformCheckerDiagramStyle" -PropertiesHash $telemetryProperties

    $validKeys = @(
        'Default',
        'EnvVar',
        'Connection',
        'Entity',
        'DefaultEntity',
        'Flow',
        'CanvasApp',
        'ModelDrivenApp',
        'WebResource',
        'Stroke'
    )

    foreach ($key in $ColorMap.Keys) {
        if ($key -notin $validKeys) {
            throw "Unsupported color key '$key'. Supported keys: $($validKeys -join ', ')"
        }

        $value = [string] $ColorMap[$key]
        if ([string]::IsNullOrWhiteSpace($value)) {
            throw "Color value for key '$key' cannot be empty."
        }

        if ($PSCmdlet.ShouldProcess("PowerPlatformChecker diagram style", "Set '$key' color to '$value'")) {
            $script:PowerPlatformCheckerDiagramColors[$key] = $value
        }
    }

    return $script:PowerPlatformCheckerDiagramColors.Clone()
}


