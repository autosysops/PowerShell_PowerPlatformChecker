function Get-PowerPlatformCheckerExternalInteractionSourceLabel {
    <#
    .SYNOPSIS
        Builds a condensed source label for aggregated external interaction edges.

    .DESCRIPTION
        Produces a colon-safe, readable label that captures the source node type,
        source display name, and normalized interaction label.

    .PARAMETER Node
        Source graph node.

    .PARAMETER InteractionLabel
        Condensed interaction label such as GET or SET.

    .EXAMPLE
        Build a source label for a canvas app read interaction.

        PS> Get-PowerPlatformCheckerExternalInteractionSourceLabel -Node $node -InteractionLabel GET
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Node,

        [Parameter(Mandatory = $true)]
        [string] $InteractionLabel,

        [Parameter(Mandatory = $false)]
        [string] $SourceAlias,

        [Parameter(Mandatory = $false)]
        [string] $ConnectorCode,

        [Parameter(Mandatory = $false)]
        [switch] $DomainUnresolved
    )

    $labelParts = [System.Collections.Generic.List[string]]::new()

    if (-not [string]::IsNullOrWhiteSpace([string]$SourceAlias)) {
        [void]$labelParts.Add(([string]$SourceAlias).Replace(':', ' '))
    }
    else {
        $sourceType = [string]$Node.Type
        $sourceName = [string]$Node.DisplayName
        if ([string]::IsNullOrWhiteSpace($sourceName)) {
            $sourceName = [string]$Node.Id
        }

        $safeSourceType = $sourceType.Replace(':', ' ')
        $safeSourceName = $sourceName.Replace(':', ' ')
        [void]$labelParts.Add(('{0} {1}' -f $safeSourceType, $safeSourceName).Trim())
    }

    $detailParts = [System.Collections.Generic.List[string]]::new()
    if ([string]$Node.Type -eq 'CanvasApp' -and $Node.Properties -and $Node.Properties.ContainsKey('SourceSignals')) {
        $firstSignal = @($Node.Properties.SourceSignals | Select-Object -First 1)
        if (@($firstSignal).Count -gt 0 -and $null -ne $firstSignal[0]) {
            $screen = [string]$firstSignal[0].Screen
            $element = [string]$firstSignal[0].Element
            if (-not [string]::IsNullOrWhiteSpace($screen)) {
                [void]$detailParts.Add($screen.Replace(':', ' '))
            }
            if (-not [string]::IsNullOrWhiteSpace($element)) {
                [void]$detailParts.Add($element.Replace(':', ' '))
            }
        }
    }
    elseif ([string]$Node.Type -eq 'ModelDrivenApp' -and @($Node.Members).Count -gt 0) {
        $memberText = [string](@($Node.Members | Select-Object -First 1)[0])
        if (-not [string]::IsNullOrWhiteSpace($memberText)) {
            [void]$detailParts.Add($memberText.Replace(':', ' '))
        }
    }

    if ($detailParts.Count -gt 0) {
        [void]$labelParts.Add(($detailParts -join ' / '))
    }

    [void]$labelParts.Add(([string]$InteractionLabel).Replace(':', ' '))

    if (-not [string]::IsNullOrWhiteSpace([string]$ConnectorCode)) {
        [void]$labelParts.Add(([string]$ConnectorCode).Replace(':', ' '))
    }

    if ($DomainUnresolved.IsPresent) {
        [void]$labelParts.Add('DomainUnresolved')
    }

    return (($labelParts -join ' ') -replace '\s{2,}', ' ').Trim()
}
