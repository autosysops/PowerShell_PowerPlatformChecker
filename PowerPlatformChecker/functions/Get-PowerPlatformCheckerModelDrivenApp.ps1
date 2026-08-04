function Get-PowerPlatformCheckerModelDrivenApp {
    <#
    .SYNOPSIS
        Retrieves model-driven app metadata from an unpacked Power Platform solution.

    .DESCRIPTION
        Parses app module and sitemap files to return model-driven app metadata including
        entities, flow references, and referenced web resources.

    .PARAMETER SolutionPath
        The root path of the unpacked solution.

    .PARAMETER AppName
        Optional wildcard filter on app unique name.

    .EXAMPLE
        Return all model-driven apps from a solution export.

        PS> Get-PowerPlatformCheckerModelDrivenApp -SolutionPath "C:\Solutions\MySolution"

    .EXAMPLE
        Return model-driven apps filtered by app unique name.

        PS> Get-PowerPlatformCheckerModelDrivenApp -SolutionPath "C:\Solutions\MySolution" -AppName "contoso_*"
    #>

    [CmdletBinding()]
    [OutputType([Object[]])]
    param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $SolutionPath,

        [Parameter(Mandatory = $false, Position = 2)]
        [string] $AppName = "*"
    )

    $telemetryProperties = @{
        AppNameFilterUsed = ($AppName -ne "*")
    }
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerModelDrivenApp" -PropertiesHash $telemetryProperties

    $appModuleRoot = Join-Path $SolutionPath "AppModules"
    if (-not (Test-Path -Path $appModuleRoot)) {
        return @()
    }

    # AppModule files are the authoritative metadata source for model-driven app composition.
    $appFiles = Get-ChildItem -Path $appModuleRoot -Recurse -File -Filter "AppModule*.xml"

    $results = foreach ($appFile in $appFiles) {
        # Parse top-level app metadata first so we can skip quickly on filter mismatches.
        $xml = Select-Xml -Path $appFile.FullName -XPath "*"
        $uniqueName = [string] $xml.Node.UniqueName

        if (-not $uniqueName -or $uniqueName -notlike $AppName) {
            continue
        }

        $displayName = [string] ($xml.Node.LocalizedNames.LocalizedName | Select-Object -First 1).description
        if (-not $displayName) {
            $displayName = $uniqueName
        }

        # Split component types so diagrams can draw table/entity refs, flow refs, and script refs.
        $components = @($xml.Node.AppModuleComponents.AppModuleComponent)

        $componentEntities = @($components | Where-Object { $_.type -eq "1" -and $_.schemaName } | ForEach-Object { [string] $_.schemaName })
        $componentFlowIds = @($components | Where-Object { $_.type -eq "29" -and $_.id } | ForEach-Object { ([string] $_.id).Trim("{}") })
        $componentWebResources = @($components | Where-Object { $_.schemaName -and $_.schemaName -like "*.js" } | ForEach-Object { [string] $_.schemaName })

        # Site map can include extra entities that are not listed directly in app components.
        $siteMapEntities = @()
        $siteMapFolder = Join-Path (Join-Path $SolutionPath "AppModuleSiteMaps") $uniqueName
        if (Test-Path -Path $siteMapFolder) {
            $siteMapFile = Get-ChildItem -Path $siteMapFolder -File -Filter "AppModuleSiteMap*.xml" | Select-Object -First 1
            if ($siteMapFile) {
                $siteMapXml = Select-Xml -Path $siteMapFile.FullName -XPath "*"
                $siteMapEntities = @($siteMapXml.Node.SiteMap.Area.Group.SubArea | Where-Object { $_.Entity } | ForEach-Object { [string] $_.Entity })
            }
        }

        [PSCustomObject]@{
            UniqueName = $uniqueName
            DisplayName = $displayName
            Entities = @($componentEntities + $siteMapEntities | Sort-Object -Unique)
            SiteMapEntities = @($siteMapEntities | Sort-Object -Unique)
            FlowIds = @($componentFlowIds | Sort-Object -Unique)
            WebResources = @($componentWebResources | Sort-Object -Unique)
            MermaidId = Convert-PowerPlatformCheckerMermaidId -InputString $uniqueName
        }
    }

    return @($results)
}

