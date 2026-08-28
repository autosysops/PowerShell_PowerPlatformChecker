. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerFlowActionList" {
    $desktopCustomFlowCases = @(
        @{
            Name = "quoted desktop segments"
            FileName = "DesktopQuotedSegments-17171717-1717-1717-1717-171717171717.json"
            AssertionType = "SimpleNames"
            ExpectedNames = @("DISPLAY", "WRITE")
        }
        @{
            Name = "desktop block scope"
            FileName = "DesktopBlockScope-19191919-1919-1919-1919-191919191919.json"
            AssertionType = "BlockScope"
        }
        @{
            Name = "desktop on error"
            FileName = "DesktopOnError-20202020-2020-2020-2020-202020202020.json"
            AssertionType = "OnError"
        }
        @{
            Name = "escaped selector tail"
            FileName = "DesktopEscapedSelectorTail-21212121-2121-2121-2121-212121212121.json"
            AssertionType = "SimpleNames"
            ExpectedNames = @("WAIT", "WebAutomation.Focus.Focus", "WRITE")
        }
    )

    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
        $script:desktopSolutionPath = Get-PowerPlatformCheckerDesktopFixtureSolutionPath
        $script:actionListDesktopCasesPath = (Resolve-Path (Join-Path $PSScriptRoot "..\fixtures\actionlist-desktop-cases\Managed\Workflows")).Path
        $script:flowPath = Join-Path $script:solutionPath "Workflows\SampleFlow-11111111-1111-1111-1111-111111111111.json"
        $script:cloudHttpProfileFlowPath = Join-Path $script:solutionPath "Workflows\CloudHttpProfileFlow-23232323-2323-2323-2323-232323232323.json"
        $script:desktopFlowPath = Join-Path $script:desktopSolutionPath "Workflows\DesktopFlow-77777777-7777-7777-7777-777777777777.json"
        $script:desktopQuotedMetadataFlowPath = Join-Path $script:desktopSolutionPath "Workflows\DesktopFlow-88888888-8888-8888-8888-888888888888.json"
        $script:desktopExternalProfileFlowPath = Join-Path $script:desktopSolutionPath "Workflows\DesktopFlow-23232323-3434-4545-5656-676767676767.json"
        $script:invalidFlowPath = Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..\fixtures\flow-type-edge\Managed\Workflows")).Path "InvalidDesktopFlow-07070707-0707-0707-0707-070707070707.json"
    }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "returns recursive actions, trigger, and parent metadata" {
        $actions = Get-PowerPlatformCheckerFlowActionList -Path $script:flowPath -Recurse -IncludeTrigger -Properties References,Entities,RunAfter,ParentAction

        ($actions | Where-Object IsTrigger).Count | Should -Be 1
        ($actions | Where-Object Name -EQ "Send_an_email").ParentAction.Type | Should -Be "actions"
        ($actions | Where-Object Name -EQ "Update_row").ParentAction.Type | Should -Be "else"
        ($actions | Where-Object Name -EQ "Call_Child_Workflow").Reference | Should -Be "22222222-2222-2222-2222-222222222222"
        ($actions | Where-Object Name -EQ "Create_orderline").Entities | Should -Contain "ppc_orderlines"
    }

    It "keeps cloud action contract for sample flow" {
        $actions = Get-PowerPlatformCheckerFlowActionList -Path $script:flowPath -Recurse -IncludeTrigger -Properties References,Entities,RunAfter,ParentAction

        ($actions | Where-Object IsTrigger).Name | Should -Contain "When_a_row_is_added"
        ($actions | Where-Object Name -EQ "Condition_Check_Order").Type | Should -Be "If"
    }

    It "returns desktop actions from desktop flow fixture" {
        $actions = Get-PowerPlatformCheckerFlowActionList -Path $script:desktopFlowPath -Recurse -Properties RunAfter,ParentAction

        $actions.Count | Should -BeGreaterThan 0
        ($actions | Select-Object -ExpandProperty Name) | Should -Contain "DISPLAY"
        ($actions | Select-Object -ExpandProperty Name) | Should -Contain "LAUNCH"
        ($actions | Select-Object -ExpandProperty Name) | Should -Contain "WRITE"

        $firstAction = $actions | Select-Object -First 1
        $firstAction.PSObject.Properties.Name | Should -Contain "Name"
        $firstAction.PSObject.Properties.Name | Should -Contain "Type"
        $firstAction.PSObject.Properties.Name | Should -Contain "RunAfter"
        $firstAction.PSObject.Properties.Name | Should -Contain "ParentAction"
    }

    It "supports actions-parameter invocation without explicit properties" {
        $flowData = Get-Content -Path $script:flowPath -Raw | ConvertFrom-Json

        $actions = Get-PowerPlatformCheckerFlowActionList -Actions $flowData.properties.definition.actions -Recurse

        $actions.Count | Should -BeGreaterThan 0
        ($actions | Select-Object -ExpandProperty Name) | Should -Contain "Call_Child_Workflow"
    }

    It "supports path invocation without explicit properties from help example" {
        $actions = Get-PowerPlatformCheckerFlowActionList -Path $script:flowPath

        $actions.Count | Should -BeGreaterThan 0
        ($actions | Select-Object -ExpandProperty Name) | Should -Contain "Condition_Check_Order"
    }

    It "returns interaction and external profile fields for cloud actions when requested" {
        $actions = Get-PowerPlatformCheckerFlowActionList -Path $script:cloudHttpProfileFlowPath -Properties InteractionProfile,ExternalProfile
        $callApi = $actions | Where-Object Name -eq "CallApi" | Select-Object -First 1

        $callApi.Method | Should -Be "GET"
        $callApi.GetSetAction | Should -Be "Get"
        $callApi.InteractionDirection | Should -Be "Read"
        $callApi.ExternalEndpoint | Should -Be "https://api.contoso.example"
        $callApi.ExternalDomain | Should -Be "api.contoso.example"
        $callApi.ExternalProtocol | Should -Be "https"
        $callApi.ExternalMainDomain | Should -Be "contoso.example"
        $callApi.ExternalResolutionState | Should -Be "Resolved"
    }

    It "extracts connector endpoint URLs from dataset and source parameters" {
        InModuleScope PowerPlatformChecker {
            $actions = [pscustomobject]@{
                GetItems = [pscustomobject]@{
                    type = 'OpenApiConnection'
                    inputs = [pscustomobject]@{
                        host = [pscustomobject]@{
                            operationId = 'GetItems'
                            apiId = '/providers/Microsoft.PowerApps/apis/shared_sharepointonline'
                        }
                        parameters = [pscustomobject]@{
                            dataset = "@parameters('sharepointSite')"
                            source = 'sites/demo-site'
                        }
                    }
                }
            }

            $definitionParameters = [pscustomobject]@{
                sharepointSite = [pscustomobject]@{ defaultValue = 'https://contoso.sharepoint.com/sites/operations' }
            }

            Get-PowerPlatformCheckerFlowActionListInternal -Actions $actions -Properties ExternalProfile -DefinitionParameters $definitionParameters
        } | ForEach-Object {
            $_.ExternalDomain | Should -Be 'contoso.sharepoint.com'
            $_.ExternalProtocol | Should -Be 'https'
            $_.ExternalResolutionState | Should -Be 'Resolved'
        }
    }

    It "resolves inline parameter interpolation for URL candidates" {
        InModuleScope PowerPlatformChecker {
            $actions = [pscustomobject]@{
                CallApi = [pscustomobject]@{
                    type = 'OpenApiConnection'
                    inputs = [pscustomobject]@{
                        host = [pscustomobject]@{
                            operationId = 'Invoke'
                            apiId = '/providers/Microsoft.PowerApps/apis/shared_http'
                        }
                        parameters = [pscustomobject]@{
                            baseUrl = "https://@{parameters('hostName')}/api/@{parameters('version')}"
                        }
                    }
                }
            }

            $definitionParameters = [pscustomobject]@{
                hostName = [pscustomobject]@{ defaultValue = 'api.contoso.example' }
                version = [pscustomobject]@{ defaultValue = 'v1' }
            }

            Get-PowerPlatformCheckerFlowActionListInternal -Actions $actions -Properties ExternalProfile -DefinitionParameters $definitionParameters
        } | ForEach-Object {
            $_.ExternalUrl | Should -Be 'https://api.contoso.example/api/v1'
            $_.ExternalEndpoint | Should -Be 'https://api.contoso.example/api/v1'
            $_.ExternalDomain | Should -Be 'api.contoso.example'
            $_.ExternalMainDomain | Should -Be 'contoso.example'
            $_.ExternalResolutionState | Should -Be 'Resolved'
        }
    }

    It "returns trigger authentication and operation profile metadata when requested" {
        InModuleScope PowerPlatformChecker {
            $actions = [pscustomobject]@{
                manual = [pscustomobject]@{
                    type = 'Request'
                    kind = 'Http'
                    inputs = [pscustomobject]@{
                        triggerAuthenticationType = 'Tenant'
                        operationId = 'ForASelectedRecordV3'
                        host = [pscustomobject]@{
                            connection = [pscustomobject]@{
                                name = "@parameters('$connections')['shared_dynamicssmbsaas']['connectionId']"
                            }
                        }
                    }
                }
            }

            Get-PowerPlatformCheckerFlowActionListInternal -Actions $actions -IncludeTrigger -IsTrigger -Properties TriggerProfile,OperationProfile
        } | ForEach-Object {
            $_.IsTrigger | Should -BeTrue
            $_.TriggerAuthenticationType | Should -Be 'Tenant'
            $_.TriggerAuthenticationDescription | Should -Be 'Any user in my tenant'
            $_.TriggerOperationId | Should -Be 'ForASelectedRecordV3'
            $_.PSObject.Properties.Name | Should -Contain 'ConnectorDisplayName'
            $_.PSObject.Properties.Name | Should -Contain 'OperationDisplayName'
        }
    }

    It "returns response profile metadata for response actions" {
        InModuleScope PowerPlatformChecker {
            $actions = [pscustomobject]@{
                Response_200 = [pscustomobject]@{
                    type = 'Response'
                    kind = 'Http'
                    inputs = [pscustomobject]@{
                        statusCode = 200
                    }
                }
                Response_500 = [pscustomobject]@{
                    type = 'Response'
                    kind = 'Http'
                    inputs = [pscustomobject]@{
                        statusCode = 500
                        body = '{"error":"failure"}'
                    }
                }
            }

            Get-PowerPlatformCheckerFlowActionListInternal -Actions $actions -Properties ResponseProfile
        } | ForEach-Object {
            if ($_.Name -eq 'Response_200') {
                $_.ResponseStatusCode | Should -Be '200'
                $_.ResponseHasBody | Should -BeFalse
                $_.ResponseDescription | Should -Be 'Returns status code only'
            }

            if ($_.Name -eq 'Response_500') {
                $_.ResponseStatusCode | Should -Be '500'
                $_.ResponseHasBody | Should -BeTrue
                $_.ResponseDescription | Should -Be 'Returns status code and body'
            }
        }
    }

    It "parses quoted desktop metadata directives without emitting pseudo actions" {
        $actions = Get-PowerPlatformCheckerFlowActionList -Path $script:desktopQuotedMetadataFlowPath -Recurse -Properties RunAfter,ParentAction

        $actions.Count | Should -Be 2
        ($actions | Select-Object -ExpandProperty Name) | Should -Be @("DISPLAY", "WRITE")
        ($actions | Select-Object -ExpandProperty Name) | Should -Not -Contain '"@@ConnectionString:'
        ($actions | Select-Object -ExpandProperty Name) | Should -Not -Contain "{"
    }

        It "handles custom desktop flow fixtures" -TestCases $desktopCustomFlowCases {
                param($Name, $FileName, $AssertionType, $ExpectedNames)

                $flowPath = Join-Path $script:actionListDesktopCasesPath $FileName
        $actions = Get-PowerPlatformCheckerFlowActionList -Path $flowPath -Recurse -Properties RunAfter,ParentAction

        switch ($AssertionType) {
            "SimpleNames" {
                $actions.Count | Should -Be $ExpectedNames.Count
                ($actions | Select-Object -ExpandProperty Name) | Should -Be $ExpectedNames
            }
            "BlockScope" {
                $blockAction = $actions | Where-Object { $_.Type -eq "Scope" -and $_.DisplayName -eq "Scope: Try executing the flow" } | Select-Object -First 1
                $handlerAction = $actions | Where-Object { $_.Name -eq "CALL" } | Select-Object -First 1
                $bodyAction = $actions | Where-Object { $_.Type -eq "Variables.ConvertJsonToCustomObject" } | Select-Object -First 1

                $blockAction | Should -Not -BeNullOrEmpty
                $blockAction.PSObject.Properties.Name | Should -Contain "DisplayName"
                $handlerAction.RunAfter | Should -Be @($blockAction.Name)
                $handlerAction.RunAfterStatus.($blockAction.Name) | Should -Be @("Error")
                $bodyAction.ParentAction.Name | Should -Be $blockAction.Name
                $bodyAction.Depth | Should -Be 1
            }
            "OnError" {
                $waitAction = $actions | Where-Object { $_.Name -eq "WAIT" } | Select-Object -First 1
                $handlerAction = $actions | Where-Object { $_.Name -eq "CALL" } | Select-Object -First 1
                $writeAction = $actions | Where-Object { $_.Name -eq "WRITE" } | Select-Object -First 1

                $handlerAction.RunAfter | Should -Be @($waitAction.Name)
                $handlerAction.RunAfterStatus.($waitAction.Name) | Should -Be @("TimeoutError")
                $writeAction.RunAfter | Should -Be @($waitAction.Name)
                $writeAction.RunAfterStatus.($waitAction.Name) | Should -Be @("Succeeded")
            }
            default {
                throw "Unknown assertion type '$AssertionType' for desktop custom flow case '$Name'."
            }
        }
    }

    It "returns desktop external profile fields when requested" {
        $actions = Get-PowerPlatformCheckerFlowActionList -Path $script:desktopExternalProfileFlowPath -Properties InteractionProfile,ExternalProfile
        $action = $actions | Select-Object -First 1

        $action.GetSetAction | Should -Be "Get"
        $action.InteractionDirection | Should -Be "Read"
        $action.ExternalDomain | Should -Be "login.contoso.example"
        $action.ExternalProtocol | Should -Be "https"
        $action.ExternalMainDomain | Should -Be "contoso.example"
    }

    It "returns empty actions and warns for invalid flow input" {
        $warnings = @()
        $actions = Get-PowerPlatformCheckerFlowActionList -Path $script:invalidFlowPath -WarningVariable warnings -WarningAction SilentlyContinue

        @($actions).Count | Should -Be 0
        (@($warnings) -join " `n") | Should -Match "Invalid flow input"
    }

    It "sends sanitized telemetry for both invocation parameter sets" {
        $telemetryCalls = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {
            param([string]$ModuleName, [string]$EventName, [hashtable]$PropertiesHash)
            [void]$telemetryCalls.Add([pscustomobject]@{ ModuleName = $ModuleName; EventName = $EventName; PropertiesHash = $PropertiesHash })
        }

        [void](Get-PowerPlatformCheckerFlowActionList -Path $script:flowPath -Recurse -IncludeTrigger -Properties References, RunAfter)
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerFlowActionList" -ExpectedKeys @("ParameterSet", "Recurse", "IncludeTrigger", "PropertyCount") -ConfidentialValues @($script:flowPath)

        $telemetryCalls.Clear()
        $flowData = Get-Content -Path $script:flowPath -Raw | ConvertFrom-Json
        [void](Get-PowerPlatformCheckerFlowActionList -Actions $flowData.properties.definition.actions -Recurse)
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerFlowActionList" -ExpectedKeys @("ParameterSet", "Recurse", "IncludeTrigger", "PropertyCount") -ConfidentialValues @("Call_Child_Workflow")
    }
}

