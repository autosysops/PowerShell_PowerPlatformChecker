function Resolve-PowerPlatformCheckerFlowChartFromRenderId {
    <#
    .SYNOPSIS
        Resolves the rendered source node id for a flowchart edge.

    .DESCRIPTION
        Returns the correct Mermaid node id for the source side of an edge.
        When the source action is wrapped in a grouped block, this returns the
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
        Resolve a source id for a dependency edge.

        PS> Resolve-PowerPlatformCheckerFlowChartFromRenderId -SourceName "Check_status" -TargetName "Update_row" -WrappedByName $wrappedByName -ActionByName $actionByName -NodeByName $nodeByName
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

    if ($WrappedByName.ContainsKey($SourceName)) {
        $targetParent = $null
        $targetIsErrorHandler = $false
        if ($ActionByName.ContainsKey($TargetName) -and
            ($ActionByName[$TargetName].PSObject.Properties.Name -contains "ParentAction") -and
            $null -ne $ActionByName[$TargetName].ParentAction) {
            $targetParent = $ActionByName[$TargetName].ParentAction.Name
        }
        if ($ActionByName.ContainsKey($TargetName) -and ($ActionByName[$TargetName].PSObject.Properties.Name -contains "IsErrorHandler")) {
            $targetIsErrorHandler = [bool]$ActionByName[$TargetName].IsErrorHandler
        }

        # External edges leave a wrapped block through the subgraph boundary.
        if ($targetParent -ne $SourceName -or $targetIsErrorHandler) {
            return $WrappedByName[$SourceName].SubgraphId
        }
    }

    return $NodeByName[$SourceName]
}

