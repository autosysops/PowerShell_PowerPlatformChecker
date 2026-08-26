# ===================================================================
# ================== TELEMETRY ======================================
# ===================================================================

# ===================================================================
# ================== DIAGRAM STYLE DEFAULTS =========================
# ===================================================================

# Keep style defaults in a target-keyed store so new renderers can add
# dedicated style maps without changing command contracts.
if (-not $script:PowerPlatformCheckerStyles) {
	$script:PowerPlatformCheckerStyles = @{
		ArchitectureDiagram = @{
			Default = "red"
			EnvVar = "#DF9A57"
			Connection = "#FCD757"
			Entity = "#B56784"
			DefaultEntity = "#71374D"
			Flow = "#DBE4EE"
			CanvasApp = "#8BC34A"
			ModelDrivenApp = "#7BAFD4"
			WebResource = "#D7C8F3"
			ExternalDomain = "#E6D3A3"
			Stroke = "#5E5B52"
		}
	}
}

# Load static connector/operation catalogs used by documentation and tier analysis.
if (-not $script:connectorData) {
	$moduleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
	$connectorCatalogCandidates = @(
		(Join-Path $moduleRoot "PowerPlatformConnectors.json"),
		(Join-Path (Split-Path $moduleRoot -Parent) "PowerPlatformConnectors.json")
	)

	$connectorCatalogPath = $connectorCatalogCandidates | Where-Object { Test-Path -Path $_ } | Select-Object -First 1
	if ($connectorCatalogPath) {
		try {
			$script:connectorData = Get-Content -Path $connectorCatalogPath -Raw | ConvertFrom-Json
		}
		catch {
			$script:connectorData = @()
		}
	}
	else {
		$script:connectorData = @()
	}
}

if (-not $script:operationData) {
	$moduleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
	$operationCatalogCandidates = @(
		(Join-Path $moduleRoot "PowerPlatformOperations.json"),
		(Join-Path (Split-Path $moduleRoot -Parent) "PowerPlatformOperations.json")
	)

	$operationCatalogPath = $operationCatalogCandidates | Where-Object { Test-Path -Path $_ } | Select-Object -First 1
	if ($operationCatalogPath) {
		try {
			$script:operationData = Get-Content -Path $operationCatalogPath -Raw | ConvertFrom-Json
		}
		catch {
			$script:operationData = @()
		}
	}
	else {
		$script:operationData = @()
	}
}

# Create env variables
$Env:PowerPlatformChecker_TELEMETRY_OPTIN = (-not $Evn:POWERSHELL_TELEMETRY_OPTOUT) # use the invert of default powershell telemetry setting

# Set up the telemetry
Initialize-THTelemetry -ModuleName "PowerPlatformChecker"
Set-THTelemetryConfiguration -ModuleName "PowerPlatformChecker" -OptInVariableName "PowerPlatformChecker_TELEMETRY_OPTIN" -StripPersonallyIdentifiableInformation $true -Confirm:$false
Add-THAppInsightsConnectionString -ModuleName "PowerPlatformChecker" -ConnectionString "InstrumentationKey=df9757a1-873b-41c6-b4a2-2b93d15c9fb1;IngestionEndpoint=https://westeurope-5.in.applicationinsights.azure.com/;LiveEndpoint=https://westeurope.livediagnostics.monitor.azure.com/"

# Create a message about the telemetry
Write-Information ("Telemetry for PowerPlatformChecker module is $(if([string] $Env:PowerPlatformChecker_TELEMETRY_OPTIN -in ("no","false","0")){"NOT "})enabled. Change the behavior by setting the value of " + '$Env:PowerPlatformChecker_TELEMETRY_OPTIN') -InformationAction Continue

# Resolve module version without requiring a full import to complete.
$moduleVersion = $null

try{
	$moduleManifestCandidates = @(
		(Join-Path $PSScriptRoot "PowerPlatformChecker.psd1"),
		(Join-Path (Split-Path $PSScriptRoot -Parent) "PowerPlatformChecker.psd1"),
		(Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "PowerPlatformChecker.psd1")
	)
	$moduleManifestPath = $moduleManifestCandidates | Where-Object { Test-Path -Path $_ } | Select-Object -First 1

	if ($moduleManifestPath) {
		try {
			$moduleManifest = Import-PowerShellDataFile -Path $moduleManifestPath
			$moduleVersion = [string]$moduleManifest.ModuleVersion
		}
		catch {
			$moduleVersion = $null
		}
	}
}
catch {
	$moduleVersion = $null
}

# Send a metric for the installation of the module
$telemetryProperties = @{
	ModuleVersion = $moduleVersion
}

Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Import Module PowerPlatformChecker" -PropertiesHash $telemetryProperties