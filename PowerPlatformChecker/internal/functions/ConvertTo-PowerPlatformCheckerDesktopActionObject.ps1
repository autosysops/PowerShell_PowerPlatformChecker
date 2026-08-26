function ConvertTo-PowerPlatformCheckerDesktopActionObject {
    <#
    .SYNOPSIS
        Creates a normalized desktop flow action object.

    .DESCRIPTION
        Desktop flow parsing needs to emit the same structural contract as the
        cloud flow action list. This helper centralizes name de-duplication and
        optional metadata fields so callers do not need to rebuild that contract
        in multiple places.

    .PARAMETER ActionNameCount
        Mutable counter table used to make duplicate base names unique.

    .PARAMETER BaseName
        Base action name before numeric de-duplication is applied.

    .PARAMETER ActionType
        Action type value exposed to downstream flowchart logic.

    .PARAMETER DisplayName
        Optional human-readable label shown in rendered diagrams.

    .PARAMETER ParentAction
        Optional parent action metadata used for scoped graph rendering.

    .PARAMETER Depth
        Nesting depth relative to the current container.

    .PARAMETER RunAfterSourceName
        Prior action name used to build RunAfter metadata.

    .PARAMETER RunAfterLabel
        Status label that should connect the source and current action.

    .PARAMETER IsErrorHandler
        Indicates whether the action belongs to an ON ERROR handler branch.

    .PARAMETER RequestedProperties
        Optional properties requested by the public flow-action contract.

    .PARAMETER IncludeTrigger
        Adds IsTrigger metadata when the caller requested trigger-compatible output.

    .PARAMETER Segment
        Original desktop definition segment used for best-effort URL extraction.

    .EXAMPLE
        ConvertTo-PowerPlatformCheckerDesktopActionObject -ActionNameCount @{} -BaseName 'WAIT' -ActionType 'Wait'

        Creates a desktop action object with the standard PowerPlatformChecker shape.
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $ActionNameCount,

        [Parameter(Mandatory = $true)]
        [string] $BaseName,

        [Parameter(Mandatory = $true)]
        [string] $ActionType,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string] $DisplayName,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $ParentAction,

        [Parameter(Mandatory = $false)]
        [int] $Depth = 0,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string] $RunAfterSourceName,

        [Parameter(Mandatory = $false)]
        [string] $RunAfterLabel = 'Succeeded',

        [Parameter(Mandatory = $false)]
        [bool] $IsErrorHandler = $false,

        [Parameter(Mandatory = $false)]
        [string[]] $RequestedProperties = @(),

        [Parameter(Mandatory = $false)]
        [switch] $IncludeTrigger,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string] $Segment
    )

    if (-not $ActionNameCount.ContainsKey($BaseName)) {
        $ActionNameCount[$BaseName] = 0
    }

    $ActionNameCount[$BaseName] = [int]$ActionNameCount[$BaseName] + 1
    $actionName = if ($ActionNameCount[$BaseName] -eq 1) {
        $BaseName
    }
    else {
        "{0}_{1}" -f $BaseName, $ActionNameCount[$BaseName]
    }

    $actionObject = [pscustomobject]@{
        Name = $actionName
        Type = $ActionType
        Group = '*'
    }

    if (-not [string]::IsNullOrWhiteSpace($DisplayName)) {
        $actionObject | Add-Member -MemberType NoteProperty -Name 'DisplayName' -Value $DisplayName
    }

    if ($RequestedProperties -contains 'References') {
        $actionObject | Add-Member -MemberType NoteProperty -Name 'Reference' -Value ''
    }

    if ($RequestedProperties -contains 'Entities') {
        $actionObject | Add-Member -MemberType NoteProperty -Name 'Entities' -Value @()
    }

    if ($RequestedProperties -contains 'RunAfter') {
        if ([string]::IsNullOrWhiteSpace($RunAfterSourceName)) {
            $actionObject | Add-Member -MemberType NoteProperty -Name 'RunAfter' -Value @()
            $actionObject | Add-Member -MemberType NoteProperty -Name 'RunAfterStatus' -Value $null
        }
        else {
            $runAfterStatus = [pscustomobject]@{}
            $runAfterStatus | Add-Member -MemberType NoteProperty -Name $RunAfterSourceName -Value @($RunAfterLabel)
            $actionObject | Add-Member -MemberType NoteProperty -Name 'RunAfter' -Value @($RunAfterSourceName)
            $actionObject | Add-Member -MemberType NoteProperty -Name 'RunAfterStatus' -Value $runAfterStatus
        }
    }

    if ($RequestedProperties -contains 'ParentAction') {
        if ($null -eq $ParentAction) {
            $actionObject | Add-Member -MemberType NoteProperty -Name 'ParentAction' -Value $null
        }
        else {
            $actionObject | Add-Member -MemberType NoteProperty -Name 'ParentAction' -Value ([pscustomobject]@{
                    Name = [string]$ParentAction.Name
                    Type = 'actions'
                })
        }

        $actionObject | Add-Member -MemberType NoteProperty -Name 'Depth' -Value $Depth
        $actionObject | Add-Member -MemberType NoteProperty -Name 'IsErrorHandler' -Value $IsErrorHandler
    }

    if ($IncludeTrigger.IsPresent) {
        $actionObject | Add-Member -MemberType NoteProperty -Name 'IsTrigger' -Value $false
    }

    if (($RequestedProperties -contains 'InteractionProfile') -or ($RequestedProperties -contains 'ExternalProfile')) {
        $method = 'Unknown'
        $getSetAction = 'Unknown'
        $interactionDirection = 'Unknown'

        if ($ActionType -match '(?i)(WaitForWebPage|Extract|Get|Read|Query|List|Search|Navigate|GoToWebPage|Launch|Attach)') {
            $method = 'GET'
            $getSetAction = 'Get'
            $interactionDirection = 'Read'
        }
        elseif ($ActionType -match '(?i)(Set|Write|Populate|Send|Post|Put|Patch|Delete|Click|Press|Create|Update)') {
            $method = 'SET'
            $getSetAction = 'Set'
            $interactionDirection = 'Write'
        }

        $urlCandidate = ''
        if (-not [string]::IsNullOrWhiteSpace($Segment)) {
            $urlMatch = [regex]::Match([string]$Segment, '(?i)(https?://[^\s''""\)]+|//[^\s''""\)]+)')
            if ($urlMatch.Success) {
                $urlCandidate = [string]$urlMatch.Value
            }
        }

        $urlProfile = ConvertTo-PowerPlatformCheckerUrlProfile -Value $urlCandidate

        if ($RequestedProperties -contains 'InteractionProfile') {
            $actionObject | Add-Member -MemberType NoteProperty -Name 'Method' -Value $method
            $actionObject | Add-Member -MemberType NoteProperty -Name 'GetSetAction' -Value $getSetAction
            $actionObject | Add-Member -MemberType NoteProperty -Name 'InteractionDirection' -Value $interactionDirection
        }

        if ($RequestedProperties -contains 'ExternalProfile') {
            $actionObject | Add-Member -MemberType NoteProperty -Name 'ExternalUrl' -Value ([string]$urlProfile.FullUrl)
            $actionObject | Add-Member -MemberType NoteProperty -Name 'ExternalProtocol' -Value ([string]$urlProfile.Protocol)
            $actionObject | Add-Member -MemberType NoteProperty -Name 'ExternalDomain' -Value ([string]$urlProfile.Domain)
            $actionObject | Add-Member -MemberType NoteProperty -Name 'ExternalMainDomain' -Value ([string]$urlProfile.MainDomain)
            $actionObject | Add-Member -MemberType NoteProperty -Name 'ExternalResolutionState' -Value ([string]$urlProfile.ResolutionState)
        }
    }

    return $actionObject
}
