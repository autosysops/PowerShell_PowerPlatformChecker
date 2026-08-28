function Add-PowerPlatformCheckerStringCandidate {
    <#
    .SYNOPSIS
        Adds a non-empty string candidate to a mutable string list.

    .DESCRIPTION
        Converts the candidate to string and appends it only when the value
        is not null, empty, or whitespace.

    .PARAMETER Values
        Mutable list that receives accepted string candidates.

    .PARAMETER Candidate
        Value to evaluate and append.

    .EXAMPLE
        Append a candidate value only when it resolves to a non-empty string.

        PS> Add-PowerPlatformCheckerStringCandidate -Values $values -Candidate $action.inputs.url
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]] $Values,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Candidate
    )

    if ($null -eq $Candidate) {
        return
    }

    $candidateText = [string]$Candidate
    if ([string]::IsNullOrWhiteSpace($candidateText)) {
        return
    }

    [void]$Values.Add($candidateText)
}
