. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerEntityFormXmlWebResource" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
    }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "returns entity script usage from form xml" {
        $usage = Get-PowerPlatformCheckerEntityFormXmlWebResource -SolutionPath $script:solutionPath

        $orderUsage = $usage | Where-Object { $_.EntitySchemaName -eq "ppc_order" } | Select-Object -First 1
        $orderUsage | Should -Not -BeNullOrEmpty
        $orderUsage.WebResources | Should -Contain "ppc_script/OrderForm.js"
    }

    It "returns empty when no forms reference javascript" {
        $testRoot = Join-Path $TestDrive "EntityFormXmlNoScriptsFixture"
        $entityFormPath = Join-Path $testRoot "Entities\sample_account\FormXml\main"

        New-Item -ItemType Directory -Path $entityFormPath -Force | Out-Null
        "<form><tabs /></form>" | Set-Content -Path (Join-Path $entityFormPath "sample_form.xml") -Encoding utf8BOM

        $usage = Get-PowerPlatformCheckerEntityFormXmlWebResource -SolutionPath $testRoot

        $usage.Count | Should -Be 0
    }

    It "sends sanitized telemetry for entity filtering" {
        $telemetryCalls = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {
            param([string]$ModuleName, [string]$EventName, [hashtable]$PropertiesHash)
            [void]$telemetryCalls.Add([pscustomobject]@{ ModuleName = $ModuleName; EventName = $EventName; PropertiesHash = $PropertiesHash })
        }

        $secretEntity = "secret_entity_name"
        [void](Get-PowerPlatformCheckerEntityFormXmlWebResource -SolutionPath $script:solutionPath -EntityName $secretEntity)

        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerEntityFormXmlWebResource" -ExpectedKeys @("EntityFilterUsed") -ConfidentialValues @($script:solutionPath, $secretEntity)
    }
}
