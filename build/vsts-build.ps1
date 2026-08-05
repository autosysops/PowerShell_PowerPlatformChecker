<#
This script publishes the module to the gallery.
It expects as input an ApiKey authorized to publish the module.

Insert any build steps you may need to take before publishing it here.
#>
param (
	$ApiKey,

	$WorkingDirectory,

	$Repository = 'PSGallery',

	[switch]
	$LocalRepo,

	[switch]
	$SkipPublish,

	[switch]
	$AutoVersion,

	[switch]
	$DontUpdateCache
)

#region Handle Working Directory Defaults
if (-not $WorkingDirectory)
{
	if ($env:RELEASE_PRIMARYARTIFACTSOURCEALIAS)
	{
		$WorkingDirectory = Join-Path -Path $env:SYSTEM_DEFAULTWORKINGDIRECTORY -ChildPath $env:RELEASE_PRIMARYARTIFACTSOURCEALIAS
	}
	else { $WorkingDirectory = $env:SYSTEM_DEFAULTWORKINGDIRECTORY }
}
if (-not $WorkingDirectory) { $WorkingDirectory = Split-Path $PSScriptRoot }

function Test-ManifestFunctionExports {
	param(
		[Parameter(Mandatory = $true)]
		[string]$ModuleRoot
	)

	$manifestPath = Join-Path $ModuleRoot 'PowerPlatformChecker.psd1'
	$publicFunctionsPath = Join-Path $ModuleRoot 'functions'

	if (-not (Test-Path $manifestPath)) {
		throw "Module manifest not found: $manifestPath"
	}

	if (-not (Test-Path $publicFunctionsPath)) {
		throw "Public functions folder not found: $publicFunctionsPath"
	}

	$manifest = Import-PowerShellDataFile -Path $manifestPath
	$manifestFunctions = @($manifest.FunctionsToExport | ForEach-Object { [string]$_ })
	$publicFunctions = @(Get-ChildItem -Path $publicFunctionsPath -File -Filter '*.ps1' | ForEach-Object { $_.BaseName })

	$missingFromManifest = @($publicFunctions | Where-Object { $_ -notin $manifestFunctions })
	$staleInManifest = @($manifestFunctions | Where-Object { $_ -notin $publicFunctions })

	if ($missingFromManifest.Count -gt 0 -or $staleInManifest.Count -gt 0) {
		$messages = @()
		if ($missingFromManifest.Count -gt 0) {
			$messages += "Missing in FunctionsToExport: $($missingFromManifest -join ', ')"
		}
		if ($staleInManifest.Count -gt 0) {
			$messages += "Listed in FunctionsToExport but no matching file in functions/: $($staleInManifest -join ', ')"
		}

		throw "Manifest export validation failed. $($messages -join '; ')"
	}

	Write-Host "Manifest export validation passed. Public functions are exported correctly."
}

$moduleRoot = Join-Path $WorkingDirectory 'PowerPlatformChecker'
Test-ManifestFunctionExports -ModuleRoot $moduleRoot
#endregion Handle Working Directory Defaults

# Prepare publish folder
Write-Host "Creating and populating publishing directory"
$publishDir = New-Item -Path $WorkingDirectory -Name publish -ItemType Directory -Force
Copy-Item -Path "$($WorkingDirectory)\PowerPlatformChecker" -Destination $publishDir.FullName -Recurse -Force

#region Gather text data to compile
$text = @()

# Gather commands
Get-ChildItem -Path "$($publishDir.FullName)\PowerPlatformChecker\internal\functions\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	$text += [System.IO.File]::ReadAllText($_.FullName)
}
Get-ChildItem -Path "$($publishDir.FullName)\PowerPlatformChecker\functions\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	$text += [System.IO.File]::ReadAllText($_.FullName)
}

# Gather scripts
Get-ChildItem -Path "$($publishDir.FullName)\PowerPlatformChecker\internal\scripts\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	$text += [System.IO.File]::ReadAllText($_.FullName)
}

# Add Local Cache of Power Platform Connector info
if(-not $DontUpdateCache) { .\build\helper\Get-PowerPlatformConnectors.ps1 -WorkingDirectory $WorkingDirectory }
$text += "# Local Cache of Power Platform Connector info"
$text += "`$script:connectorData = @`'
" + (Get-Content -Path "$WorkingDirectory\PowerPlatformConnectors.json" -Raw) + "`'@ | ConvertFrom-Json"

# Add Local Cache of Power Platform Operations info
if(-not $DontUpdateCache) { .\build\helper\Get-PowerPlatformFlowOperations.ps1 -WorkingDirectory $WorkingDirectory }
$text += "# Local Cache of Power Platform Operations info"
$text += "`$script:operationData = @`'
" + (Get-Content -Path "$WorkingDirectory\PowerPlatformOperations.json" -Raw) + "`'@ | ConvertFrom-Json"

#region Update the psm1 file & Cleanup
[System.IO.File]::WriteAllText("$($publishDir.FullName)\PowerPlatformChecker\PowerPlatformChecker.psm1", ($text -join "`n`n"), [System.Text.Encoding]::UTF8)
Remove-Item -Path "$($publishDir.FullName)\PowerPlatformChecker\internal" -Recurse -Force
Remove-Item -Path "$($publishDir.FullName)\PowerPlatformChecker\functions" -Recurse -Force
#endregion Update the psm1 file & Cleanup

#region Updating the Module Version
if ($AutoVersion)
{
	Write-Host  "Updating module version numbers."
	try { [version]$remoteVersion = (Find-Module 'PowerPlatformChecker' -Repository $Repository -ErrorAction Stop).Version }
	catch
	{
		throw "Failed to access $($Repository) : $_"
	}
	if (-not $remoteVersion)
	{
		throw "Couldn't find PowerPlatformChecker on repository $($Repository) : $_"
	}
	$newBuildNumber = $remoteVersion.Build + 1
	[version]$localVersion = (Import-PowerShellDataFile -Path "$($publishDir.FullName)\PowerPlatformChecker\PowerPlatformChecker.psd1").ModuleVersion
	Update-ModuleManifest -Path "$($publishDir.FullName)\PowerPlatformChecker\PowerPlatformChecker.psd1" -ModuleVersion "$($localVersion.Major).$($localVersion.Minor).$($newBuildNumber)"
}
#endregion Updating the Module Version

#region Publish
if ($SkipPublish) { return }
if ($LocalRepo)
{
	# Dependencies must go first
	Write-Host  "Creating Nuget Package for module: PSFramework"
	New-PSMDModuleNugetPackage -ModulePath (Get-Module -Name PSFramework).ModuleBase -PackagePath .
	Write-Host  "Creating Nuget Package for module: PowerPlatformChecker"
	New-PSMDModuleNugetPackage -ModulePath "$($publishDir.FullName)\PowerPlatformChecker" -PackagePath .
}
else
{
	# Publish to Gallery
	Write-Host  "Publishing the PowerPlatformChecker module to $($Repository)"
	Publish-Module -Path "$($publishDir.FullName)\PowerPlatformChecker" -NuGetApiKey $ApiKey -Force -Repository $Repository
}
#endregion Publish