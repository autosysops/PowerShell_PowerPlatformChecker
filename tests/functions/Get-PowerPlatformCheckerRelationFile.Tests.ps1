. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerRelationFile" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
    }

    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {}
    }

    It "returns empty when relationship folder does not exist even with outer-scope files variable" {
        InModuleScope PowerPlatformChecker {
            $testRoot = Join-Path $TestDrive "NoRelationships"
            New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

            # Simulate outer scope variable pollution that historically leaked into this helper.
            $files = @("not-a-file-object")

            { Get-PowerPlatformCheckerRelationFile -SolutionPath $testRoot -ErrorAction Stop } | Should -Not -Throw
            $result = Get-PowerPlatformCheckerRelationFile -SolutionPath $testRoot
            @($result).Count | Should -Be 0
        }
    }

    It "returns full paths for relation files and supports target filtering" {
        InModuleScope PowerPlatformChecker {
            $testRoot = Join-Path $TestDrive "WithRelationships"
            $relationshipDir = Join-Path $testRoot "Other\Relationships"
            New-Item -ItemType Directory -Path $relationshipDir -Force | Out-Null

            $fileA = Join-Path $relationshipDir "account.xml"
            $fileB = Join-Path $relationshipDir "contact.xml"
            Set-Content -Path $fileA -Value "<root />" -Encoding utf8BOM
            Set-Content -Path $fileB -Value "<root />" -Encoding utf8BOM

            $all = @(Get-PowerPlatformCheckerRelationFile -SolutionPath $testRoot)
            $filtered = @(Get-PowerPlatformCheckerRelationFile -SolutionPath $testRoot -RelationTarget "account")

            $all.Count | Should -Be 2
            $all | Should -Contain $fileA
            $all | Should -Contain $fileB
            $filtered | Should -Be @($fileA)
        }
    }
}
