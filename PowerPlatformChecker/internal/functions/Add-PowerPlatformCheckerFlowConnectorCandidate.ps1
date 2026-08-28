function Add-PowerPlatformCheckerFlowConnectorCandidate {
    <#
    .SYNOPSIS
        Adds one desktop connector candidate entry when it matches the filter.

    .DESCRIPTION
        Normalizes connector names and appends a connector row to the mutable
        candidate list only when the connector name passes the wildcard filter.

    .PARAMETER CandidateList
        Mutable list that receives connector candidate rows.

    .PARAMETER Name
        Connector name or id.

    .PARAMETER DisplayName
        Connector display name.

    .PARAMETER Tier
        Connector tier.

    .PARAMETER ConnectorFilter
        Wildcard filter value from Get-PowerPlatformCheckerFlowConnectorTier.

    .EXAMPLE
        PS> Add-PowerPlatformCheckerFlowConnectorCandidate -CandidateList $list -Name 'shared_office365' -ConnectorFilter '*'
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[object]] $CandidateList,

        [Parameter(Mandatory = $false)]
        [string] $Name,

        [Parameter(Mandatory = $false)]
        [string] $DisplayName,

        [Parameter(Mandatory = $false)]
        [string] $Tier,

        [Parameter(Mandatory = $true)]
        [string] $ConnectorFilter
    )

    $normalizedName = [string]$Name
    if ($normalizedName -like '*/apis/*') {
        $normalizedName = $normalizedName.Split('/')[-1]
    }

    if ([string]::IsNullOrWhiteSpace($normalizedName) -or $normalizedName -notlike $ConnectorFilter) {
        return
    }

    [void]$CandidateList.Add([pscustomobject]@{
            Name = [string]$normalizedName
            DisplayName = [string]$DisplayName
            Tier = [string]$Tier
        })
}
