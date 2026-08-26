function Get-PowerPlatformCheckerDesktopFlowBinary {
    <#
    .SYNOPSIS
        Resolves desktop flow binary records linked to a workflow.

    .DESCRIPTION
        Finds desktopflowbinary metadata entries for a desktop flow and loads
        their referenced JSON payloads from the data folder.

    .PARAMETER Path
        Path to the desktop flow JSON file.

    .PARAMETER Type
        Optional desktopflowbinary type filter. Supports wildcard matching.

    .EXAMPLE
        Get connector binary payloads for a desktop flow.

        PS> Get-PowerPlatformCheckerDesktopFlowBinary -Path "C:\Flow.json" -Type "ConnectorDefinition"
    #>

    [CmdLetBinding()]
    [OutputType([Object[]])]
    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [String] $Path,

        [Parameter(Mandatory = $false, Position = 2)]
        [String] $Type = "*"
    )

    $metadata = Get-PowerPlatformCheckerDesktopFlowMeta -Path $Path
    if ($null -eq $metadata -or [string]::IsNullOrWhiteSpace($metadata.WorkflowId)) {
        return @()
    }

    $workflowsRoot = Split-Path -Path $Path -Parent
    $solutionRoot = Split-Path -Path $workflowsRoot -Parent
    $binaryRoot = Join-Path $solutionRoot "desktopflowbinaries"

    if (-not (Test-Path -Path $binaryRoot)) {
        return @()
    }

    $results = @()
    $metadataWorkflowId = ([string]$metadata.WorkflowId).Trim("{").Trim("}").ToLower()

    foreach ($binaryFile in @(Get-ChildItem -Path (Join-Path $binaryRoot "*\desktopflowbinary.xml") -File -ErrorAction SilentlyContinue)) {
        try {
            $binaryXml = Select-Xml -Path $binaryFile.FullName -XPath "*"
            if ($null -eq $binaryXml -or $null -eq $binaryXml.Node) {
                continue
            }

            $binaryType = [string]$binaryXml.Node.type
            if ($binaryType -notlike $Type) {
                continue
            }

            $binaryWorkflowId = [string]$binaryXml.Node.process.workflowid
            $binaryWorkflowId = $binaryWorkflowId.Trim("{").Trim("}").ToLower()
            if ($binaryWorkflowId -ne $metadataWorkflowId) {
                continue
            }

            $dataFileName = [string]$binaryXml.Node.data."#text"
            if ([string]::IsNullOrWhiteSpace($dataFileName)) {
                continue
            }

            $dataPath = Join-Path $binaryFile.DirectoryName (Join-Path "data" $dataFileName)
            if (-not (Test-Path -Path $dataPath)) {
                continue
            }

            $dataContent = Get-Content -Path $dataPath -Raw
            $dataObject = $null
            try {
                $dataObject = $dataContent | ConvertFrom-Json
            }
            catch {
                $dataObject = $null
            }

            $results += [pscustomobject]@{
                Type = $binaryType
                Reference = [string]$binaryXml.Node.reference
                DataPath = $dataPath
                Data = $dataObject
            }
        }
        catch {
            continue
        }
    }

    return $results
}





