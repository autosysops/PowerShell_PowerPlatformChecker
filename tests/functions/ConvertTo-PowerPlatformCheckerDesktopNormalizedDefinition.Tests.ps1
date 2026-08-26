. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "ConvertTo-PowerPlatformCheckerDesktopNormalizedDefinition" {
    It "normalizes standalone desktop definition transformations" -ForEach @(
        @{
            Name = 'matching wrapper quotes'
            Definition = '"DISPLAY Message=''ok''"'
            ExpectedValue = "DISPLAY Message='ok'"
        }
        @{
            Name = 'unmatched wrapper quotes'
            Definition = '"DISPLAY Message=''ok'''
            ExpectedValue = '"DISPLAY Message=''ok'''
        }
        @{
            Name = 'escaped double quotes'
            Definition = 'Text: \"quoted\"'
            ExpectedValue = 'Text: "quoted"'
        }
        @{
            Name = 'escaped carriage-return line-feeds'
            Definition = 'DISPLAY\r\nWRITE'
            ExpectedValue = "DISPLAY`nWRITE"
        }
        @{
            Name = 'escaped line-feeds'
            Definition = 'DISPLAY\nWRITE'
            ExpectedValue = "DISPLAY`nWRITE"
        }
        @{
            Name = 'empty definitions'
            Definition = ''
            ExpectedValue = ''
        }
        @{
            Name = 'null definitions'
            Definition = $null
            ExpectedValue = ''
        }
    ) {
        $normalized = & (Get-Module PowerPlatformChecker) {
            param($value)
            ConvertTo-PowerPlatformCheckerDesktopNormalizedDefinition -Definition $value
        } $Definition

        $normalized | Should -Be $ExpectedValue
    }

    It "unwraps and normalizes escaped desktop definitions" {
        $definition = '"DISPLAY Message: \"ok\"\r\nWRITE Text: \"done\""'
        $normalized = & (Get-Module PowerPlatformChecker) {
            param($value)
            ConvertTo-PowerPlatformCheckerDesktopNormalizedDefinition -Definition $value
        } $definition
        $expected = "DISPLAY Message: `"ok`"`nWRITE Text: `"done`""

        $normalized | Should -Be $expected
    }
}



