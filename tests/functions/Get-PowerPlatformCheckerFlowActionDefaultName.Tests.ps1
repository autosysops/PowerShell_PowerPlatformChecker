. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerFlowActionDefaultName" {
    BeforeAll { Initialize-PowerPlatformCheckerTestData }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "resolves by operation type when group is wildcard" {
        $summary = Get-PowerPlatformCheckerFlowActionDefaultName -Type "CreateRecord" -Group "*"
        $summary | Should -Be "Create orderline"
    }

    It "resolves by explicit group" {
        $summary = Get-PowerPlatformCheckerFlowActionDefaultName -Type "Send an email" -Group "shared_office365"
        $summary | Should -Be "Send an email"
    }

    It "maps the flow JSON condition type If to the catalog operation Condition" {
        # The real catalog stores a condition as operationType Condition, not If
        Mock -CommandName Get-PowerPlatformCheckerOperationData -ModuleName PowerPlatformChecker {
            param($Name = "*", $OperationType = "*", $Group = "*")
            @([pscustomobject]@{ name = "Condition"; operationType = "Condition"; group = "Control"; summary = "Condition"; builtin = $true }) |
                Where-Object { $_.name -like $Name -and $_.operationType -like $OperationType -and $_.group -like $Group }
        }

        Get-PowerPlatformCheckerFlowActionDefaultName -Type "If" -Group "*" | Should -Be "Condition"
    }

    It "matches catalog names that write the version with an underscore" {
        # The real catalog names this operation GetItems_V2, the flow JSON says GetItemsV2
        Mock -CommandName Get-PowerPlatformCheckerOperationData -ModuleName PowerPlatformChecker {
            param($Name = "*", $OperationType = "*", $Group = "*")
            @([pscustomobject]@{ name = "GetItems_V2"; operationType = "OpenApiConnection"; group = "shared_sql"; summary = "Get rows (V2)"; builtin = $false }) |
                Where-Object { $_.name -like $Name -and $_.operationType -like $OperationType -and $_.group -like $Group }
        }

        Get-PowerPlatformCheckerFlowActionDefaultName -Type "GetItemsV2" -Group "shared_sql" | Should -Be "Get rows (V2)"
    }

    It "prefers builtin operation metadata when multiple matches are returned" {
        Mock -CommandName Get-PowerPlatformCheckerOperationData -ModuleName PowerPlatformChecker {
            @(
                [pscustomobject]@{ summary = "Custom summary"; builtin = $false },
                [pscustomobject]@{ summary = "Built-in summary"; builtin = $true }
            )
        }

        $summary = Get-PowerPlatformCheckerFlowActionDefaultName -Type "CreateRecord" -Group "*"

        $summary | Should -Be "Built-in summary"
    }

    It "sends sanitized telemetry for wildcard and explicit group invocation" {
        $telemetryCalls = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {
            param([string]$ModuleName, [string]$EventName, [hashtable]$PropertiesHash)
            [void]$telemetryCalls.Add([pscustomobject]@{ ModuleName = $ModuleName; EventName = $EventName; PropertiesHash = $PropertiesHash })
        }

        $secretType = "CreateRecord"
        [void](Get-PowerPlatformCheckerFlowActionDefaultName -Type $secretType -Group "*")
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerFlowActionDefaultName" -ExpectedKeys @("UsesWildcardGroup") -ConfidentialValues @($secretType)

        $telemetryCalls.Clear()
        [void](Get-PowerPlatformCheckerFlowActionDefaultName -Type "Send an email" -Group "shared_office365")
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerFlowActionDefaultName" -ExpectedKeys @("UsesWildcardGroup") -ConfidentialValues @("shared_office365")
    }
}

