. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerFlowDirectionProfile" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
    }

    $directionCases = @(
        @{
            Name = "write operations"
            Actions = @(
                [pscustomobject]@{ IsTrigger = $false; Type = "CreateRecord"; Group = "shared_commondataserviceforapps" },
                [pscustomobject]@{ IsTrigger = $false; Type = "UpdateOnlyRecord"; Group = "shared_commondataserviceforapps" }
            )
            ExpectedDirection = "Write"
            ExpectedConfidence = "High"
            ExpectedEvidence = "OperationCatalog+Heuristic"
        }
        @{
            Name = "read operations"
            Actions = @(
                [pscustomobject]@{ IsTrigger = $false; Type = "GetItems"; Group = "shared_sharepointonline" },
                [pscustomobject]@{ IsTrigger = $false; Type = "ListRows"; Group = "shared_commondataserviceforapps" }
            )
            ExpectedDirection = "Read"
            ExpectedConfidence = "Medium"
            ExpectedEvidence = "OperationHeuristic"
        }
        @{
            Name = "mixed operations"
            Actions = @(
                [pscustomobject]@{ IsTrigger = $false; Type = "ListRows"; Group = "shared_commondataserviceforapps" },
                [pscustomobject]@{ IsTrigger = $false; Type = "CreateRecord"; Group = "shared_commondataserviceforapps" }
            )
            ExpectedDirection = "Mixed"
            ExpectedConfidence = "High"
            ExpectedEvidence = "OperationCatalog+Heuristic"
        }
        @{
            Name = "unknown operations"
            Actions = @(
                [pscustomobject]@{ IsTrigger = $false; Type = "Compose"; Group = "*" },
                [pscustomobject]@{ IsTrigger = $true; Type = "Request"; Group = "*" }
            )
            ExpectedDirection = "Unknown"
            ExpectedConfidence = "Low"
            ExpectedEvidence = "NoDirectionSignal"
        }
    )

    It "classifies direction metadata for <Name>" -TestCases $directionCases {
        param($Name, $Actions, $ExpectedDirection, $ExpectedConfidence, $ExpectedEvidence)

        InModuleScope PowerPlatformChecker {
            param($InnerActions)

            Get-PowerPlatformCheckerFlowDirectionProfile -Actions $InnerActions
        } -Parameters @{ InnerActions = $Actions } | ForEach-Object {
            $_.InteractionDirection | Should -Be $ExpectedDirection
            $_.DirectionConfidence | Should -Be $ExpectedConfidence
            $_.SourceEvidence | Should -Be $ExpectedEvidence
        }
    }
}
