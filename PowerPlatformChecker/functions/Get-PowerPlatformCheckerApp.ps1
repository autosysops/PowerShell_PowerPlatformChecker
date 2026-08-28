function Get-PowerPlatformCheckerApp {
    <#
    .SYNOPSIS
        Returns documentation-oriented metadata for apps in a solution.

    .DESCRIPTION
        Retrieves both canvas and model-driven app metadata through one command.
        Summary fields are returned by default, while larger nested sections can be
        requested through the Properties parameter.

    .PARAMETER SolutionPath
        Root path of the unpacked solution.

    .PARAMETER Name
        Optional wildcard filter for app internal name or display name.

    .PARAMETER AppType
        Optional app-type filter.

    .PARAMETER Properties
        Optional metadata sections to include.

    .EXAMPLE
        Return summary metadata for all apps in a solution.

        PS> Get-PowerPlatformCheckerApp -SolutionPath "C:\Solutions\MySolution"

    .EXAMPLE
        Return only model-driven apps with entity and flow metadata.

        PS> Get-PowerPlatformCheckerApp -SolutionPath "C:\Solutions\MySolution" -AppType ModelDrivenApp -Properties Entities,FlowIds
    #>

    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $SolutionPath,

        [Parameter(Mandatory = $false, Position = 2)]
        [Alias('CanvasAppDisplayName', 'AppName')]
        [string] $Name = '*',

        [Parameter(Mandatory = $false)]
        [ValidateSet('CanvasApp', 'ModelDrivenApp')]
        [string[]] $AppType = @('CanvasApp', 'ModelDrivenApp'),

        [Parameter(Mandatory = $false)]
        [ValidateSet('Publisher', 'Description', 'ConnectionReferences', 'DataSources', 'Entities', 'FlowIds', 'WebResources', 'EntityWebResources', 'Components', 'Dependencies')]
        [string[]] $Properties = @('Publisher', 'Description', 'ConnectionReferences', 'DataSources', 'Entities', 'FlowIds', 'WebResources', 'EntityWebResources', 'Components', 'Dependencies')
    )

    if ($MyInvocation.Line -match '(?i)-CanvasAppDisplayName\b') {
        Write-Warning 'Parameter CanvasAppDisplayName is deprecated. Use -Name instead.'
    }

    if ($MyInvocation.Line -match '(?i)-AppName\b') {
        Write-Warning 'Parameter AppName is deprecated. Use -Name instead.'
    }

    $telemetryProperties = @{
        NameFilterUsed = ($Name -ne '*')
        AppTypeCount = @($AppType).Count
        PropertyCount = if ($PSBoundParameters.ContainsKey('Properties')) { @($Properties).Count } else { 0 }
    }
    Send-THEvent -ModuleName 'PowerPlatformChecker' -EventName 'Get-PowerPlatformCheckerApp' -PropertiesHash $telemetryProperties

    $results = [System.Collections.Generic.List[object]]::new()

    if (@($AppType) -contains 'CanvasApp') {
        foreach ($canvasApp in @(Get-PowerPlatformCheckerCanvasApp -SolutionPath $SolutionPath -Name $Name)) {
            if ($null -eq $canvasApp) {
                continue
            }

            $appObject = [ordered]@{
                AppType = 'CanvasApp'
                Name = [string]$canvasApp.Name
                DisplayName = [string]$canvasApp.DisplayName
            }

            if ($Properties -contains 'Description') {
                $appObject['Description'] = [string]$canvasApp.Description
            }
            if ($Properties -contains 'Publisher') {
                $appObject['Publisher'] = [string]$canvasApp.Publisher
            }
            if ($Properties -contains 'ConnectionReferences') {
                $appObject['ConnectionReferences'] = @($canvasApp.ConnectionReferences)
            }
            if ($Properties -contains 'DataSources') {
                $appObject['DataSources'] = @($canvasApp.DataSources)
            }
            if ($Properties -contains 'Dependencies') {
                $appObject['Dependencies'] = [pscustomobject]@{
                    Connections = @($canvasApp.ConnectionReferences)
                    DataSources = @($canvasApp.DataSources)
                }
            }

            [void]$results.Add([pscustomobject]$appObject)
        }
    }

    if (@($AppType) -contains 'ModelDrivenApp') {
        foreach ($modelApp in @(Get-PowerPlatformCheckerAppModelDriven -SolutionPath $SolutionPath -Name $Name)) {
            if ($null -eq $modelApp) {
                continue
            }

            $appObject = [ordered]@{
                AppType = 'ModelDrivenApp'
                Name = [string]$modelApp.UniqueName
                DisplayName = [string]$modelApp.DisplayName
            }

            if ($Properties -contains 'Description') {
                $appObject['Description'] = ''
            }
            if ($Properties -contains 'Publisher') {
                $appObject['Publisher'] = ''
            }
            if ($Properties -contains 'Entities') {
                $appObject['Entities'] = @($modelApp.Entities)
            }
            if ($Properties -contains 'FlowIds') {
                $appObject['FlowIds'] = @($modelApp.FlowIds)
            }
            if ($Properties -contains 'WebResources') {
                $appObject['WebResources'] = @($modelApp.WebResources)
            }
            if ($Properties -contains 'EntityWebResources') {
                $appObject['EntityWebResources'] = @($modelApp.EntityWebResources)
            }
            if ($Properties -contains 'Components') {
                $appObject['Components'] = @($modelApp.Components)
            }
            if ($Properties -contains 'Dependencies') {
                $appObject['Dependencies'] = [pscustomobject]@{
                    Entities = @($modelApp.Entities)
                    Flows = @($modelApp.FlowIds)
                    WebResources = @($modelApp.WebResources)
                    EntityWebResources = @($modelApp.EntityWebResources)
                }
            }

            [void]$results.Add([pscustomobject]$appObject)
        }
    }

    return @($results | Sort-Object AppType, Name)
}
