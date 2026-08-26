function Get-PowerPlatformCheckerAppType {
    <#
    .SYNOPSIS
        Detects whether app metadata represents a canvas app or model-driven app.

    .DESCRIPTION
        Detects app type from a known app file path.
        Detection is best effort and returns Unknown when required signals are absent.

    .PARAMETER Path
        Optional app file path used for type detection.

    .EXAMPLE
        Detect app type from an unpacked solution file path.

        PS> Get-PowerPlatformCheckerAppType -Path "C:\Solutions\MySolution\Managed\CanvasApps\MyApp.meta.xml"
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $Path
    )

    $telemetryProperties = @{}
    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerAppType" -PropertiesHash $telemetryProperties

    if ([string]::IsNullOrWhiteSpace($Path)) {
        Write-Warning "Invalid app path provided."
        return "Unknown"
    }

    if (-not (Test-Path -Path $Path)) {
        Write-Warning "Invalid app path: file not found."
        return "Unknown"
    }

    $normalizedPath = [string]$Path -replace '/', '\\'
    if ($normalizedPath -match '\\CanvasApps\\') {
        return "CanvasApp"
    }

    if ($normalizedPath -match '\\AppModules\\' -or $normalizedPath -match '\\Other\\AppModules\\') {
        return "ModelDrivenApp"
    }

    Write-Warning "Invalid app metadata path. Could not determine app type."
    return "Unknown"
}
