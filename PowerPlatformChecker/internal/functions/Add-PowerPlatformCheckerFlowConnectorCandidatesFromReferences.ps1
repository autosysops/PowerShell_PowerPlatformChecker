function Add-PowerPlatformCheckerFlowConnectorCandidatesFromReferences {
    <#
    .SYNOPSIS
        Adds desktop connector candidates from connection reference payloads.

    .DESCRIPTION
        Supports both array and object-map connection reference shapes used by
        desktop flow metadata exports.

    .PARAMETER CandidateList
        Mutable list that receives connector candidate rows.

    .PARAMETER ConnectionReferences
        ConnectionReferences payload in object-map or array shape.

    .PARAMETER ConnectorFilter
        Wildcard filter value from Get-PowerPlatformCheckerFlowConnectorTier.

    .EXAMPLE
        PS> Add-PowerPlatformCheckerFlowConnectorCandidatesFromReferences -CandidateList $list -ConnectionReferences $refs -ConnectorFilter '*'
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[object]] $CandidateList,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $ConnectionReferences,

        [Parameter(Mandatory = $true)]
        [string] $ConnectorFilter
    )

    if ($null -eq $ConnectionReferences) {
        return
    }

    $referenceItems = @()
    if ($ConnectionReferences -is [array]) {
        $referenceItems = @($ConnectionReferences)
    }
    elseif (($ConnectionReferences.PSObject.Properties.Name -contains 'api') -or ($ConnectionReferences.PSObject.Properties.Name -contains 'name')) {
        $referenceItems = @($ConnectionReferences)
    }

    if (@($referenceItems).Count -gt 0) {
        foreach ($connectionReference in @($referenceItems)) {
            if ($null -eq $connectionReference) {
                continue
            }

            $referenceName = ''
            if ($null -ne $connectionReference.api -and -not [string]::IsNullOrWhiteSpace([string]$connectionReference.api.name)) {
                $referenceName = [string]$connectionReference.api.name
            }
            elseif (-not [string]::IsNullOrWhiteSpace([string]$connectionReference.connectorId)) {
                $referenceName = [string]$connectionReference.connectorId
            }
            elseif (-not [string]::IsNullOrWhiteSpace([string]$connectionReference.name)) {
                $referenceName = [string]$connectionReference.name
            }

            $referenceDisplayName = [string]$connectionReference.displayName
            if ([string]::IsNullOrWhiteSpace($referenceDisplayName)) {
                $referenceDisplayName = [string]$connectionReference.connectionDisplayName
            }

            Add-PowerPlatformCheckerFlowConnectorCandidate -CandidateList $CandidateList -Name $referenceName -DisplayName $referenceDisplayName -Tier ([string]$connectionReference.tier) -ConnectorFilter $ConnectorFilter
        }

        return
    }

    foreach ($connectionProperty in @($ConnectionReferences | Get-Member -MemberType NoteProperty)) {
        $entry = $ConnectionReferences.($connectionProperty.Name)
        $entryDisplayName = [string]$entry.displayName
        if ([string]::IsNullOrWhiteSpace($entryDisplayName)) {
            $entryDisplayName = [string]$connectionProperty.Name
        }

        Add-PowerPlatformCheckerFlowConnectorCandidate -CandidateList $CandidateList -Name ([string]$connectionProperty.Name) -DisplayName $entryDisplayName -Tier ([string]$entry.tier) -ConnectorFilter $ConnectorFilter
    }
}
