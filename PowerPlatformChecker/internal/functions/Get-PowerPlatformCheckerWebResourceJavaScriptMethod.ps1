function Get-PowerPlatformCheckerWebResourceJavaScriptMethod {
    <#
    .SYNOPSIS
        Extracts JavaScript method names from a web resource file.

    .DESCRIPTION
        Reads the source JavaScript file that belongs to a web resource and returns
        the method names assigned on object members. This is used for diagram output.

    .PARAMETER SourcePath
        Path to the JavaScript file.

    .EXAMPLE
        Extract method names from a script web resource.

        PS> Get-PowerPlatformCheckerWebResourceJavaScriptMethod -SourcePath "C:\\Solution\\WebResources\\my_script.js"

        Returns unique JavaScript method names detected in the source file.
    #>

    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourcePath
    )

    if (-not (Test-Path -Path $SourcePath)) {
        return [string[]]@()
    }

    try {
        $sourceText = Get-Content -Path $SourcePath -Raw -ErrorAction Stop
    }
    catch {
        return [string[]]@()
    }

    # Capture only two patterns that map cleanly to reusable web resource methods:
    # 1. Plain function declarations: `function saveRecord() {}`
    # 2. Namespaced member assignments: `App.Form.onLoad = (...) => {}`
    $functionDeclarationNames = @(
        [regex]::Matches($sourceText, '(?m)^[ \t]*function\s+(?<method>[A-Za-z_$][\w$]*)\s*\(') |
            ForEach-Object { $_.Groups['method'].Value } |
            Where-Object { $_ }
    )

    $memberAssignmentNames = @(
        [regex]::Matches($sourceText, '(?m)^[ \t]*(?:[A-Za-z_$][\w$]*\.)+(?<method>[A-Za-z_$][\w$]*)\s*=\s*(?:async\s+)?(?:function\s*\(|\([^\r\n]*\)\s*=>|[A-Za-z_$][\w$]*\s*=>)') |
            ForEach-Object { $_.Groups['method'].Value } |
            Where-Object { $_ }
    )

    $methodNames = @($functionDeclarationNames + $memberAssignmentNames)

    return [string[]]@($methodNames | Sort-Object -Unique)
}
