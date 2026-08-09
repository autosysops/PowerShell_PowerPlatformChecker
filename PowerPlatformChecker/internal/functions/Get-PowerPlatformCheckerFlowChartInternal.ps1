function Get-PowerPlatformCheckerFlowChartInternal {
    <#
    .SYNOPSIS
        Builds one recursively owned flowchart graph.

    .DESCRIPTION
        Builds the graph rooted at RootActionName from precomputed flowchart
        context. The synthetic root and nested action roots follow the same path:
        collect the root node when rendered, recursively collect child graphs,
        and retain edges whose endpoints are direct members of that graph.

    .PARAMETER GraphContext
        Precomputed flowchart indexes, nodes, edges, and wrapper metadata.

    .PARAMETER RootActionName
        Action whose graph is built, or the synthetic root action name.

    .PARAMETER Direction
        Mermaid flow direction.

    .OUTPUTS
        System.Management.Automation.PSCustomObject. Returns a FlowchartGraph with
        Id, ActionName, Title, Direction, IsEmpty, Nodes, Edges, and Subgraphs.

    .EXAMPLE
        Build the complete graph from prepared action metadata.

        PS> Get-PowerPlatformCheckerFlowChartInternal -GraphContext $context -RootActionName $context.RootActionName -Direction TB
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $GraphContext,

        [Parameter(Mandatory = $true)]
        [string] $RootActionName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("TB", "BT", "LR", "RL")]
        [string] $Direction
    )

    $isSyntheticRoot = $RootActionName -eq $GraphContext.RootActionName
    $isWrapped = $GraphContext.WrappedByName.ContainsKey($RootActionName)
    $isBranchWrapper = $GraphContext.ActionByName.ContainsKey($RootActionName) -and $GraphContext.ActionByName[$RootActionName].Type -in @("If", "Switch")
    $nodes = @()
    $subgraphs = @()

    if ((-not $isWrapped -or $isBranchWrapper) -and $GraphContext.NodeByName.ContainsKey($RootActionName)) {
        $nodeId = $GraphContext.NodeByName[$RootActionName]
        if ($GraphContext.NodeById.ContainsKey($nodeId)) {
            $nodes += $GraphContext.NodeById[$nodeId]
        }
    }

    $orderedChildNames = Get-PowerPlatformCheckerFlowChartOrderedChildName -ParentName $RootActionName -ChildrenByParent $GraphContext.ChildrenByParent -NodeByName $GraphContext.NodeByName -WrappedByName $GraphContext.WrappedByName -ActionByName $GraphContext.ActionByName
    foreach ($childName in @($orderedChildNames)) {
        $childGraph = Get-PowerPlatformCheckerFlowChartInternal -GraphContext $GraphContext -RootActionName $childName -Direction $Direction
        if ($GraphContext.WrappedByName.ContainsKey($childName)) {
            $subgraphs += $childGraph
            continue
        }

        $nodes += @($childGraph.Nodes)
        $subgraphs += @($childGraph.Subgraphs)
    }

    $nodes = @($nodes | Select-Object -Unique Id, Label, Shape)
    $subgraphs = @($subgraphs | Sort-Object { [int]($_.Id -replace "\D", "") })
    $memberIds = @($nodes | ForEach-Object { $_.Id })
    $memberIds += @($subgraphs | ForEach-Object { $_.Id })
    $memberIds = @($memberIds | Select-Object -Unique)
    $edges = @(
        $GraphContext.Edges |
            Where-Object { $memberIds -contains $_.From -and $memberIds -contains $_.To } |
            Sort-Object From, Label, To
    )

    $wrapperId = if ($isWrapped) { $GraphContext.WrappedByName[$RootActionName].SubgraphId } else { $null }
    $displayName = if ($GraphContext.ActionByName.ContainsKey($RootActionName) -and $GraphContext.ActionByName[$RootActionName].PSObject.Properties.Name -contains "DisplayName") {
        [string]$GraphContext.ActionByName[$RootActionName].DisplayName
    }
    else {
        $RootActionName
    }
    $wrapperTitle = if (-not $isWrapped) { $null } elseif ($GraphContext.ActionByName[$RootActionName].Type -eq "If") { " " } else { $displayName }

    return [pscustomobject]@{
        GraphType = "FlowchartGraph"
        Id = $wrapperId
        ActionName = if ($isSyntheticRoot) { $null } else { $displayName }
        Title = $wrapperTitle
        Direction = $Direction
        IsEmpty = $isSyntheticRoot -and $GraphContext.IsEmpty
        Nodes = @($nodes)
        Edges = @($edges)
        Subgraphs = @($subgraphs)
    }
}