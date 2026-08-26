function Get-PowerPlatformCheckerFlowTriggerMode {
    <#
    .SYNOPSIS
        Classifies a flow trigger into a normalized trigger mode.

    .DESCRIPTION
        Inspects trigger actions returned by Get-PowerPlatformCheckerFlowActionList and
        maps known trigger types to a stable mode contract used by architecture graph
        output.

    .PARAMETER Actions
        Action list that may contain one or more trigger rows marked with IsTrigger.

    .EXAMPLE
        Resolve a normalized trigger mode from flow actions.

        PS> Get-PowerPlatformCheckerFlowTriggerMode -Actions $actions
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [object[]] $Actions = @()
    )

    $triggerAction = @($Actions | Where-Object {
            $_ -and
            $_.PSObject.Properties.Name -contains 'IsTrigger' -and
            [bool]$_.IsTrigger
        } | Select-Object -First 1)

    if (@($triggerAction).Count -eq 0) {
        return 'Unknown'
    }

    $triggerType = [string]$triggerAction[0].Type
    if ([string]::IsNullOrWhiteSpace($triggerType)) {
        return 'Unknown'
    }

    switch -Regex ($triggerType) {
        '^Recurrence$' {
            return 'Polling'
        }
        '^Request$' {
            return 'ManualHttp'
        }
        'Webhook' {
            return 'Webhook'
        }
        default {
            return 'Unknown'
        }
    }
}


