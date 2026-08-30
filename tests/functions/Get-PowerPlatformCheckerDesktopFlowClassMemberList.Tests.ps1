. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerDesktopFlowClassMemberList" {
    BeforeAll {
        $script:desktopClassMemberEdgePath = (Resolve-Path (Join-Path $PSScriptRoot "..\fixtures\desktop-class-members-edge\Managed\Workflows")).Path
        $script:desktopFlowChartSolutionPath = (Resolve-Path (Join-Path $PSScriptRoot "..\fixtures\desktop-flowchart-solution\Managed")).Path
    }

    It "returns expected class members for file-backed desktop flow cases" -ForEach @(
        @{
            Name = 'unresolvable paths'
            Path = '__MISSING__'
            ExpectedMembers = @()
        }
        @{
            Name = 'merged metadata and definition declarations'
            Path = 'DesktopClassMembers-31313131-3131-3131-3131-313131313131.json'
            ExpectedMembers = @('    [INPUT]var_Input', '    [OUTPUT]var_Output', '    [OUTPUT]var_Extra')
        }
        @{
            Name = 'wildcard flow paths'
            Path = 'DesktopWildcard-*.json'
            ExpectedMembers = @('    [INPUT]var_FromDefinition')
        }
    ) {
        $resolvedPath = if ($Path -eq '__MISSING__') {
            Join-Path $script:desktopClassMemberEdgePath 'Missing*.json'
        }
        else {
            Join-Path $script:desktopClassMemberEdgePath $Path
        }

        $members = & (Get-Module PowerPlatformChecker) {
            param($path)
            Get-PowerPlatformCheckerDesktopFlowClassMemberList -Path $path
        } $resolvedPath

        $members | Should -Be $ExpectedMembers
    }

    It "returns subflow members for desktop flows that declare FUNCTION blocks" {
        $path = Join-Path $script:desktopFlowChartSolutionPath "Workflows\DesktopFlow-Subflows-99999999-9999-9999-9999-999999999999.json"

        $members = & (Get-Module PowerPlatformChecker) {
            param($resolvedPath)
            Get-PowerPlatformCheckerDesktopFlowClassMemberList -Path $resolvedPath
        } $path

        $members | Should -Contain '    Subflow(ProcessOrder)'
        $members | Should -Contain '    Subflow(SendAudit)'
    }
}


