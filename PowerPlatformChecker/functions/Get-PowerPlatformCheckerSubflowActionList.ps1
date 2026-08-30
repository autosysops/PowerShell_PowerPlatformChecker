function Get-PowerPlatformCheckerSubflowActionList {
    <#
    .SYNOPSIS
        Gets actions from one desktop subflow.

    .DESCRIPTION
        Extracts one FUNCTION block from a desktop flow definition and returns
        its actions in the same contract used by Get-PowerPlatformCheckerFlowActionList.

    .PARAMETER Path
        Path to a desktop flow JSON file.

    .PARAMETER SubflowName
        Name of the desktop FUNCTION/subflow to extract.

    .PARAMETER IncludeTrigger
        Adds IsTrigger metadata when requested.

    .PARAMETER Properties
        Additional optional properties to include in the output.

    .EXAMPLE
        Get actions for one desktop subflow.

        PS> Get-PowerPlatformCheckerSubflowActionList -Path 'C:\Flow.json' -SubflowName 'ProcessOrder' -Properties RunAfter,ParentAction
    #>

    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $Path,

        [Parameter(Mandatory = $true, Position = 2)]
        [string] $SubflowName,

        [Parameter(Mandatory = $false, Position = 3)]
        [switch] $IncludeTrigger,

        [Parameter(Mandatory = $false, Position = 4)]
        [ValidateSet('References', 'Entities', 'RunAfter', 'ParentAction', 'InteractionProfile', 'ExternalProfile', 'TriggerProfile', 'OperationProfile', 'ResponseProfile')]
        [string[]] $Properties = @()
    )

    $telemetryProperties = @{
        PropertyCount = @($Properties).Count
        IncludeTrigger = $IncludeTrigger.IsPresent
    }
    Send-THEvent -ModuleName 'PowerPlatformChecker' -EventName 'Get-PowerPlatformCheckerSubflowActionList' -PropertiesHash $telemetryProperties

    $flowType = Get-PowerPlatformCheckerFlowType -Path $Path
    if ($flowType -ne 'Desktop') {
        Write-Warning 'Subflow extraction is only supported for desktop flows.'
        return @()
    }

    $actions = @(Get-PowerPlatformCheckerDesktopFlowActionList -Path $Path -IncludeTrigger:$IncludeTrigger -Properties $Properties -SubflowName $SubflowName)
    if (@($actions).Count -eq 0) {
        Write-Warning ("No matching subflow was found for name '{0}'." -f $SubflowName)
        return @()
    }

    return @($actions)
}

