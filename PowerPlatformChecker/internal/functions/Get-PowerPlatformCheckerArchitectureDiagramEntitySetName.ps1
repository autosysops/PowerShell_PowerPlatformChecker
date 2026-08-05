function Get-PowerPlatformCheckerArchitectureDiagramEntitySetName {
    <#
    .SYNOPSIS
        Resolves entity references to canonical entity set names.

    .DESCRIPTION
        Converts logical names or entity set names into the canonical entity set name
        used by the architecture diagram so relationship labels remain stable.

    .PARAMETER EntityReference
        Logical name or entity set name to resolve.

    .PARAMETER EntitySetByReference
        Lookup table that maps known entity references to canonical entity set names.

    .EXAMPLE
        Resolve an entity reference for architecture link generation.

        PS> Get-PowerPlatformCheckerArchitectureDiagramEntitySetName -EntityReference "account" -EntitySetByReference $entityMap

        Returns the canonical entity set name used by diagram nodes and links.
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [string] $EntityReference,

        [Parameter(Mandatory = $true)]
        [hashtable] $EntitySetByReference
    )

    if ([string]::IsNullOrWhiteSpace($EntityReference)) {
        return $null
    }

    $lookupKey = $EntityReference.Trim().ToLower()
    if ($EntitySetByReference.ContainsKey($lookupKey)) {
        return [string]$EntitySetByReference[$lookupKey]
    }

    return $lookupKey
}
