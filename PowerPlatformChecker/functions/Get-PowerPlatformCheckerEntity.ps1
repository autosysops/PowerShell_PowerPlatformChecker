function Get-PowerPlatformCheckerEntity {
    <#
    .SYNOPSIS
        Gets the entity information from a Power Platform solution.

    .DESCRIPTION
        This function retrieves the entity information from a Power Platform solution. It reads the entity XML files and returns an object with the entity name and its attributes.

    .PARAMETER SolutionPath
        The file path to the Power Platform solution.

    .PARAMETER EntityName
        The name of the entity to retrieve. If not specified, information for all entities will be returned.

    .PARAMETER Relations
        If specified, the relations of the entities will also be retrieved and added to the return object.

    .EXAMPLE
        Get the entity information for all entities in a Power Platform solution.

        PS> Get-PowerPlatformCheckerEntity -SolutionPath "C:\Solutions\MySolution"

    .EXAMPLE
        Get the entity information for a specific entity in a Power Platform solution.

        PS> Get-PowerPlatformCheckerEntity -SolutionPath "C:\Solutions\MySolution" -EntityName "MyEntity"
    #>

    [CmdLetBinding()]
    [OutputType([Object[]])]
    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [String] $SolutionPath,

        [Parameter(Mandatory = $false, Position = 2)]
        [String] $EntityName,

        [Parameter(Mandatory = $false, Position = 4)]
        [Switch] $Relations
    )

    # Send telemetry data
    $telemetryProperties = @{
        EntityFilterUsed = (-not [string]::IsNullOrWhiteSpace($EntityName))
        IncludeRelations = $Relations.IsPresent
    }
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerEntity" -PropertiesHash $telemetryProperties

    $entityRoot = Join-Path $SolutionPath "Entities"
    $entityNamePattern = if ([string]::IsNullOrWhiteSpace($EntityName)) { "*" } else { $EntityName }
    $entityFiles = @()
    if (Test-Path -Path $entityRoot) {
        $entityFiles = @(Get-ChildItem -Path (Join-Path $entityRoot "*\Entity.xml") -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Directory.Name -like $entityNamePattern } |
                Select-Object -ExpandProperty FullName)
    }

    # Create a empty return object
    $returnObject = @()

    # If the relation switch is on, get the relations and add them to the return object
    if($Relations) {
        $relationlist = Get-PowerPlatformCheckerSolutionRelation -SolutionPath $SolutionPath
    }

    # Parse form XML script usage once so entity output can expose direct form library links.
    $entityFormWebResources = @{}
    foreach ($entry in @(Get-PowerPlatformCheckerEntityFormXmlWebResource -SolutionPath $SolutionPath -EntityName ($(if ($EntityName) { $EntityName } else { "*" })))) {
        if ($entry -and $entry.EntitySchemaName) {
            $entityFormWebResources[[string]$entry.EntitySchemaName.ToLower()] = @($entry.WebResources)
        }
    }

    # Loop through all files and read the xml files. Take the name and attributes and return them in a object where the attributes are an array
    foreach ($file in $entityFiles) {
        $xmlfile = Select-Xml -Path $file -XPath "*"
        $attributes = @()
        foreach ($attribute in $xmlfile.Node.EntityInfo.entity.attributes.attribute) {
            $attributes += [PSCustomObject]@{
                Name = $attribute.Name
                DisplayName = $attribute.displaynames.displayname.description
                Desription = $attribute.descriptions.description.description
                Type = $attribute.Type
            }
        }

        $entityLogicalName = [string]$xmlfile.Node.Name."#text"
        $entityLookupKey = $entityLogicalName.ToLower()
        $formWebResources = if ($entityFormWebResources.ContainsKey($entityLookupKey)) { @($entityFormWebResources[$entityLookupKey]) } else { @() }
        $iconResources = @()
        if (-not [string]::IsNullOrWhiteSpace([string]$xmlfile.Node.EntityInfo.entity.IconVectorName)) {
            $iconResources += [PSCustomObject]@{
                FieldName = 'IconVectorName'
                WebResourceName = [string]$xmlfile.Node.EntityInfo.entity.IconVectorName
            }
        }

        $returnObject += [PSCustomObject]@{
            Name = $xmlfile.Node.Name."#text"
            EntitySetName = $xmlfile.Node.EntityInfo.entity.EntitySetName
            IconVectorName = $xmlfile.Node.EntityInfo.entity.IconVectorName
            IconResources = $iconResources
            Attributes = $attributes
            FormWebResources = $formWebResources
        }

        # If the relation switch is on, add the relations to the return object by filtering for the name in the Source and Target of the relations
        if($Relations) {
            $entityRelations = $relationlist | Where-Object { $_.Source -eq $xmlfile.Node.Name."#text" -or $_.Target -eq $xmlfile.Node.Name."#text" }
            $returnObject[-1] | Add-Member -MemberType NoteProperty -Name "Relations" -Value $entityRelations
        }
    }

    # Return the object
    return $returnObject
}