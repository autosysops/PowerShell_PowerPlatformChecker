. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Set-PowerPlatformCheckerStyle" {
    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {}
    }

    It "updates configured colors from named key parameters and returns a hashtable" {
        try {
            $result = Set-PowerPlatformCheckerStyle -StyleTarget ArchitectureDiagram -Flow "#778899"
            $result.GetType().Name | Should -Be "Hashtable"
            $result.Flow | Should -Be "#778899"

            $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath (Get-PowerPlatformCheckerFixtureSolutionPath)
            $markdown | Should -Match "classDef Flow fill:#778899,stroke:#5E5B52"
        }
        finally {
            Set-PowerPlatformCheckerStyle -StyleTarget ArchitectureDiagram -Flow "#DBE4EE" | Out-Null
        }
    }

    It "updates multiple configured colors in a single call" {
        try {
            $result = Set-PowerPlatformCheckerStyle -StyleTarget ArchitectureDiagram -Flow "#335577" -Stroke "#111111"
            $result.Flow | Should -Be "#335577"
            $result.Stroke | Should -Be "#111111"

            $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath (Get-PowerPlatformCheckerFixtureSolutionPath)
            $markdown | Should -Match "classDef Flow fill:#335577,stroke:#111111"
        }
        finally {
            Set-PowerPlatformCheckerStyle -StyleTarget ArchitectureDiagram -Flow "#DBE4EE" -Stroke "#5E5B52" | Out-Null
        }
    }

    It "throws when no updates are provided" {
        { Set-PowerPlatformCheckerStyle -StyleTarget ArchitectureDiagram } | Should -Throw
    }

    It "throws for empty values" {
        { Set-PowerPlatformCheckerStyle -StyleTarget ArchitectureDiagram -Flow "" } | Should -Throw
    }

    It "throws for unsupported style keys" {
        { Set-PowerPlatformCheckerStyle -StyleTarget ArchitectureDiagram -NotARealKey "#000000" } | Should -Throw
    }
}