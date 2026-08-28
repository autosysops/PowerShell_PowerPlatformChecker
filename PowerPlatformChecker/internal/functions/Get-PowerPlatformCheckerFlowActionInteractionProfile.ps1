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

    $candidateUrlValues = [System.Collections.Generic.List[string]]::new()

    if ($Action.PSObject.Properties.Name -contains 'inputs' -and $null -ne $Action.inputs) {
        if ($Action.inputs.PSObject.Properties.Name -contains 'uri') {
            Add-PowerPlatformCheckerStringCandidate -Values $candidateUrlValues -Candidate $Action.inputs.uri
        }

        if ($Action.inputs.PSObject.Properties.Name -contains 'url') {
            Add-PowerPlatformCheckerStringCandidate -Values $candidateUrlValues -Candidate $Action.inputs.url
        }

        if ($Action.inputs.PSObject.Properties.Name -contains 'parameters' -and $null -ne $Action.inputs.parameters) {
            $parameters = $Action.inputs.parameters

            $preferredKeys = @(
                'request/url',
                'uri',
                'url',
                'dataset',
                'source',
                'siteAddress',
                'baseUrl',
                'host',
                'authority',
                'resourceUrl',
                'parameters/source',
                'parameters/dataset',
                'parameters/siteAddress',
                'parameters/baseUrl',
                'destinationDataset'
            )

            foreach ($preferredKey in $preferredKeys) {
                if ($parameters.PSObject.Properties.Name -contains $preferredKey) {
                    Add-PowerPlatformCheckerStringCandidate -Values $candidateUrlValues -Candidate $parameters.$preferredKey
                }
            }

            foreach ($parameterProperty in @($parameters.PSObject.Properties)) {
                $propertyName = [string]$parameterProperty.Name
                if ([string]::IsNullOrWhiteSpace($propertyName)) {
                    continue
                }

                if ($propertyName -match '(?i)(^|/)(dataset|source|siteaddress|baseurl|request/url|uri|url|authority|host)$') {
                    Add-PowerPlatformCheckerStringCandidate -Values $candidateUrlValues -Candidate $parameterProperty.Value
                }
            }
        }
    }

    $urlProfile = $null
    foreach ($candidateValue in @($candidateUrlValues)) {
        $resolvedUrl = Resolve-PowerPlatformCheckerFlowExpressionValue -Value $candidateValue -DefinitionParameters $DefinitionParameters
        $urlCandidateProfile = ConvertTo-PowerPlatformCheckerUrlProfile -Value $resolvedUrl
        if ([string]$urlCandidateProfile.ResolutionState -eq 'Resolved') {
            $urlProfile = $urlCandidateProfile
            break
        }
    }

    if ($null -eq $urlProfile) {
        $urlProfile = ConvertTo-PowerPlatformCheckerUrlProfile -Value ''
    }

    return [pscustomobject]@{
        Method = $method
        GetSetAction = $getSetAction
        InteractionDirection = $interactionDirection
        ExternalUrl = [string]$urlProfile.FullUrl
        ExternalEndpoint = [string]$urlProfile.Endpoint
        ExternalProtocol = [string]$urlProfile.Protocol
        ExternalDomain = [string]$urlProfile.Domain
        ExternalMainDomain = [string]$urlProfile.MainDomain
        ExternalResolutionState = [string]$urlProfile.ResolutionState
    }
}
