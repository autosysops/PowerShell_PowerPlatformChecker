function Get-PowerPlatformCheckerDefaultEntityFieldName {
    <#
    .SYNOPSIS
        Returns default Dataverse/system field names.

    .DESCRIPTION
        Provides the baseline set of Dataverse/system-maintained entity fields that are often
        filtered out from architecture diagrams to reduce noise.

    .EXAMPLE
        Return default entity fields used in architecture filtering.

        PS> Get-PowerPlatformCheckerDefaultEntityFieldName
    #>

    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    return [string[]]@(
        "createdby",
        "createdon",
        "createdonbehalfby",
        "importsequencenumber",
        "modifiedby",
        "modifiedon",
        "modifiedonbehalfby",
        "overriddencreatedon",
        "ownerid",
        "owningbusinessunit",
        "owningteam",
        "owninguser",
        "statecode",
        "statuscode",
        "timezoneruleversionnumber",
        "utcconversiontimezonecode"
    )
}

