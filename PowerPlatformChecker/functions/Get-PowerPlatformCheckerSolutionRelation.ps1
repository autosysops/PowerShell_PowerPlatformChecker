function Get-PowerPlatformCheckerSolutionRelation {
    <#
    .SYNOPSIS
        This function retrieves the relationships from a Power Platform solution. It reads the relationship XML files and returns an object with the relationship name, source, target and type.

    .DESCRIPTION
        This function retrieves the relationships from a Power Platform solution. It reads the relationship XML files and returns an object with the relationship name, source, target and type.

    .PARAMETER SolutionPath
        The file path to the Power Platform solution.

    .EXAMPLE
        Get the relationships for a Power Platform solution.

        PS> Get-PowerPlatformCheckerSolutionRelation -SolutionPath "C:\Solutions\MySolution"
    #>

    [CmdLetBinding()]
    [OutputType([Object[]])]
    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [String] $SolutionPath
    )

    # Send telemetry data
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerSolutionRelation"

    # Create an array to return
    $returnObject = @()

    # Get the relation files
    $relationFiles = Get-PowerPlatformCheckerRelationFile -SolutionPath $SolutionPath

    foreach ($relationFile in $relationFiles) {
        # Load the XML file
        $relations = Select-Xml -Path $relationFile -XPath "*"

        # Loop for every relation and return the name, source, target and type of relation
        foreach ($relation in $relations.Node.EntityRelationship) {
            # Store the relation in the object
            $returnObject += [pscustomobject]@{
                Name   = $relation.Name
                Source = $relation.ReferencingEntityName
                Target = $relation.ReferencedEntityName
                Type   = $relation.EntityRelationshipType
            }
        }
    }

    # Return the object
    return $returnObject

}