. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerStyle" {
    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {}
    }

    It "returns style values as a hashtable" {
        $style = Get-PowerPlatformCheckerStyle -StyleTarget ArchitectureDiagram

        $style.GetType().Name | Should -Be "Hashtable"
        $style.ContainsKey("Flow") | Should -BeTrue
        $style.ContainsKey("Stroke") | Should -BeTrue
    }

    It "returns expected key values directly" {
        $style = Get-PowerPlatformCheckerStyle -StyleTarget ArchitectureDiagram

        $style.Flow | Should -Not -BeNullOrEmpty
        $style.Solution | Should -Be "#f5f5fa"
        $style.ExternalDomain | Should -Be "#E6D3A3"
        $style.Stroke | Should -Be "#5E5B52"
    }

    It "throws for unsupported style targets in module state" {
        InModuleScope PowerPlatformChecker {
            $originalStyles = $script:PowerPlatformCheckerDiagramStyles
            try {
                $script:PowerPlatformCheckerDiagramStyles = @{}
                { Get-PowerPlatformCheckerStyle -StyleTarget ArchitectureDiagram } | Should -Throw "Unsupported style target*"
            }
            finally {
                $script:PowerPlatformCheckerDiagramStyles = $originalStyles
            }
        }
    }

    It "sends usage telemetry without style values" {
        $telemetryCalls = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {
            param([string]$ModuleName, [string]$EventName, [hashtable]$PropertiesHash)
            [void]$telemetryCalls.Add([pscustomobject]@{ ModuleName = $ModuleName; EventName = $EventName; PropertiesHash = $PropertiesHash })
        }

        [void](Get-PowerPlatformCheckerStyle)
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerStyle" -ExpectedKeys @("StyleTargetExplicit") -ConfidentialValues @("ArchitectureDiagram")

        $telemetryCalls.Clear()
        [void](Get-PowerPlatformCheckerStyle -StyleTarget "ArchitectureDiagram")
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerStyle" -ExpectedKeys @("StyleTargetExplicit") -ConfidentialValues @("ArchitectureDiagram")
    }
}