function Get-PowerPlatformCheckerTriggerAuthenticationDescription {
    <#
    .SYNOPSIS
        Maps triggerAuthenticationType values to human-readable descriptions.

    .DESCRIPTION
        Power Automate trigger authentication values are compact enum-like strings.
        This helper returns the friendly wording shown in designer experiences
        where known, and falls back to the original value for unknown entries.

    .PARAMETER AuthenticationType
        Raw triggerAuthenticationType value from trigger inputs.

    .EXAMPLE
        Get-PowerPlatformCheckerTriggerAuthenticationDescription -AuthenticationType 'Tenant'

        Returns: Any user in my tenant
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [string] $AuthenticationType
    )

    if ([string]::IsNullOrWhiteSpace([string]$AuthenticationType)) {
        return ''
    }

    switch -Regex ([string]$AuthenticationType) {
        '^Anyone$' { return 'Anyone' }
        '^Anonymous$' { return 'Anyone' }
        '^Tenant$' { return 'Any user in my tenant' }
        '^SpecificAccounts$' { return 'Specific users in my tenant' }
        '^SpecificUsers$' { return 'Specific users in my tenant' }
        '^AAD$' { return 'Any user in my tenant' }
        default { return [string]$AuthenticationType }
    }
}

