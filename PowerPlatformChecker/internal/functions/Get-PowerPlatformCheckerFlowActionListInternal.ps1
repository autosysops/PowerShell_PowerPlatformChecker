function Get-PowerPlatformCheckerFlowActionListInternal {
    <#
    .SYNOPSIS
        Gets a list of actions in a Power Platform flow

    .DESCRIPTION
        Gets a list of actions in a Power Platform flow, if the flow contains nested actions it will get those as well if the recurse switch is used

    .PARAMETER Path
        The file path to the flow json file

    .PARAMETER Actions
        The actions object from the flow json file

    .PARAMETER ParentAction
        The name of the parent action if the current actions are nested

    .PARAMETER Recurse
        A switch to indicate if nested actions should be included in the list

    .PARAMETER IncludeTrigger
        A switch to indicate if the trigger should be included in the list

    .PARAMETER Properties
        A list of additional properties to include in the output, options are References,
        Entities, RunAfter, ParentAction, InteractionProfile, and ExternalProfile

    .PARAMETER IsTrigger
        A switch to indicate if the current actions are triggers, used in combination with the IncludeTrigger switch

    .PARAMETER Depth
        An integer to indicate how deep the action is nested, used for internal purposes when calling recursively

    .PARAMETER DefinitionParameters
        Flow definition parameters used to resolve expression-backed values when
        InteractionProfile or ExternalProfile properties are requested.

    .EXAMPLE
        Get a list of actions in a Power Platform flow

        PS> Get-PowerPlatformCheckerFlowActionListInternal -Actions $flowdata.definition.actions

    .EXAMPLE
        Get a list of actions in a Power Platform flow including nested actions

        PS> Get-PowerPlatformCheckerFlowActionListInternal -Actions $flowdata.definition.actions -Recurse

    .EXAMPLE
        Get a list of actions in a Power Platform flow including the references of the actions

        PS> Get-PowerPlatformCheckerFlowActionListInternal -Actions $flowdata.definition.actions -Properties References

    .EXAMPLE
        Get a list of actions in a Power Platform flow including the actions that run after each action

        PS> Get-PowerPlatformCheckerFlowActionListInternal -Actions $flowdata.definition.actions -Properties RunAfter

    .EXAMPLE
        Get a list of actions in a Power Platform flow including the parent action of each action

        PS> Get-PowerPlatformCheckerFlowActionListInternal -Actions $flowdata.definition.actions -Properties ParentAction

    .EXAMPLE
        Get a list of actions in a Power Platform flow with a specific parent action

        PS> Get-PowerPlatformCheckerFlowActionListInternal -Actions $flowdata.definition.actions -Properties ParentAction -ParentAction "Apply_to_each"

    .EXAMPLE
        Get a list including the triggers in a Power Platform flow

        PS> Get-PowerPlatformCheckerFlowActionListInternal -Path C:\Path\To\Flow -IncludeTrigger

    .EXAMPLE
        Get a list including the triggers in a Power Platform flow where the actions are set to be a trigger

        PS> Get-PowerPlatformCheckerFlowActionListInternal -Actions $flowdata.definition.triggers -IncludeTrigger -IsTrigger

    .EXAMPLE
        Get a list of actions in a Power Platform flow by providing the path to the flow file

        PS> Get-PowerPlatformCheckerFlowActionListInternal -Path C:\Path\To\Flow

    .EXAMPLE
        Get a list of action and add a specific depth value to the output

        PS> Get-PowerPlatformCheckerFlowActionListInternal -Actions $flowdata.definition.actions -Recurse -Properties ParentAction -Depth 2

    .EXAMPLE
        Get action interaction metadata including read/write classification

        PS> Get-PowerPlatformCheckerFlowActionListInternal -Actions $flowdata.definition.actions -Properties InteractionProfile

    .EXAMPLE
        Get action external URL/domain metadata with definition parameters for expression resolution

        PS> Get-PowerPlatformCheckerFlowActionListInternal -Actions $flowdata.definition.actions -Properties ExternalProfile -DefinitionParameters $flowdata.definition.parameters
    #>

    [CmdLetBinding(defaultParameterSetName = "Path")]
    Param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Path', Position = 1)]
        [String] $Path,

        [Parameter(Mandatory = $true, ParameterSetName = 'Actions', Position = 1)]
        [Object] $Actions,

        [Parameter(Mandatory = $false, ParameterSetName = 'Actions', Position = 2)]
        [Parameter(Mandatory = $false, ParameterSetName = 'Path', Position = 2)]
        [Object] $ParentAction = $null,

        [Parameter(Mandatory = $false, ParameterSetName = 'Actions', Position = 3)]
        [Parameter(Mandatory = $false, ParameterSetName = 'Path', Position = 3)]
        [Switch] $Recurse,

        [Parameter(Mandatory = $false, ParameterSetName = 'Actions', Position = 4)]
        [Parameter(Mandatory = $false, ParameterSetName = 'Path', Position = 4)]
        [Switch] $IncludeTrigger,

        [Parameter(Mandatory = $false, ParameterSetName = 'Actions', Position = 5)]
        [Parameter(Mandatory = $false, ParameterSetName = 'Path', Position = 5)]
        [ValidateSet("References", "Entities", "RunAfter", "ParentAction", "InteractionProfile", "ExternalProfile", "TriggerProfile", "OperationProfile", "ResponseProfile")]
        [String[]] $Properties = @(),

        [Parameter(Mandatory = $false, ParameterSetName = 'Actions', Position = 6)]
        [Parameter(Mandatory = $false, ParameterSetName = 'Path', Position = 6)]
        [Switch] $IsTrigger,

        [Parameter(Mandatory = $false, ParameterSetName = 'Actions', Position = 7)]
        [Parameter(Mandatory = $false, ParameterSetName = 'Path', Position = 7)]
        [int] $Depth = 0,

        [Parameter(Mandatory = $false, ParameterSetName = 'Actions', Position = 8)]
        [Parameter(Mandatory = $false, ParameterSetName = 'Path', Position = 8)]
        [AllowNull()]
        [Object] $DefinitionParameters = $null
    )

    # Import the flow data
    if ($Path) {
        $flowdata = Import-PowerPlatformCheckerFlow -Path $Path
        $actions = $flowdata.properties.definition.actions
        $DefinitionParameters = $flowdata.properties.definition.parameters
    }

    # Create an empty actionList
    $actionsList = @()

    # If the trigger is included call this recursivly to add the trigger as well
    if ($IncludeTrigger -and $null -eq $ParentAction -and $Path) {
        $actionsList += Get-PowerPlatformCheckerFlowActionListInternal -Actions $flowdata.properties.definition.triggers -ParentAction "Trigger" -Recurse:$Recurse -Properties $Properties -IncludeTrigger -IsTrigger -Depth $Depth -DefinitionParameters $DefinitionParameters
    }

    # Loop through the actions and get the information of the actions, if there are nested actions then loop through those as well
    $actionsList += $actions | Get-Member -MemberType NoteProperty | ForEach-Object {
        $switchBranches = @()
        if ($actions.$($_.Name).actions -and $Recurse) {
            Get-PowerPlatformCheckerFlowActionListInternal -Actions $actions.$($_.Name).actions -ParentAction @{"Name" = $($_.Name); "Type" = "actions"} -Recurse -IncludeTrigger:$IncludeTrigger -Properties $Properties -Depth ($Depth + 1) -DefinitionParameters $DefinitionParameters

            # Check if there is an else statement and loop through those actions as well
            if ($actions.$($_.Name).else -and $Recurse) {
                Get-PowerPlatformCheckerFlowActionListInternal -Actions $actions.$($_.Name).else.actions -ParentAction @{"Name" = $($_.Name); "Type" = "else"} -Recurse -IncludeTrigger:$IncludeTrigger -Properties $Properties -Depth ($Depth + 1) -DefinitionParameters $DefinitionParameters
            }
        }

        if ($actions.$($_.Name).type -eq "Switch" -and $Recurse) {
            $switchName = $_.Name
            foreach ($caseProperty in @($actions.$switchName.cases | Get-Member -MemberType NoteProperty)) {
                $caseName = $caseProperty.Name
                $caseActions = $actions.$switchName.cases.$caseName.actions
                $switchBranches += [pscustomobject]@{ Type = "case"; Name = $caseName }
                if ($caseActions) {
                    Get-PowerPlatformCheckerFlowActionListInternal -Actions $caseActions -ParentAction @{"Name" = $switchName; "Type" = "case"; "BranchName" = $caseName} -Recurse -IncludeTrigger:$IncludeTrigger -Properties $Properties -Depth ($Depth + 1) -DefinitionParameters $DefinitionParameters
                }
            }

            if ($null -ne $actions.$switchName.default) {
                $switchBranches += [pscustomobject]@{ Type = "default"; Name = "Default" }
                if ($actions.$switchName.default.actions) {
                    Get-PowerPlatformCheckerFlowActionListInternal -Actions $actions.$switchName.default.actions -ParentAction @{"Name" = $switchName; "Type" = "default"; "BranchName" = "Default"} -Recurse -IncludeTrigger:$IncludeTrigger -Properties $Properties -Depth ($Depth + 1) -DefinitionParameters $DefinitionParameters
                }
            }
        }
        # Store the data from the action
        $rawAction = $actions.$($_.Name)
        $type = $rawAction.type
        $group = "*"
        if ($type -eq "OpenApiConnection" -or $type -eq "OpenApiConnectionWebhook") {
            $type = $rawAction.inputs.host.operationId
            $group = $rawAction.inputs.host.apiId.split("/")[-1]
        }
        elseif ($rawAction.inputs -and $rawAction.inputs.host -and $rawAction.inputs.host.apiId) {
            $group = [string]$rawAction.inputs.host.apiId.split("/")[-1]
        }
        elseif ($rawAction.inputs -and $rawAction.inputs.host -and $rawAction.inputs.host.connectionName) {
            $group = [string]$rawAction.inputs.host.connectionName
        }
        elseif ($rawAction.inputs -and $rawAction.inputs.host -and $rawAction.inputs.host.connection -and $rawAction.inputs.host.connection.name) {
            $connectionExpression = [string]$rawAction.inputs.host.connection.name
            $connectionMatch = [regex]::Match($connectionExpression, "\['(?<name>shared_[^']+)'\]\['connectionId'\]")
            if ($connectionMatch.Success) {
                $group = [string]$connectionMatch.Groups['name'].Value
            }
        }

        $triggerOperationId = ''
        if ($IsTrigger.IsPresent -and $rawAction.inputs) {
            if ($rawAction.inputs.operationId) {
                $triggerOperationId = [string]$rawAction.inputs.operationId
            }
            elseif ($rawAction.inputs.host -and $rawAction.inputs.host.operationId) {
                $triggerOperationId = [string]$rawAction.inputs.host.operationId
            }
        }

        $operationDisplayName = ''
        if (-not [string]::IsNullOrWhiteSpace([string]$type)) {
            $operationLookup = @()
            if (-not [string]::IsNullOrWhiteSpace([string]$group) -and [string]$group -ne '*') {
                $operationLookup = @(Get-PowerPlatformCheckerOperationData -OperationType ([string]$type) -Group ([string]$group))
            }
            else {
                $operationLookup = @(Get-PowerPlatformCheckerOperationData -OperationType ([string]$type))
            }

            if (@($operationLookup).Count -gt 0) {
                $operationDisplayName = [string]$operationLookup[0].name
            }
        }

        if ($IsTrigger.IsPresent -and [string]::IsNullOrWhiteSpace($operationDisplayName) -and -not [string]::IsNullOrWhiteSpace([string]$triggerOperationId)) {
            $triggerOperationLookup = @()
            if (-not [string]::IsNullOrWhiteSpace([string]$group) -and [string]$group -ne '*') {
                $triggerOperationLookup = @(Get-PowerPlatformCheckerOperationData -OperationType ([string]$triggerOperationId) -Group ([string]$group))
            }
            else {
                $triggerOperationLookup = @(Get-PowerPlatformCheckerOperationData -OperationType ([string]$triggerOperationId))
            }

            if (@($triggerOperationLookup).Count -gt 0) {
                $operationDisplayName = [string]$triggerOperationLookup[0].name
            }
        }

        $connectorDisplayName = ''
        if (-not [string]::IsNullOrWhiteSpace([string]$group) -and [string]$group -ne '*') {
            $connectorLookup = @(Get-PowerPlatformCheckerConnectorData -Name ([string]$group))
            if (@($connectorLookup).Count -gt 0) {
                $connectorDisplayName = [string]$connectorLookup[0].displayname
            }
        }

        $actionObject = [pscustomobject]@{
            Name  = $_.Name
            Type  = $type
            Group = $group
        }

        if ($type -eq "Switch") {
            $actionObject | Add-Member -MemberType NoteProperty -Name "SwitchBranches" -Value $switchBranches
        }

        if ($Properties -contains "References") {
            $reference = ""

            if ($type -eq "Workflow") {
                $reference = $actions.$($_.Name).inputs.host.workflowReferenceName
            }

            $actionObject | Add-Member -MemberType NoteProperty -Name "Reference" -Value $reference
        }

        if ($Properties -contains "RunAfter") {
            # Triggers never have a runafter so make sure it's set to empty
            if($IsTrigger) {
                $runAfterActions = ""
                $runAfterStatus = $null
            }
            else {
                $runAfterStatus = $actions.$($_.Name).runAfter
                if ($null -ne $runAfterStatus) {
                    $runAfterActions = $runAfterStatus | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
                }
                else {
                    $runAfterActions = @()
                }
            }
            $actionObject | Add-Member -MemberType NoteProperty -Name "RunAfter" -Value $runAfterActions
            $actionObject | Add-Member -MemberType NoteProperty -Name "RunAfterStatus" -Value $runAfterStatus
        }

        if ($Properties -contains "ParentAction") {
            # To make sure no infinite loop occurs the parent action is filled when calling recursively for a trigger, here we empty it if looking for a trigger
            if($IsTrigger) {
                $ParentAction = $null
            }
            $actionObject | Add-Member -MemberType NoteProperty -Name "ParentAction" -Value $ParentAction

            # Also add a depth property to indicate how deep the action is nested
            $actionObject | Add-Member -MemberType NoteProperty -Name "Depth" -Value $Depth
        }

        if ($IncludeTrigger) {
            $actionObject | Add-Member -MemberType NoteProperty -Name "IsTrigger" -Value $IsTrigger.IsPresent
        }

        if ($Properties -contains "OperationProfile") {
            $actionObject | Add-Member -MemberType NoteProperty -Name "OperationDisplayName" -Value ([string]$operationDisplayName)
            $actionObject | Add-Member -MemberType NoteProperty -Name "ConnectorDisplayName" -Value ([string]$connectorDisplayName)
        }

        if ($Properties -contains "TriggerProfile") {
            $triggerAuthenticationType = ''
            $triggerKind = ''
            if ($rawAction.inputs -and $rawAction.inputs.triggerAuthenticationType) {
                $triggerAuthenticationType = [string]$rawAction.inputs.triggerAuthenticationType
            }
            if ($rawAction.kind) {
                $triggerKind = [string]$rawAction.kind
            }

            $triggerAuthenticationDescription = Get-PowerPlatformCheckerTriggerAuthenticationDescription -AuthenticationType $triggerAuthenticationType
            $actionObject | Add-Member -MemberType NoteProperty -Name "TriggerKind" -Value ([string]$triggerKind)
            $actionObject | Add-Member -MemberType NoteProperty -Name "TriggerOperationId" -Value ([string]$triggerOperationId)
            $actionObject | Add-Member -MemberType NoteProperty -Name "TriggerAuthenticationType" -Value ([string]$triggerAuthenticationType)
            $actionObject | Add-Member -MemberType NoteProperty -Name "TriggerAuthenticationDescription" -Value ([string]$triggerAuthenticationDescription)
        }

        if ($Properties -contains "ResponseProfile") {
            $responseStatusCode = ''
            $responseHasBody = $false
            $responseBodyDescription = ''
            if ([string]$rawAction.type -eq 'Response' -and $rawAction.inputs) {
                if ($rawAction.inputs.PSObject.Properties.Name -contains 'statusCode') {
                    $responseStatusCode = [string]$rawAction.inputs.statusCode
                }

                if ($rawAction.inputs.PSObject.Properties.Name -contains 'body' -and $null -ne $rawAction.inputs.body) {
                    $bodyValue = [string]$rawAction.inputs.body
                    if (-not [string]::IsNullOrWhiteSpace($bodyValue)) {
                        $responseHasBody = $true
                    }
                }
            }

            if ([string]$rawAction.type -eq 'Response') {
                $responseBodyDescription = if ($responseHasBody) { 'Returns status code and body' } else { 'Returns status code only' }
            }

            $actionObject | Add-Member -MemberType NoteProperty -Name 'ResponseStatusCode' -Value ([string]$responseStatusCode)
            $actionObject | Add-Member -MemberType NoteProperty -Name 'ResponseHasBody' -Value ([bool]$responseHasBody)
            $actionObject | Add-Member -MemberType NoteProperty -Name 'ResponseDescription' -Value ([string]$responseBodyDescription)
        }

        if ($Properties -contains "Entities") {
            $entities = @()

            if ($actions.$($_.Name).inputs.parameters) {
                if($actions.$($_.Name).inputs.parameters.entityName) {
                    $entities += $actions.$($_.Name).inputs.parameters.entityName
                }

                if($actions.$($_.Name).inputs.parameters."subscriptionRequest/entityname") {
                    $entities += $actions.$($_.Name).inputs.parameters."subscriptionRequest/entityname"
                }
            }

            $actionObject | Add-Member -MemberType NoteProperty -Name "Entities" -Value ($entities | Sort-Object -Unique)
        }

        if (($Properties -contains "InteractionProfile") -or ($Properties -contains "ExternalProfile")) {
            $interactionProfile = Get-PowerPlatformCheckerFlowActionInteractionProfile -Action $actions.$($_.Name) -ActionType $type -DefinitionParameters $DefinitionParameters

            if ($Properties -contains "InteractionProfile") {
                $actionObject | Add-Member -MemberType NoteProperty -Name "Method" -Value ([string]$interactionProfile.Method)
                $actionObject | Add-Member -MemberType NoteProperty -Name "GetSetAction" -Value ([string]$interactionProfile.GetSetAction)
                $actionObject | Add-Member -MemberType NoteProperty -Name "InteractionDirection" -Value ([string]$interactionProfile.InteractionDirection)
            }

            if ($Properties -contains "ExternalProfile") {
                $actionObject | Add-Member -MemberType NoteProperty -Name "ExternalUrl" -Value ([string]$interactionProfile.ExternalUrl)
                $actionObject | Add-Member -MemberType NoteProperty -Name "ExternalEndpoint" -Value ([string]$interactionProfile.ExternalEndpoint)
                $actionObject | Add-Member -MemberType NoteProperty -Name "ExternalProtocol" -Value ([string]$interactionProfile.ExternalProtocol)
                $actionObject | Add-Member -MemberType NoteProperty -Name "ExternalDomain" -Value ([string]$interactionProfile.ExternalDomain)
                $actionObject | Add-Member -MemberType NoteProperty -Name "ExternalMainDomain" -Value ([string]$interactionProfile.ExternalMainDomain)
                $actionObject | Add-Member -MemberType NoteProperty -Name "ExternalResolutionState" -Value ([string]$interactionProfile.ExternalResolutionState)
            }
        }

        $actionObject
    }

    # Return the list of actions
    return $actionsList
}