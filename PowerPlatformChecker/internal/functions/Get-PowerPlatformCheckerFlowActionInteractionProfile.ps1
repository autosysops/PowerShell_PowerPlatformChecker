function Get-PowerPlatformCheckerFlowActionInteractionProfile {
    <#
    .SYNOPSIS
        Builds interaction and external profile metadata for one cloud flow action.

    .DESCRIPTION
        Derives method/get-set interaction and URL/domain profile from cloud
        action payload fields. Supports simple parameter default resolution.

    .PARAMETER Action
        Raw action object from flow definition actions.

    .PARAMETER ActionType
        Normalized action type value from action processing.

    .PARAMETER DefinitionParameters
        Flow definition parameters object used to resolve parameter expressions.

    .EXAMPLE
        Derive request method, read/write direction, and external URL profile for an action.

        PS> Get-PowerPlatformCheckerFlowActionInteractionProfile -Action $action -ActionType $type -DefinitionParameters $params
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Action,

        [Parameter(Mandatory = $false)]
        [string] $ActionType,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $DefinitionParameters
    )

    $rawMethod = ""
    if ($Action.PSObject.Properties.Name -contains 'inputs' -and $null -ne $Action.inputs) {
        if ($Action.inputs.PSObject.Properties.Name -contains 'method') {
            $rawMethod = [string]$Action.inputs.method
        }
        elseif ($Action.inputs.PSObject.Properties.Name -contains 'parameters' -and $null -ne $Action.inputs.parameters) {
            if ($Action.inputs.parameters.PSObject.Properties.Name -contains 'request/method') {
                $rawMethod = [string]$Action.inputs.parameters.'request/method'
            }
        }
    }

    $method = if ([string]::IsNullOrWhiteSpace($rawMethod)) { "Unknown" } else { ([string]$rawMethod).ToUpperInvariant() }

    $getSetAction = 'Unknown'
    $interactionDirection = 'Unknown'
    if ($method -in @('GET', 'HEAD', 'OPTIONS')) {
        $getSetAction = 'Get'
        $interactionDirection = 'Read'
    }
    elseif ($method -in @('POST', 'PUT', 'PATCH', 'DELETE')) {
        $getSetAction = 'Set'
        $interactionDirection = 'Write'
    }
    elseif (-not [string]::IsNullOrWhiteSpace($ActionType)) {
        if ($ActionType -match '(?i)(get|list|read|retrieve|fetch|query|search)') {
            $getSetAction = 'Get'
            $interactionDirection = 'Read'
        }
        elseif ($ActionType -match '(?i)(create|update|delete|insert|set|add|post|send|upsert|patch|write)') {
            $getSetAction = 'Set'
            $interactionDirection = 'Write'
        }
    }

    $rawUrl = ''
    if ($Action.PSObject.Properties.Name -contains 'inputs' -and $null -ne $Action.inputs) {
        if ($Action.inputs.PSObject.Properties.Name -contains 'uri') {
            $rawUrl = [string]$Action.inputs.uri
        }
        elseif ($Action.inputs.PSObject.Properties.Name -contains 'parameters' -and $null -ne $Action.inputs.parameters) {
            if ($Action.inputs.parameters.PSObject.Properties.Name -contains 'request/url') {
                $rawUrl = [string]$Action.inputs.parameters.'request/url'
            }
            elseif ($Action.inputs.parameters.PSObject.Properties.Name -contains 'uri') {
                $rawUrl = [string]$Action.inputs.parameters.uri
            }
        }
    }

    $resolvedUrl = Resolve-PowerPlatformCheckerFlowExpressionValue -Value $rawUrl -DefinitionParameters $DefinitionParameters
    $urlProfile = ConvertTo-PowerPlatformCheckerUrlProfile -Value $resolvedUrl

    return [pscustomobject]@{
        Method = $method
        GetSetAction = $getSetAction
        InteractionDirection = $interactionDirection
        ExternalUrl = [string]$urlProfile.FullUrl
        ExternalProtocol = [string]$urlProfile.Protocol
        ExternalDomain = [string]$urlProfile.Domain
        ExternalMainDomain = [string]$urlProfile.MainDomain
        ExternalResolutionState = [string]$urlProfile.ResolutionState
    }
}
