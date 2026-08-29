. "$PSScriptRoot\PowerPlatformChecker.TestCommon.ps1"

Describe "Get-PowerPlatformCheckerExternalInteraction" {
    $externalInteractionSnapshotCases = @(
        @{
            Name = 'SingleSolutionManagedPath'
            SolutionPathKey = 'Default'
            MermaidSnapshot = 'ExternalInteraction.SingleSolution.expected.mermaid.md'
            GraphSnapshot = 'ExternalInteraction.SingleSolution.expected.graph.json'
        },
        @{
            Name = 'SingleSolutionManagedPathMergedEnergy'
            SolutionPathKey = 'Default'
            MermaidSnapshot = 'ExternalInteraction.SingleSolution.MergedEnergy.expected.mermaid.md'
            GraphSnapshot = 'ExternalInteraction.SingleSolution.MergedEnergy.expected.graph.json'
        },
        @{
            Name = 'CanvasExternalFixture'
            SolutionPathKey = 'CanvasExternal'
            MermaidSnapshot = 'ExternalInteraction.CanvasExternal.expected.mermaid.md'
            GraphSnapshot = 'ExternalInteraction.CanvasExternal.expected.graph.json'
        }
    )

    BeforeAll {
        Initialize-PowerPlatformCheckerTestData
        $script:solutionPath = Get-PowerPlatformCheckerFixtureSolutionPath
        $script:canvasExternalSolutionPath = Get-PowerPlatformCheckerCanvasExternalFixtureSolutionPath

        $script:externalInteractionGraphSnapshotConverter = {
            param([object] $Graph)

            $stableNodes = @($Graph.Nodes |
                Sort-Object { [string]$_.Id } |
                ForEach-Object {
                    [ordered]@{
                        Id = [string]$_.Id
                        Type = [string]$_.Type
                        DisplayName = [string]$_.DisplayName
                        ClassKind = [string]$_.ClassKind
                        Members = @(@($_.Members) | ForEach-Object { [string]$_ })
                        HasExplicitDisplayName = [bool]$_.HasExplicitDisplayName
                    }
                })

            $stableEdges = @($Graph.Edges |
                Sort-Object { "{0}|{1}|{2}|{3}" -f [string]$_.SourceId, [string]$_.TargetId, [string]$_.Label, [string]$_.EdgeType } |
                ForEach-Object {
                    [ordered]@{
                        SourceId = [string]$_.SourceId
                        TargetId = [string]$_.TargetId
                        Label = [string]$_.Label
                        EdgeType = [string]$_.EdgeType
                        Metadata = [ordered]@{
                            Arrow = [string]$_.Metadata.Arrow
                            Evidence = [string]$_.Metadata.Evidence
                        }
                    }
                })

            $stableStyles = [ordered]@{}
            foreach ($styleName in @($Graph.Styles.Keys | Sort-Object)) {
                $stableStyles[[string]$styleName] = [string]$Graph.Styles[[string]$styleName]
            }

            $snapshotPayload = [ordered]@{
                Metadata = [ordered]@{
                    Direction = [string]$Graph.Metadata.Direction
                    DiagramKind = [string]$Graph.Metadata.DiagramKind
                    IncludeElements = @($Graph.Metadata.IncludeElements | Sort-Object)
                    OutputFormat = [string]$Graph.Metadata.OutputFormat
                    SourceSolutions = @($Graph.Metadata.SourceSolutions |
                        ForEach-Object {
                            $sourcePath = [string]$_
                            if ([string]::IsNullOrWhiteSpace($sourcePath)) {
                                return ''
                            }

                            # Keep snapshots host-independent by storing only the
                            # trailing solution folder and managed/unmanaged marker.
                            $normalizedPath = $sourcePath -replace '\\', '/'
                            $segments = @($normalizedPath.TrimEnd('/') -split '/')
                            if ($segments.Count -ge 2) {
                                return ('{0}/{1}' -f $segments[$segments.Count - 2], $segments[$segments.Count - 1])
                            }

                            return $normalizedPath
                        } |
                        Sort-Object)
                    SourceSolutionCount = [int]$Graph.Metadata.SourceSolutionCount
                    IsScopedDiagram = [bool]$Graph.Metadata.IsScopedDiagram
                    SourceFilterType = [string]$Graph.Metadata.SourceFilterType
                    SourceFilterValue = [string]$Graph.Metadata.SourceFilterValue
                }
                Nodes = $stableNodes
                Edges = $stableEdges
                Styles = $stableStyles
                StyleOrder = @($Graph.StyleOrder | ForEach-Object { [string]$_ })
            }

            return ($snapshotPayload | ConvertTo-Json -Depth 20)
        }
    }

    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {}
    }

    Context "Scenario Snapshots" {
        It "matches expected Mermaid snapshot for <Name>" -TestCases $externalInteractionSnapshotCases {
            param($Name, $SolutionPathKey, $MermaidSnapshot)

            $expected = Get-PowerPlatformCheckerExpectedSnapshot -FileName $MermaidSnapshot
            $parameters = @{
                SolutionPaths = @($(if ($SolutionPathKey -eq 'CanvasExternal') { $script:canvasExternalSolutionPath } else { $script:solutionPath }))
                Direction = 'LR'
                OutputFormat = 'Mermaid'
            }
            if ($Name -eq 'SingleSolutionManagedPathMergedEnergy') {
                $parameters.Merge = 'Energy'
            }

            $markdown = Get-PowerPlatformCheckerExternalInteraction @parameters

            (Normalize-PowerPlatformCheckerSnapshotText -Text $markdown) |
                Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $expected)
        }

        It "matches expected Graph snapshot for <Name>" -TestCases $externalInteractionSnapshotCases {
            param($Name, $SolutionPathKey, $GraphSnapshot)

            $expected = Get-PowerPlatformCheckerExpectedSnapshot -FileName $GraphSnapshot
            $parameters = @{
                SolutionPaths = @($(if ($SolutionPathKey -eq 'CanvasExternal') { $script:canvasExternalSolutionPath } else { $script:solutionPath }))
                Direction = 'LR'
                OutputFormat = 'Graph'
            }
            if ($Name -eq 'SingleSolutionManagedPathMergedEnergy') {
                $parameters.Merge = 'Energy'
            }

            $graph = Get-PowerPlatformCheckerExternalInteraction @parameters
            $actual = & $script:externalInteractionGraphSnapshotConverter -Graph $graph

            (Normalize-PowerPlatformCheckerSnapshotText -Text $actual) |
                Should -Be (Normalize-PowerPlatformCheckerSnapshotText -Text $expected)
        }
    }

    It "returns a combined graph for multiple solution inputs" {
        $graph = Get-PowerPlatformCheckerExternalInteraction -SolutionPaths @($script:solutionPath, $script:solutionPath) -OutputFormat Graph

        $graph.Metadata.SourceSolutionCount | Should -Be 1
        ($graph.Nodes | Where-Object Type -eq 'Solution').Count | Should -Be 1
        ($graph.Nodes | Where-Object { $_.Type -in @('Flow', 'CanvasApp', 'ModelDrivenApp', 'Entity', 'WebResource') }).Count | Should -Be 0
        $graph.Edges.Count | Should -BeGreaterThan 0
        (($graph.Edges | Select-Object -ExpandProperty SourceId | Sort-Object -Unique).Count) | Should -BeGreaterThan 0
        (($graph.Edges | Select-Object -ExpandProperty SourceId) -contains ($graph.Nodes | Where-Object Type -eq 'Solution' | Select-Object -First 1 -ExpandProperty Id)) | Should -BeTrue
        ((@($graph.Edges | Select-Object -ExpandProperty Label | Where-Object { [string]$_ -match '(GET|SET|INBOUND|OUTBOUND)' })).Count -gt 0) | Should -BeTrue
    }

    It "supports merged output naming for selected solutions" {
        $graph = Get-PowerPlatformCheckerExternalInteraction -SolutionPaths @($script:solutionPath, $script:solutionPath) -Merge 'Energy' -OutputFormat Graph

        $solutionNodes = @($graph.Nodes | Where-Object Type -eq 'Solution')
        $solutionNodes.Count | Should -Be 1
        $solutionNodes[0].DisplayName | Should -Be 'Energy'
    }

    It "supports include and exclude folder filters" {
        $parent = Split-Path $script:solutionPath -Parent
        $folderName = Split-Path $script:solutionPath -Leaf

        $included = Get-PowerPlatformCheckerExternalInteraction -SolutionPaths @($parent) -IncludeSolutionFolders @($folderName) -OutputFormat Graph
        $excluded = Get-PowerPlatformCheckerExternalInteraction -SolutionPaths @($parent) -ExcludeSolutionFolders @($folderName) -OutputFormat Graph

        $included.Metadata.SourceSolutionCount | Should -BeGreaterThan 0
        $excluded.Metadata.SourceSolutionCount | Should -Be 0
    }

    It "supports recursive discovery and mermaid output" {
        $parent = Split-Path $script:solutionPath -Parent
        $folderName = Split-Path $script:solutionPath -Leaf

        $markdown = Get-PowerPlatformCheckerExternalInteraction -SolutionPaths @($parent) -Recurse -IncludeSolutionFolders @($folderName) -OutputFormat Mermaid

        $markdown | Should -Match ":::mermaid"
        $markdown | Should -Match "graph LR;"
        $markdown | Should -Not -Match '(?m)^classDef\s+\w+\s*$'
        $markdown | Should -Match '(?m)^classDef Solution fill:'
        $markdown | Should -Match '(?m)^classDef ExternalDomain fill:'

        # Mermaid flowchart edge labels use |label| delimiters.
        # Keep labels free from punctuation interpreted as Mermaid syntax tokens.
        $edgeLines = @($markdown -split "`r?`n" | Where-Object { $_ -match '-->\|' })
        $edgeLines.Count | Should -BeGreaterThan 0
        foreach ($edgeLine in $edgeLines) {
            ([regex]::Matches([string]$edgeLine, '\|').Count) | Should -Be 2
            $labelMatch = [regex]::Match([string]$edgeLine, '\|(?<label>.*)\|')
            $labelMatch.Success | Should -BeTrue
            [string]$labelMatch.Groups['label'].Value | Should -Not -Match '[\(\)\[\]\{\}]'
            [string]$labelMatch.Groups['label'].Value | Should -Not -Match '[:;,]'
        }
    }

    It "emits condensed directional edges toward external targets" {
        $graph = Get-PowerPlatformCheckerExternalInteraction -SolutionPaths @($script:solutionPath) -OutputFormat Graph
        $solutionNode = $graph.Nodes | Where-Object Type -eq 'Solution' | Select-Object -First 1

        $solutionNode | Should -Not -BeNullOrEmpty
        ($graph.Edges | Where-Object { $_.SourceId -eq $solutionNode.Id }).Count | Should -BeGreaterThan 0
        (($graph.Edges | Select-Object -ExpandProperty Label) | Where-Object { [string]$_ -match 'Flow-[0-9]{2}|App-[0-9]{2}' }).Count | Should -BeGreaterThan 0
    }

    It "creates synthetic destination nodes from flow destination metadata" {
        $graph = Get-PowerPlatformCheckerExternalInteraction -SolutionPaths @($script:solutionPath) -OutputFormat Graph

        ($graph.Nodes | Where-Object { $_.Type -eq 'ExternalDomain' -and [string]$_.DisplayName -eq 'internet' }).Count | Should -BeGreaterThan 0
        ($graph.Nodes | Where-Object { $_.Type -eq 'Connection' -and $_.DisplayName -eq 'shared_commondataserviceforapps' }).Count | Should -BeGreaterThan 0
    }

    It "does not expose internal Dataverse webhook triggers as internet inbound edges" {
        $graph = Get-PowerPlatformCheckerExternalInteraction -SolutionPaths @($script:solutionPath) -OutputFormat Graph
        $solutionNode = $graph.Nodes | Where-Object Type -eq 'Solution' | Select-Object -First 1

        ($graph.Edges | Where-Object {
                $_.SourceId -eq 'externaldomain_internet' -and
                $_.TargetId -eq $solutionNode.Id -and
                [string]$_.Label -match 'Microsoft Dataverse'
            }).Count | Should -Be 0
    }

    It "does not keep orphan internet nodes when no inbound or outbound internet edge exists" {
        $graph = Get-PowerPlatformCheckerExternalInteraction -SolutionPaths @($script:solutionPath) -OutputFormat Graph

        $internetNodes = @($graph.Nodes | Where-Object { $_.Id -eq 'externaldomain_internet' })
        foreach ($internetNode in $internetNodes) {
            @($graph.Edges | Where-Object { $_.SourceId -eq $internetNode.Id -or $_.TargetId -eq $internetNode.Id }).Count | Should -BeGreaterThan 0
        }
    }

    It "uses packaged canvas app fixture data for external domain read and write edges" {
        $graph = Get-PowerPlatformCheckerExternalInteraction -SolutionPaths @($script:canvasExternalSolutionPath) -OutputFormat Graph
        $solutionNode = $graph.Nodes | Where-Object Type -eq 'Solution' | Select-Object -First 1

        ($graph.Nodes | Where-Object { $_.Id -eq 'externaldomain_https_contoso_sharepoint_com' -and $_.Type -eq 'ExternalDomain' }).Count | Should -Be 1
        ($graph.Edges | Where-Object { $_.SourceId -eq $solutionNode.Id -and $_.TargetId -eq 'externaldomain_https_contoso_sharepoint_com' -and [string]$_.Label -match '^App-[0-9]{2} GET' }).Count | Should -Be 1
        ($graph.Edges | Where-Object { $_.SourceId -eq $solutionNode.Id -and $_.TargetId -eq 'externaldomain_https_contoso_sharepoint_com' -and [string]$_.Label -match '^App-[0-9]{2} SET' }).Count | Should -Be 1
    }

    It "sends sanitized telemetry" {
        $telemetryCalls = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {
            param([string]$ModuleName, [string]$EventName, [hashtable]$PropertiesHash)
            [void]$telemetryCalls.Add([pscustomobject]@{ ModuleName = $ModuleName; EventName = $EventName; PropertiesHash = $PropertiesHash })
        }

        [void](Get-PowerPlatformCheckerExternalInteraction -SolutionPaths @($script:solutionPath) -OutputFormat Graph)
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerExternalInteraction" -ExpectedKeys @("PathCount", "Recurse", "IncludeFilterCount", "ExcludeFilterCount", "Direction", "OutputFormat", "HasStyleOverrides", "HasMerge") -ConfidentialValues @($script:solutionPath)
    }

    It "includes merge usage in telemetry properties" {
        $telemetryCalls = [System.Collections.Generic.List[object]]::new()
        Mock -CommandName Send-THEvent -ModuleName PowerPlatformChecker {
            param([string]$ModuleName, [string]$EventName, [hashtable]$PropertiesHash)
            [void]$telemetryCalls.Add([pscustomobject]@{ ModuleName = $ModuleName; EventName = $EventName; PropertiesHash = $PropertiesHash })
        }

        [void](Get-PowerPlatformCheckerExternalInteraction -SolutionPaths @($script:solutionPath) -Merge 'Energy' -OutputFormat Graph)
        Assert-PowerPlatformCheckerTelemetrySafe -TelemetryCalls @($telemetryCalls) -EventName "Get-PowerPlatformCheckerExternalInteraction" -ExpectedKeys @("PathCount", "Recurse", "IncludeFilterCount", "ExcludeFilterCount", "Direction", "OutputFormat", "HasStyleOverrides", "HasMerge") -ConfidentialValues @($script:solutionPath)

        $matchingCall = @($telemetryCalls | Where-Object { $_.EventName -eq 'Get-PowerPlatformCheckerExternalInteraction' })[0]
        [bool]$matchingCall.PropertiesHash.HasMerge | Should -BeTrue
    }

    It "supports per-call style overrides" {
        $markdown = Get-PowerPlatformCheckerExternalInteraction -SolutionPaths @($script:solutionPath) -OutputFormat Mermaid -StyleOverrides @{ Connection = '#123456' }

        $markdown | Should -Match 'classDef Connection fill:#123456,stroke:#5E5B52'
    }

    It "sanitizes invalid quoted stroke values in Mermaid class definitions" {
        try {
            [void](Set-PowerPlatformCheckerStyle -StyleTarget ArchitectureDiagram -Stroke '"a934a73fdcd8491e8bfc"')

            $markdown = Get-PowerPlatformCheckerExternalInteraction -SolutionPaths @($script:solutionPath) -OutputFormat Mermaid

            $markdown | Should -Not -Match '(?m)^classDef\s+\w+\s+.*stroke:"'
            $markdown | Should -Match 'classDef Connection fill:#FCD757,stroke:#5E5B52'
        }
        finally {
            [void](Set-PowerPlatformCheckerStyle -StyleTarget ArchitectureDiagram -Stroke '#5E5B52')
        }
    }

    It "overrides malformed inherited Solution class styles in external interaction graphs" {
        InModuleScope PowerPlatformChecker {
            Mock -CommandName Get-PowerPlatformCheckerArchitectureDiagram -MockWith {
                [pscustomobject]@{
                    Nodes = @()
                    Edges = @()
                    Styles = [pscustomobject]@{
                        default = 'fill:red,stroke:"0e75a9249ce34eca8f8c"'
                        Solution = 'fill:#f5f5f5,stroke:"0e75a9249ce34eca8f8c"'
                    }
                    StyleOrder = @('default', 'Solution')
                }
            }

            Mock -CommandName Get-PowerPlatformCheckerFlowFile -MockWith { @() }

            Get-PowerPlatformCheckerExternalInteractionGraphInternal -FilteredSolutionPaths @('C:\Temp\MySolution\Managed') -Direction 'LR'
        } | ForEach-Object {
            [string]$_.Styles.Solution | Should -Be 'fill:#f5f5f5,stroke:#111111,stroke-width:2px;'
            [string]$_.Styles.Solution | Should -Not -Match 'stroke:"'
        }
    }

    It "normalizes managed solution identity and keeps inbound plus multi-target outbound evidence" {
        InModuleScope PowerPlatformChecker {
            Mock -CommandName Get-PowerPlatformCheckerArchitectureDiagram -MockWith {
                [pscustomobject]@{
                    Nodes = @(
                        [pscustomobject]@{
                            Id = 'flow11111111-1111-1111-1111-111111111111'
                            Type = 'Flow'
                            DisplayName = 'Inbound Flow'
                            ClassKind = 'Flow'
                            Properties = @{
                                TriggerMode = 'Webhook'
                                InteractionDirection = 'Write'
                                Destination = 'api.contoso.example'
                                DestinationTargets = @('api.contoso.example', 'contoso.sharepoint.com')
                                DestinationType = 'Domain'
                            }
                            Members = @()
                            HasExplicitDisplayName = $true
                        }
                    )
                    Edges = @()
                    Styles = @{}
                    StyleOrder = @()
                }
            }

            Mock -CommandName Get-PowerPlatformCheckerFlowFile -MockWith {
                @('C:\Temp\MySolution\Managed\Workflows\InboundFlow-11111111-1111-1111-1111-111111111111.json')
            }

            Mock -CommandName Get-PowerPlatformCheckerFlowActionList -MockWith {
                @(
                    [pscustomobject]@{ Name = 'CallApi'; ExternalDomain = 'api.contoso.example'; GetSetAction = 'Set'; InteractionDirection = 'Write' },
                    [pscustomobject]@{ Name = 'CreateFile'; ExternalDomain = 'contoso.sharepoint.com'; GetSetAction = 'Set'; InteractionDirection = 'Write' }
                )
            }

            Get-PowerPlatformCheckerExternalInteractionGraphInternal -FilteredSolutionPaths @('C:\Temp\MySolution\Managed') -Direction 'LR'
        } | ForEach-Object {
            $solutionNode = $_.Nodes | Where-Object { $_.Type -eq 'Solution' } | Select-Object -First 1
            $solutionNode.DisplayName | Should -Be 'MySolution'

            $inboundEdge = $_.Edges | Where-Object { $_.SourceId -eq 'externaldomain_internet' -and $_.TargetId -eq $solutionNode.Id -and [string]$_.Label -match 'INBOUND$' } | Select-Object -First 1
            $inboundEdge | Should -Not -BeNullOrEmpty

            $outboundApi = $_.Edges | Where-Object { $_.SourceId -eq $solutionNode.Id -and $_.TargetId -eq 'externaldomain_api_contoso_example' } | Select-Object -First 1
            $outboundSp = $_.Edges | Where-Object { $_.SourceId -eq $solutionNode.Id -and $_.TargetId -eq 'externaldomain_contoso_sharepoint_com' } | Select-Object -First 1

            $outboundApi | Should -Not -BeNullOrEmpty
            $outboundSp | Should -Not -BeNullOrEmpty
            $outboundApi.Label | Should -Match '^Flow-[0-9]{2} SET'
            $outboundSp.Label | Should -Match '^Flow-[0-9]{2} SET'
            $outboundApi.Metadata.Evidence | Should -Match 'CallApi'
            $outboundSp.Metadata.Evidence | Should -Match 'CreateFile'
        }
    }

    It "emits one line per resource interaction and filters invalid external-domain tokens" {
        InModuleScope PowerPlatformChecker {
            Mock -CommandName Get-PowerPlatformCheckerArchitectureDiagram -MockWith {
                [pscustomobject]@{
                    Nodes = @(
                        [pscustomobject]@{
                            Id = 'flow11111111-1111-1111-1111-111111111111'
                            Type = 'Flow'
                            DisplayName = 'Inbound Flow'
                            ClassKind = 'Flow'
                            Properties = @{
                                TriggerMode = 'Webhook'
                                InteractionDirection = 'Mixed'
                                Destination = 'api.contoso.example'
                                DestinationTargets = @('api.contoso.example')
                                DestinationType = 'Domain'
                            }
                            Members = @()
                            HasExplicitDisplayName = $true
                        },
                        [pscustomobject]@{
                            Id = 'webresource_badtoken'
                            Type = 'WebResource'
                            DisplayName = 'Bad Token Script'
                            ClassKind = 'WebResource'
                            Properties = @{}
                            Members = @()
                            HasExplicitDisplayName = $true
                        },
                        [pscustomobject]@{
                            Id = 'external_set'
                            Type = 'ExternalDomain'
                            DisplayName = 'set'
                            ClassKind = 'ExternalDomain'
                            Properties = @{}
                            Members = @()
                            HasExplicitDisplayName = $true
                        }
                    )
                    Edges = @(
                        [pscustomobject]@{
                            SourceId = 'webresource_badtoken'
                            TargetId = 'external_set'
                            Label = 'Suspicious'
                            EdgeType = 'Link'
                            Metadata = [pscustomobject]@{ Arrow = '-->' }
                        }
                    )
                    Styles = @{}
                    StyleOrder = @()
                }
            }

            Mock -CommandName Get-PowerPlatformCheckerFlowFile -MockWith {
                @('C:\Temp\MySolution\Managed\Workflows\InboundFlow-11111111-1111-1111-1111-111111111111.json')
            }

            Mock -CommandName Get-PowerPlatformCheckerFlowActionList -MockWith {
                @(
                    [pscustomobject]@{ Name = 'GetCatalog'; ExternalDomain = 'api.contoso.example'; GetSetAction = 'Get'; InteractionDirection = 'Read' },
                    [pscustomobject]@{ Name = 'UpdateCatalog'; ExternalDomain = 'api.contoso.example'; GetSetAction = 'Set'; InteractionDirection = 'Write' }
                )
            }

            Get-PowerPlatformCheckerExternalInteractionGraphInternal -FilteredSolutionPaths @('C:\Temp\MySolution\Managed') -Direction 'LR'
        } | ForEach-Object {
            $solutionNode = $_.Nodes | Where-Object { $_.Type -eq 'Solution' } | Select-Object -First 1
            $solutionNode | Should -Not -BeNullOrEmpty

            ($_.Nodes | Where-Object { $_.DisplayName -eq 'set' }).Count | Should -Be 0

            $outboundApiEdges = @($_.Edges | Where-Object {
                    $_.SourceId -eq $solutionNode.Id -and $_.TargetId -eq 'externaldomain_api_contoso_example'
                })

            $outboundApiEdges.Count | Should -Be 2
            (@($outboundApiEdges | ForEach-Object { [string]$_.Label }) -join '|') | Should -Match 'Flow-[0-9]{2}'
            (@($outboundApiEdges | ForEach-Object { [string]$_.Label }) -join '|') | Should -Match 'GET'
            (@($outboundApiEdges | ForEach-Object { [string]$_.Label }) -join '|') | Should -Match 'SET'
        }
    }

    It "routes flow interactions to resolved site targets and suppresses unresolved internal destinations" {
        InModuleScope PowerPlatformChecker {
            Mock -CommandName Get-PowerPlatformCheckerArchitectureDiagram -MockWith {
                [pscustomobject]@{
                    Nodes = @(
                        [pscustomobject]@{
                            Id = 'flow11111111-1111-1111-1111-111111111111'
                            Type = 'Flow'
                            DisplayName = 'SharePoint Flow'
                            ClassKind = 'Flow'
                            Properties = @{
                                TriggerMode = 'Recurrence'
                                InteractionDirection = 'Mixed'
                                Destination = 'shared_sharepointonline'
                                DestinationTargets = @('shared_sharepointonline')
                                DestinationType = 'Connection'
                            }
                            Members = @()
                            HasExplicitDisplayName = $true
                        }
                    )
                    Edges = @()
                    Styles = @{}
                    StyleOrder = @()
                }
            }

            Mock -CommandName Get-PowerPlatformCheckerFlowFile -MockWith {
                @('C:\Temp\Energy\Managed\Workflows\SharePointFlow-11111111-1111-1111-1111-111111111111.json')
            }

            Mock -CommandName Get-PowerPlatformCheckerFlowActionList -MockWith {
                @(
                    [pscustomobject]@{ Name = 'ReadPlan'; ExternalEndpoint = 'https://contoso.sharepoint.com/sites/energy'; ExternalDomain = 'contoso.sharepoint.com'; GetSetAction = 'Get'; InteractionDirection = 'Read'; Group = 'shared_sharepointonline' },
                    [pscustomobject]@{ Name = 'WritePlan'; ExternalEndpoint = 'https://contoso.sharepoint.com/sites/ops'; ExternalDomain = 'contoso.sharepoint.com'; GetSetAction = 'Set'; InteractionDirection = 'Write'; Group = 'shared_sharepointonline' },
                    [pscustomobject]@{ Name = 'WriteUnknownSite'; ExternalEndpoint = ''; ExternalDomain = ''; GetSetAction = 'Set'; InteractionDirection = 'Write'; Group = 'shared_sharepointonline' }
                )
            }

            Get-PowerPlatformCheckerExternalInteractionGraphInternal -FilteredSolutionPaths @('C:\Temp\Energy\Managed') -Direction 'LR'
        } | ForEach-Object {
            $solutionNode = $_.Nodes | Where-Object { $_.Type -eq 'Solution' } | Select-Object -First 1
            $solutionNode | Should -Not -BeNullOrEmpty

            ($_ | Select-Object -ExpandProperty Nodes | Where-Object { $_.Id -eq 'externaldomain_https_contoso_sharepoint_com_sites_energy' }).Count | Should -Be 1
            ($_ | Select-Object -ExpandProperty Nodes | Where-Object { $_.Id -eq 'externaldomain_https_contoso_sharepoint_com_sites_ops' }).Count | Should -Be 1
            ($_ | Select-Object -ExpandProperty Nodes | Where-Object { $_.Id -eq 'externaldomain_unknown_shared_sharepointonline_' }).Count | Should -Be 0

            ($_ | Select-Object -ExpandProperty Nodes | Where-Object { $_.Id -eq 'connection_shared_sharepointonline' }).Count | Should -Be 0

            $energyEdge = $_.Edges | Where-Object { $_.SourceId -eq $solutionNode.Id -and $_.TargetId -eq 'externaldomain_https_contoso_sharepoint_com_sites_energy' -and [string]$_.Label -match 'GET' } | Select-Object -First 1
            $opsEdge = $_.Edges | Where-Object { $_.SourceId -eq $solutionNode.Id -and $_.TargetId -eq 'externaldomain_https_contoso_sharepoint_com_sites_ops' -and [string]$_.Label -match 'SET' } | Select-Object -First 1
            $unknownEdge = $_.Edges | Where-Object { $_.SourceId -eq $solutionNode.Id -and $_.TargetId -eq 'externaldomain_unknown_shared_sharepointonline_' -and [string]$_.Label -match 'SET' } | Select-Object -First 1

            $energyEdge | Should -Not -BeNullOrEmpty
            $opsEdge | Should -Not -BeNullOrEmpty
            $unknownEdge | Should -BeNullOrEmpty

            $energyEdge.Metadata.Evidence | Should -Match 'ReadPlan'
            $opsEdge.Metadata.Evidence | Should -Match 'WritePlan'
        }
    }

    It "adds response actions as outbound arrows to internet with body/status details" {
        InModuleScope PowerPlatformChecker {
            Mock -CommandName Get-PowerPlatformCheckerArchitectureDiagram -MockWith {
                [pscustomobject]@{
                    Nodes = @(
                        [pscustomobject]@{
                            Id = 'flow11111111-1111-1111-1111-111111111111'
                            Type = 'Flow'
                            DisplayName = 'Webhook Flow'
                            ClassKind = 'Flow'
                            Properties = @{
                                TriggerMode = 'ManualHttp'
                                InteractionDirection = 'Write'
                                Destination = ''
                                DestinationTargets = @()
                                DestinationType = 'Unknown'
                            }
                            Members = @()
                            HasExplicitDisplayName = $true
                        }
                    )
                    Edges = @()
                    Styles = @{}
                    StyleOrder = @()
                }
            }

            Mock -CommandName Get-PowerPlatformCheckerFlowFile -MockWith {
                @('C:\Temp\MySolution\Managed\Workflows\WebhookFlow-11111111-1111-1111-1111-111111111111.json')
            }

            Mock -CommandName Get-PowerPlatformCheckerFlowActionList -MockWith {
                @(
                    [pscustomobject]@{
                        Name = 'manual'
                        Type = 'Request'
                        Group = '*'
                        IsTrigger = $true
                        TriggerAuthenticationType = 'Tenant'
                        TriggerAuthenticationDescription = 'Any user in my tenant'
                        TriggerOperationId = 'Request'
                        OperationDisplayName = 'When an HTTP request is received'
                        ConnectorDisplayName = ''
                    },
                    [pscustomobject]@{
                        Name = 'Response_200_back_to_integration'
                        Type = 'Response'
                        Group = '*'
                        IsTrigger = $false
                        ResponseStatusCode = '200'
                        ResponseHasBody = $false
                        ResponseDescription = 'Returns status code only'
                        OperationDisplayName = ''
                        ConnectorDisplayName = ''
                        ExternalProtocol = 'https'
                    }
                )
            }

            Get-PowerPlatformCheckerExternalInteractionGraphInternal -FilteredSolutionPaths @('C:\Temp\MySolution\Managed') -Direction 'LR'
        } | ForEach-Object {
            $solutionNode = $_.Nodes | Where-Object { $_.Type -eq 'Solution' } | Select-Object -First 1
            $solutionNode | Should -Not -BeNullOrEmpty

            $inboundEdge = $_.Edges | Where-Object { $_.SourceId -eq 'externaldomain_internet' -and $_.TargetId -eq $solutionNode.Id -and [string]$_.Label -match 'INBOUND' } | Select-Object -First 1
            $responseEdge = $_.Edges | Where-Object { $_.SourceId -eq $solutionNode.Id -and $_.TargetId -eq 'externaldomain_internet' -and [string]$_.Label -match 'OUTBOUND' } | Select-Object -First 1

            $inboundEdge | Should -Not -BeNullOrEmpty
            $inboundEdge.Label | Should -Match '^Flow-[0-9]{2} INBOUND'
            $responseEdge | Should -Not -BeNullOrEmpty
            $responseEdge.Metadata.Evidence | Should -Match 'Response_200_back_to_integration'
        }
    }

}
