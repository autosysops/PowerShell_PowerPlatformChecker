. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Set-PowerPlatformCheckerDiagramStyle" {
    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {}
    }

    It "updates configured colors and returns a hashtable" {
        try {
            $result = Set-PowerPlatformCheckerDiagramStyle -ColorMap @{ Flow = "#778899" }
            $result.GetType().Name | Should -Be "Hashtable"
            $result.Flow | Should -Be "#778899"

            $markdown = Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath (Get-PowerPlatformCheckerFixtureSolutionPath)
            $markdown | Should -Match "classDef Flow fill:#778899,stroke:#5E5B52"
        }
        finally {
            Set-PowerPlatformCheckerDiagramStyle -ColorMap @{ Flow = "#DBE4EE" } | Out-Null
        }
    }

    It "throws for empty values" {
        { Set-PowerPlatformCheckerDiagramStyle -ColorMap @{ Flow = "" } } | Should -Throw
    }
}


