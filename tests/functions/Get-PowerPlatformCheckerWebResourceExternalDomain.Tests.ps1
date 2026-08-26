. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerWebResourceExternalDomain" {
    BeforeAll {
        $script:webResourceExternalDomainFixturePath = (Resolve-Path (Join-Path $PSScriptRoot "..\fixtures\webresource-external-domain-edge\Managed\WebResources")).Path
    }

    It "extracts unique normalized domains from absolute and protocol-relative URLs" {
        $sourcePath = Join-Path $script:webResourceExternalDomainFixturePath "ExternalUrls.js"

        $domains = InModuleScope PowerPlatformChecker {
            param($Path)
            Get-PowerPlatformCheckerWebResourceExternalDomain -SourcePath $Path
        } -Parameters @{ Path = $sourcePath }

        $domains | Should -Be @('api.example.test', 'portal.contoso.test')
    }

    It "ignores local and relative addresses" {
                $sourcePath = Join-Path $script:webResourceExternalDomainFixturePath "LocalUrls.js"

        $domains = InModuleScope PowerPlatformChecker {
            param($Path)
            Get-PowerPlatformCheckerWebResourceExternalDomain -SourcePath $Path
        } -Parameters @{ Path = $sourcePath }

        $domains.Count | Should -Be 0
    }
}
