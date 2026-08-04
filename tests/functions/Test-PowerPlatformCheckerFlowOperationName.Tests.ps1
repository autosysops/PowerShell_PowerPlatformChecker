Describe "Test-PowerPlatformCheckerFlowOperationName" {
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "marks action names that match default names" {
        Mock -CommandName Get-PowerPlatformCheckerFlowActionList -ModuleName PowerPlatformChecker {
            @(
                [pscustomobject]@{ Name = "Create_orderline"; Type = "CreateRecord"; Group = "*" },
                [pscustomobject]@{ Name = "NonDefaultAction"; Type = "SendEmailV2"; Group = "*" }
            )
        }

        Mock -CommandName Get-PowerPlatformCheckerFlowActionDefaultName -ModuleName PowerPlatformChecker {
            param($Type, $Group)
            if ($Type -eq "CreateRecord") { return "Create orderline" }
            return "Send an email"
        }

        $result = Test-PowerPlatformCheckerFlowOperationName -Path "dummy"

        ($result | Where-Object ActionName -eq "Create_orderline").Equal | Should -Be $true
        ($result | Where-Object ActionName -eq "NonDefaultAction").Equal | Should -Be $false
    }
}

