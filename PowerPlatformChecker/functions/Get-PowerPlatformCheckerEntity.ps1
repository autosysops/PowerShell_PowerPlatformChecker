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
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerEntity"

    # Get the right file
    $entityfiles = Get-PowerPlatformCheckerEntityFile -SolutionPath $SolutionPath -EntityName $EntityName

    # Create a empty return object
    $returnObject = @()

    # If the relation switch is on, get the relations and add them to the return object
    if($Relations) {
        $relationlist = Get-PowerPlatformCheckerSolutionRelation -SolutionPath $SolutionPath
    }

    # Loop through all files and read the xml files. Take the name and attributes and return them in a object where the attributes are an array
    foreach ($file in $entityfiles) {
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

        $returnObject += [PSCustomObject]@{
            Name = $xmlfile.Node.Name."#text"
            EntitySetName = $xmlfile.Node.EntityInfo.entity.EntitySetName
            Attributes = $attributes
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