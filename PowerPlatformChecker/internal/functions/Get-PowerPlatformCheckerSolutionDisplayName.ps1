function Get-PowerPlatformCheckerSolutionDisplayName {
    <#
    .SYNOPSIS
        Resolves a human-readable solution name from a solution folder path.

    .DESCRIPTION
        Managed and Unmanaged exports live in child folders, but diagrams should
        show the solution folder name people recognize instead of the packaging
        folder name.

    .PARAMETER Path
        Candidate solution path.

    .EXAMPLE
        Resolve the display name for a managed solution folder.

        PS> Get-PowerPlatformCheckerSolutionDisplayName -Path 'C:\Solutions\MyApp\Managed'
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $leaf = [System.IO.Path]::GetFileName($Path)
    if ($leaf -in @('Managed', 'Unmanaged')) {
        $parentPath = Split-Path -Path $Path -Parent
        $parentLeaf = [System.IO.Path]::GetFileName($parentPath)
        if (-not [string]::IsNullOrWhiteSpace([string]$parentLeaf)) {
            return [string]$parentLeaf
        }
    }

    return [string]$leaf
}
