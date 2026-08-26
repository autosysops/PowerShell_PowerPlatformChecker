function Get-PowerPlatformCheckerFlowType {
    <#
    .SYNOPSIS
        Detects whether a flow file is a cloud flow, desktop flow, or unknown.

    .DESCRIPTION
        Uses flow JSON structure for cloud detection and companion workflow XML
        metadata for desktop detection.

    .PARAMETER Path
        The path to the flow JSON file.

    .EXAMPLE
        Detect the type of a flow file.

        PS> Get-PowerPlatformCheckerFlowType -Path "C:\Flows\MyFlow.json"
    #>

    [CmdLetBinding()]
    [OutputType([String])]
    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [String] $Path
    )

    $classification = "Unknown"
    $telemetryProperties = @{}

    # A missing file cannot be inspected further, so classify it as Unknown
    # instead of throwing. That keeps downstream analysis code defensive when
    # a solution contains references to files that were not unpacked.
    if (-not (Test-Path -Path $Path)) {
        Write-Warning "Invalid flow path: file not found."
        Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerFlowType" -PropertiesHash $telemetryProperties
        return $classification
    }

    $flowJson = $null
    $jsonParsed = $false
    try {
        # Cloud flows expose their actionable metadata in the JSON file itself.
        # Attempt that path first because it is the cheapest and most direct
        # classification signal.
        $flowJson = Get-Content -Path $Path -Raw | ConvertFrom-Json
        $jsonParsed = $true
    }
    catch {
        Write-Warning "Invalid flow JSON payload. Falling back to metadata classification."
        $flowJson = $null
    }

    if ($jsonParsed -and $null -ne $flowJson) {
        $hasCloudProperties = $flowJson.PSObject.Properties.Name -contains "properties"
        if ($hasCloudProperties) {
            $hasConnectionReferences = $flowJson.properties.PSObject.Properties.Name -contains "connectionReferences"
            $hasDefinition = $flowJson.properties.PSObject.Properties.Name -contains "definition"
            if ($hasConnectionReferences -and $hasDefinition) {
                $classification = "Cloud"
                Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerFlowType" -PropertiesHash $telemetryProperties
                return $classification
            }
        }
    }

    $flowXmlPath = "$Path.data.xml"
    if (Test-Path -Path $flowXmlPath) {
        try {
            # Desktop flows keep their defining markers in the companion XML,
            # not in the lightweight JSON wrapper. Category 6 and UIFlowType 2
            # are the platform values that identify desktop flows.
            $flowXml = Select-Xml -Path $flowXmlPath -XPath "*" -ErrorAction Stop
            $categoryValue = [string]$flowXml.Node.Category
            $uiFlowTypeValue = [string]$flowXml.Node.UIFlowType

            if ($categoryValue -eq "6" -or $uiFlowTypeValue -eq "2") {
                $classification = "Desktop"
            }
        }
        catch {
            Write-Warning "Invalid desktop flow metadata XML."
            $classification = "Unknown"
        }
    }

    Send-THEvent -ModuleName "PowerPlatformChecker" -EventName "Get-PowerPlatformCheckerFlowType" -PropertiesHash $telemetryProperties

    return $classification
}





