function Get-PowerPlatformCheckerCanvasDestinationProfile {
    <#
    .SYNOPSIS
        Infers destination metadata for a canvas app.

    .DESCRIPTION
        Derives a best-effort external destination from canvas connection
        references. This is intentionally conservative and falls back to Unknown.

    .PARAMETER CanvasApp
        Canvas app object returned by Get-PowerPlatformCheckerCanvasApp.

    .EXAMPLE
        PS> Get-PowerPlatformCheckerCanvasDestinationProfile -CanvasApp $app
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [object] $CanvasApp
    )

    $externalDomainCandidates = @($CanvasApp.ExternalDomains | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Select-Object -Unique)
    if ($externalDomainCandidates.Count -gt 0) {
        return [pscustomobject]@{
            Destination = [string]$externalDomainCandidates[0]
            DestinationType = 'Domain'
            DestinationConfidence = 'Medium'
            DestinationEvidence = 'MsAppConnectedDataSource'
        }
    }

    $connectorNames = @($CanvasApp.ConnectionReferences | ForEach-Object {
            if ($_ -and $_.id) {
                [string]($_.id).Split('/')[-1]
            }
        } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)

    if ($connectorNames -contains 'shared_commondataserviceforapps') {
        return [pscustomobject]@{
            Destination = 'dataverse'
            DestinationType = 'Service'
            DestinationConfidence = 'Low'
            DestinationEvidence = 'ConnectionReference'
        }
    }

    if ($connectorNames -contains 'shared_office365') {
        return [pscustomobject]@{
            Destination = 'office365'
            DestinationType = 'Service'
            DestinationConfidence = 'Low'
            DestinationEvidence = 'ConnectionReference'
        }
    }

    if ($connectorNames -contains 'shared_sharepointonline') {
        return [pscustomobject]@{
            Destination = 'sharepoint'
            DestinationType = 'Service'
            DestinationConfidence = 'Low'
            DestinationEvidence = 'ConnectionReference'
        }
    }

    if ($connectorNames -contains 'shared_sql') {
        return [pscustomobject]@{
            Destination = 'sql'
            DestinationType = 'Service'
            DestinationConfidence = 'Low'
            DestinationEvidence = 'ConnectionReference'
        }
    }

    if ($connectorNames -contains 'shared_dynamicssmbsaas') {
        return [pscustomobject]@{
            Destination = 'businesscentral'
            DestinationType = 'Service'
            DestinationConfidence = 'Low'
            DestinationEvidence = 'ConnectionReference'
        }
    }

    return [pscustomobject]@{
        Destination = ''
        DestinationType = 'Unknown'
        DestinationConfidence = 'Low'
        DestinationEvidence = 'NoDestinationSignal'
    }
}


