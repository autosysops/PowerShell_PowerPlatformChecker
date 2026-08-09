function Get-PowerPlatformCheckerFlowChartOrderedChildName {
    <#
    .SYNOPSIS
        Returns child action names ordered for deterministic subgraph rendering.

    .DESCRIPTION
        Filters pseudo child names and then orders valid child actions by local
        runAfter dependencies. If cyclic/ambiguous dependencies exist, remaining
        names are appended deterministically.

    .PARAMETER ParentName
        Parent action name whose child names should be ordered.

    .PARAMETER ChildrenByParent
        Hashtable mapping parent action name to child action-name array.

    .PARAMETER NodeByName
        Hashtable mapping action name to Mermaid node id.

    .PARAMETER WrappedByName
        Hashtable containing wrapper metadata keyed by action name.

    .PARAMETER ActionByName
        Hashtable mapping action name to action object.

    .EXAMPLE
        Return deterministically ordered child action names for one wrapper parent.

        PS> Get-PowerPlatformCheckerFlowChartOrderedChildName -ParentName Try_Supplier_check -ChildrenByParent $childrenByParent -NodeByName $nodeByName -WrappedByName $wrappedByName -ActionByName $actionByName
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string] $ParentName,

        [Parameter(Mandatory = $true)]
        [hashtable] $ChildrenByParent,

        [Parameter(Mandatory = $true)]
        [hashtable] $NodeByName,

        [Parameter(Mandatory = $true)]
        [hashtable] $WrappedByName,

        [Parameter(Mandatory = $true)]
        [hashtable] $ActionByName
    )

    if (-not $ChildrenByParent.ContainsKey($ParentName)) {
        return @()
    }

    $orderedChildNames = @()
    $remainingChildNames = [System.Collections.Generic.List[string]]::new()
    foreach ($childName in @($ChildrenByParent[$ParentName])) {
        if ([string]::IsNullOrWhiteSpace([string]$childName)) { continue }

        # Some branch metadata can surface pseudo child names; only keep real action names.
        if ($NodeByName.ContainsKey($childName) -or $WrappedByName.ContainsKey($childName)) {
            [void]$remainingChildNames.Add([string]$childName)
        }
    }

    while ($remainingChildNames.Count -gt 0) {
        $progress = $false

        foreach ($candidateName in @($remainingChildNames)) {
            $runAfterInRemaining = @()
            if ($ActionByName.ContainsKey($candidateName)) {
                $candidateAction = $ActionByName[$candidateName]
                if ($null -ne $candidateAction.RunAfter -and $candidateAction.RunAfter -ne "") {
                    $runAfterInRemaining = @($candidateAction.RunAfter) | Where-Object { $remainingChildNames.Contains($_) }
                }
            }

            if (@($runAfterInRemaining).Count -eq 0) {
                $orderedChildNames += $candidateName
                [void]$remainingChildNames.Remove($candidateName)
                $progress = $true
            }
        }

        if (-not $progress) {
            # Keep deterministic output even if cyclic/ambiguous dependencies exist.
            $orderedChildNames += @($remainingChildNames)
            [void]$remainingChildNames.Clear()
        }
    }

    return $orderedChildNames
}
