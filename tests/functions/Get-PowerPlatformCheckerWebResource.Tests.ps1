. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerWebResource" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
    }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "returns javascript resources and dependencies" {
        $resources = Get-PowerPlatformCheckerWebResource -SolutionPath $script:solutionPath -JavaScriptOnly

        $resources.Count | Should -Be 2
        $orderForm = $resources | Where-Object Name -eq "ppc_script/OrderForm.js" | Select-Object -First 1
        $shared = $resources | Where-Object Name -eq "ppc_script/Shared.js" | Select-Object -First 1
        $orderForm.Type | Should -Be "JavaScript"
        $orderForm.Kind | Should -Be "Script"
        $orderForm.Methods | Should -Contain "onLoad"
        $orderForm.Dependencies | Should -Contain "ppc_script/Shared.js"
        $shared.Type | Should -Be "JavaScript"
        $shared.Methods | Should -Contain "setTabVisibility"
    }

    It "ignores malformed dependency xml without failing" {
        $testRoot = Join-Path $TestDrive "MalformedDependencyFixture"
        $resourcePath = Join-Path $testRoot "WebResources\sample_script"
        New-Item -ItemType Directory -Path $resourcePath -Force | Out-Null

        @"
<WebResource>
    <Name>sample_script/Broken.js</Name>
    <DisplayName>Broken Script</DisplayName>
    <WebResourceType>3</WebResourceType>
    <DependencyXml>&lt;Dependencies&gt;&lt;Dependency&gt;&lt;Library name="sample_script/Helper.js"&gt;&lt;/Dependency&gt;&lt;/Dependencies&gt;</DependencyXml>
    <FileName>/WebResources/sample_scriptBrokenjs11111111-1111-1111-1111-111111111111</FileName>
</WebResource>
"@ | Set-Content -Path (Join-Path $resourcePath "Broken.js.data.xml") -Encoding utf8BOM

        $resources = Get-PowerPlatformCheckerWebResource -SolutionPath $testRoot -JavaScriptOnly

        $resources.Count | Should -Be 1
        $resources[0].Dependencies.Count | Should -Be 0
    }

    It "returns non-javascript resources when JavaScriptOnly is not set" {
        $testRoot = Join-Path $TestDrive "MixedWebResourceFixture"
        $resourcePath = Join-Path $testRoot "WebResources\sample_text"
        New-Item -ItemType Directory -Path $resourcePath -Force | Out-Null

        @"
<WebResource>
    <Name>sample_text/Notes.txt</Name>
    <DisplayName>Notes</DisplayName>
    <WebResourceType>5</WebResourceType>
    <DependencyXml></DependencyXml>
    <FileName>/WebResources/sample_textNotestxt11111111-1111-1111-1111-111111111111</FileName>
</WebResource>
"@ | Set-Content -Path (Join-Path $resourcePath "Notes.txt.data.xml") -Encoding utf8BOM

        $resources = Get-PowerPlatformCheckerWebResource -SolutionPath $testRoot

        $resources.Count | Should -Be 1
        $resources[0].Type | Should -Be "PNG"
    }

    It "extracts namespaced javascript methods without treating keywords as methods" {
        $testRoot = Join-Path $TestDrive "NamespacedMethodFixture"
        $resourcePath = Join-Path $testRoot "WebResources\sample_script"
        New-Item -ItemType Directory -Path $resourcePath -Force | Out-Null

        @"
<WebResource>
    <Name>sample_script/App.js</Name>
    <DisplayName>App Script</DisplayName>
    <WebResourceType>3</WebResourceType>
    <DependencyXml></DependencyXml>
    <FileName>/WebResources/sample_scriptAppjs11111111-1111-1111-1111-111111111111</FileName>
</WebResource>
"@ | Set-Content -Path (Join-Path $resourcePath "App.js.data.xml") -Encoding utf8BOM

        @"
var Sample = Sample || {};
Sample.Form = Sample.Form || {};

Sample.Form.onLoad = (executionContext) => {
    if (!executionContext) {
        return;
    }
};

Sample.Form.onSave = function(context) {
    return context;
};
"@ | Set-Content -Path (Join-Path $resourcePath "App.js") -Encoding utf8BOM

        $resources = Get-PowerPlatformCheckerWebResource -SolutionPath $testRoot -JavaScriptOnly

        $resources.Count | Should -Be 1
        $resources[0].Methods | Should -Contain "onLoad"
        $resources[0].Methods | Should -Contain "onSave"
        $resources[0].Methods | Should -Not -Contain "if"
    }
}

