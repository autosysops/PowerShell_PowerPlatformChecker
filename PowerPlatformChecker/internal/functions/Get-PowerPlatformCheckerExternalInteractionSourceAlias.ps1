function Get-PowerPlatformCheckerExternalInteractionSourceAlias {
    <#
    .SYNOPSIS
        Returns a stable short alias for a source node in external interaction diagrams.

    .DESCRIPTION
        Assigns compact aliases (for example Flow-01, App-01) to improve edge-label
        readability while retaining a separate legend for full names.

    .PARAMETER Node
        Source node to alias.

    .PARAMETER AliasByNodeId
        Hashtable cache keyed by node id.

    .PARAMETER AliasCounters
        Hashtable of per-prefix counters.

    .PARAMETER SourceLegend
        Optional mutable list to receive legend rows.

    .PARAMETER SolutionName
        Optional solution name to include in legend rows.

    .EXAMPLE
        Get or create a stable short alias for a source node.

        PS> Get-PowerPlatformCheckerExternalInteractionSourceAlias -Node $flowNode -AliasByNodeId $map -AliasCounters $counters
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Node,

        [Parameter(Mandatory = $true)]
        [hashtable] $AliasByNodeId,

        [Parameter(Mandatory = $true)]
        [hashtable] $AliasCounters,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [System.Collections.Generic.List[object]] $SourceLegend,

        [Parameter(Mandatory = $false)]
        [string] $SolutionName
    )

    $nodeId = [string]$Node.Id
    if ([string]::IsNullOrWhiteSpace($nodeId)) {
        return ''
    }

    if ($AliasByNodeId.ContainsKey($nodeId)) {
        return [string]$AliasByNodeId[$nodeId]
    }

    $prefix = 'Source'
    switch ([string]$Node.Type) {
        'Flow' { $prefix = 'Flow' }
        'CanvasApp' { $prefix = 'App' }
        'ModelDrivenApp' { $prefix = 'App' }
        'WebResource' { $prefix = 'WebResource' }
        'Connection' { $prefix = 'Connector' }
    }

    if (-not $AliasCounters.ContainsKey($prefix)) {
        $AliasCounters[$prefix] = 0
    }

    $AliasCounters[$prefix] = [int]$AliasCounters[$prefix] + 1
    $alias = '{0}-{1:d2}' -f $prefix, [int]$AliasCounters[$prefix]
    $AliasByNodeId[$nodeId] = $alias

    if ($null -ne $SourceLegend) {
        $displayName = [string]$Node.DisplayName
        if ([string]::IsNullOrWhiteSpace($displayName)) {
            $displayName = $nodeId
        }

        [void]$SourceLegend.Add([pscustomobject]@{
                Alias = $alias
                Type = [string]$Node.Type
                DisplayName = $displayName
                SolutionName = [string]$SolutionName
                NodeId = $nodeId
            })
    }

    return $alias
}
