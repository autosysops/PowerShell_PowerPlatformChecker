function Get-PowerPlatformCheckerWebResource {
    <#
    .SYNOPSIS
        Retrieves web resources from an unpacked Power Platform solution.

    .DESCRIPTION
        Reads web resource metadata files from a solution export and returns normalized
        information including name, display name, type, dependencies, and a Mermaid-safe class id.

    .PARAMETER SolutionPath
        The root path of the unpacked solution.

    .PARAMETER Name
        Optional wildcard filter on resource name.

    .PARAMETER JavaScriptOnly
        If set, only JavaScript web resources are returned.

    .EXAMPLE
        Return all web resources from a solution export.

        PS> Get-PowerPlatformCheckerWebResource -SolutionPath "C:\Solutions\MySolution"

    .EXAMPLE
        Return only JavaScript web resources from a solution export.

        PS> Get-PowerPlatformCheckerWebResource -SolutionPath "C:\Solutions\MySolution" -JavaScriptOnly
    #>

    [CmdletBinding()]
    [OutputType([Object[]])]
    param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $SolutionPath,

        [Parameter(Mandatory = $false, Position = 2)]
        [string] $Name = "*",

        [Parameter(Mandatory = $false, Position = 3)]
        [switch] $JavaScriptOnly
    )

    $telemetryProperties = @{
        NameFilterUsed = ($Name -ne "*")
        JavaScriptOnly = $JavaScriptOnly.IsPresent
    }
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerWebResource" -PropertiesHash $telemetryProperties

    $webResourcePath = Join-Path $SolutionPath "WebResources"
    if (-not (Test-Path -Path $webResourcePath)) {
        return @()
    }

    # Metadata files contain web resource descriptors including encoded DependencyXml.
    $metadataFiles = Get-ChildItem -Path $webResourcePath -Recurse -File -Filter "*.data.xml"

    $results = foreach ($metadataFile in $metadataFiles) {
        $xml = Select-Xml -Path $metadataFile.FullName -XPath "*"
        if (-not $xml.Node.Name) { continue }

        # Normalize the documented Dataverse web resource type codes in one helper so the
        # getter and diagram code both work from the same type vocabulary.
        $typeCode = 0
        [void][int]::TryParse([string]$xml.Node.WebResourceType, [ref]$typeCode)
        $resourceTypeInfo = Get-PowerPlatformCheckerWebResourceType -Type $typeCode
        $resourceType = [string]$resourceTypeInfo.Name
        $resourceKind = [string]$resourceTypeInfo.Kind

        if ($JavaScriptOnly -and $resourceType -ne "JavaScript") {
            continue
        }

        if ($xml.Node.Name -notlike $Name) {
            continue
        }

        $sourcePath = Join-Path $metadataFile.DirectoryName ($metadataFile.BaseName -replace '\.data$','')
        if ($resourceType -eq "JavaScript") {
            $methodNames = @(Get-PowerPlatformCheckerWebResourceJavaScriptMethod -SourcePath $sourcePath)
        }
        else {
            $methodNames = @()
        }

        # DependencyXml is HTML-encoded inside metadata; decode then parse inner XML structure.
        $dependencies = @()
        if ($xml.Node.DependencyXml) {
            try {
                $dependencyXmlText = [System.Net.WebUtility]::HtmlDecode([string] $xml.Node.DependencyXml)
                [xml] $dependencyXml = $dependencyXmlText
                # Library nodes contain the canonical script names used for dependency links.
                $dependencies = @($dependencyXml.Dependencies.Dependency.Library | ForEach-Object { $_.name } | Where-Object { $_ })
            }
            catch {
                # Keep function resilient when dependency metadata is malformed.
                $dependencies = @()
            }
        }

        [PSCustomObject]@{
            Name = [string] $xml.Node.Name
            DisplayName = [string] $xml.Node.DisplayName
            Type = $resourceType
            Kind = $resourceKind
            TypeCode = $typeCode
            FileName = [string] $xml.Node.FileName
            Dependencies = $dependencies
            Methods = $methodNames
            SourcePath = $sourcePath
            MermaidId = Convert-PowerPlatformCheckerMermaidId -InputString ([string] $xml.Node.Name)
        }
    }

    return @($results)
}

