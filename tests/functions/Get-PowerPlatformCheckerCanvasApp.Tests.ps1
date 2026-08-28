. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerCanvasApp" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
        $script:invalidAppPath = (Resolve-Path (Join-Path $PSScriptRoot "..\fixtures\invalid-app-edge\Managed")).Path
    }
    It "returns canvas app metadata" {
        InModuleScope PowerPlatformChecker {
            param($SolutionPath)
            $apps = Get-PowerPlatformCheckerCanvasApp -SolutionPath $SolutionPath
            $apps.Count | Should -Be 1
            $apps[0].DisplayName | Should -Be "Sales Canvas App"
            $apps[0].ConnectionReferences.Count | Should -Be 2
        } -Parameters @{ SolutionPath = $script:solutionPath }
    }

    It "handles invalid canvas metadata fixtures gracefully" {
        InModuleScope PowerPlatformChecker {
            param($SolutionPath)
            $warnings = @()
            $apps = Get-PowerPlatformCheckerCanvasApp -SolutionPath $SolutionPath -WarningVariable warnings -WarningAction SilentlyContinue

            @($apps).Count | Should -Be 0
            (@($warnings) -join " `n") | Should -Match "Invalid canvas app"
        } -Parameters @{ SolutionPath = $script:invalidAppPath }
    }

    It "returns empty set when CanvasApps folder is missing" {
        $emptySolutionPath = Join-Path $TestDrive "NoCanvasApps"
        New-Item -Path $emptySolutionPath -ItemType Directory -Force | Out-Null

        InModuleScope PowerPlatformChecker {
            param($SolutionPath)
            $apps = Get-PowerPlatformCheckerCanvasApp -SolutionPath $SolutionPath
            @($apps).Count | Should -Be 0
        } -Parameters @{ SolutionPath = $emptySolutionPath }
    }

    It "captures invalid connection reference payload warnings" {
        InModuleScope PowerPlatformChecker {
            param($SolutionPath)
            $warnings = @()
            [void](Get-PowerPlatformCheckerCanvasApp -SolutionPath $SolutionPath -Name "Invalid Canvas Connection" -WarningVariable warnings -WarningAction SilentlyContinue)

            (@($warnings) -join " `n") | Should -Match "Invalid canvas app connection reference payload"
        } -Parameters @{ SolutionPath = $script:invalidAppPath }
    }

        It "enriches canvas app metadata with msapp datasource and interaction signals when available" {
                $solutionPath = Join-Path $TestDrive "CanvasMsApp"
                $canvasPath = Join-Path $solutionPath "CanvasApps"
                $msappExpandPath = Join-Path $TestDrive "CanvasMsAppExpanded"
                $referencesPath = Join-Path $msappExpandPath "References"
                $srcPath = Join-Path $msappExpandPath "Src"

                New-Item -Path $canvasPath -ItemType Directory -Force | Out-Null
                New-Item -Path $referencesPath -ItemType Directory -Force | Out-Null
                New-Item -Path $srcPath -ItemType Directory -Force | Out-Null

                $metaXml = @'
<CanvasApp xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <Name>elearning_canvas</Name>
    <DisplayName>E-Learning Canvas</DisplayName>
    <Description>Fixture for msapp enrichment</Description>
    <Publisher>Test Publisher</Publisher>
    <ConnectionReferences>{"refSharePoint":{"id":"/providers/microsoft.powerapps/apis/shared_sharepointonline","xrmConnectionReferenceLogicalName":"test_sharedsharepointonline","displayName":"SharePoint Test"}}</ConnectionReferences>
    <DatabaseReferences>{"default.cds":{"dataSources":{"Courses":{"entitySetName":"ppc_courses","logicalName":"ppc_course"}}}}</DatabaseReferences>
</CanvasApp>
'@
                Set-Content -Path (Join-Path $canvasPath "elearning_canvas.meta.xml") -Value $metaXml -Encoding utf8BOM

                $dataSourcesJson = @'
{
    "DataSources": [
        {
            "Name": "E-Learning-Progress",
            "Type": "ConnectedDataSourceInfo",
            "DatasetName": "https://contoso.sharepoint.com/sites/elearning",
            "TableName": "progress-list",
            "ApiId": "/providers/microsoft.powerapps/apis/shared_sharepointonline",
            "IsWritable": true
        }
    ]
}
'@
                Set-Content -Path (Join-Path $referencesPath "DataSources.json") -Value $dataSourcesJson -Encoding utf8BOM

                $sourceYaml = @'
Screens:
    Course Screen:
        Children:
            - Next Button:
                    Properties:
                        OnSelect: |-
                            =Patch(
                                    'E-Learning-Progress',
                                    Defaults('E-Learning-Progress'),
                                    { Title: User().Email }
                            )
'@
                Set-Content -Path (Join-Path $srcPath "Course Screen.pa.yaml") -Value $sourceYaml -Encoding utf8BOM

                Compress-Archive -Path (Join-Path $msappExpandPath "*") -DestinationPath (Join-Path $canvasPath "elearning_canvas_DocumentUri.msapp") -Force

                InModuleScope PowerPlatformChecker {
                        param($SolutionPath)
                        $apps = Get-PowerPlatformCheckerCanvasApp -SolutionPath $SolutionPath
                        $app = $apps | Select-Object -First 1

                        $app.DisplayName | Should -Be "E-Learning Canvas"
                        @($app.ConnectedDataSources).Count | Should -Be 1
                        @($app.ExternalDomains) | Should -Contain "https://contoso.sharepoint.com"
                        @($app.DomainInteractions | Where-Object { $_.DataSourceName -eq 'E-Learning-Progress' -and $_.Direction -eq 'Write' }).Count | Should -Be 1
                        $app.InteractionDirection | Should -Be "Write"
                        $app.InteractionEvidence | Should -Be "SourceFormula"
                } -Parameters @{ SolutionPath = $solutionPath }
        }
}

