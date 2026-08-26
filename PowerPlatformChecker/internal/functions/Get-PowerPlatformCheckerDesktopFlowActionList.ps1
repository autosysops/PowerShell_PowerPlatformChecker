function Get-PowerPlatformCheckerDesktopFlowActionList {
    <#
    .SYNOPSIS
        Parses desktop flow definition script into action objects.

    .DESCRIPTION
        Converts desktop flow script segments into a chart-compatible list of
        action objects that mirror the public cloud flow action-list contract.

    .PARAMETER Path
        Path to the desktop flow JSON file.

    .PARAMETER IncludeTrigger
        Adds IsTrigger metadata field when requested.

    .PARAMETER Properties
        Additional optional properties to include in the output.

    .EXAMPLE
        Get desktop actions and include chart relationship metadata.

        PS> Get-PowerPlatformCheckerDesktopFlowActionList -Path "C:\Flow.json" -Properties RunAfter,ParentAction
    #>

    [CmdLetBinding()]
    [OutputType([Object[]])]
    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [String] $Path,

        [Parameter(Mandatory = $false, Position = 2)]
        [Switch] $IncludeTrigger,

        [Parameter(Mandatory = $false, Position = 3)]
        [String[]] $Properties = @()
    )

    $metadata = Get-PowerPlatformCheckerDesktopFlowMeta -Path $Path
    if ($null -eq $metadata -or [string]::IsNullOrWhiteSpace($metadata.Definition)) {
        return @()
    }

    $segments = @(ConvertTo-PowerPlatformCheckerDesktopDefinitionSegmentList -Definition ([string]$metadata.Definition))

    $actions = @()
    $actionNameCount = @{}
    $previousActionName = $null
    $containerStack = [System.Collections.Generic.List[object]]::new()
    $handlerStack = [System.Collections.Generic.List[object]]::new()
    $functionDepth = 0
    $includeTriggerRequested = $IncludeTrigger.IsPresent
    $requestedProperties = @($Properties)

    foreach ($segment in $segments) {
        $trimmedSegment = $segment.TrimStart()
        if ([string]::IsNullOrWhiteSpace($trimmedSegment) -or $trimmedSegment -match '^#') {
            continue
        }

        if ($trimmedSegment -match '^"?@@?' -or $trimmedSegment -match '^"?@INPUT\b' -or $trimmedSegment -match '^"?@OUTPUT\b' -or $trimmedSegment -match '^"?@SENSITIVE\b' -or $trimmedSegment -match '^"?IMPORT\b') {
            continue
        }

        if ($functionDepth -gt 0) {
            if ($trimmedSegment -match '^FUNCTION\b') {
                $functionDepth++
            }
            elseif ($trimmedSegment -match '^END FUNCTION\b') {
                $functionDepth--
            }
            continue
        }

        if ($trimmedSegment -match '^FUNCTION\b') {
            $functionDepth = 1
            continue
        }

        if ($trimmedSegment -match '^ON BLOCK ERROR(?:\s+(?<label>.+))?$') {
            $currentContainer = if ($containerStack.Count -gt 0) { $containerStack[$containerStack.Count - 1] } else { $null }
            if ($null -ne $currentContainer) {
                $statusLabel = if ([string]::IsNullOrWhiteSpace($matches['label']) -or $matches['label'] -eq 'all') { 'Error' } else { $matches['label'].Trim() }
                [void]$handlerStack.Add([pscustomobject]@{
                        OwnerName = [string]$currentContainer.Action.Name
                        ParentAction = if ($containerStack.Count -lt 2) { $null } else { $containerStack[$containerStack.Count - 2].Action }
                        Depth = if ($containerStack.Count -lt 2) { 0 } else { [int]$containerStack[$containerStack.Count - 2].Depth + 1 }
                        PreviousActionName = $null
                        StatusLabel = $statusLabel
                    })
            }
            continue
        }

        if ($trimmedSegment -match '^ON ERROR(?:\s+(?<label>.+))?$') {
            $currentContainer = if ($containerStack.Count -gt 0) { $containerStack[$containerStack.Count - 1] } else { $null }
            $runAfterSourceName = if ($null -eq $currentContainer) { $previousActionName } else { $currentContainer.PreviousActionName }
            if (-not [string]::IsNullOrWhiteSpace($runAfterSourceName)) {
                $statusLabel = if ([string]::IsNullOrWhiteSpace($matches['label']) -or $matches['label'] -eq 'all') { 'Error' } else { $matches['label'].Trim() }
                [void]$handlerStack.Add([pscustomobject]@{
                        OwnerName = $runAfterSourceName
                        ParentAction = if ($null -eq $currentContainer) { $null } else { $currentContainer.Action }
                        Depth = if ($null -eq $currentContainer) { 0 } else { [int]$currentContainer.Depth + 1 }
                        PreviousActionName = $null
                        StatusLabel = $statusLabel
                    })
            }
            continue
        }

        if ($trimmedSegment -eq 'END') {
            if ($handlerStack.Count -gt 0) {
                [void]$handlerStack.RemoveAt($handlerStack.Count - 1)
                continue
            }

            if ($containerStack.Count -gt 0) {
                $closedContainer = $containerStack[$containerStack.Count - 1]
                [void]$containerStack.RemoveAt($containerStack.Count - 1)
                $currentContainer = if ($containerStack.Count -gt 0) { $containerStack[$containerStack.Count - 1] } else { $null }
                if ($null -eq $currentContainer) {
                    $previousActionName = $closedContainer.Action.Name
                }
                else {
                    $currentContainer.PreviousActionName = $closedContainer.Action.Name
                    $containerStack[$containerStack.Count - 1] = $currentContainer
                }
            }
            continue
        }

        if ($trimmedSegment -match '^BLOCK\s+''(?<title>.*)''$') {
            $scopeDisplayName = $matches['title'] -replace "''", "'"
            $currentContainer = if ($containerStack.Count -gt 0) { $containerStack[$containerStack.Count - 1] } else { $null }
            $scopeRunAfterSourceName = if ($null -eq $currentContainer) { $previousActionName } else { $currentContainer.PreviousActionName }
            $scopeParentAction = if ($null -eq $currentContainer) { $null } else { $currentContainer.Action }
            $scopeDepth = if ($null -eq $currentContainer) { 0 } else { [int]$currentContainer.Depth + 1 }
            $scopeAction = ConvertTo-PowerPlatformCheckerDesktopActionObject -ActionNameCount $actionNameCount -BaseName 'Scope' -ActionType 'Scope' -DisplayName $scopeDisplayName -ParentAction $scopeParentAction -Depth $scopeDepth -RunAfterSourceName $scopeRunAfterSourceName -RequestedProperties $requestedProperties -IncludeTrigger:$includeTriggerRequested -Segment $trimmedSegment

            $actions += $scopeAction
            [void]$containerStack.Add([pscustomobject]@{
                    Action = $scopeAction
                    PreviousActionName = $null
                    Depth = $scopeDepth
                })
            continue
        }

        if ($trimmedSegment -match '^LOOP\b(?<loopDescriptor>.*)$') {
            $loopDescriptor = [string]$matches['loopDescriptor']
            $loopDisplayName = if ([string]::IsNullOrWhiteSpace($loopDescriptor)) {
                'LOOP'
            }
            else {
                "LOOP {0}" -f $loopDescriptor.Trim()
            }

            $currentContainer = if ($containerStack.Count -gt 0) { $containerStack[$containerStack.Count - 1] } else { $null }
            $loopRunAfterSourceName = if ($null -eq $currentContainer) { $previousActionName } else { $currentContainer.PreviousActionName }
            $loopParentAction = if ($null -eq $currentContainer) { $null } else { $currentContainer.Action }
            $loopDepth = if ($null -eq $currentContainer) { 0 } else { [int]$currentContainer.Depth + 1 }
            $loopAction = ConvertTo-PowerPlatformCheckerDesktopActionObject -ActionNameCount $actionNameCount -BaseName 'LOOP' -ActionType 'Loop' -DisplayName $loopDisplayName -ParentAction $loopParentAction -Depth $loopDepth -RunAfterSourceName $loopRunAfterSourceName -RequestedProperties $requestedProperties -IncludeTrigger:$includeTriggerRequested -Segment $trimmedSegment

            $actions += $loopAction
            [void]$containerStack.Add([pscustomobject]@{
                    Action = $loopAction
                    PreviousActionName = $null
                    Depth = $loopDepth
                })
            continue
        }

        $commandName = [regex]::Match($trimmedSegment, '^[^\s(]+').Value.Trim('"')
        if ([string]::IsNullOrWhiteSpace($commandName)) {
            continue
        }

        if ($commandName -notmatch '^[A-Za-z_][A-Za-z0-9._]*$') {
            continue
        }

        $hasNamespaceQualifier = $commandName.Contains('.')
        $knownSimpleCommands = @('BLOCK', 'CALL', 'DISABLE', 'DISPLAY', 'END', 'FUNCTION', 'IF', 'LAUNCH', 'LOOP', 'NEXT', 'SET', 'THROW', 'WAIT', 'WRITE')
        if (-not $hasNamespaceQualifier -and -not ($knownSimpleCommands -contains $commandName.ToUpperInvariant())) {
            continue
        }

        $actionBaseName = $commandName
        $presentation = Get-PowerPlatformCheckerDesktopCommandPresentation -CommandName $commandName -Segment $trimmedSegment
        $actionType = [string]$presentation.ActionType
        $actionDisplayName = [string]$presentation.DisplayName

        $activeHandler = if ($handlerStack.Count -gt 0) { $handlerStack[$handlerStack.Count - 1] } else { $null }
        $runAfterSourceName = $null
        $runAfterLabel = 'Succeeded'
        $isErrorHandler = $false
        $currentContainer = if ($containerStack.Count -gt 0) { $containerStack[$containerStack.Count - 1] } else { $null }
        $parentAction = if ($null -eq $currentContainer) { $null } else { $currentContainer.Action }
        $actionDepth = if ($null -eq $currentContainer) { 0 } else { [int]$currentContainer.Depth + 1 }
        if ($null -ne $activeHandler) {
            $runAfterSourceName = if ([string]::IsNullOrWhiteSpace([string]$activeHandler.PreviousActionName)) { [string]$activeHandler.OwnerName } else { [string]$activeHandler.PreviousActionName }
            $runAfterLabel = if ([string]::IsNullOrWhiteSpace([string]$activeHandler.PreviousActionName)) { [string]$activeHandler.StatusLabel } else { 'Succeeded' }
            $isErrorHandler = $true
            $parentAction = $activeHandler.ParentAction
            $actionDepth = [int]$activeHandler.Depth
        }
        else {
            $runAfterSourceName = if ($null -eq $currentContainer) { $previousActionName } else { $currentContainer.PreviousActionName }
        }

        $actionObject = ConvertTo-PowerPlatformCheckerDesktopActionObject -ActionNameCount $actionNameCount -BaseName $actionBaseName -ActionType $actionType -DisplayName $actionDisplayName -ParentAction $parentAction -Depth $actionDepth -RunAfterSourceName $runAfterSourceName -RunAfterLabel $runAfterLabel -IsErrorHandler $isErrorHandler -RequestedProperties $requestedProperties -IncludeTrigger:$includeTriggerRequested -Segment $trimmedSegment

        $actions += $actionObject
        if ($null -ne $activeHandler) {
            $activeHandler.PreviousActionName = $actionObject.Name
            $handlerStack[$handlerStack.Count - 1] = $activeHandler
            continue
        }

        if ($null -eq $currentContainer) {
            $previousActionName = $actionObject.Name
        }
        else {
            $currentContainer.PreviousActionName = $actionObject.Name
            $containerStack[$containerStack.Count - 1] = $currentContainer
        }
    }

    return $actions
}





