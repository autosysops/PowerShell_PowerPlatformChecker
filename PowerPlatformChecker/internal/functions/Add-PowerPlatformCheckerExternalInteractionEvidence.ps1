function Add-PowerPlatformCheckerExternalInteractionEvidence {
    <#
    .SYNOPSIS
        Adds evidence for a condensed external interaction target.

    .DESCRIPTION
        Aggregates one or more source labels under a single external target so the
        condensed graph can keep stable edges while preserving representative evidence.

    .PARAMETER InteractionByTarget
        Hashtable keyed by target id, then by source label.

    .PARAMETER TargetNodeById
        Hashtable of rendered target nodes keyed by target id.

    .PARAMETER TargetId
        External target identifier.

    .PARAMETER InteractionLabel
        Condensed interaction label such as GET or SET.

    .PARAMETER TargetNode
        External target node.

    .PARAMETER SourceNode
        Source node that produced the interaction.

    .PARAMETER Evidence
        Optional evidence string to retain for the aggregated edge.

    .PARAMETER SourceLabelOverride
        Optional explicit source label. When omitted the label is derived from the source node.

    .PARAMETER SourceLabelPartsOverride
        Optional structured label metadata paired with SourceLabelOverride.

    .PARAMETER CompactLabelOverride
        Optional compact Mermaid label paired with the full SourceLabelOverride.

    .EXAMPLE
        Add a read interaction between a solution component and an external node.

        PS> Add-PowerPlatformCheckerExternalInteractionEvidence -InteractionByTarget $map -TargetNodeById $nodes -TargetId 'externaldomain_api_contoso_example' -InteractionLabel GET -TargetNode $target -SourceNode $source
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $InteractionByTarget,

        [Parameter(Mandatory = $true)]
        [hashtable] $TargetNodeById,

        [Parameter(Mandatory = $true)]
        [string] $TargetId,

        [Parameter(Mandatory = $true)]
        [string] $InteractionLabel,

        [Parameter(Mandatory = $true)]
        [object] $TargetNode,

        [Parameter(Mandatory = $true)]
        [object] $SourceNode,

        [Parameter(Mandatory = $false)]
        [string] $Evidence,

        [Parameter(Mandatory = $false)]
        [string] $SourceLabelOverride,

        [Parameter(Mandatory = $false)]
        [object] $SourceLabelPartsOverride

        ,

        [Parameter(Mandatory = $false)]
        [string] $CompactLabelOverride
    )

    if ([string]::IsNullOrWhiteSpace($TargetId)) {
        return
    }

    if (-not $InteractionByTarget.ContainsKey($TargetId)) {
        $InteractionByTarget[$TargetId] = @{}
    }
    $TargetNodeById[$TargetId] = $TargetNode

    $sourceLabelResult = if (-not [string]::IsNullOrWhiteSpace([string]$SourceLabelOverride)) {
        [pscustomobject]@{
            Label = [string]$SourceLabelOverride
            MermaidLabel = if ([string]::IsNullOrWhiteSpace([string]$CompactLabelOverride)) { [string]$SourceLabelOverride } else { [string]$CompactLabelOverride }
            LabelParts = $SourceLabelPartsOverride
        }
    }
    else {
        Get-PowerPlatformCheckerExternalInteractionSourceLabel -Node $SourceNode -InteractionLabel $InteractionLabel
    }

    $sourceLabel = [string]$sourceLabelResult.Label

    if (-not $InteractionByTarget[$TargetId].ContainsKey($sourceLabel)) {
        $InteractionByTarget[$TargetId][$sourceLabel] = [pscustomobject]@{
            Label = $sourceLabel
            MermaidLabel = [string]$sourceLabelResult.MermaidLabel
            LabelParts = $sourceLabelResult.LabelParts
            Evidence = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        }
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$Evidence)) {
        [void]$InteractionByTarget[$TargetId][$sourceLabel].Evidence.Add([string]$Evidence)
    }
}
