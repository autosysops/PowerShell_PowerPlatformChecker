function Get-PowerPlatformCheckerFlowDiagramContent {
    <#
    .SYNOPSIS
        Builds Mermaid flow class nodes and associated links for architecture diagrams.

    .DESCRIPTION
        Creates flow node class text and flow-driven relationship links used by
        Get-PowerPlatformCheckerArchitectureDiagram. This helper is responsible for
        translating flow parameters and action metadata into diagram members and
        connections.

    .PARAMETER FlowsToRender
        Flow metadata objects that should be rendered.

    .PARAMETER SolutionPath
        Root path of the unpacked solution used to locate workflow JSON files.

    .PARAMETER SolutionObject
        Aggregated solution metadata returned by Get-PowerPlatformCheckerSolutionObject.

    .PARAMETER EntitySetByReference
        Lookup table that maps logical/entity references to canonical entity set names.

    .PARAMETER IncludeFlows
        Include flow-to-flow links when action references resolve to other flows.

    .PARAMETER IncludeEnvironmentVariables
        Include parameter-driven environment variable members and links.

    .PARAMETER IncludeConnections
        Include connection reference members and links.

    .PARAMETER IncludeEntities
        Include action entity usage members and links.

    .PARAMETER HasFlowFilter
        Indicates whether rendering is scoped to a specific flow filter.

    .PARAMETER FlowId
        Flow id that identifies the selected scope when HasFlowFilter is set.

    .PARAMETER NewLine
        Line separator used when composing Mermaid output.

    .EXAMPLE
        Build flow diagram content for architecture assembly.

        PS> Get-PowerPlatformCheckerFlowDiagramContent -FlowsToRender $flows -SolutionPath $path -SolutionObject $solution -EntitySetByReference $entityMap -IncludeFlows -IncludeConnections -IncludeEntities

        Returns node text plus link collections that the caller appends to the final diagram.
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)]
        [object[]] $FlowsToRender = @(),

        [Parameter(Mandatory = $true)]
        [string] $SolutionPath,

        [Parameter(Mandatory = $true)]
        [object] $SolutionObject,

        [Parameter(Mandatory = $true)]
        [hashtable] $EntitySetByReference,

        [Parameter(Mandatory = $false)]
        [switch] $IncludeFlows,

        [Parameter(Mandatory = $false)]
        [switch] $IncludeEnvironmentVariables,

        [Parameter(Mandatory = $false)]
        [switch] $IncludeConnections,

        [Parameter(Mandatory = $false)]
        [switch] $IncludeEntities,

        [Parameter(Mandatory = $false)]
        [switch] $HasFlowFilter,

        [Parameter(Mandatory = $false)]
        [string] $FlowId,

        [Parameter(Mandatory = $false)]
        [string] $NewLine = [Environment]::NewLine
    )

    $diagram = ""
    $links = @()
    $connectedEnvVars = @()
    $connectedConnections = @()
    $connectedEntities = @()

    foreach ($flow in @($FlowsToRender)) {
        if (-not $flow -or [string]::IsNullOrWhiteSpace([string]$flow.Id)) {
            continue
        }

        $flowNode = "flow$($flow.Id)"
        $flowMembers = @()

        # Flow parameters provide environment-variable usage links into the flow node.
        try {
            $parameters = Get-PowerPlatformCheckerFlowParameter -Path (Join-Path (Join-Path $SolutionPath "Workflows") ("*" + $flow.Id + "*.json"))
            foreach ($parameter in @($parameters)) {
                if (-not $IncludeEnvironmentVariables.IsPresent) { continue }
                $flowMembers += "    [$($parameter.Type)]$($parameter.SchemaName)$NewLine"
                $links += "$($parameter.SchemaName) ..> ${flowNode}:$($parameter.SchemaName)$NewLine"
                $connectedEnvVars += $parameter.SchemaName
            }
        }
        catch {
            Write-Warning "Error in reading the parameters of flow $($flow.Name)"
        }

        # Flow action metadata drives flow-to-flow, flow-to-connector, and flow-to-entity links.
        try {
            $actions = Get-PowerPlatformCheckerFlowActionList -Path (Join-Path (Join-Path $SolutionPath "Workflows") ("*" + $flow.Id + "*.json")) -Recurse -IncludeTrigger -Properties References,Entities
            foreach ($action in @($actions)) {
                if ($null -ne $action.Reference -and $action.Reference -ne "") {
                    $referenceFlow = $SolutionObject.Workflows | Where-Object { $_.Id -eq $action.Reference } | Select-Object -First 1
                    if ($IncludeFlows.IsPresent -and $referenceFlow -and ((-not $HasFlowFilter.IsPresent) -or $referenceFlow.Id -eq $FlowId)) {
                        $links += "${flowNode} --> flow$($referenceFlow.Id):$($action.Name.replace(' ', '_'))$NewLine"
                    }
                }

                if ($IncludeConnections.IsPresent -and $action.Group -ne "*" -and $null -ne $action.Group) {
                    $flowMembers += "    $($action.Name.replace(' ', '_'))($($action.Group))$NewLine"
                    $links += "$($action.Group) --> ${flowNode}:$($action.Group)$NewLine"
                    $connectedConnections += $action.Group
                }

                if ($IncludeEntities.IsPresent -and $action.Entities.Count -gt 0) {
                    foreach ($entity in @($action.Entities)) {
                        $resolvedEntitySet = Get-PowerPlatformCheckerArchitectureDiagramEntitySetName -EntityReference ([string]$entity) -EntitySetByReference $EntitySetByReference
                        if (-not $resolvedEntitySet) {
                            continue
                        }

                        $flowMembers += "    $($action.Name.replace(' ', '_'))($($resolvedEntitySet))$NewLine"
                        $links += "${flowNode} --> $($resolvedEntitySet):$($entity)$NewLine"
                        $connectedEntities += $resolvedEntitySet
                    }
                }
            }
        }
        catch {
            Write-Warning "Error in reading the actions of flow $($flow.Name)"
        }

        if ($flowMembers.Count -gt 0) {
            $diagram += "class $flowNode[`"$($flow.Name)`"]:::Flow {$NewLine"
            foreach ($flowMember in $flowMembers) {
                $diagram += $flowMember
            }
            $diagram += "}$NewLine"
        }
        else {
            $diagram += "class $flowNode[`"$($flow.Name)`"]:::Flow$NewLine"
        }
    }

    return [pscustomobject]@{
        DiagramText = $diagram
        Links = @($links)
        ConnectedEnvVars = @($connectedEnvVars | Select-Object -Unique)
        ConnectedConnections = @($connectedConnections | Select-Object -Unique)
        ConnectedEntities = @($connectedEntities | Select-Object -Unique)
    }
}
