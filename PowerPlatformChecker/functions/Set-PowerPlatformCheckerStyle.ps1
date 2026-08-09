function Set-PowerPlatformCheckerStyle {
    <#
    .SYNOPSIS
        Updates style values for a PowerPlatformChecker style target.

    .DESCRIPTION
        Updates the module-scoped style map for the selected target. Style key
        parameters are exposed dynamically based on the selected target so future
        style targets can provide their own key sets without changing this command.

    .PARAMETER StyleTarget
        Style target to update. Currently only ArchitectureDiagram is supported.

    .PARAMETER Default
        Style value for unresolved or missing components.

    .PARAMETER EnvVar
        Style value for environment variable nodes.

    .PARAMETER Connection
        Style value for connection reference nodes.

    .PARAMETER Entity
        Style value for entity nodes.

    .PARAMETER DefaultEntity
        Style value for default-entity nodes.

    .PARAMETER Flow
        Style value for flow nodes.

    .PARAMETER CanvasApp
        Style value for canvas app nodes.

    .PARAMETER ModelDrivenApp
        Style value for model-driven app nodes.

    .PARAMETER WebResource
        Style value for web resource nodes.

    .PARAMETER Stroke
        Shared style value for class border color.

    .PARAMETER WhatIf
        Shows what would happen if the command runs. No style changes are applied.

    .PARAMETER Confirm
        Prompts for confirmation before applying style changes.

    .OUTPUTS
        System.Collections.Hashtable. Returns the updated style map for the selected target.

    .EXAMPLE
        Update flow and connector colors for architecture diagrams.

        PS> Set-PowerPlatformCheckerStyle -StyleTarget ArchitectureDiagram -Flow '#00AEEF' -Connection '#FFD166'

    .EXAMPLE
        Update multiple architecture style keys in a single call.

        PS> Set-PowerPlatformCheckerStyle -StyleTarget ArchitectureDiagram -Flow '#00AEEF' -Stroke '#222222'
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('ArchitectureDiagram')]
        [string] $StyleTarget
    )

    DynamicParam {
        $validKeysByTarget = @{
            ArchitectureDiagram = @(
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
        }

        $selectedTarget = $null
        if ($PSBoundParameters.ContainsKey('StyleTarget') -and -not [string]::IsNullOrWhiteSpace([string]$PSBoundParameters['StyleTarget'])) {
            $selectedTarget = [string]$PSBoundParameters['StyleTarget']
        }

        $dynamicParameters = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
        if ([string]::IsNullOrWhiteSpace($selectedTarget) -or -not $validKeysByTarget.ContainsKey($selectedTarget)) {
            return $dynamicParameters
        }

        foreach ($key in @($validKeysByTarget[$selectedTarget])) {
            $attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
            $parameterAttribute = [System.Management.Automation.ParameterAttribute]::new()
            $parameterAttribute.Mandatory = $false
            [void]$attributeCollection.Add($parameterAttribute)

            $dynamicParameter = [System.Management.Automation.RuntimeDefinedParameter]::new([string]$key, [string], $attributeCollection)
            $dynamicParameters.Add([string]$key, $dynamicParameter)
        }

        return $dynamicParameters
    }

    begin {
        if (-not $script:PowerPlatformCheckerStyles.ContainsKey($StyleTarget)) {
            throw "Unsupported style target '$StyleTarget'."
        }

        $validKeysByTarget = @{
            ArchitectureDiagram = @(
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
        }

        $updates = @{}
        foreach ($key in @($validKeysByTarget[$StyleTarget])) {
            if ($PSBoundParameters.ContainsKey($key)) {
                $updates[$key] = [string]$PSBoundParameters[$key]
            }
        }

        if (@($updates.Keys).Count -eq 0) {
            throw "No style values were provided. Use one or more style key parameters for target '$StyleTarget'."
        }

        $validKeys = @($validKeysByTarget[$StyleTarget])
        foreach ($key in @($updates.Keys)) {
            if ($key -notin $validKeys) {
                throw "Unsupported style key '$key' for target '$StyleTarget'. Supported keys: $($validKeys -join ', ')"
            }

            if ([string]::IsNullOrWhiteSpace([string]$updates[$key])) {
                throw "Style value for key '$key' cannot be empty."
            }
        }

        $telemetryProperties = @{
            StyleTarget = $StyleTarget
            UpdateCount = @($updates.Keys).Count
            UpdateKeys = (@($updates.Keys | Sort-Object -Unique) -join ',')
            UpdateSource = 'DynamicParameters'
        }
        Send-THEvent -ModuleName 'PowerPlatformChecker' -EventName 'Set-PowerPlatformCheckerStyle' -PropertiesHash $telemetryProperties

        foreach ($key in @($updates.Keys)) {
            $value = [string]$updates[$key]
            if ($PSCmdlet.ShouldProcess("$StyleTarget style", "Set '$key' style value to '$value'")) {
                $script:PowerPlatformCheckerStyles[$StyleTarget][$key] = $value
            }
        }

        return $script:PowerPlatformCheckerStyles[$StyleTarget].Clone()
    }
}