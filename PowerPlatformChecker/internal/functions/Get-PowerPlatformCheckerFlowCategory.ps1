function Get-PowerPlatformCheckerFlowCategory {
    <#
    .SYNOPSIS
        Gets the category of a Power Platform flow based on the category id

    .DESCRIPTION
        This function retrieves the category name of a Power Platform flow based on the provided category id.

    .PARAMETER CategoryId
        The id of the category to retrieve.

    .EXAMPLE
        Get the category of a Power Platform flow

        PS> Get-PowerPlatformCheckerFlowCategory -CategoryId 0
    #>

    [CmdLetBinding()]
    [OutputType([String])]
    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [Int] $CategoryId
    )

    # Send telemetry data
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerFlowCategory"

    # Return the name as defined in the workflow EntityType
    switch ($CategoryId) {
        0 { return "Workflow" }
        1 { return "Dialog" }
        2 { return "Business Rule" }
        3 { return "Action" }
        4 { return "Business Process Flow" }
        5 { return "Modern Flow" }
        6 { return "Desktop Flow" }
        7 { return "AI Flow" }
        default { return "Unknown" }
    }
}