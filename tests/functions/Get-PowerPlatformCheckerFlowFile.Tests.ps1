. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerFlowFile" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
        $script:canvasExternalSolutionPath = Get-PowerPlatformCheckerCanvasExternalFixtureSolutionPath
    }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "returns json and xml variants for flow id" {
        $json = Get-PowerPlatformCheckerFlowFile -SolutionPath $script:solutionPath -FlowId "11111111-1111-1111-1111-111111111111" -Type json
        $xml = Get-PowerPlatformCheckerFlowFile -SolutionPath $script:solutionPath -FlowId "11111111-1111-1111-1111-111111111111" -Type xml

        ($json | Select-Object -First 1) | Should -Match "SampleFlow-11111111-1111-1111-1111-111111111111.json"
        ($xml | Select-Object -First 1) | Should -Match "SampleFlow-11111111-1111-1111-1111-111111111111.json.data.xml"
    }

    It "returns an empty set when the solution has no Workflows folder" {
        $result = @(Get-PowerPlatformCheckerFlowFile -SolutionPath $script:canvasExternalSolutionPath -Type json)

        $result.Count | Should -Be 0
    }
}

