# PowerPlatformChecker

![example workflow](https://github.com/autosysops/PowerShell_PowerPlatformChecker/actions/workflows/build.yml/badge.svg)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/PowerPlatformChecker.svg)](https://www.powershellgallery.com/packages/PowerPlatformChecker/)

PowerPlatformChecker is a PowerShell module for analyzing unpacked Microsoft Power Platform solutions in CI/CD and local development.

The module works on exported/unpacked files and does not require a live connection to Dataverse or Power Automate.

## What This Module Solves

Use this module when you want to:

- Inspect flows, connectors, actions, and parameters from exported JSON/XML
- Check if flow action names still match default operation names
- Build architecture diagrams (Mermaid classDiagram) from solution assets
- Build flowcharts (Mermaid flowchart) with runAfter labels and grouped Scope/If/Switch branches
- Read canvas app metadata, model-driven app metadata, and JavaScript web resources
- Resolve model-driven app form libraries and their dependent JavaScript web resources
- Summarize entities, relations, environment variables, and connection references

## Prerequisites

- PowerShell 7+ recommended
- Solution unpacked with Power Platform CLI (`pac solution unpack`) or equivalent structure
- Required dependency module: `TelemetryHelper`

## Installation

Install from PowerShell Gallery:

```powershell
Install-Module -Name PowerPlatformChecker
```

Or with PSResourceGet:

```powershell
Install-PSResource -Name PowerPlatformChecker
```

Import the module:

```powershell
Import-Module PowerPlatformChecker -Force
```

## Expected Solution Structure

The module expects a folder structure similar to unpacked solutions:

- `Workflows/*.json` and `Workflows/*.json.data.xml`
- `Other/Customizations.xml`
- `Entities/*/Entity.xml`
- `Other/Relationships/*.xml`
- `environmentvariabledefinitions/*/environmentvariabledefinition.xml`
- Optional:
  - `CanvasApps/*.meta.xml`
  - `AppModules/*/AppModule*.xml`
  - `AppModuleSiteMaps/*/AppModuleSiteMap*.xml`
  - `WebResources/**/*.data.xml`
  - `Entities/*/FormXml/**/*.xml`
  - `desktopflowbinaries/*/desktopflowbinary.xml` (+ referenced `data/*.json` payloads)

## Command Overview

### Flow Analysis

- `Get-PowerPlatformCheckerFlowActionList`
- `Get-PowerPlatformCheckerFlowActionDefaultName`
- `Test-PowerPlatformCheckerFlowOperationName`
- `Get-PowerPlatformCheckerFlowType`
- `Get-PowerPlatformCheckerAppType`
- `Get-PowerPlatformCheckerFlowParameter`
- `Get-PowerPlatformCheckerFlowDescription`
- `Get-PowerPlatformCheckerFlowConnectorTier`
- `Get-PowerPlatformCheckerAppConnectorTier`

Path-based flow commands (`Get-PowerPlatformCheckerFlowActionList`,
`Get-PowerPlatformCheckerFlowParameter`, and `Get-PowerPlatformCheckerFlowConnectorTier`)
auto-detect cloud and desktop flows.

`Get-PowerPlatformCheckerFlowActionList` supports optional action profile fields:

- `InteractionProfile` adds `Method`, `GetSetAction`, and `InteractionDirection`
- `ExternalProfile` adds `ExternalUrl`, `ExternalProtocol`, `ExternalDomain`, `ExternalMainDomain`, and `ExternalResolutionState`

`Get-PowerPlatformCheckerFlowType` classifies as `Cloud` when the JSON includes
`properties.connectionReferences` and `properties.definition`; otherwise it checks
desktop metadata markers (`Category=6` or `UIFlowType=2`) in the companion
`Workflows/*.json.data.xml` file.

Desktop flow parsing also normalizes escaped `Definition` payloads before tokenizing
commands. That allows flowcharts and architecture members to handle multiline email
bodies, escaped selector literals, and `@INPUT`/`@OUTPUT` directives without leaking
metadata lines or free-form text into rendered diagrams.

### Solution Metadata

- `Get-PowerPlatformCheckerSolutionObject`
- `Get-PowerPlatformCheckerSolutionRelation`
- `Get-PowerPlatformCheckerEntity`
- `Get-PowerPlatformCheckerEntityFormXmlWebResource`
- `Get-PowerPlatformCheckerApp`
- `Get-PowerPlatformCheckerWebResource`

`Get-PowerPlatformCheckerApp` behavior:

- Returns both canvas and model-driven app metadata.
- Use `-AppType CanvasApp` or `-AppType ModelDrivenApp` when you want one app family only.
- Use `-Properties` to request heavier sections such as `ConnectionReferences`, `DataSources`, `Entities`, `FlowIds`, `WebResources`, `EntityWebResources`, and `Components`.

### Diagram Generation

- `Get-PowerPlatformCheckerArchitectureDiagram`
- `Get-PowerPlatformCheckerApp`
- `Get-PowerPlatformCheckerFlowChart`
- `Get-PowerPlatformCheckerFlow`
- `Get-PowerPlatformCheckerExternalInteraction`

`Get-PowerPlatformCheckerArchitectureDiagram` supports:

- Filtered views with `-FlowId`, `-CanvasAppName`, or `-ModelDrivenAppName`
- Include-group filtering with `-IncludeElements`
- Per-call style overrides with `-StyleOverrides`
- Session-level style defaults with `Set-PowerPlatformCheckerStyle`
- Output format selection with `-OutputFormat Mermaid|Graph`
- Flow nodes are tagged in the diagram label as `[CLOUD]` or `[DESKTOP]`.
- External-domain rendering can be toggled with `-IncludeElements ExternalDomains`.

`Get-PowerPlatformCheckerExternalInteraction` supports multi-solution interaction generation:

- Accepts multiple input paths
- Optional recursive discovery of solution folders
- Optional include/exclude wildcard filters for solution folder names
- Returns either Mermaid or combined Graph output
- Preserves multiple outbound destinations per solution when distinct domains/services are discovered
- Adds inbound `internet` relationships for webhook/manual HTTP-triggered flows
- Carries representative action evidence in graph-edge metadata for downstream consumers
- Stores structured edge label metadata (`LabelParts`) in Graph output so downstream renderers can rebuild labels per format
- Keeps full descriptive edge labels in Graph output, including connector names where available
- Uses compact lookup labels in Mermaid output and lists the source aliases plus plain-text connector codes in the legend
- Normalizes external domain node labels by removing `http://` or `https://` prefixes for wiki-safe rendering

`Get-PowerPlatformCheckerFlowChart` supports Mermaid and recursive graph output with
`-OutputFormat Mermaid|Graph`.

### App And Flow Retrieval

- `Get-PowerPlatformCheckerApp`
- `Get-PowerPlatformCheckerFlow`

`Get-PowerPlatformCheckerApp` returns summary metadata for canvas and model-driven apps through one command.
Use `-Properties` to request larger sections such as `ConnectionReferences`, `DataSources`, `Entities`, or `FlowIds` when generating documentation.

`Get-PowerPlatformCheckerFlow` returns summary metadata for cloud and desktop flows through one command.
Use `-Properties` to request `Parameters`, `Actions`, `Trigger`, or `ConnectorTiers` for documentation-focused expansion.

Cloud flow action external profiles now resolve URL/domain metadata from direct URLs and connector-style parameter fields such as `dataset`, `source`, `siteAddress`, and `baseUrl`, including simple parameter interpolation.

### Connector and Operation Catalogs

- `Get-PowerPlatformCheckerConnectorData`
- `Get-PowerPlatformCheckerOperationData`

## Telemetry

Public commands send lightweight usage telemetry through `TelemetryHelper`.

- Telemetry is opt-in through `$Env:PowerPlatformChecker_TELEMETRY_OPTIN`.
- Payloads are limited to non-sensitive metadata such as parameter-set selection,
  counts, or classification outcomes.
- File paths, solution names, flow names, action contents, and other customer data
  are not intentionally added to telemetry payloads by module commands.

## Usage Examples

### 1) Build a solution object snapshot

```powershell
$solutionPath = "C:\Solutions\MySolution\Managed"
$solution = Get-PowerPlatformCheckerSolutionObject -SolutionPath $solutionPath

$solution.Workflows.Count
$solution.Entities.Count
$solution.CanvasApps.Count
$solution.ModelDrivenApps.Count
```

### 2) Check connector tiers used in a flow

```powershell
$flowPath = "C:\Solutions\MySolution\Managed\Workflows\MyFlow.json"
Get-PowerPlatformCheckerFlowConnectorTier -Path $flowPath
```

### 2c) Check connector tiers used by canvas and model-driven apps

```powershell
Get-PowerPlatformCheckerAppConnectorTier -SolutionPath "C:\Solutions\MySolution\Managed"
```

`Get-PowerPlatformCheckerAppConnectorTier` auto-detects app type from solution files and emits rows for both canvas and model-driven apps.

### 2b) Detect flow type before analysis

```powershell
$flowPath = "C:\Solutions\MySolution\Managed\Workflows\MyFlow.json"
Get-PowerPlatformCheckerFlowType -Path $flowPath
```

### 3) Validate flow action names against defaults

```powershell
Test-PowerPlatformCheckerFlowOperationName -Path "C:\Solutions\MySolution\Managed\Workflows\MyFlow.json"
```

### 4) Generate a flowchart (markdown + mermaid)

```powershell
$actions = Get-PowerPlatformCheckerFlowActionList `
  -Path "C:\Solutions\MySolution\Managed\Workflows\MyFlow.json" `
  -Recurse -IncludeTrigger -Properties RunAfter, ParentAction, References, Entities, InteractionProfile, ExternalProfile

Get-PowerPlatformCheckerFlowChart -Actions $actions
```

Flowchart output groups Scope and If blocks with explicit post-branch continuation into Mermaid subgraphs. Switch blocks include titled case/default subgraphs when they contain actions, keeping branch internals separate from downstream "Succeeded" continuation actions while avoiding empty Mermaid wrappers.

When generating per-flow documentation, `Get-PowerPlatformCheckerFlowType` is used to show the flow type and the flowchart section is generated from the same flow-specific metadata.

### 5) Generate architecture diagram for entire solution

```powershell
Get-PowerPlatformCheckerArchitectureDiagram -SolutionPath "C:\Solutions\MySolution\Managed"
```

### 6) Generate filtered architecture diagrams

```powershell
# Single flow
Get-PowerPlatformCheckerArchitectureDiagram `
  -SolutionPath "C:\Solutions\MySolution\Managed" `
  -FlowId "00000000-0000-0000-0000-000000000000"

# Single canvas app
Get-PowerPlatformCheckerArchitectureDiagram `
  -SolutionPath "C:\Solutions\MySolution\Managed" `
  -CanvasAppName "contoso_canvasapp_1234"

# Single model-driven app
Get-PowerPlatformCheckerArchitectureDiagram `
  -SolutionPath "C:\Solutions\MySolution\Managed" `
  -ModelDrivenAppName "contoso_ModelApp"
```

Filtered flow, canvas app, and model-driven app diagrams are scoped to directly connected components for the selected item.

### 7) Generate graph output for downstream tooling

```powershell
$graph = Get-PowerPlatformCheckerArchitectureDiagram `
  -SolutionPath "C:\Solutions\MySolution\Managed" `
  -OutputFormat Graph

$graph.Nodes.Count
$graph.Edges.Count
```

Graph output is the complete, renderer-independent source used to produce Mermaid. It does not
contain a second copy of the Mermaid text.

Flowcharts can be returned as graphs in the same way:

```powershell
$flowGraph = Get-PowerPlatformCheckerFlowChart `
  -Actions $actions `
  -Direction TB `
  -OutputFormat Graph

$flowGraph.Nodes.Count
$flowGraph.Subgraphs.Count
```

### 8) Build a combined external interaction graph from multiple solutions

```powershell
Get-PowerPlatformCheckerExternalInteraction `
  -SolutionPaths @(
    "C:\Solutions\Energy\Managed",
    "C:\Solutions\Telecom\Managed"
  ) `
  -OutputFormat Mermaid
```

## Graph Schemas

### Architecture diagram graph

`Get-PowerPlatformCheckerArchitectureDiagram -OutputFormat Graph` returns this top-level schema:

| Property | Contents |
| --- | --- |
| `Metadata` | `Direction`, `IncludeElements`, `IsScopedDiagram`, `SourceFilterType`, `SourceFilterValue`, and `OutputFormat` |
| `Nodes` | Architecture components consumed by the class-diagram renderer |
| `Edges` | Valid, deduplicated relationships between declared nodes |
| `Styles` | Mermaid class names mapped to resolved `fill` and `stroke` declarations |
| `StyleOrder` | Stable class-style rendering order |

Every architecture node has the following properties:

| Property | Meaning |
| --- | --- |
| `Id` | Stable Mermaid-safe node identifier |
| `Type` | Component type such as `Flow`, `Entity`, `CanvasApp`, or `WebResource` |
| `DisplayName` | Human-readable component name |
| `ClassKind` | Style class selected from `Styles` |
| `Properties` | Additional structured component metadata; currently reserved for graph consumers |
| `Members` | Lines rendered inside the Mermaid class, including entity fields and flow references |
| `HasExplicitDisplayName` | Whether the renderer emits a separate display label |

Every architecture edge contains `SourceId`, `TargetId`, `Label`, `EdgeType`, and
`Metadata.Arrow`. `EdgeType` describes the relationship semantics; `Metadata.Arrow` contains the
resolved Mermaid arrow such as `-->` or `..>`. Edge endpoints always refer to nodes in `Nodes`.

### Flowchart graph

`Get-PowerPlatformCheckerFlowChart -OutputFormat Graph` returns a recursive `FlowchartGraph`:

| Property | Contents |
| --- | --- |
| `GraphType` | Always `FlowchartGraph` |
| `Id` | Subgraph identifier; `$null` for the root graph |
| `ActionName` | Action that owns the subgraph; `$null` for the root graph |
| `Title` | Mermaid subgraph title |
| `Direction` | `TB`, `BT`, `LR`, or `RL` |
| `IsEmpty` | Indicates an empty root action list |
| `Nodes` | Nodes directly owned by this graph, each with `Id`, `Label`, and `Shape` |
| `Edges` | Edges directly owned by this graph, each with `From`, `To`, and `Label` |
| `Subgraphs` | Nested objects using this same `FlowchartGraph` schema |

Node `Shape` is `Trigger`, `Decision`, or `Action`. Scope, continuation-style condition, Switch,
and Switch case/default boundaries are represented by recursive `Subgraphs`; an edge is stored
at the graph level that owns both of its endpoints. This ownership prevents nested edges from
leaking into the root graph.

## Architecture Diagram Styles

Styling applies to architecture diagrams, not flowcharts. The resolved palette follows this
precedence, from lowest to highest:

1. Built-in module defaults.
2. Session defaults changed with `Set-PowerPlatformCheckerStyle`.
3. Per-call values passed to `Get-PowerPlatformCheckerArchitectureDiagram -StyleOverrides`.

Supported keys and built-in values are:

| Key | Default | Used for |
| --- | --- | --- |
| `Default` | `red` | Missing or unresolved components |
| `EnvVar` | `#DF9A57` | Environment variables |
| `Connection` | `#FCD757` | Connection references |
| `Entity` | `#B56784` | Solution entities |
| `DefaultEntity` | `#71374D` | Referenced platform entities |
| `Flow` | `#DBE4EE` | Power Automate flows |
| `CanvasApp` | `#8BC34A` | Canvas apps |
| `ModelDrivenApp` | `#7BAFD4` | Model-driven apps |
| `WebResource` | `#D7C8F3` | JavaScript and icon web resources |
| `Solution` | `#f5f5fa` | External interaction solution nodes |
| `ExternalDomain` | `#E6D3A3` | External systems and internet domains |
| `Stroke` | `#5E5B52` | Border color shared by all classes |

Set defaults for all subsequent diagrams in the current imported-module session:

```powershell
Set-PowerPlatformCheckerStyle `
  -StyleTarget ArchitectureDiagram `
  -Flow '#0078D4' `
  -Entity '#00A36C' `
  -Connection '#FFB900' `
  -Stroke '#242424'
```

The command returns a copy of the resolved session palette, rejects unsupported keys and empty
values, and supports `-WhatIf` and `-Confirm`. Re-importing the module starts a new session with
the built-in defaults.

You can update multiple values in one call by passing multiple style key parameters:

```powershell
Set-PowerPlatformCheckerStyle -StyleTarget ArchitectureDiagram -Flow '#0078D4' -Stroke '#242424'
```

To inspect available keys and current values:

```powershell
Get-PowerPlatformCheckerStyle -StyleTarget ArchitectureDiagram
```

Override only one diagram without changing session defaults:

```powershell
Get-PowerPlatformCheckerArchitectureDiagram `
  -SolutionPath "C:\Solutions\MySolution\Managed" `
  -StyleOverrides @{ Flow = '#4CC9F0'; Stroke = '#2B2D42' }
```

`-StyleOverrides` applies recognized, non-empty keys to that call only. Other classes retain the
current session values. The resolved styles are also exposed in graph output through `Styles` and
`StyleOrder`, so downstream renderers can use the same palette.

## Telemetry Details

This module uses `TelemetryHelper` for lightweight usage telemetry.

Telemetry captures non-sensitive usage metadata only, for example:

- Which parameter set was used
- Whether optional filters were supplied
- Feature usage buckets (such as action count size categories)

Telemetry does **not** send flow names, entity names, file contents, or credentials.

You can control telemetry using the module's telemetry opt-in environment variable shown during import.

## Development, Build, and Test

From repository root:

```powershell
# Run validation (includes Pester and analyzer)
.\build\vsts-validate.ps1

# Build publish folder locally without publishing
.\build\vsts-build.ps1 -SkipPublish

# Optional: skip connector/operation cache refresh for faster local iteration
.\build\vsts-build.ps1 -SkipPublish -DontUpdateCache
```

`vsts-build.ps1` now validates `FunctionsToExport` in the module manifest against files in `PowerPlatformChecker/functions` and fails fast on mismatches.

Test outputs are written to `TestResults/`.

Function tests are organized per command in `tests/functions/`.

Code coverage is generated during test runs and enforced by threshold in `tests/pester.ps1`.

## CI Test Reporting

GitHub workflows in `.github/workflows/`:

- Run validation on PR and push
- Publish pester XML test reports (`TestResults/TEST-*.xml`)
- Upload full `TestResults/*` artifacts

## Credits

- Telemetry: [TelemetryHelper](https://github.com/nyanhp/TelemetryHelper)
- Module scaffolding baseline: [PSModuleDevelopment](https://github.com/PowershellFrameworkCollective/PSModuleDevelopment)
