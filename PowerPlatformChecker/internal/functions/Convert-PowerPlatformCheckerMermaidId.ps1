function Convert-PowerPlatformCheckerMermaidId {
    <#
    .SYNOPSIS
        Converts arbitrary text to a Mermaid-safe identifier.

    .DESCRIPTION
        Mermaid identifiers cannot reliably contain spaces and several punctuation characters.
        This helper normalizes strings to alphanumeric/underscore identifiers for stable diagrams.

    .PARAMETER InputString
        The raw identifier text.

    .EXAMPLE
        Convert a web resource name to a Mermaid-safe id.

        PS> Convert-PowerPlatformCheckerMermaidId -InputString "ppc_script/OrderForm.js"
        ppc_script_OrderForm_js
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $InputString
    )

    $value = $InputString -replace '[^A-Za-z0-9_]', '_'
    $value = $value -replace '_{2,}', '_'

    if ($value -match '^[0-9]') {
        $value = "id_$value"
    }

    return $value
}

