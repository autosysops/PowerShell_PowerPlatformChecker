function Get-PowerPlatformCheckerCanvasApp {
    <#
    .SYNOPSIS
        This function retrieves the canvas apps from a Power Platform solution. It reads the canvas app XML files and returns an object with the canvas app display name, description, publisher, connection references and data sources.

    .DESCRIPTION
        This function retrieves the canvas apps from a Power Platform solution. It reads the canvas app XML files and returns an object with the canvas app display name, description, publisher, connection references and data sources. If a specific canvas app display name is provided, it will return only the canvas apps matching that name.

    .PARAMETER SolutionPath
        The file path to the Power Platform solution.

    .PARAMETER CanvasAppDisplayName
        The display name of the canvas app to retrieve. If not specified, information for all canvas apps will be returned.

    .EXAMPLE
        Get the canvas app information for all canvas apps in a Power Platform solution.

        PS> Get-PowerPlatformCheckerCanvasApp -SolutionPath "C:\Solutions\MySolution"

    .EXAMPLE
        Get the canvas app information for a specific canvas app in a Power Platform solution.

        PS> Get-PowerPlatformCheckerCanvasApp -SolutionPath "C:\Solutions\MySolution" -CanvasAppDisplayName "My Canvas App"
    #>

    [CmdLetBinding()]
    [OutputType([Object[]])]
    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [String] $SolutionPath,

        [Parameter(Mandatory = $false, Position = 2)]
        [String] $CanvasAppDisplayName
    )

    # Send telemetry data (captures whether filtering was used, not actual names).
    $telemetryProperties = @{
        CanvasAppFilterUsed = (-not [string]::IsNullOrWhiteSpace($CanvasAppDisplayName))
    }
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerCanvasApp" -PropertiesHash $telemetryProperties

    $canvasAppRoot = Join-Path $SolutionPath "CanvasApps"
    $canvasFiles = @()
    if (Test-Path -Path $canvasAppRoot) {
        $canvasFiles = @(Get-ChildItem -Path (Join-Path $canvasAppRoot "*.meta.xml") -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)
    }

    # Create a empty return object
    $returnObject = @()

    # Loop through all files and read the xml files. Take the name and attributes and return them in a object where the attributes are an array
    foreach ($file in $canvasFiles) {
        $xmlfile = Select-Xml -Path $file -XPath "*"

        if($xmlfile.Node.DisplayName -like $CanvasAppDisplayName -or $CanvasAppDisplayName -eq "") {

            $fallbackName = [System.IO.Path]::GetFileNameWithoutExtension($file)
            $appName = if ([string]::IsNullOrWhiteSpace([string]$xmlfile.Node.Name)) { $fallbackName } else { [string]$xmlfile.Node.Name }
            $appDisplayName = if ([string]::IsNullOrWhiteSpace([string]$xmlfile.Node.DisplayName)) { $appName } else { [string]$xmlfile.Node.DisplayName }

            # Get all the data sources
            $dataSources = @()
            $databaseReferences = $xmlfile.Node.DatabaseReferences | ConvertFrom-Json
            foreach($db in ($databaseReferences | Get-Member -MemberType NoteProperty).Name) {
                $dataSources += [PSCustomObject]@{
                    Database = $db
                    DataSources = ($databaseReferences.$db.DataSources | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                        [PSCustomObject]@{
                            Name = $_
                            entitySetName = $databaseReferences.$db.DataSources.$_.entitySetName
                            logicalName = $databaseReferences.$db.DataSources.$_.logicalName
                        }
                    })
                }
            }

            # Get all the connection references
            $connectionReferencesJson = $xmlfile.Node.ConnectionReferences | ConvertFrom-Json
            $connectionReferenceNames = $connectionReferencesJson | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
            $connectionReferences = foreach ($connectionReferenceName in $connectionReferenceNames) {
                $connectionReferencesJson.$connectionReferenceName | Select-Object id, xrmConnectionReferenceLogicalName, displayName
            }

            $returnObject += [PSCustomObject]@{
                Name = $appName
                DisplayName = $appDisplayName
                Description = $xmlfile.Node.Description
                Publisher = $xmlfile.Node.Publisher
                ConnectionReferences = $connectionReferences
                DataSources = $dataSources
            }
        }
    }

    # Return the object
    return $returnObject
}