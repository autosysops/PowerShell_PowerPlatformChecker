. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerModelDrivenApp" {
    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
    }
    BeforeEach { Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {} }

    It "returns app metadata from appmodule and sitemap" {
        $apps = Get-PowerPlatformCheckerModelDrivenApp -SolutionPath $script:solutionPath

        $apps.Count | Should -Be 1
        $apps[0].UniqueName | Should -Be "ppc_ModelApp"
        $apps[0].DisplayName | Should -Be "Sales Model App"
        $apps[0].Entities | Should -Contain "ppc_order"
        $apps[0].Entities | Should -Contain "ppc_supplier"
        $apps[0].Entities | Should -Contain "ppc_productpricespecification"
        $apps[0].FlowIds | Should -Contain "11111111-1111-1111-1111-111111111111"
        ($apps[0].Components | Where-Object { $_.ComponentType -eq 1 }).Count | Should -BeGreaterThan 0
        ($apps[0].Components | Where-Object { $_.ComponentType -eq 29 }).Count | Should -BeGreaterThan 0
        ($apps[0].Components | Where-Object { $_.ComponentType -eq 62 }).Count | Should -BeGreaterThan 0
    }

    It "discovers fixture web resources from entity form xml without appmodule js components" {
        $app = Get-PowerPlatformCheckerModelDrivenApp -SolutionPath $script:solutionPath -AppName "ppc_ModelApp" | Select-Object -First 1

        @($app.WebResources).Count | Should -Be 0

        $entityEntry = $app.EntityWebResources | Where-Object { $_.EntitySchemaName -eq "ppc_order" } | Select-Object -First 1
        $entityEntry | Should -Not -BeNullOrEmpty
        $entityEntry.WebResources | Should -Contain "ppc_script/OrderForm.js"
    }

        It "keeps model-driven app web resources limited to direct app component links" {
                $testRoot = Join-Path $TestDrive "ModelDrivenAppFormLibraryFixture"
                $appModulePath = Join-Path $testRoot "AppModules\sample_model_app"
                $entityFormPath = Join-Path $testRoot "Entities\sample_account\FormXml\main"
                $webResourcePath = Join-Path $testRoot "WebResources\sample_script"

                New-Item -ItemType Directory -Path $appModulePath -Force | Out-Null
                New-Item -ItemType Directory -Path $entityFormPath -Force | Out-Null
                New-Item -ItemType Directory -Path $webResourcePath -Force | Out-Null

                @"
<AppModule>
    <UniqueName>sample_model_app</UniqueName>
    <LocalizedNames>
        <LocalizedName description="Sample Model App" languagecode="1033" />
    </LocalizedNames>
    <AppModuleComponents>
        <AppModuleComponent type="1" schemaName="sample_account" />
    </AppModuleComponents>
</AppModule>
"@ | Set-Content -Path (Join-Path $appModulePath "AppModule_managed.xml") -Encoding utf8BOM

                @"
<form>
    <formLibraries>
        <Library name="sample_script/Form.js" libraryUniqueId="{11111111-1111-1111-1111-111111111111}" />
    </formLibraries>
    <events>
        <event>
            <Handler functionName="Sample.OnLoad" libraryName="sample_script/Form.js" enabled="true" />
        </event>
    </events>
</form>
"@ | Set-Content -Path (Join-Path $entityFormPath "sample_form.xml") -Encoding utf8BOM

                @"
<WebResource>
    <Name>sample_script/Form.js</Name>
    <DisplayName>Sample Form Script</DisplayName>
    <WebResourceType>3</WebResourceType>
    <DependencyXml>&lt;Dependencies&gt;&lt;Dependency componentType="WebResource"&gt;&lt;Library libraryUniqueId="{22222222-2222-2222-2222-222222222222}" name="sample_script/Helper.js" displayName="Helper" /&gt;&lt;/Dependency&gt;&lt;/Dependencies&gt;</DependencyXml>
    <FileName>/WebResources/sample_scriptFormjs11111111-1111-1111-1111-111111111111</FileName>
</WebResource>
"@ | Set-Content -Path (Join-Path $webResourcePath "Form.js.data.xml") -Encoding utf8BOM

        $webResources = Get-PowerPlatformCheckerModelDrivenApp -SolutionPath $testRoot | Select-Object -First 1 | Select-Object -ExpandProperty WebResources

        @($webResources).Count | Should -Be 0
        }

        It "captures entity-level webresource usage from form xml" {
                $testRoot = Join-Path $TestDrive "ModelDrivenEntityWebResourceFixture"
                $appModulePath = Join-Path $testRoot "AppModules\sample_model_app"
                $entityFormPath = Join-Path $testRoot "Entities\sample_account\FormXml\main"
                $webResourcePath = Join-Path $testRoot "WebResources\sample_script"

                New-Item -ItemType Directory -Path $appModulePath -Force | Out-Null
                New-Item -ItemType Directory -Path $entityFormPath -Force | Out-Null
                New-Item -ItemType Directory -Path $webResourcePath -Force | Out-Null

                @"
<AppModule>
    <UniqueName>sample_model_app</UniqueName>
    <LocalizedNames>
        <LocalizedName description="Sample Model App" languagecode="1033" />
    </LocalizedNames>
    <AppModuleComponents>
        <AppModuleComponent type="1" schemaName="sample_account" />
    </AppModuleComponents>
</AppModule>
"@ | Set-Content -Path (Join-Path $appModulePath "AppModule_managed.xml") -Encoding utf8BOM

                @"
<form>
    <formLibraries>
        <Library name="sample_script/Form.js" libraryUniqueId="{11111111-1111-1111-1111-111111111111}" />
    </formLibraries>
</form>
"@ | Set-Content -Path (Join-Path $entityFormPath "sample_form.xml") -Encoding utf8BOM

                @"
<WebResource>
    <Name>sample_script/Form.js</Name>
    <DisplayName>Sample Form Script</DisplayName>
    <WebResourceType>3</WebResourceType>
    <DependencyXml>&lt;Dependencies&gt;&lt;Dependency componentType="WebResource"&gt;&lt;Library libraryUniqueId="{22222222-2222-2222-2222-222222222222}" name="sample_script/Helper.js" displayName="Helper" /&gt;&lt;/Dependency&gt;&lt;/Dependencies&gt;</DependencyXml>
    <FileName>/WebResources/sample_scriptFormjs11111111-1111-1111-1111-111111111111</FileName>
</WebResource>
"@ | Set-Content -Path (Join-Path $webResourcePath "Form.js.data.xml") -Encoding utf8BOM

                $app = Get-PowerPlatformCheckerModelDrivenApp -SolutionPath $testRoot | Select-Object -First 1
                $entityEntry = $app.EntityWebResources | Where-Object { $_.EntitySchemaName -eq "sample_account" } | Select-Object -First 1

                $entityEntry | Should -Not -BeNullOrEmpty
                $entityEntry.WebResources | Should -Contain "sample_script/Form.js"
        }

        It "includes direct app component javascript as direct webresource links" {
                $testRoot = Join-Path $TestDrive "ModelDrivenDirectWebResourceFixture"
                $appModulePath = Join-Path $testRoot "AppModules\sample_model_app"

                New-Item -ItemType Directory -Path $appModulePath -Force | Out-Null

                @"
<AppModule>
    <UniqueName>sample_model_app</UniqueName>
    <LocalizedNames>
        <LocalizedName description="Sample Model App" languagecode="1033" />
    </LocalizedNames>
    <AppModuleComponents>
        <AppModuleComponent type="61" schemaName="sample_script/App.js" />
    </AppModuleComponents>
</AppModule>
"@ | Set-Content -Path (Join-Path $appModulePath "AppModule_managed.xml") -Encoding utf8BOM

                $app = Get-PowerPlatformCheckerModelDrivenApp -SolutionPath $testRoot | Select-Object -First 1

                $app.WebResources | Should -Contain "sample_script/App.js"
                ($app.Components | Where-Object { $_.ComponentType -eq 61 } | Select-Object -First 1).ComponentTypeName | Should -Be "Web Resources"
        }
}

