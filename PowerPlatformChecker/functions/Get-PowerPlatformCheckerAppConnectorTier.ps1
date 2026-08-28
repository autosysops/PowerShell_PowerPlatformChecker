function Get-PowerPlatformCheckerAppConnectorTier {
    <#
    .SYNOPSIS
        Returns connector tiers used by canvas and model-driven apps.

    .DESCRIPTION
        Produces connector/tier inventories for app assets. Canvas connectors are
        read from app connection references; model-driven connectors are derived
        from flows linked to each app.

    .PARAMETER SolutionPath
        Path to the unpacked solution.

    .PARAMETER Name
        Optional wildcard filter for app name/display name.

    .EXAMPLE
        Get connector tier data for all discovered apps in a solution.

        PS> Get-PowerPlatformCheckerAppConnectorTier -SolutionPath "C:\Solutions\MySolution"
    #>

    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $SolutionPath,

        [Parameter(Mandatory = $false, Position = 2)]
        [string] $Name = '*'
    )

    $telemetryProperties = @{
        AppNameFilterUsed = ($Name -ne '*')
    }
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerAppConnectorTier" -PropertiesHash $telemetryProperties

    $rows = [System.Collections.Generic.List[object]]::new()
    $workflowFiles = @(Get-ChildItem -Path (Join-Path $SolutionPath 'Workflows') -Filter '*.json' -File -ErrorAction SilentlyContinue)

    foreach ($canvasApp in @(Get-PowerPlatformCheckerApp -SolutionPath $SolutionPath -Name $Name -AppType CanvasApp -Properties ConnectionReferences)) {
        if ($null -eq $canvasApp) {
            continue
        }

            foreach ($connectionReference in @($canvasApp.ConnectionReferences)) {
                if ($null -eq $connectionReference -or [string]::IsNullOrWhiteSpace([string]$connectionReference.id)) {
                    continue
                }

                $connectorApiName = [string]$connectionReference.id
                if ($connectorApiName -like '*/apis/*') {
                    $connectorApiName = $connectorApiName.Split('/')[-1]
                }

                $connectorData = @(Get-PowerPlatformCheckerConnectorData -Name $connectorApiName | Select-Object -First 1)
                if (@($connectorData).Count -eq 0 -and $connectorApiName -like 'shared_*') {
                    $connectorData = @(Get-PowerPlatformCheckerConnectorData -Name ($connectorApiName -replace '^shared_', '') | Select-Object -First 1)
                }

                [void]$rows.Add([pscustomobject]@{
                        AppType = 'CanvasApp'
                        AppName = [string]$canvasApp.Name
                        AppDisplayName = [string]$canvasApp.DisplayName
                        ConnectorName = $connectorApiName
                        ConnectorDisplayName = if (@($connectorData).Count -gt 0) { [string]$connectorData[0].displayname } else { [string]$connectionReference.displayName }
                        Tier = if (@($connectorData).Count -gt 0) { [string]$connectorData[0].tier } else { '' }
                        Source = 'ConnectionReference'
                    })
            }
        }

    foreach ($modelApp in @(Get-PowerPlatformCheckerApp -SolutionPath $SolutionPath -Name $Name -AppType ModelDrivenApp -Properties FlowIds)) {
        if ($null -eq $modelApp) {
            continue
        }

            $modelFlowIds = @($modelApp.FlowIds | Where-Object { $_ } | ForEach-Object { ([string]$_).ToLowerInvariant() })
            foreach ($flowFile in $workflowFiles) {
                if (-not ($flowFile.BaseName -match '(?<id>[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})')) {
                    continue
                }

                $flowId = [string]$matches['id']
                if ($modelFlowIds -notcontains $flowId.ToLowerInvariant()) {
                    continue
                }

                foreach ($connector in @(Get-PowerPlatformCheckerFlowConnectorTier -Path $flowFile.FullName)) {
                    [void]$rows.Add([pscustomobject]@{
                            AppType = 'ModelDrivenApp'
                            AppName = [string]$modelApp.Name
                            AppDisplayName = [string]$modelApp.DisplayName
                            ConnectorName = [string]$connector.Name
                            ConnectorDisplayName = [string]$connector.DisplayName
                            Tier = [string]$connector.Tier
                            Source = 'ReferencedFlow'
                        })
                }
            }
    }

    return @($rows | Sort-Object AppType, AppName, ConnectorName -Unique)
}
