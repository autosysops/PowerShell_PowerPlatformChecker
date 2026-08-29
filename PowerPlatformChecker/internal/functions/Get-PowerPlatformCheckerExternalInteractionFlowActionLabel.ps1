function Get-PowerPlatformCheckerExternalInteractionFlowActionLabel {
    <#
    .SYNOPSIS
        Builds a condensed flow-action label for external interaction diagrams.

    .DESCRIPTION
        Keeps flow action labels readable and Mermaid-safe while preserving the
        action name, connector context, protocol hints, and inbound/response role.

    .PARAMETER FlowNode
        Source flow graph node.

    .PARAMETER FlowAction
        Action or trigger metadata record.

    .PARAMETER InteractionLabel
        Condensed interaction label such as GET, SET, INBOUND, or OUTBOUND.

    .PARAMETER FlowAlias
        Optional short source alias (for example Flow-01) used in edge labels.

    .PARAMETER ConnectorCode
        Optional connector lookup code used in compact Mermaid labels.

    .PARAMETER DomainUnresolved
        Marks labels that still point to connection references instead of resolved domains.

    .EXAMPLE
        Build a label for a flow HTTP action.

        PS> Get-PowerPlatformCheckerExternalInteractionFlowActionLabel -FlowNode $flowNode -FlowAction $action -InteractionLabel GET
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [object] $FlowNode,

        [Parameter(Mandatory = $true)]
        [object] $FlowAction,

        [Parameter(Mandatory = $true)]
        [string] $InteractionLabel,

        [Parameter(Mandatory = $false)]
        [string] $FlowAlias,

        [Parameter(Mandatory = $false)]
        [string] $ConnectorCode,

        [Parameter(Mandatory = $false)]
        [switch] $DomainUnresolved
    )

    $safeFlowName = [string]$FlowAlias
    if ([string]::IsNullOrWhiteSpace($safeFlowName)) {
        $safeFlowName = ([string]$FlowNode.DisplayName).Replace(':', ' ')
        if ([string]::IsNullOrWhiteSpace($safeFlowName)) {
            $safeFlowName = ([string]$FlowNode.Id).Replace(':', ' ')
        }
    }

    $actionName = ([string]$FlowAction.Name).Replace(':', ' ')
    if ([string]::IsNullOrWhiteSpace($actionName)) {
        $actionName = 'action'
    }

    $operationName = ([string]$FlowAction.OperationDisplayName).Replace(':', ' ')
    $connectorName = ([string]$FlowAction.ConnectorDisplayName).Replace(':', ' ')
    $protocol = ([string]$FlowAction.ExternalProtocol).Replace(':', ' ')
    $triggerAuthText = ([string]$FlowAction.TriggerAuthenticationDescription).Replace(':', ' ')

    $descriptorParts = [System.Collections.Generic.List[string]]::new()
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
    $labelPartMap = [ordered]@{
        Kind = 'FlowAction'
        SourceAlias = [string]$FlowAlias
        SourceType = 'Flow'
        SourceDisplayName = ([string]$FlowNode.DisplayName).Replace(':', ' ')
        DetailParts = @()
        Interaction = ([string]$InteractionLabel).Replace(':', ' ')
        DomainUnresolved = [bool]$DomainUnresolved.IsPresent
        ActionName = $actionName
        OperationName = $operationName
        Protocol = $protocol
        TriggerAuthenticationDescription = $triggerAuthText
    }
    if (-not [string]::IsNullOrWhiteSpace($connectorName)) {
        $labelPartMap['ConnectorName'] = $connectorName
    }
    if (-not [string]::IsNullOrWhiteSpace([string]$ConnectorCode)) {
        $labelPartMap['ConnectorCode'] = ([string]$ConnectorCode).Replace(':', ' ')
    }
    $labelPartObject = [pscustomobject]$labelPartMap

    return [pscustomobject]@{
        Label = Get-PowerPlatformCheckerExternalInteractionRenderedLabel -LabelParts $labelPartObject
        MermaidLabel = Get-PowerPlatformCheckerExternalInteractionRenderedLabel -LabelParts $labelPartObject -Compact
        LabelParts = $labelPartObject
    }
}
