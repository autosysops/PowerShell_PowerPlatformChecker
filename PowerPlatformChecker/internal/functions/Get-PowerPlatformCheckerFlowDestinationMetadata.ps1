function Get-PowerPlatformCheckerFlowDestinationProfile {
    <#
    .SYNOPSIS
        Infers a destination target for flow interactions.

    .DESCRIPTION
        Uses layered evidence to infer a representative destination for a flow:
        URL/domain hints from flow definition defaults first, then Dataverse entity
        references, then connector-group service fallbacks.

    .PARAMETER Path
        Optional path to the flow definition file.

    .PARAMETER Actions
        Flow action list returned by Get-PowerPlatformCheckerFlowActionList.

    .EXAMPLE
        PS> Get-PowerPlatformCheckerFlowDestinationProfile -Path $flowPath -Actions $actions
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)]
        [string] $Path,

        [Parameter(Mandatory = $false)]
        [object[]] $Actions = @()
    )

    $domains = [System.Collections.Generic.List[string]]::new()

    $hasParameterDomainEvidence = $false
    $hasActionDomainEvidence = $false

    if (-not [string]::IsNullOrWhiteSpace($Path) -and (Test-Path -Path $Path)) {
        try {
            $flowData = Import-PowerPlatformCheckerFlow -Path $Path
            $parameterDefaults = @($flowData.properties.definition.parameters | Get-Member -MemberType NoteProperty | ForEach-Object {
                    $parameterValue = $flowData.properties.definition.parameters.($_.Name).defaultValue
                    if ($null -ne $parameterValue) {
                        [string]$parameterValue
                    }
                } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

            foreach ($parameterDefault in $parameterDefaults) {
                $domain = ConvertTo-PowerPlatformCheckerDomain -Value $parameterDefault
                if (-not [string]::IsNullOrWhiteSpace($domain)) {
                    if (Test-PowerPlatformCheckerExternalDomainToken -DomainValue $domain) {
                        [void]$domains.Add(([string]$domain).Trim().ToLowerInvariant())
                    }
                    $hasParameterDomainEvidence = $true
                }
            }

            $definitionJson = ($flowData.properties.definition | ConvertTo-Json -Depth 30)
            $urlMatches = [regex]::Matches([string]$definitionJson, '(?i)(https?:\\/\\/[^"''\\s]+|\\/\\/[^"''\\s]+)')
            foreach ($urlMatch in @($urlMatches)) {
                $candidateUrl = [string]$urlMatch.Value -replace '\\/', '/'
                $domain = ConvertTo-PowerPlatformCheckerDomain -Value $candidateUrl
                if (-not [string]::IsNullOrWhiteSpace($domain)) {
                    if (Test-PowerPlatformCheckerExternalDomainToken -DomainValue $domain) {
                        [void]$domains.Add(([string]$domain).Trim().ToLowerInvariant())
                    }
                    $hasParameterDomainEvidence = $true
                }
            }
        }
        catch {
            $domains = [System.Collections.Generic.List[string]]::new(@($domains))
        }
    }

    foreach ($action in @($Actions)) {
        if ($null -eq $action) {
            continue
        }

        if ($action.PSObject.Properties.Name -contains 'ExternalDomain') {
            $externalDomain = [string]$action.ExternalDomain
            if (-not [string]::IsNullOrWhiteSpace($externalDomain) -and $externalDomain -ne 'Unknown') {
                if (Test-PowerPlatformCheckerExternalDomainToken -DomainValue $externalDomain) {
                    [void]$domains.Add(([string]$externalDomain).Trim().ToLowerInvariant())
                }
                $hasActionDomainEvidence = $true
            }
        }

        if ($action.PSObject.Properties.Name -contains 'ExternalUrl') {
            $externalDomainFromUrl = ConvertTo-PowerPlatformCheckerDomain -Value ([string]$action.ExternalUrl)
            if (-not [string]::IsNullOrWhiteSpace($externalDomainFromUrl)) {
                if (Test-PowerPlatformCheckerExternalDomainToken -DomainValue $externalDomainFromUrl) {
                    [void]$domains.Add(([string]$externalDomainFromUrl).Trim().ToLowerInvariant())
                }
                $hasActionDomainEvidence = $true
            }
        }
    }

    $domains = @($domains | Sort-Object -Unique)
    if ($domains.Count -gt 0) {
        $destinationEvidence = if ($hasParameterDomainEvidence -and $hasActionDomainEvidence) {
            'FlowParameterDefault+ActionExternalProfile'
        }
        elseif ($hasParameterDomainEvidence) {
            'FlowParameterDefault'
        }
        else {
            'ActionExternalProfile'
        }

        return [pscustomobject]@{
            Destination = [string]$domains[0]
            DestinationTargets = @($domains)
            DestinationType = 'Domain'
            DestinationConfidence = 'High'
            DestinationEvidence = $destinationEvidence
        }
    }

    $entityNames = @($Actions | ForEach-Object {
            if ($_ -and $_.PSObject.Properties.Name -contains 'Entities') {
                @($_.Entities)
            }
        } | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Select-Object -Unique)

    if ($entityNames.Count -gt 0) {
        return [pscustomobject]@{
            Destination = [string]$entityNames[0]
            DestinationTargets = @($entityNames)
            DestinationType = 'DataverseEntity'
            DestinationConfidence = 'Medium'
            DestinationEvidence = 'ActionEntity'
        }
    }

    $connectorGroups = @($Actions | ForEach-Object {
            if ($_ -and $_.PSObject.Properties.Name -contains 'Group') {
                [string]$_.Group
            }
        } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and $_ -ne '*' } | Select-Object -Unique)

    if ($connectorGroups -contains 'shared_office365') {
        return [pscustomobject]@{
            Destination = 'office365'
            DestinationTargets = @('office365')
            DestinationType = 'Service'
            DestinationConfidence = 'Low'
            DestinationEvidence = 'ConnectorGroup'
        }
    }

    if ($connectorGroups -contains 'shared_sharepointonline') {
        return [pscustomobject]@{
            Destination = 'sharepoint'
            DestinationTargets = @('sharepoint')
            DestinationType = 'Service'
            DestinationConfidence = 'Low'
            DestinationEvidence = 'ConnectorGroup'
        }
    }

    if ($connectorGroups -contains 'shared_dynamicssmbsaas') {
        return [pscustomobject]@{
            Destination = 'businesscentral'
            DestinationTargets = @('businesscentral')
            DestinationType = 'Service'
            DestinationConfidence = 'Low'
            DestinationEvidence = 'ConnectorGroup'
        }
    }

    return [pscustomobject]@{
        Destination = ''
        DestinationTargets = @()
        DestinationType = 'Unknown'
        DestinationConfidence = 'Low'
        DestinationEvidence = 'NoDestinationSignal'
    }
}


