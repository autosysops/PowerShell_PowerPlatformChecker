function Get-PowerPlatformCheckerModelDrivenApp {
    <#
    .SYNOPSIS
        Retrieves model-driven app metadata from an unpacked Power Platform solution.

    .DESCRIPTION
        Parses app module, sitemap, and form metadata to return model-driven app metadata including
        entities, flow references, and script ownership information.
        The WebResources property contains direct app-component script links only.
        Form library usage is returned per entity in EntityWebResources.

    .PARAMETER SolutionPath
        The root path of the unpacked solution.

    .PARAMETER Name
        Optional wildcard filter on app unique name.

    .EXAMPLE
        Return all model-driven apps from a solution export.

        PS> Get-PowerPlatformCheckerModelDrivenApp -SolutionPath "C:\Solutions\MySolution"

        This includes entity-level form library mappings in EntityWebResources.

    .EXAMPLE
        Return model-driven apps filtered by app unique name.

        PS> Get-PowerPlatformCheckerModelDrivenApp -SolutionPath "C:\Solutions\MySolution" -Name "contoso_*"
    #>

    [CmdletBinding()]
    [OutputType([Object[]])]
    param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $SolutionPath,

        [Parameter(Mandatory = $false, Position = 2)]
        [Alias('AppName')]
        [string] $Name = "*"
    )

    if ($MyInvocation.Line -match '(?i)-AppName\b') {
        Write-Warning 'Parameter AppName is deprecated. Use -Name instead.'
    }

    $telemetryProperties = @{
        AppNameFilterUsed = ($Name -ne "*")
    }
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerModelDrivenApp" -PropertiesHash $telemetryProperties

    $appModuleRoot = Join-Path $SolutionPath "AppModules"
    if (-not (Test-Path -Path $appModuleRoot)) {
        return @()
    }

    # AppModule files are the authoritative metadata source for model-driven app composition.
    $appFiles = Get-ChildItem -Path $appModuleRoot -Recurse -File -Filter "AppModule*.xml"

    $results = foreach ($appFile in $appFiles) {
        try {
        # Parse top-level app metadata first so we can skip quickly on filter mismatches.
        $xml = Select-Xml -Path $appFile.FullName -XPath "*" -ErrorAction Stop
        $uniqueName = [string] $xml.Node.UniqueName

        if (-not $uniqueName -or $uniqueName -notlike $Name) {
            continue
        }

        $displayName = [string] ($xml.Node.LocalizedNames.LocalizedName | Select-Object -First 1).description
        if (-not $displayName) {
            $displayName = $uniqueName
        }

        # Split component types so diagrams can draw table/entity refs, flow refs, and script refs.
        $components = @($xml.Node.AppModuleComponents.AppModuleComponent)
        $typedComponents = @(
            foreach ($component in @($components)) {
                $componentTypeCode = 0
                [void][int]::TryParse([string]$component.type, [ref]$componentTypeCode)

                [PSCustomObject]@{
                    ComponentType = $componentTypeCode
                    ComponentTypeName = Get-PowerPlatformCheckerAppComponentType -Type $componentTypeCode
                    SchemaName = [string]$component.schemaName
                    Id = [string]$component.id
                }
            }
        )

        $componentEntities = @($typedComponents | Where-Object { $_.ComponentType -eq 1 -and $_.SchemaName } | ForEach-Object { [string] $_.SchemaName })
        $componentFlowIds = @($typedComponents | Where-Object { $_.ComponentType -eq 29 -and $_.Id } | ForEach-Object { ([string] $_.Id).Trim("{}") })
        $componentWebResources = @($typedComponents | Where-Object { $_.SchemaName -and $_.SchemaName -like "*.js" } | ForEach-Object { [string] $_.SchemaName })

        # Read entity form-script ownership from FormXML so model app output only keeps direct app links.
        $entityDetails = @(
            foreach ($entityName in @($componentEntities | Sort-Object -Unique | Where-Object { $_ })) {
                Get-PowerPlatformCheckerEntityFormXmlWebResource -SolutionPath $SolutionPath -EntityName $entityName
            }
        )

        $entityWebResourceMap = @{}
        foreach ($entityDetail in @($entityDetails)) {
            if (-not $entityDetail -or -not $entityDetail.EntitySchemaName) {
                continue
            }

            $entityKey = [string]$entityDetail.EntitySchemaName.ToLower()
            $entityWebResourceMap[$entityKey] = @($entityDetail.WebResources | Where-Object { $_ } | Sort-Object -Unique)
        }

        # Site map can include extra entities that are not listed directly in app components.
        $siteMapEntities = @()
        $siteMapFolder = Join-Path (Join-Path $SolutionPath "AppModuleSiteMaps") $uniqueName
        if (Test-Path -Path $siteMapFolder) {
            $siteMapFile = Get-ChildItem -Path $siteMapFolder -File -Filter "AppModuleSiteMap*.xml" | Select-Object -First 1
            if ($siteMapFile) {
                try {
                    $siteMapXml = Select-Xml -Path $siteMapFile.FullName -XPath "*" -ErrorAction Stop
                    $siteMapEntities = @($siteMapXml.Node.SiteMap.Area.Group.SubArea | Where-Object { $_.Entity } | ForEach-Object { [string] $_.Entity })
                }
                catch {
                    Write-Warning "Invalid model-driven app sitemap metadata skipped."
                    $siteMapEntities = @()
                }
            }
        }

        # Preserve entity -> script mappings so architecture rendering can chain App -> Entity -> Script.
        $entityWebResources = @(
            $entityWebResourceMap.Keys |
                Sort-Object |
                ForEach-Object {
                    [PSCustomObject]@{
                        EntitySchemaName = $_
                        WebResources = @($entityWebResourceMap[$_] | Sort-Object -Unique)
                    }
                }
        )

        [PSCustomObject]@{
            AppType = Get-PowerPlatformCheckerAppType -Path $appFile.FullName
            UniqueName = $uniqueName
            DisplayName = $displayName
            Entities = @($componentEntities + $siteMapEntities | Sort-Object -Unique)
            SiteMapEntities = @($siteMapEntities | Sort-Object -Unique)
            FlowIds = @($componentFlowIds | Sort-Object -Unique)
            # Keep only direct app component script links here; entity/form ownership is exposed via EntityWebResources.
            WebResources = @($componentWebResources | Sort-Object -Unique)
            EntityWebResources = $entityWebResources
            Components = $typedComponents
            MermaidId = Convert-PowerPlatformCheckerMermaidId -InputString $uniqueName
        }
        }
        catch {
            Write-Warning "Invalid model-driven app metadata file skipped."
            continue
        }
    }

    return @($results)
}

