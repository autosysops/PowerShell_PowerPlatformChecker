function Get-PowerPlatformCheckerEntityFormXmlWebResource {
    <#
    .SYNOPSIS
        Extracts JavaScript form library usage per entity from FormXML files.

    .DESCRIPTION
        Scans entity FormXml folders and returns the JavaScript web resources referenced
        by form library declarations and event handlers.

    .PARAMETER SolutionPath
        The root path of the unpacked solution.

    .PARAMETER EntityName
        Optional wildcard filter for entity schema names.

    .EXAMPLE
        Return FormXML web resource usage for all entities.

        PS> Get-PowerPlatformCheckerEntityFormXmlWebResource -SolutionPath "C:\Solutions\MySolution"
    #>

    [CmdletBinding()]
    [OutputType([Object[]])]
    param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $SolutionPath,

        [Parameter(Mandatory = $false, Position = 2)]
        [string] $EntityName = "*"
    )

    $telemetryProperties = @{
        EntityFilterUsed = ($EntityName -ne "*")
    }
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerEntityFormXmlWebResource" -PropertiesHash $telemetryProperties

    $entitiesRoot = Join-Path $SolutionPath "Entities"
    if (-not (Test-Path -Path $entitiesRoot)) {
        return @()
    }

    $results = foreach ($entityFolder in @(Get-ChildItem -Path $entitiesRoot -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like $EntityName })) {
        $formFolder = Join-Path $entityFolder.FullName "FormXml"
        if (-not (Test-Path -Path $formFolder)) {
            continue
        }

        $scripts = @()
        foreach ($formFile in @(Get-ChildItem -Path $formFolder -Recurse -File -Filter "*.xml" -ErrorAction SilentlyContinue)) {
            try {
                $formContent = Get-Content -Path $formFile.FullName -Raw -ErrorAction Stop
                # Capture both <Library name="...js"> and handler libraryName="...js" values.
                $scripts += @(
                    [regex]::Matches($formContent, '(?:libraryName|name)="([^"]+\.js)"') |
                        ForEach-Object { $_.Groups[1].Value } |
                        Where-Object { $_ }
                )
            }
            catch {
                continue
            }
        }

        if ($scripts.Count -gt 0) {
            [PSCustomObject]@{
                EntitySchemaName = [string]$entityFolder.Name.ToLower()
                WebResources = @($scripts | Sort-Object -Unique)
            }
        }
    }

    return @($results)
}
