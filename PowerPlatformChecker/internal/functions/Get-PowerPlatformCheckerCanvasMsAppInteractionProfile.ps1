function Get-PowerPlatformCheckerCanvasMsAppInteractionProfile {
    <#
    .SYNOPSIS
        Extracts best-effort datasource and interaction metadata from a canvas .msapp package.

    .DESCRIPTION
        Reads References/DataSources.json and Src/*.pa.yaml from a .msapp archive,
        then derives connected data sources, external domains, datasource-level
        interaction direction, and formula-level evidence.

    .PARAMETER MsAppPath
        Absolute path to the canvas app .msapp package.

    .EXAMPLE
        Read a canvas app package and derive datasource/domain interaction metadata.

        PS> Get-PowerPlatformCheckerCanvasMsAppInteractionProfile -MsAppPath "C:\\solution\\CanvasApps\\app_DocumentUri.msapp"
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)]
        [string] $MsAppPath
    )

    $emptyResult = [pscustomobject]@{
        ConnectedDataSources = @()
        ExternalDomains = @()
        DomainInteractions = @()
        SourceSignals = @()
        InteractionDirection = 'Unknown'
        InteractionEvidence = 'NoMsAppSignal'
    }

    if ([string]::IsNullOrWhiteSpace([string]$MsAppPath) -or -not (Test-Path -Path $MsAppPath -PathType Leaf)) {
        return $emptyResult
    }

    $writeFunctionSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($writeName in @('Patch', 'Collect', 'ClearCollect', 'Remove', 'RemoveIf', 'SubmitForm', 'UpdateIf')) {
        [void]$writeFunctionSet.Add([string]$writeName)
    }

    $readFunctionSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($readName in @('LookUp', 'Filter', 'Refresh', 'First', 'Distinct', 'Count', 'CountIf')) {
        [void]$readFunctionSet.Add([string]$readName)
    }

    $zipArchive = $null
    try {
        $zipArchive = [System.IO.Compression.ZipFile]::OpenRead($MsAppPath)

        $dataSourcesEntry = $zipArchive.Entries | Where-Object { $_.FullName -match '(?i)^References[\\/]DataSources\.json$' } | Select-Object -First 1
        if ($null -eq $dataSourcesEntry) {
            return $emptyResult
        }

        $dataSourcesText = ''
        $dataSourcesReader = [System.IO.StreamReader]::new($dataSourcesEntry.Open())
        try {
            $dataSourcesText = [string]$dataSourcesReader.ReadToEnd()
        }
        finally {
            $dataSourcesReader.Dispose()
        }

        $dataSourcesJson = $null
        try {
            $dataSourcesJson = $dataSourcesText | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            return $emptyResult
        }

        $connectedDataSources = @(
            @($dataSourcesJson.DataSources) |
                Where-Object { $_ -and [string]$_.Type -eq 'ConnectedDataSourceInfo' -and -not [string]::IsNullOrWhiteSpace([string]$_.Name) } |
                ForEach-Object {
                    $datasetName = [string]$_.DatasetName
                    $authority = ''
                    if (-not [string]::IsNullOrWhiteSpace($datasetName)) {
                        try {
                            $authority = ([System.Uri]$datasetName).GetLeftPart([System.UriPartial]::Authority)
                        }
                        catch {
                            $authority = ''
                        }
                    }

                    [pscustomobject]@{
                        Name = [string]$_.Name
                        DatasetName = $datasetName
                        Domain = [string]$authority
                        ApiId = [string]$_.ApiId
                        TableName = [string]$_.TableName
                        IsWritable = [bool]$_.IsWritable
                    }
                }
        )

        $sourceSignals = [System.Collections.Generic.List[object]]::new()
        $directionByDataSource = @{}
        foreach ($dataSource in $connectedDataSources) {
            $directionByDataSource[[string]$dataSource.Name] = [pscustomobject]@{
                Read = $false
                Write = $false
            }
        }

        $sourceEntries = @($zipArchive.Entries | Where-Object { $_.FullName -match '(?i)^Src[\\/].+\.pa\.yaml$' })
        foreach ($sourceEntry in $sourceEntries) {
            $sourceText = ''
            $sourceReader = [System.IO.StreamReader]::new($sourceEntry.Open())
            try {
                $sourceText = [string]$sourceReader.ReadToEnd()
            }
            finally {
                $sourceReader.Dispose()
            }

            $lines = @([string]$sourceText -split "`r?`n")
            $screenName = [System.IO.Path]::GetFileNameWithoutExtension([string]$sourceEntry.Name)
            if ($screenName.EndsWith('.pa', [System.StringComparison]::OrdinalIgnoreCase)) {
                $screenName = [System.IO.Path]::GetFileNameWithoutExtension($screenName)
            }
            $currentElement = ''

            for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex++) {
                $line = [string]$lines[$lineIndex]
                if ($line -match '^\s{6,}-\s([^:]+)\:\s*$') {
                    $currentElement = ([string]$matches[1]).Trim()
                }

                foreach ($dataSource in $connectedDataSources) {
                    $dataSourceName = [string]$dataSource.Name
                    if ([string]::IsNullOrWhiteSpace($dataSourceName)) {
                        continue
                    }

                    $quotedDataSourcePattern = "'" + [regex]::Escape($dataSourceName) + "'"
                    if ($line -notmatch $quotedDataSourcePattern) {
                        continue
                    }

                    # Start with the current line so neighboring properties do not bleed into the
                    # inferred direction for this datasource reference. Multi-line operations such
                    # as Patch may reference the datasource on one line and Defaults/other helpers
                    # on the next, so expand narrowly only when the current line has no function.
                    $functionContext = [string]$line
                    $functionMatches = @([regex]::Matches($functionContext, '(?i)(Refresh|Patch|Collect|ClearCollect|LookUp|Filter|RemoveIf|Remove|Set|UpdateIf|SubmitForm|Defaults|First|Distinct|Count|CountIf)\(') | ForEach-Object { [string]$_.Groups[1].Value } | Select-Object -Unique)
                    if ($functionMatches.Count -eq 0) {
                        $contextStart = [Math]::Max(0, $lineIndex - 1)
                        $contextEnd = [Math]::Min($lines.Count - 1, $lineIndex + 1)
                        $functionContext = ($lines[$contextStart..$contextEnd] -join "`n")
                        $functionMatches = @([regex]::Matches($functionContext, '(?i)(Refresh|Patch|Collect|ClearCollect|LookUp|Filter|RemoveIf|Remove|Set|UpdateIf|SubmitForm|Defaults|First|Distinct|Count|CountIf)\(') | ForEach-Object { [string]$_.Groups[1].Value } | Select-Object -Unique)
                    }

                    $hasRead = $false
                    $hasWrite = $false
                    foreach ($functionName in $functionMatches) {
                        if ($writeFunctionSet.Contains([string]$functionName)) {
                            $hasWrite = $true
                        }
                        if ($readFunctionSet.Contains([string]$functionName)) {
                            $hasRead = $true
                        }
                    }

                    $direction = 'Unknown'
                    if ($hasRead -and $hasWrite) {
                        $direction = 'Mixed'
                    }
                    elseif ($hasWrite) {
                        $direction = 'Write'
                    }
                    elseif ($hasRead) {
                        $direction = 'Read'
                    }

                    if ($directionByDataSource.ContainsKey($dataSourceName)) {
                        if ($hasRead) {
                            $directionByDataSource[$dataSourceName].Read = $true
                        }
                        if ($hasWrite) {
                            $directionByDataSource[$dataSourceName].Write = $true
                        }
                    }

                    $sourceSignals.Add([pscustomobject]@{
                        File = [string]$sourceEntry.Name
                        Screen = [string]$screenName
                        Element = [string]$currentElement
                        LineNumber = $lineIndex + 1
                        DataSourceName = $dataSourceName
                        Direction = $direction
                        FunctionNames = @($functionMatches)
                        Formula = [string]$line.Trim()
                    }) | Out-Null
                }
            }
        }

        $domainInteractions = @(
            foreach ($dataSource in $connectedDataSources) {
                $dataSourceName = [string]$dataSource.Name
                $domain = [string]$dataSource.Domain
                if ([string]::IsNullOrWhiteSpace($domain)) {
                    continue
                }

                $read = $false
                $write = $false
                if ($directionByDataSource.ContainsKey($dataSourceName)) {
                    $read = [bool]$directionByDataSource[$dataSourceName].Read
                    $write = [bool]$directionByDataSource[$dataSourceName].Write
                }

                $direction = 'Unknown'
                if ($read -and $write) {
                    $direction = 'Mixed'
                }
                elseif ($write) {
                    $direction = 'Write'
                }
                elseif ($read) {
                    $direction = 'Read'
                }

                [pscustomobject]@{
                    Domain = $domain
                    DataSourceName = $dataSourceName
                    Direction = $direction
                    Evidence = if ($direction -eq 'Unknown') { 'ConnectedDataSource' } else { 'SourceFormula' }
                }
            }
        )

        $hasAnyRead = @($domainInteractions | Where-Object { $_.Direction -in @('Read', 'Mixed') }).Count -gt 0
        $hasAnyWrite = @($domainInteractions | Where-Object { $_.Direction -in @('Write', 'Mixed') }).Count -gt 0
        $overallDirection = 'Unknown'
        if ($hasAnyRead -and $hasAnyWrite) {
            $overallDirection = 'Mixed'
        }
        elseif ($hasAnyWrite) {
            $overallDirection = 'Write'
        }
        elseif ($hasAnyRead) {
            $overallDirection = 'Read'
        }

        return [pscustomobject]@{
            ConnectedDataSources = @($connectedDataSources)
            ExternalDomains = @($domainInteractions | ForEach-Object { [string]$_.Domain } | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Select-Object -Unique)
            DomainInteractions = @($domainInteractions)
            SourceSignals = @($sourceSignals)
            InteractionDirection = $overallDirection
            InteractionEvidence = if ($overallDirection -eq 'Unknown') { 'ConnectedDataSource' } else { 'SourceFormula' }
        }
    }
    catch {
        return $emptyResult
    }
    finally {
        if ($null -ne $zipArchive) {
            $zipArchive.Dispose()
        }
    }
}
