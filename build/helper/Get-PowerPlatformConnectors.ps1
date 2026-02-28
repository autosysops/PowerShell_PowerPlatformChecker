param (
    [string] $WorkingDirectory
)

# Check for config file
if (Test-Path -Path "$WorkingDirectory\PowerPlatformAPI.conf") {
    # Get the config file
    $config = Get-Content -Path "$WorkingDirectory\PowerPlatformAPI.conf" | ConvertFrom-Json
}
else {
    $config = @{
        TenantID = $env:TENANTID
        ApplicationID = $env:APPLICATIONID
        ClientSecret = $env:CLIENTSECRET
        EnvironmentID = $env:ENVIRONMENTID
    }
}

$tokenResp = Invoke-RestMethod -Method Post `
    -Uri "https://login.microsoftonline.com/$($config.TenantID)/oauth2/v2.0/token" `
    -ContentType "application/x-www-form-urlencoded" `
    -Body @{
        client_id     = $config.ApplicationID
        client_secret = $config.ClientSecret
        grant_type    = "client_credentials"
        scope         = "https://api.powerplatform.com/.default"
}

$filter = [Uri]::EscapeDataString("environment eq '$($config.EnvironmentID)'")
$uri = "https://api.powerplatform.com/connectivity/environments/$($config.EnvironmentID)/connectors?`$filter=$filter&api-version=2022-03-01-preview"
$resp = Invoke-RestMethod -Method Get -Uri $uri -Headers @{
    Authorization = "Bearer $($tokenResp.access_token)"
}

$resp.value | Select-Object -Property `
@{ Name= 'displayname'; Expression = { $_.properties.displayName}}, `
@{ Name= 'description'; Expression = { $_.properties.description}}, `
name, `
@{ Name= 'apiEnvironment'; Expression = { $_.properties.apiEnvironment}}, `
@{ Name= 'connectionParameters'; Expression = { $_.properties.connectionParameters}}, `
@{ Name= 'releaseTag'; Expression = { $_.properties.releaseTag}}, `
@{ Name= 'tier'; Expression = { $_.properties.tier}}, `
@{ Name= 'publisher'; Expression = { $_.properties.publisher}} `
| ConvertTo-Json -Depth 10 -Compress | Out-File -FilePath "$WorkingDirectory\PowerPlatformConnectors.json" -Encoding UTF8