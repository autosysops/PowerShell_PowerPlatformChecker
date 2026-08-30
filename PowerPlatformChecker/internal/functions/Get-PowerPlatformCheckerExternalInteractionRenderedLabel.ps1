function Get-PowerPlatformCheckerExternalInteractionRenderedLabel {
    <#
    .SYNOPSIS
        Renders external interaction edge labels from structured label parts.

    .DESCRIPTION
        Builds either a full graph-facing label or a compact Mermaid-facing label
        from structured external interaction edge metadata.

    .PARAMETER LabelParts
        Structured label metadata for an external interaction edge.

    .PARAMETER Compact
        Renders the compact alias-based Mermaid label instead of the full graph label.

    .EXAMPLE
        Render the compact Mermaid label from structured external interaction label parts.

        Get-PowerPlatformCheckerExternalInteractionRenderedLabel -LabelParts $parts -Compact
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $LabelParts,

        [Parameter(Mandatory = $false)]
        [switch] $Compact
    )

    if ($null -eq $LabelParts) {
        return ''
    }

    $interaction = [string]$LabelParts.Interaction
    $sourceAlias = ''
    if ($LabelParts.PSObject.Properties.Name -contains 'CompactSourceAlias') {
        $sourceAlias = [string]$LabelParts.CompactSourceAlias
    }
    if ([string]::IsNullOrWhiteSpace($sourceAlias) -and $LabelParts.PSObject.Properties.Name -contains 'SourceAlias') {
        $sourceAlias = [string]$LabelParts.SourceAlias
    }
    $sourceType = [string]$LabelParts.SourceType
    $sourceDisplayName = [string]$LabelParts.SourceDisplayName
    $connectorName = [string]$LabelParts.ConnectorName
    $connectorCode = [string]$LabelParts.ConnectorCode
    $detailParts = @($LabelParts.DetailParts | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
    $domainUnresolved = $false
    if ($LabelParts.PSObject.Properties.Name -contains 'DomainUnresolved') {
        $domainUnresolved = [bool]$LabelParts.DomainUnresolved
    }

    $parts = [System.Collections.Generic.List[string]]::new()

    if ($Compact.IsPresent -and -not [string]::IsNullOrWhiteSpace($sourceAlias)) {
        [void]$parts.Add($sourceAlias)
    }
    else {
        $fullSource = ('{0} / {1}' -f $sourceType, $sourceDisplayName).Trim(' ', '/')
        if (-not [string]::IsNullOrWhiteSpace($fullSource)) {
            [void]$parts.Add($fullSource)
        }
    }

    if ($detailParts.Count -gt 0) {
        [void]$parts.Add(($detailParts -join ' / '))
    }

    if (-not [string]::IsNullOrWhiteSpace($interaction)) {
        [void]$parts.Add($interaction)
    }

    if ($Compact.IsPresent) {
        if (-not [string]::IsNullOrWhiteSpace($connectorCode)) {
            [void]$parts.Add($connectorCode)
        }
    }
    elseif ([string]$LabelParts.Kind -eq 'Source') {
        if (-not [string]::IsNullOrWhiteSpace($connectorName)) {
            [void]$parts.Add($connectorName)
        }
    }

    if ($domainUnresolved) {
        [void]$parts.Add('DomainUnresolved')
    }

    if ([string]$LabelParts.Kind -eq 'FlowAction') {
        $descriptorParts = [System.Collections.Generic.List[string]]::new()
        $actionName = [string]$LabelParts.ActionName
        $operationName = [string]$LabelParts.OperationName
        $connectorName = [string]$LabelParts.ConnectorName
        $protocol = [string]$LabelParts.Protocol
        $triggerAuthText = [string]$LabelParts.TriggerAuthenticationDescription

        if ($Compact.IsPresent) {
            if (-not [string]::IsNullOrWhiteSpace($actionName)) {
                [void]$descriptorParts.Add($actionName)
            }
            elseif (-not [string]::IsNullOrWhiteSpace($operationName)) {
                [void]$descriptorParts.Add($operationName)
            }

            if (-not [string]::IsNullOrWhiteSpace($protocol) -and $protocol -ne 'Unknown') {
                [void]$descriptorParts.Add($protocol)
            }
        }
        else {
            if (-not [string]::IsNullOrWhiteSpace($actionName)) {
                [void]$descriptorParts.Add($actionName)
            }
            if (-not [string]::IsNullOrWhiteSpace($operationName) -and $operationName -ne $actionName) {
                [void]$descriptorParts.Add($operationName)
            }
            if (-not [string]::IsNullOrWhiteSpace($connectorName)) {
                [void]$descriptorParts.Add($connectorName)
            }
            if (-not [string]::IsNullOrWhiteSpace($protocol) -and $protocol -ne 'Unknown') {
                [void]$descriptorParts.Add($protocol)
            }
            if (-not [string]::IsNullOrWhiteSpace($triggerAuthText)) {
                [void]$descriptorParts.Add($triggerAuthText)
            }
        }

        if ($descriptorParts.Count -gt 0) {
            [void]$parts.Add(($descriptorParts -join '_'))
        }
    }

    return ((@($parts) -join ' ') -replace '\s{2,}', ' ').Trim()
}
