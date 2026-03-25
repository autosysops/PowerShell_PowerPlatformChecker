function Get-PowerPlatformCheckerSolutionObject {
    <#
    .SYNOPSIS
        Gets a Power Platform solution object

    .DESCRIPTION
        This function retrieves a Power Platform solution object, including its workflows, environment variables, and connection references

    .PARAMETER SolutionPath
        The file path to the Power Platform solution

    .EXAMPLE
        Get a Power Platform solution object

        PS> Get-PowerPlatformCheckerSolutionObject -SolutionPath "C:\Solutions\MySolution"
    #>

    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [String] $SolutionPath
    )

    # Send telemetry data
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerSolutionObject"

    # Create the object to return
    $solutionObject = [PSCustomObject] @{}

    # Get the flows in the solution
    $solutionFlows = @()

    Get-PowerPlatformCheckerFlowFile -SolutionPath $SolutionPath -Type "xml" | `
    Foreach-Object {
        $flowXml = Select-Xml -Path $_ -XPath "*"
        $solutionFlows += [PSCustomObject]@{
            Id = $flowXml.Node.WorkflowId.replace("{", "").replace("}", "")
            Name = $flowXml.Node.Name
            Category = (Get-PowerPlatformCheckerFlowCategory -CategoryId $flowXml.Node.Category)
        }
    }

    if($solutionFlows.Count -gt 0) {
        $solutionObject | Add-Member -MemberType NoteProperty -Name "Workflows" -Value $solutionFlows
    }

    # Get the environmental variables
    $solutionEnvVars = @()

    Get-PowerPlatformCheckerEnvVarFile -SolutionPath $SolutionPath | `
    Foreach-Object {
        $envVarXml = Select-Xml -Path $_ -XPath "*"
        $solutionEnvVars += [PSCustomObject]@{
            Name = $envVarXml.Node.schemaname
        }
    }

    if($solutionEnvVars.Count -gt 0) {
        $solutionObject | Add-Member -MemberType NoteProperty -Name "EnvironmentVariables" -Value $solutionEnvVars
    }

    # Get the connection references
    $solutionConnectionReferences = @()

    $customizationXml = Select-Xml -Path (Join-Path $SolutionPath "Other/Customizations.xml") -XPath "*"
    $customizationXml.node.connectionreferences.connectionreference | ForEach-Object {
        $solutionConnectionReferences += [PSCustomObject]@{
            ConnectorId = $_.connectorid
            DisplayName = $_.connectionreferencedisplayname
        }
    }

    if($solutionConnectionReferences.Count -gt 0) {
        $solutionObject | Add-Member -MemberType NoteProperty -Name "ConnectionReferences" -Value $solutionConnectionReferences
    }

    # return the solution object
    return $solutionObject
}