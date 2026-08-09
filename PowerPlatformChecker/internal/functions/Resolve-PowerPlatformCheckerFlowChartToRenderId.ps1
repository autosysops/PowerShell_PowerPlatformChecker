function Resolve-PowerPlatformCheckerFlowChartToRenderId {
    <#
    .SYNOPSIS
        Resolves the rendered target node id for a flowchart edge.

    .DESCRIPTION
        Returns the correct Mermaid node id for the target side of an edge.
        When the target action is wrapped in a grouped block, this returns the
        subgraph id for external edges and the normal action id for internal
        parent-child edges.

    .PARAMETER SourceName
        Name of the source action for the edge.

    .PARAMETER TargetName
        Name of the target action for the edge.

    .PARAMETER WrappedByName
        Hashtable containing wrapper metadata keyed by action name.

    .PARAMETER ActionByName
        Hashtable containing action objects keyed by action name.

    .PARAMETER NodeByName
        Hashtable containing Mermaid node ids keyed by action name.

    .EXAMPLE
        Resolve a target id for a dependency edge.

        PS> Resolve-PowerPlatformCheckerFlowChartToRenderId -SourceName "Compose" -TargetName "Check_status" -WrappedByName $wrappedByName -ActionByName $actionByName -NodeByName $nodeByName
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourceName,

        [Parameter(Mandatory = $true)]
        [string] $TargetName,

        [Parameter(Mandatory = $true)]
        [hashtable] $WrappedByName,

        [Parameter(Mandatory = $true)]
        [hashtable] $ActionByName,

        [Parameter(Mandatory = $true)]
        [hashtable] $NodeByName
    )

    if ($WrappedByName.ContainsKey($TargetName)) {
        $sourceParent = $null
        if ($ActionByName.ContainsKey($SourceName) -and
            ($ActionByName[$SourceName].PSObject.Properties.Name -contains "ParentAction") -and
            $null -ne $ActionByName[$SourceName].ParentAction) {
            $sourceParent = $ActionByName[$SourceName].ParentAction.Name
        }

        # External edges enter a wrapped block through the subgraph boundary.
        if ($sourceParent -ne $TargetName) {
            return $WrappedByName[$TargetName].SubgraphId
        }
    }

    return $NodeByName[$TargetName]
}

