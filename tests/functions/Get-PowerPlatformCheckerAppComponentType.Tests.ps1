Describe "Get-PowerPlatformCheckerAppComponentType" {
    It "resolves known appmodule component types" -TestCases @(
        @{ Type = 1; Expected = "Entities" }
        @{ Type = 26; Expected = "Views" }
        @{ Type = 29; Expected = "Business Process Flows" }
        @{ Type = 48; Expected = "Command (Ribbon)" }
        @{ Type = 59; Expected = "Charts" }
        @{ Type = 60; Expected = "Forms" }
        @{ Type = 61; Expected = "Web Resources" }
        @{ Type = 62; Expected = "Sitemap" }
    ) {
        param($Type, $Expected)

        (& (Get-Module PowerPlatformChecker) { param($value) Get-PowerPlatformCheckerAppComponentType -Type $value } $Type) | Should -Be $Expected
    }

    It "returns unknown for unmapped type" {
        (& (Get-Module PowerPlatformChecker) { Get-PowerPlatformCheckerAppComponentType -Type 999 }) | Should -Be "Unknown (999)"
    }
}
