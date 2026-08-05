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
- Build flowcharts (Mermaid flowchart) with runAfter and branch labels
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

## Command Overview

### Flow Analysis

- `Get-PowerPlatformCheckerFlowActionList`
- `Get-PowerPlatformCheckerFlowActionDefaultName`
- `Test-PowerPlatformCheckerFlowOperationName`
- `Get-PowerPlatformCheckerFlowParameter`
- `Get-PowerPlatformCheckerFlowDescription`
- `Get-PowerPlatformCheckerFlowConnectorTier`

### Solution Metadata

- `Get-PowerPlatformCheckerSolutionObject`
- `Get-PowerPlatformCheckerSolutionRelation`
- `Get-PowerPlatformCheckerEntity`
- `Get-PowerPlatformCheckerEntityFormXmlWebResource`
- `Get-PowerPlatformCheckerCanvasApp`
- `Get-PowerPlatformCheckerModelDrivenApp`
- `Get-PowerPlatformCheckerModelDrivenAppComponentType`
- `Get-PowerPlatformCheckerWebResource`

`Get-PowerPlatformCheckerModelDrivenApp` behavior:
- `WebResources` contains direct app component links.
- `EntityWebResources` contains entity FormXML script ownership used for `App -> Entity -> Script` chains.

`Get-PowerPlatformCheckerModelDrivenAppComponentType` common values:
- `1` = Entities
- `29` = Business Process Flows
- `62` = Sitemap

### Diagram Generation

- `Get-PowerPlatformCheckerArchitectureDiagram`
- `Get-PowerPlatformCheckerFlowChart`

`Get-PowerPlatformCheckerArchitectureDiagram` supports:
- Filtered views with `-FlowId`, `-CanvasAppName`, or `-ModelDrivenAppName`
- Include-group filtering with `-IncludeElements`
- Style overrides with `-StyleOverrides`
- Output format selection with `-OutputFormat Mermaid|Graph`

### Connector and Operation Catalogs

- `Get-PowerPlatformCheckerConnectorData`
- `Get-PowerPlatformCheckerOperationData`

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

### 3) Validate flow action names against defaults

```powershell
Test-PowerPlatformCheckerFlowOperationName -Path "C:\Solutions\MySolution\Managed\Workflows\MyFlow.json"
```

### 4) Generate a flowchart (markdown + mermaid)

```powershell
$actions = Get-PowerPlatformCheckerFlowActionList `
  -Path "C:\Solutions\MySolution\Managed\Workflows\MyFlow.json" `
  -Recurse -IncludeTrigger -Properties RunAfter, ParentAction, References, Entities

Get-PowerPlatformCheckerFlowChart -Actions $actions
```

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

The Graph output includes `Metadata`, `Nodes`, `Edges`, `Styles`, and the original `Mermaid` text.

## Telemetry

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
