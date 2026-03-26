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
        [String] $EntityName
    )

    # Send telemetry data
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerEntity"

    # Get the right file
    $entityfiles = Get-PowerPlatformCheckerEntityFile -SolutionPath $SolutionPath -EntityName $EntityName

    # Create a empty return object
    $returnObject = @()

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
            Attributes = $attributes
        }
    }

    # Return the object
    return $returnObject
}