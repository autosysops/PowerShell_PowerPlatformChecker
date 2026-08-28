function Get-PowerPlatformCheckerSolutionObject {
    <#
    .SYNOPSIS
        Gets a Power Platform solution object

    .DESCRIPTION
        This function retrieves a Power Platform solution object, including its workflows, environment variables, connection references, and entities

    .PARAMETER SolutionPath
        The file path to the Power Platform solution

    .PARAMETER Properties
        Optional list of solution sections to include. When omitted, all sections
        are returned. Use this to narrow output to specific sections.

    .EXAMPLE
        Get a Power Platform solution object

        PS> Get-PowerPlatformCheckerSolutionObject -SolutionPath "C:\Solutions\MySolution"

    .EXAMPLE
        Get only workflows and entities from a solution.

        PS> Get-PowerPlatformCheckerSolutionObject -SolutionPath "C:\Solutions\MySolution" -Properties Workflows,Entities
    #>

    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [String] $SolutionPath,

        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateSet('Workflows', 'EnvironmentVariables', 'ConnectionReferences', 'Entities', 'CanvasApps', 'ModelDrivenApps', 'WebResources')]
        [String[]] $Properties = @()
    )

    $allProperties = @('Workflows', 'EnvironmentVariables', 'ConnectionReferences', 'Entities', 'CanvasApps', 'ModelDrivenApps', 'WebResources')
    $effectiveProperties = if ($PSBoundParameters.ContainsKey('Properties')) { @($Properties) } else { @($allProperties) }

    # Create the object to return
    $solutionObject = [PSCustomObject] @{}

    # Get the flows in the solution
    if ($effectiveProperties -contains 'Workflows') {
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
    }

    # Get the environmental variables
    if ($effectiveProperties -contains 'EnvironmentVariables') {
        $solutionEnvVars = @()

        $environmentVariableRoot = Join-Path $SolutionPath "environmentvariabledefinitions"
        if (Test-Path -Path $environmentVariableRoot) {
            Get-ChildItem -Path $environmentVariableRoot -Recurse -File -Filter "*.xml" | ForEach-Object {
                $envVarXml = Select-Xml -Path $_.FullName -XPath "*"
                $solutionEnvVars += [PSCustomObject]@{
                    Name = $envVarXml.Node.schemaname
                }
            }
        }

        if($solutionEnvVars.Count -gt 0) {
            $solutionObject | Add-Member -MemberType NoteProperty -Name "EnvironmentVariables" -Value $solutionEnvVars
        }
    }

    # Get the connection references
    if ($effectiveProperties -contains 'ConnectionReferences') {
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
    }

    # Get the entities
    if ($effectiveProperties -contains 'Entities') {
        $solutionEntities = Get-PowerPlatformCheckerEntity -SolutionPath $SolutionPath -Relations

        if($solutionEntities.Count -gt 0) {
            $solutionObject | Add-Member -MemberType NoteProperty -Name "Entities" -Value $solutionEntities
        }
    }

    # Get the Canvas Apps
    if ($effectiveProperties -contains 'CanvasApps') {
        $canvasApps = Get-PowerPlatformCheckerCanvasApp -SolutionPath $SolutionPath

        if($canvasApps.Count -gt 0) {
            $solutionObject | Add-Member -MemberType NoteProperty -Name "CanvasApps" -Value $canvasApps
        }
    }

    # Get the model-driven apps
    if ($effectiveProperties -contains 'ModelDrivenApps') {
        $modelDrivenApps = Get-PowerPlatformCheckerAppModelDriven -SolutionPath $SolutionPath

        if($modelDrivenApps.Count -gt 0) {
            $solutionObject | Add-Member -MemberType NoteProperty -Name "ModelDrivenApps" -Value $modelDrivenApps
        }
    }

    # Get JavaScript web resources
    if ($effectiveProperties -contains 'WebResources') {
        $webResources = Get-PowerPlatformCheckerWebResource -SolutionPath $SolutionPath -JavaScriptOnly

        if($webResources.Count -gt 0) {
            $solutionObject | Add-Member -MemberType NoteProperty -Name "WebResources" -Value $webResources
        }
    }

    # This command currently has one required input and no optional usage shape,
    # so a simple invocation metric is enough to understand adoption.
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerSolutionObject" -PropertiesHash @{}

    # return the solution object
    return $solutionObject
}