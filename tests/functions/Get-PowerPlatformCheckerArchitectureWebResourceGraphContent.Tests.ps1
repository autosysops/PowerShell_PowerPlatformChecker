. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerArchitectureWebResourceGraphContent" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
    }

    It "renders script classes with methods and dependency links" {
        InModuleScope PowerPlatformChecker {
            $webResources = @(
                [pscustomobject]@{
                    Name = "main.js"
                    MermaidId = "main_js"
                    DisplayName = "Main"
                    Kind = "Script"
                    Type = "JavaScript"
                    Methods = @("onLoad")
                    Dependencies = @("shared.js")
                },
                [pscustomobject]@{
                    Name = "shared.js"
                    MermaidId = "shared_js"
                    DisplayName = "Shared"
                    Kind = "Script"
                    Type = "JavaScript"
                    Methods = @()
                    Dependencies = @()
                }
            )

            Mock -CommandName Get-PowerPlatformCheckerWebResource -ModuleName PowerPlatformChecker -MockWith { $webResources }
            $result = Get-PowerPlatformCheckerArchitectureWebResourceGraphContent -SolutionPath "C:\dummy" -SolutionObject ([pscustomobject]@{ Entities = @() }) -IncludeWebResources:$true -IncludeExternalDomains:$true

            @($result.Nodes | Where-Object { $_.Id -eq "main_js" }).Count | Should -Be 1
            ($result.Nodes | Where-Object Id -eq "main_js").Members | Should -Contain "  [Script]onLoad"
            @($result.Edges | Where-Object { $_.SourceId -eq "main_js" -and $_.TargetId -eq "shared_js" -and $_.Label -eq "Dependency" }).Count | Should -Be 1
        }
    }

    It "keeps unresolved dependencies visible as missing webresource nodes" {
        InModuleScope PowerPlatformChecker {
            $webResources = @(
                [pscustomobject]@{
                    Name = "main.js"
                    MermaidId = "main_js"
                    DisplayName = "Main"
                    Kind = "Script"
                    Type = "JavaScript"
                    Methods = @()
                    Dependencies = @("external.js")
                }
            )

            Mock -CommandName Get-PowerPlatformCheckerWebResource -ModuleName PowerPlatformChecker -MockWith { $webResources }
            $result = Get-PowerPlatformCheckerArchitectureWebResourceGraphContent -SolutionPath "C:\dummy" -SolutionObject ([pscustomobject]@{ Entities = @() }) -IncludeWebResources:$true -IncludeExternalDomains:$true

            @($result.Nodes | Where-Object { $_.Id -eq "external_js" -and $_.DisplayName -eq "external.js" }).Count | Should -Be 1
        }
    }

    It "adds external domain nodes and edges for outbound web resource calls" {
        InModuleScope PowerPlatformChecker {
            $webResources = @(
                [pscustomobject]@{
                    Name = "main.js"
                    MermaidId = "main_js"
                    DisplayName = "Main"
                    Kind = "Script"
                    Type = "JavaScript"
                    Methods = @()
                    Dependencies = @()
                    ExternalDomains = @("api.example.test")
                }
            )

            Mock -CommandName Get-PowerPlatformCheckerWebResource -ModuleName PowerPlatformChecker -MockWith { $webResources }
            $result = Get-PowerPlatformCheckerArchitectureWebResourceGraphContent -SolutionPath "C:\dummy" -SolutionObject ([pscustomobject]@{ Entities = @() }) -IncludeWebResources:$true -IncludeExternalDomains:$true

            @($result.Nodes | Where-Object { $_.ClassKind -eq "ExternalDomain" -and $_.DisplayName -eq "api.example.test" }).Count | Should -Be 1
            @($result.Edges | Where-Object { $_.SourceId -eq "main_js" -and $_.Label -eq "ExternalCall" }).Count | Should -Be 1
        }
    }
}
