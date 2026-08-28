function Get-PowerPlatformCheckerFlow {
    <#
    .SYNOPSIS
        Returns documentation-oriented metadata for flows in a solution.

    .DESCRIPTION
        Retrieves summary flow metadata for cloud and desktop flows. Optional
        detail sections such as parameters, actions, and connector tiers can be
        requested through the Properties parameter.

    .PARAMETER SolutionPath
        Root path of the unpacked solution.

    .PARAMETER Name
        Optional wildcard filter for flow name.

    .PARAMETER Id
        Optional exact flow id filter.

    .PARAMETER Properties
        Optional metadata sections to include.

    .EXAMPLE
        Return summary metadata for all flows in a solution.

        PS> Get-PowerPlatformCheckerFlow -SolutionPath "C:\Solutions\MySolution"

    .EXAMPLE
        Return one flow with parameters and connector tiers.

        PS> Get-PowerPlatformCheckerFlow -SolutionPath "C:\Solutions\MySolution" -Name "My Flow" -Properties Parameters,ConnectorTiers
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'ByName')]
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'ById')]
        [string] $SolutionPath,

        [Parameter(Mandatory = $false, Position = 2, ParameterSetName = 'ByName')]
        [Alias('FlowName')]
        [string] $Name = '*',

        [Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'ById')]
        [Alias('FlowId')]
        [string] $Id,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Parameters', 'Actions', 'ConnectorTiers', 'Trigger')]
        [string[]] $Properties = @('Parameters', 'Actions', 'ConnectorTiers', 'Trigger')
    )

    $telemetryProperties = @{
        ParameterSet = $PSCmdlet.ParameterSetName
        NameFilterUsed = ($PSCmdlet.ParameterSetName -eq 'ByName' -and $Name -ne '*')
        PropertyCount = if ($PSBoundParameters.ContainsKey('Properties')) { @($Properties).Count } else { 0 }
    }
    Send-THEvent -ModuleName 'PowerPlatformChecker' -EventName 'Get-PowerPlatformCheckerFlow' -PropertiesHash $telemetryProperties

    $xmlPaths = @()
    if ($PSCmdlet.ParameterSetName -eq 'ById') {
        $xmlPaths = @(Get-PowerPlatformCheckerFlowFile -SolutionPath $SolutionPath -FlowId $Id -Type 'xml')
    }
    elseif ($Name -eq '*') {
        $xmlPaths = @(Get-PowerPlatformCheckerFlowFile -SolutionPath $SolutionPath -Type 'xml')
    }
    else {
        $xmlPaths = @(Get-PowerPlatformCheckerFlowFile -SolutionPath $SolutionPath -FlowName $Name -Type 'xml')
    }

    $results = [System.Collections.Generic.List[object]]::new()
    foreach ($xmlPath in $xmlPaths) {
        if ([string]::IsNullOrWhiteSpace([string]$xmlPath) -or -not (Test-Path -Path $xmlPath)) {
            continue
        }

        $flowXml = Select-Xml -Path $xmlPath -XPath '*'
        $flowId = [string]$flowXml.Node.WorkflowId.Replace('{', '').Replace('}', '')
        $flowName = [string]$flowXml.Node.Name
        $jsonPath = @(Get-PowerPlatformCheckerFlowFile -SolutionPath $SolutionPath -FlowId $flowId -Type 'json' | Select-Object -First 1)
        $flowPath = if (@($jsonPath).Count -gt 0) { [string]$jsonPath[0] } else { '' }
        $flowType = if ([string]::IsNullOrWhiteSpace($flowPath)) { 'Unknown' } else { [string](Get-PowerPlatformCheckerFlowType -Path $flowPath) }

        $flowObject = [ordered]@{
            Id = $flowId
            Name = $flowName
            Description = if ($flowXml.Node.Description) { [string]$flowXml.Node.Description } else { '' }
            FlowType = $flowType
        }

        $includeParameters = $Properties -contains 'Parameters'
        $includeActions = $Properties -contains 'Actions'
        $includeConnectorTiers = $Properties -contains 'ConnectorTiers'
        $includeTrigger = $Properties -contains 'Trigger'

        $flowActions = @()
        if (($includeActions -or $includeTrigger) -and -not [string]::IsNullOrWhiteSpace($flowPath)) {
            $flowActions = @(Get-PowerPlatformCheckerFlowActionList -Path $flowPath -Recurse -IncludeTrigger -Properties TriggerProfile,OperationProfile,ResponseProfile,InteractionProfile,ExternalProfile)
        }

        if ($includeParameters -and -not [string]::IsNullOrWhiteSpace($flowPath)) {
            $flowObject['Parameters'] = @(Get-PowerPlatformCheckerFlowParameter -Path $flowPath)
        }
        if ($includeActions -and -not [string]::IsNullOrWhiteSpace($flowPath)) {
            $flowObject['Actions'] = @($flowActions | Where-Object { -not $_.IsTrigger })
        }
        if ($includeTrigger -and -not [string]::IsNullOrWhiteSpace($flowPath)) {
            $flowObject['Trigger'] = @($flowActions | Where-Object { $_.IsTrigger })
        }
        if ($includeConnectorTiers -and -not [string]::IsNullOrWhiteSpace($flowPath)) {
            $flowObject['ConnectorTiers'] = @(Get-PowerPlatformCheckerFlowConnectorTier -Path $flowPath)
        }

        [void]$results.Add([pscustomobject]$flowObject)
    }

    return @($results | Sort-Object Name, Id -Unique)
}
