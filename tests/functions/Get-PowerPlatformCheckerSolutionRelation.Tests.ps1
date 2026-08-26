. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerSolutionRelation" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
    }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "returns relation records" {
        $relations = Get-PowerPlatformCheckerSolutionRelation -SolutionPath $script:solutionPath
        $relations.Count | Should -Be 4
        ($relations | Where-Object Name -eq "ppc_Order_ppc_OrderLine").Type | Should -Be "OneToMany"
    }

    It "returns empty when the relationship folder does not exist" {
        $testRoot = Join-Path $TestDrive "NoRelationships"
        New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

        { Get-PowerPlatformCheckerSolutionRelation -SolutionPath $testRoot -ErrorAction Stop } | Should -Not -Throw
        @(Get-PowerPlatformCheckerSolutionRelation -SolutionPath $testRoot).Count | Should -Be 0
    }

    It "sends invocation telemetry without solution paths or result counts" {
        $telemetryCalls = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {
            param([string]$ModuleName, [string]$EventName, [hashtable]$PropertiesHash)
            [void]$telemetryCalls.Add([pscustomobject]@{ ModuleName = $ModuleName; EventName = $EventName; PropertiesHash = $PropertiesHash })
        }

        [void](Get-PowerPlatformCheckerSolutionRelation -SolutionPath $script:solutionPath)
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerSolutionRelation" -ExpectedKeys @() -ConfidentialValues @($script:solutionPath)
    }
}

