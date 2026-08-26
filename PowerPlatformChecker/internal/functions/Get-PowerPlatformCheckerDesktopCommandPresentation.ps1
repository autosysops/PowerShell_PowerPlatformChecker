function Get-PowerPlatformCheckerDesktopCommandPresentation {
    <#
    .SYNOPSIS
        Resolves display and type metadata for desktop flow commands.

    .DESCRIPTION
        Desktop PAD commands often have terse verb names that are hard to read
        in diagrams. This helper centralizes the translation rules used by the
        flowchart renderer so command labels stay consistent across parser paths.

    .PARAMETER CommandName
        Parsed command token from the desktop flow segment.

    .PARAMETER Segment
        Full desktop flow segment used to derive richer display text.

    .EXAMPLE
        Get-PowerPlatformCheckerDesktopCommandPresentation -CommandName 'WAIT' -Segment 'WAIT 5'

        Returns the normalized action type and diagram label for the command.
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $CommandName,

        [Parameter(Mandatory = $true)]
        [string] $Segment
    )

    $actionType = $CommandName
    $displayName = $null

    if ($CommandName -eq 'CALL') {
        $callTarget = [regex]::Match($Segment, '^CALL\s+(?<target>[^\s]+)').Groups['target'].Value
        $displayName = if ([string]::IsNullOrWhiteSpace($callTarget)) { 'CALL' } else { "CALL {0}" -f $callTarget.Trim() }
        $actionType = 'Call'
    }
    elseif ($CommandName -eq 'WAIT') {
        if ($Segment -match '^WAIT\s+(?<seconds>\d+(?:\.\d+)?)$') {
            $displayName = "WAIT for {0} seconds" -f $matches['seconds']
        }
        elseif ($Segment -match 'WaitForWebPageContent\.(?<waitType>[A-Za-z0-9_]+)') {
            $waitDescriptionByType = @{
                WebPageToContainElement = 'contain element'
                WebPageToNotContainElement = 'not contain element'
                WebPageToContainText = 'contain text'
                WebPageToNotContainText = 'not contain text'
                WebPageToContainElementInState = 'contain element in state'
            }

            $waitType = [string]$matches['waitType']
            $displayName = if ($waitDescriptionByType.ContainsKey($waitType)) {
                "WAIT for web page content ({0})" -f $waitDescriptionByType[$waitType]
            }
            else {
                'WAIT for web page content'
            }
        }
        else {
            $displayName = 'WAIT'
        }

        $actionType = 'Wait'
    }
    elseif ($CommandName -eq 'External.InvokeCloudConnector') {
        $connectorId = [regex]::Match($Segment, "ConnectorId:\s*'(?<connectorId>[^']+)'").Groups['connectorId'].Value
        $operationId = [regex]::Match($Segment, "OperationId:\s*'(?<operationId>[^']+)'").Groups['operationId'].Value
        $connectorName = ''
        if (-not [string]::IsNullOrWhiteSpace($connectorId)) {
            $connectorName = ([string]$connectorId).Split('/')[-1]
        }

        if (-not [string]::IsNullOrWhiteSpace($connectorName) -and -not [string]::IsNullOrWhiteSpace($operationId)) {
            $displayName = "External.InvokeCloudConnector ({0}.{1})" -f $connectorName, $operationId
        }
        elseif (-not [string]::IsNullOrWhiteSpace($operationId)) {
            $displayName = "External.InvokeCloudConnector ({0})" -f $operationId
        }
        elseif (-not [string]::IsNullOrWhiteSpace($connectorName)) {
            $displayName = "External.InvokeCloudConnector ({0})" -f $connectorName
        }
    }

    return [pscustomobject]@{
        ActionType = $actionType
        DisplayName = $displayName
    }
}
