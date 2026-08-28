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

    .PARAMETER IsInbound
        Format the label as an inbound trigger edge.

    .PARAMETER IsResponse
        Format the label as an outbound HTTP response edge.

    .EXAMPLE
        Build a label for a flow HTTP action.

        PS> Get-PowerPlatformCheckerExternalInteractionFlowActionLabel -FlowNode $flowNode -FlowAction $action -InteractionLabel GET
    #>

    [CmdletBinding()]
    [OutputType([string])]
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
        [switch] $DomainUnresolved,

        [Parameter(Mandatory = $false)]
        [switch] $IsInbound,

        [Parameter(Mandatory = $false)]
        [switch] $IsResponse
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

    $labelParts = [System.Collections.Generic.List[string]]::new()
    [void]$labelParts.Add($safeFlowName)
    [void]$labelParts.Add(([string]$InteractionLabel).Replace(':', ' '))

    if (-not [string]::IsNullOrWhiteSpace([string]$ConnectorCode)) {
        [void]$labelParts.Add(([string]$ConnectorCode).Replace(':', ' '))
    }

    if ($DomainUnresolved.IsPresent) {
        [void]$labelParts.Add('DomainUnresolved')
    }

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
    if ($descriptorParts.Count -gt 0) {
        [void]$labelParts.Add(($descriptorParts -join '_'))
    }

    return (($labelParts -join ' ') -replace '\s{2,}', ' ').Trim()
}
