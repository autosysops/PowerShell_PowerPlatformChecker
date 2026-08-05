Describe "Get-PowerPlatformCheckerModelDrivenAppComponentType" {
    It "resolves known appmodule component types" {
        (Get-PowerPlatformCheckerModelDrivenAppComponentType -Type 1) | Should -Be "Entities"
        (Get-PowerPlatformCheckerModelDrivenAppComponentType -Type 29) | Should -Be "Business Process Flows"
        (Get-PowerPlatformCheckerModelDrivenAppComponentType -Type 62) | Should -Be "Sitemap"
    }

    It "returns unknown for unmapped type" {
        (Get-PowerPlatformCheckerModelDrivenAppComponentType -Type 999) | Should -Be "Unknown (999)"
    }
}
