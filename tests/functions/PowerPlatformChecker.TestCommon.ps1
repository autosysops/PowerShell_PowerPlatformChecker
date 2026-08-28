function Get-PowerPlatformCheckerFixtureSolutionPath {
    return (Resolve-Path (Join-Path $PSScriptRoot "..\fixtures\anonymized-solution\Managed")).Path
}

function Get-PowerPlatformCheckerDesktopFixtureSolutionPath {
    return (Resolve-Path (Join-Path $PSScriptRoot "..\fixtures\anonymized-desktop-solution\Managed")).Path
}

function Get-PowerPlatformCheckerCanvasExternalFixtureSolutionPath {
    return (Resolve-Path (Join-Path $PSScriptRoot "..\fixtures\canvas-external-solution\Managed")).Path
}

function Get-PowerPlatformCheckerExpectedSnapshot {
    param(
        [Parameter(Mandatory = $true)]
        [string] $FileName
    )

    $snapshotPath = Join-Path $PSScriptRoot (Join-Path "..\fixtures\expected" $FileName)
    return Get-Content -Path $snapshotPath -Raw
}

function Normalize-PowerPlatformCheckerSnapshotText {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Text
    )

    return ($Text -replace "`r`n", "`n").TrimEnd()
}

function Initialize-PowerPlatformCheckerTestData {
    InModuleScope PowerPlatformChecker {
        $script:connectorData = @(
            [pscustomobject]@{
                name = "shared_commondataserviceforapps"
                displayname = "Microsoft Dataverse"
                tier = "Premium"
                releaseTag = "Production"
                publisher = "Microsoft"
            },
            [pscustomobject]@{
                name = "shared_office365"
                displayname = "Office 365 Outlook"
                tier = "Standard"
                releaseTag = "Production"
                publisher = "Microsoft"
            },
            [pscustomobject]@{
                name = "shared_todo"
                displayname = "Todo"
                tier = "Standard"
                releaseTag = "Preview"
                publisher = "Fabrikam"
            }
        )

        $script:operationData = @(
            [pscustomobject]@{
                name = "Create orderline"
                operationType = "CreateRecord"
                usage = "Action"
                group = "shared_commondataserviceforapps"
                summary = "Create orderline"
                builtin = $true
            },
            [pscustomobject]@{
                name = "Send an email"
                operationType = "SendEmailV2"
                usage = "Action"
                group = "shared_office365"
                summary = "Send an email"
                builtin = $true
            },
            [pscustomobject]@{
                name = "When a row is added"
                operationType = "SubscribeWebhookTrigger"
                usage = "Trigger"
                group = "shared_commondataserviceforapps"
                summary = "When a row is added"
                builtin = $true
            },
            [pscustomobject]@{
                name = "Condition"
                operationType = "If"
                usage = "Action"
                group = "Control"
                summary = "Condition"
                builtin = $true
            }
        )
    }
}

function global:Assert-PowerPlatformCheckerTelemetrySafe {
    param(
        [Parameter(Mandatory = $true)]
        [object[]] $TelemetryCalls,

        [Parameter(Mandatory = $true)]
        [string] $EventName,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $ExpectedKeys,

        [Parameter(Mandatory = $false)]
        [string[]] $ConfidentialValues = @()
    )

    $matchingCalls = @($TelemetryCalls | Where-Object { $_.EventName -eq $EventName })
    $matchingCalls.Count | Should -Be 1

    $properties = $matchingCalls[0].PropertiesHash
    ($null -ne $properties) | Should -BeTrue

    $actualKeys = @($properties.Keys | ForEach-Object { [string]$_ } | Sort-Object)
    $actualKeys | Should -Be @($ExpectedKeys | Sort-Object)

    foreach ($key in @($actualKeys)) {
        $key | Should -Not -Match '(?i)(password|passphrase|secret|token|apikey|api_key|connectionstring|sas|certificate|privatekey|clientsecret)'
    }

    $propertiesJson = ($properties | ConvertTo-Json -Depth 10 -Compress)
    foreach ($confidentialValue in @($ConfidentialValues | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })) {
        $escapedValue = [regex]::Escape([string]$confidentialValue)
        $propertiesJson | Should -Not -Match $escapedValue
    }
}

