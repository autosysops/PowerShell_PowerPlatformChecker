. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerDiagramIncludePolicy" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
    }

    It "returns include flags for all supported element types" {
        InModuleScope PowerPlatformChecker {
            $policy = Get-PowerPlatformCheckerDiagramIncludePolicy -IncludeElements @("Flows", "CanvasApps", "ModelDrivenApps", "EnvironmentVariables", "Connections", "Entities", "DefaultEntities", "WebResources", "ExternalDomains")

            $policy.IncludeFlows | Should -BeTrue
            $policy.IncludeCanvasApps | Should -BeTrue
            $policy.IncludeModelDrivenApps | Should -BeTrue
            $policy.IncludeEnvironmentVariables | Should -BeTrue
            $policy.IncludeConnections | Should -BeTrue
            $policy.IncludeEntities | Should -BeTrue
            $policy.IncludeDefaultEntities | Should -BeTrue
            $policy.IncludeWebResources | Should -BeTrue
            $policy.IncludeExternalDomains | Should -BeTrue
        }
    }

    It "disables non-selected elements" {
        InModuleScope PowerPlatformChecker {
            $policy = Get-PowerPlatformCheckerDiagramIncludePolicy -IncludeElements @("Flows", "Connections")

            $policy.IncludeFlows | Should -BeTrue
            $policy.IncludeConnections | Should -BeTrue
            $policy.IncludeEntities | Should -BeFalse
            $policy.IncludeWebResources | Should -BeFalse
            $policy.IncludeExternalDomains | Should -BeFalse
            $policy.IncludeCanvasApps | Should -BeFalse
        }
    }

    It "sets scope flags based on filter parameters" {
        InModuleScope PowerPlatformChecker {
            $policy = Get-PowerPlatformCheckerDiagramIncludePolicy -IncludeElements @("Flows") -HasFlowFilter -HasCanvasFilter:$false -HasModelDrivenFilter:$false
            $policy.IsScopedDiagram | Should -BeTrue
            $policy.AllowFlowPass | Should -BeTrue
            $policy.AllowCanvasPass | Should -BeFalse

            $policy2 = Get-PowerPlatformCheckerDiagramIncludePolicy -IncludeElements @("CanvasApps") -HasFlowFilter:$false -HasCanvasFilter:$true -HasModelDrivenFilter:$false
            $policy2.IsScopedDiagram | Should -BeTrue
            $policy2.AllowFlowPass | Should -BeFalse
            $policy2.AllowCanvasPass | Should -BeTrue
        }
    }
}
