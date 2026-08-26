function Get-PowerPlatformCheckerDesktopFlowClassMemberList {
    <#
    .SYNOPSIS
        Gets [INPUT]/[OUTPUT] member lines for a desktop flow architecture node.

    .DESCRIPTION
        Desktop flows can declare inputs and outputs in multiple places. The
        workflow metadata contains structured Inputs/Outputs payloads, while the
        Definition text can also include @INPUT/@OUTPUT directives. This helper
        merges both sources without duplicating member names.

    .PARAMETER Path
        Path or wildcard path that resolves to the desktop flow JSON file.

    .EXAMPLE
        Get-PowerPlatformCheckerDesktopFlowClassMemberList -Path 'C:\Solutions\MySolution\Managed\Workflows\*1111*.json'

        Returns the ordered class member lines used in the architecture diagram.
    #>

    [CmdletBinding()]
    [OutputType([Object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $inputNames = [System.Collections.Generic.List[string]]::new()
    $outputNames = [System.Collections.Generic.List[string]]::new()
    $seenInputs = [System.Collections.Generic.HashSet[string]]::new()
    $seenOutputs = [System.Collections.Generic.HashSet[string]]::new()

    try {
        $desktopFlowPath = $Path
        if (-not (Test-Path -LiteralPath $desktopFlowPath -PathType Leaf)) {
            $resolvedDesktopFlow = @(Get-ChildItem -Path $desktopFlowPath -File -ErrorAction SilentlyContinue | Select-Object -First 1)
            if ($resolvedDesktopFlow.Count -gt 0 -and $null -ne $resolvedDesktopFlow[0]) {
                $desktopFlowPath = [string]$resolvedDesktopFlow[0].FullName
            }
        }

        if (-not (Test-Path -LiteralPath $desktopFlowPath -PathType Leaf)) {
            return @()
        }

        $desktopMetadata = Get-PowerPlatformCheckerDesktopFlowMeta -Path $desktopFlowPath
        if ($null -eq $desktopMetadata) {
            return @()
        }

        if ($null -ne $desktopMetadata.Inputs -and
            $desktopMetadata.Inputs.PSObject.Properties.Name -contains 'schema' -and
            $null -ne $desktopMetadata.Inputs.schema -and
            $desktopMetadata.Inputs.schema.PSObject.Properties.Name -contains 'properties' -and
            $null -ne $desktopMetadata.Inputs.schema.properties) {
            foreach ($propertyName in @($desktopMetadata.Inputs.schema.properties.PSObject.Properties.Name)) {
                Add-PowerPlatformCheckerDesktopMemberName -MemberNames $inputNames -SeenMemberNames $seenInputs -Name ([string]$propertyName)
            }
        }

        if ($null -ne $desktopMetadata.Outputs) {
            foreach ($propertyName in @($desktopMetadata.Outputs.PSObject.Properties.Name)) {
                Add-PowerPlatformCheckerDesktopMemberName -MemberNames $outputNames -SeenMemberNames $seenOutputs -Name ([string]$propertyName)
            }
        }

        $normalizedDefinition = ConvertTo-PowerPlatformCheckerDesktopNormalizedDefinition -Definition ([string]$desktopMetadata.Definition)
        foreach ($definitionLine in @($normalizedDefinition -split "`n")) {
            if ($definitionLine -match '^\s*"?@INPUT\s+(?<name>[A-Za-z0-9_]+)\s*:') {
                Add-PowerPlatformCheckerDesktopMemberName -MemberNames $inputNames -SeenMemberNames $seenInputs -Name ([string]$matches['name'])
                continue
            }

            if ($definitionLine -match '^\s*"?@OUTPUT\s+(?<name>[A-Za-z0-9_]+)\s*:') {
                Add-PowerPlatformCheckerDesktopMemberName -MemberNames $outputNames -SeenMemberNames $seenOutputs -Name ([string]$matches['name'])
            }
        }
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Warning "Error in resolving desktop parameter members for flow path $Path. $errorMessage"
    }

    $members = [System.Collections.Generic.List[string]]::new()
    foreach ($inputName in @($inputNames)) {
        [void]$members.Add("    [INPUT]$inputName")
    }
    foreach ($outputName in @($outputNames)) {
        [void]$members.Add("    [OUTPUT]$outputName")
    }

    return @($members)
}
