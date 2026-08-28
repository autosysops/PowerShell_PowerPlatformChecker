. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerCanvasMsAppInteractionProfile" {
    It "extracts connected data sources, domains, and read/write interaction hints from msapp sources" {
        $msappRoot = Join-Path $TestDrive "msapp"
        $referencesPath = Join-Path $msappRoot "References"
        $srcPath = Join-Path $msappRoot "Src"
        New-Item -Path $referencesPath -ItemType Directory -Force | Out-Null
        New-Item -Path $srcPath -ItemType Directory -Force | Out-Null

        $dataSourcesJson = @'
{
  "DataSources": [
    {
      "Name": "E-Learning-Content",
      "Type": "ConnectedDataSourceInfo",
      "DatasetName": "https://contoso.sharepoint.com/sites/elearning",
      "TableName": "content-list",
      "ApiId": "/providers/microsoft.powerapps/apis/shared_sharepointonline",
      "IsWritable": true
    },
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
  Course Selection Screen:
    Children:
      - Course Button:
          Properties:
            Items: =Filter('E-Learning-Content','Course Collection'="Security")
            OnSelect: |-
              =Patch(
                  'E-Learning-Progress',
                  Defaults('E-Learning-Progress'),
                  { Title: User().Email }
              )
'@
        Set-Content -Path (Join-Path $srcPath "Course Selection Screen.pa.yaml") -Value $sourceYaml -Encoding utf8BOM

        $msappPath = Join-Path $TestDrive "sample.msapp"
        Compress-Archive -Path (Join-Path $msappRoot "*") -DestinationPath $msappPath -Force

        InModuleScope PowerPlatformChecker {
            param($Path)
            $profile = Get-PowerPlatformCheckerCanvasMsAppInteractionProfile -MsAppPath $Path

            @($profile.ConnectedDataSources).Count | Should -Be 2
            @($profile.ExternalDomains) | Should -Contain "https://contoso.sharepoint.com"
            @($profile.DomainInteractions | Where-Object { $_.DataSourceName -eq 'E-Learning-Content' }).Count | Should -Be 1
            @($profile.DomainInteractions | Where-Object { $_.DataSourceName -eq 'E-Learning-Progress' -and $_.Direction -in @('Write', 'Mixed') }).Count | Should -Be 1
            @($profile.SourceSignals | Where-Object { $_.Screen -eq 'Course Selection Screen' -and $_.Element -eq 'Course Button' }).Count | Should -BeGreaterThan 0
            $profile.InteractionDirection | Should -BeIn @('Read', 'Write', 'Mixed')
            $profile.InteractionEvidence | Should -Be 'SourceFormula'
        } -Parameters @{ Path = $msappPath }
    }
}
