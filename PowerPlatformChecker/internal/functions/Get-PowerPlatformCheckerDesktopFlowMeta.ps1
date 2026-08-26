function Get-PowerPlatformCheckerDesktopFlowMeta {
    <#
    .SYNOPSIS
        Reads desktop flow metadata from the companion workflow XML file.

    .DESCRIPTION
        Loads and parses the *.json.data.xml metadata that belongs to a desktop
        flow JSON file and returns normalized values used by desktop parsers.

    .PARAMETER Path
        Path to the desktop flow JSON file.

    .EXAMPLE
        Get the desktop metadata for a flow file.

        PS> Get-PowerPlatformCheckerDesktopFlowMeta -Path "C:\Flow.json"
    #>

    [CmdLetBinding()]
    [OutputType([Object])]
    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [String] $Path
    )

    $flowXmlPath = "$Path.data.xml"
    if (-not (Test-Path -Path $flowXmlPath)) {
        return $null
    }

    try {
        $flowXml = Select-Xml -Path $flowXmlPath -XPath "*" -ErrorAction Stop
        if ($null -eq $flowXml -or $null -eq $flowXml.Node) {
            return $null
        }

        $workflowId = [string]$flowXml.Node.WorkflowId
        $workflowId = $workflowId.Trim("{").Trim("}")

        $connectionReferences = $null
        if (-not [string]::IsNullOrWhiteSpace([string]$flowXml.Node.ConnectionReferences)) {
            try {
                $connectionReferences = ([string]$flowXml.Node.ConnectionReferences | ConvertFrom-Json)
            }
            catch {
                $connectionReferences = $null
            }
        }

        $inputs = $null
        if (-not [string]::IsNullOrWhiteSpace([string]$flowXml.Node.Inputs)) {
            try {
                $inputs = ([string]$flowXml.Node.Inputs | ConvertFrom-Json)
            }
            catch {
                $inputs = $null
            }
        }

        $outputs = $null
        if (-not [string]::IsNullOrWhiteSpace([string]$flowXml.Node.Outputs)) {
            try {
                $outputs = ([string]$flowXml.Node.Outputs | ConvertFrom-Json)
            }
            catch {
                $outputs = $null
            }
        }

        $dependencies = $null
        if (-not [string]::IsNullOrWhiteSpace([string]$flowXml.Node.Dependencies)) {
            try {
                $dependencies = ([string]$flowXml.Node.Dependencies | ConvertFrom-Json)
            }
            catch {
                $dependencies = $null
            }
        }

        return [pscustomobject]@{
            WorkflowId = $workflowId
            Category = [string]$flowXml.Node.Category
            UIFlowType = [string]$flowXml.Node.UIFlowType
            Name = [string]$flowXml.Node.Name
            Description = [string]$flowXml.Node.Description
            Definition = [string]$flowXml.Node.Definition
            ConnectionReferences = $connectionReferences
            Inputs = $inputs
            Outputs = $outputs
            Dependencies = $dependencies
            WorkflowXmlPath = $flowXmlPath
        }
    }
    catch {
        return $null
    }
}





