# ===================================================================
# ================== TELEMETRY ======================================
# ===================================================================

# Create env variables
$Env:PowerPlatformChecker_TELEMETRY_OPTIN = (-not $Evn:POWERSHELL_TELEMETRY_OPTOUT) # use the invert of default powershell telemetry setting

# Set up the telemetry
Initialize-THTelemetry -ModuleName "PowerPlatformChecker"
Set-THTelemetryConfiguration -ModuleName "PowerPlatformChecker" -OptInVariableName "PowerPlatformChecker_TELEMETRY_OPTIN" -StripPersonallyIdentifiableInformation $true -Confirm:$false
Add-THAppInsightsConnectionString -ModuleName "PowerPlatformChecker" -ConnectionString "InstrumentationKey=df9757a1-873b-41c6-b4a2-2b93d15c9fb1;IngestionEndpoint=https://westeurope-5.in.applicationinsights.azure.com/;LiveEndpoint=https://westeurope.livediagnostics.monitor.azure.com/"

# Create a message about the telemetry
Write-Information ("Telemetry for PowerPlatformChecker module is $(if([string] $Env:PowerPlatformChecker_TELEMETRY_OPTIN -in ("no","false","0")){"NOT "})enabled. Change the behavior by setting the value of " + '$Env:PowerPlatformChecker_TELEMETRY_OPTIN') -InformationAction Continue

# Send a metric for the installation of the module
Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Import Module PowerPlatformChecker"