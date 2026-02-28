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
        scope         = "https://service.flow.microsoft.com/.default"
}

$urlenvid = $config.EnvironmentID.Replace("-","")
$uri = "https://$($urlenvid.Substring(0,$urlenvid.Length-2)).$($urlenvid.Substring($urlenvid.Length-2,2)).environment.api.powerplatform.com/powerautomate/operations?api-version=1&`$top=250"

$operations = @()

Do {
    $resp = Invoke-RestMethod -Method Post -Uri $uri -Headers @{
        Authorization = "Bearer $($tokenResp.access_token)"
    }
    $operations += ($resp.value | Select-Object -Property `
    name, `
    @{ Name= 'summary'; Expression = { $_.properties.summary}}, `
    @{ Name= 'description'; Expression = { $_.properties.description}}, `
    @{ Name= 'usage'; Expression = { $_.properties.usage}}, `
    @{ Name= 'group'; Expression = { $_.properties.operationGroup.name}})
    $uri = $resp.nextlink
} Until ($null -eq $resp.nextlink)


$operations | ConvertTo-Json -Depth 10 -Compress | Out-File -FilePath "$WorkingDirectory\PowerPlatformOperations.json" -Encoding UTF8