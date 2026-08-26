function Get-PowerPlatformCheckerFlowDirectionProfile {
    <#
    .SYNOPSIS
        Infers aggregate interaction direction metadata for a flow.

    .DESCRIPTION
        Classifies non-trigger flow actions into Read, Write, Mixed, or Unknown.
        Uses operation catalog metadata when available and falls back to
        operation-name heuristics when no direct catalog match is found.

    .PARAMETER Actions
        Action list from Get-PowerPlatformCheckerFlowActionList.

    .EXAMPLE
        PS> Get-PowerPlatformCheckerFlowDirectionProfile -Actions $actions
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)]
        [object[]] $Actions = @()
    )

    $catalogOperations = @()
    try {
        $catalogOperations = @(Get-PowerPlatformCheckerOperationData)
    }
    catch {
        $catalogOperations = @()
    }

    $readSignalCount = 0
    $writeSignalCount = 0
    $catalogMatchCount = 0

    $candidateActions = @($Actions | Where-Object {
            $_ -and
            -not ($_.PSObject.Properties.Name -contains 'IsTrigger' -and [bool]$_.IsTrigger)
        })

    foreach ($action in $candidateActions) {
        $actionType = [string]$action.Type
        if ([string]::IsNullOrWhiteSpace($actionType)) {
            continue
        }

        $searchTokens = @($actionType)
        $actionGroup = ''
        if ($action.PSObject.Properties.Name -contains 'Group') {
            $actionGroup = [string]$action.Group
        }

        if ($catalogOperations.Count -gt 0) {
            $catalogMatch = @($catalogOperations | Where-Object {
                    [string]$_.operationType -eq $actionType -and (
                        [string]::IsNullOrWhiteSpace($actionGroup) -or
                        $actionGroup -eq '*' -or
                        [string]$_.group -eq $actionGroup
                    )
                } | Select-Object -First 1)

            if (@($catalogMatch).Count -gt 0) {
                $catalogMatchCount++
                if (-not [string]::IsNullOrWhiteSpace([string]$catalogMatch[0].name)) {
                    $searchTokens += [string]$catalogMatch[0].name
                }
                if (-not [string]::IsNullOrWhiteSpace([string]$catalogMatch[0].summary)) {
                    $searchTokens += [string]$catalogMatch[0].summary
                }
            }
        }

        $hasReadSignal = $false
        $hasWriteSignal = $false

        foreach ($token in $searchTokens) {
            if ($token -match '(?i)(get|list|read|retrieve|fetch|query|search)') {
                $hasReadSignal = $true
            }
            if ($token -match '(?i)(create|update|delete|insert|set|add|post|send|upsert|patch|write)') {
                $hasWriteSignal = $true
            }
        }

        if ($hasReadSignal) {
            $readSignalCount++
        }
        if ($hasWriteSignal) {
            $writeSignalCount++
        }
    }

    $direction = 'Unknown'
    if ($readSignalCount -gt 0 -and $writeSignalCount -gt 0) {
        $direction = 'Mixed'
    }
    elseif ($readSignalCount -gt 0) {
        $direction = 'Read'
    }
    elseif ($writeSignalCount -gt 0) {
        $direction = 'Write'
    }

    $confidence = 'Low'
    $evidence = 'NoDirectionSignal'
    if ($direction -ne 'Unknown') {
        if ($catalogMatchCount -gt 0) {
            $confidence = 'High'
            $evidence = 'OperationCatalog+Heuristic'
        }
        else {
            $confidence = 'Medium'
            $evidence = 'OperationHeuristic'
        }
    }

    return [pscustomobject]@{
        InteractionDirection = $direction
        DirectionConfidence = $confidence
        SourceEvidence = $evidence
    }
}


