function Add-PowerPlatformCheckerDesktopMemberName {
    <#
    .SYNOPSIS
        Adds a desktop member name only once.

    .DESCRIPTION
        Uses a hash set to prevent duplicate [INPUT]/[OUTPUT] member names while
        preserving first-seen order for architecture class rendering.

    .PARAMETER MemberNames
        Mutable ordered list that receives unique member names.

    .PARAMETER SeenMemberNames
        Hash set used to prevent duplicate names from multiple metadata sources.

    .PARAMETER Name
        Candidate member name to add.

    .EXAMPLE
        Add-PowerPlatformCheckerDesktopMemberName -MemberNames $names -SeenMemberNames $seen -Name 'var_Input'

        Adds the member only when it has not already been recorded.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]] $MemberNames,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.HashSet[string]] $SeenMemberNames,

        [Parameter(Mandatory = $false)]
        [string] $Name
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return
    }

    $trimmedName = $Name.Trim()
    if ($SeenMemberNames.Add($trimmedName)) {
        [void]$MemberNames.Add($trimmedName)
    }
}
