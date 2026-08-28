# Research Notes - Testing Rules and Lessons Learned

Date: 2026-08-25
Scope: PowerShell_PowerPlatformChecker module

## 1. Purpose

This file captures the testing standards, telemetry privacy rules, regression protections, and practical lessons learned during this conversation so implementation can continue without ambiguity.

## 2. Non-negotiable Requirements

These requirements were explicitly requested and are treated as policy:

- Verify telemetry is useful and does not send confidential information.
- Test full telemetry payload content, not only that Send-THEvent was called.
- Keep tests data-driven where patterns repeat.
- Maintain code coverage at or above 95 percent.
- Include edge-case tests, not only happy paths.
- Keep one function per file.
- Keep code readable and sufficiently commented where logic is non-obvious.

## 3. Testing Architecture Rules

- Use one test file per function under tests/functions.
- Keep shared test helpers in tests/functions/PowerPlatformChecker.TestCommon.ps1.
- Keep telemetry safety assertions in each function test file (not centralized in one telemetry mega-file).
- For private/internal function tests, use InModuleScope PowerPlatformChecker.
- Use deterministic fixture-based snapshots for graph/diagram outputs.
- Keep fixture and expected files UTF-8 BOM to satisfy file integrity tests.
- Prefer reusable fixture files under tests/fixtures for contract scenarios rather than generating full flow payloads in TestDrive.
- Reserve TestDrive-generated flow payloads for narrow parser-fuzz/escaping edge cases only.

### Progress reporting discipline (2026-08-26)

- Every implementation burst must append status in LOG.MD before moving phases.
- PLAN.MD and RESEARCH.MD must mirror major LOG.MD steering updates so phase intent and execution evidence stay aligned.
- If a planned behavior is deferred to a later phase, track it in PLAN.MD/RESEARCH.MD and avoid skipped tests in full-coverage suites.

### Test hygiene policy (2026-08-26)

- No skipped tests in functional coverage-critical suites; tests must pass or fail.
- When warnings are expected in tests, capture/assert them without console noise using warning stream controls.
- Keep fixture structure close to unpacked solution layouts so tests remain realistic for solution-wide analyzers.
- Consolidate related fixtures when shared structure increases realism and avoids fragmented edge-case directories.

### Execution ordering clarification (2026-08-26)

- App/flow parity hardening and invalid-fixture resilience are pre-stabilization requirements.
- These items must execute before final stabilization (Phase F) to avoid late-cycle regressions and forgotten backlog tasks.

### Fixture-first clarification (2026-08-26)

- If a test validates a behavior that should be represented in architecture/graph outputs, add it to fixtures first.
- Add or extend snapshot tests where practical so new fixture behavior is visible in long-term regression coverage.
- Treat inline JSON/XML flow payload generation as an exception path and annotate why it cannot reasonably be fixture-backed.
- Before final stabilization, run an explicit audit of snippet/TestDrive usage in tests and migrate remaining contract-path cases to fixtures.
- Keep inline snippet tests only for parser-fuzz/tokenizer edge cases where fixture files reduce clarity or test intent.

### App/flow parity clarification (2026-08-26)

- Where possible, app classification functions should mirror flow classification ergonomics.
- Public type-detection commands should prefer path-based contracts over object-shape contracts.
- Internal object-shape detection is acceptable only when there is a proven implementation need that cannot be met by path-based metadata.

### Invalid fixture resilience clarification (2026-08-26)

- Where invalid app/flow fixtures exist, public analysis functions should fail gracefully.
- Preferred behavior for invalid inputs:
  - classify as Unknown where classification commands apply,
  - return empty collections for list-style analyzers,
  - emit a warning message that indicates invalid app/flow payload or missing file.
- Add fixture-backed tests for warning/message behavior where practical.

## 4. Telemetry Privacy Standard

### Core rule

Telemetry may capture option usage and execution shape, never user data or sensitive content.

### Required test pattern per telemetry-emitting public function

1. Mock Send-THEvent and capture full call payload.
2. Filter captured events by expected EventName.
3. Assert exactly one matching event for the test invocation.
4. Assert exact PropertiesHash key set (strict schema regression guard).
5. Assert key names do not include sensitive markers.
6. Assert confidential values from invocation are absent from serialized PropertiesHash.

### Shared helper

- tests/functions/PowerPlatformChecker.TestCommon.ps1
- Helper: Assert-PowerPlatformCheckerTelemetrySafe

Implementation details learned:

- Declare shared helper as global: to avoid scope misses in direct file-level Invoke-Pester runs.
- Allow empty ExpectedKeys in telemetry tests.
- Validate non-null hashtable with:
  - ($null -ne $properties) | Should -BeTrue
  instead of Should -Not -BeNull for empty hashtables.

## 5. Telemetry Test Coverage Strategy

Telemetry checks were embedded into each relevant function test so behavior and privacy assertions stay together.

Covered telemetry-emitting public functions include:

- Get-PowerPlatformCheckerArchitectureDiagram
- Get-PowerPlatformCheckerCanvasApp
- Get-PowerPlatformCheckerConnectorData
- Get-PowerPlatformCheckerEntity
- Get-PowerPlatformCheckerEntityFormXmlWebResource
- Get-PowerPlatformCheckerFlowActionDefaultName
- Get-PowerPlatformCheckerFlowActionList
- Get-PowerPlatformCheckerFlowChart
- Get-PowerPlatformCheckerFlowConnectorTier
- Get-PowerPlatformCheckerFlowDescription
- Get-PowerPlatformCheckerFlowParameter
- Get-PowerPlatformCheckerFlowType
- Get-PowerPlatformCheckerModelDrivenApp
- Get-PowerPlatformCheckerModelDrivenAppComponentType
- Get-PowerPlatformCheckerOperationData
- Get-PowerPlatformCheckerSolutionObject
- Get-PowerPlatformCheckerSolutionRelation
- Get-PowerPlatformCheckerStyle
- Get-PowerPlatformCheckerWebResource
- Set-PowerPlatformCheckerStyle
- Test-PowerPlatformCheckerFlowOperationName

Important multi-path coverage examples:

- ArchitectureDiagram: no filter, flow filter, canvas filter, model-driven filter.
- FlowDescription: ByName and ById paths.
- FlowActionList: Path and Actions parameter sets.
- FlowConnectorTier and FlowType: cloud and desktop variants.

## 6. Baseline Validation Status

Previously validated in this conversation:

- Full test run green: 6251 tests.
- Coverage after telemetry hardening: 95.38 percent.

This is the baseline to preserve while adding the external interaction feature.

## 7. High-value Regression Learnings

### 7.1 Snapshot and graph determinism

- Compare normalized full output for diagram snapshots, not partial regex checks.
- Mermaid regressions can come from malformed blank edge lines; sanitize before snapshot compare/regeneration.
- In recursive graph rendering helpers, cast List mutators (Add/Remove/Clear) to [void] to prevent True/False leakage into output.

### 7.2 Scoped architecture behavior

- Expand scoped reachability before entity rendering to avoid false missing-reference nodes.
- Resolve DefaultEntity logical names through entity-set mapping first to avoid duplicate or false default nodes.

### 7.3 Desktop flow parsing behavior

- Desktop Definition can be wrapped in outer quotes and include directive lines (for example @@ConnectionString, @INPUT).
- Parser must ignore directive/non-command segments.
- Tokenize across full Definition payload, not line-by-line only, to support multiline single-quoted payloads.
- Tokenizer must always split correctly on line breaks outside triple-single-quoted blocks.

### 7.4 Desktop flowchart semantics and readability

- ON BLOCK ERROR handlers must keep correct RunAfter from wrapped scope while using outer parent for ParentAction/Depth.
- Keep scope boundary edges at parent graph level to avoid Mermaid cycle errors.
- Improve labels for readability:
  - CALL includes called target
  - WAIT <number> renders as WAIT for X seconds
  - WaitForWebPageContent.* renders human-readable condition text
  - External.InvokeCloudConnector labels include connector tail and operation id when available

### 7.5 Desktop architecture extraction rules

- Resolve wildcard workflow paths to concrete file paths before reading .json.data.xml metadata.
- Source desktop environment variables from Workflow.Dependencies.environmentVariables (or EnvironmentVariables), not input schema properties.
- For [INPUT] members, include only true runtime inputs and @INPUT directives.

### 7.6 Web resource and model-driven dependency tests

- Derive JavaScript source path from .data.xml metadata by removing .data suffix before extension.
- Model-driven fixture tests must validate App -> Entity -> Script dependency chaining, not only AppModuleComponent JS links.

## 8. Telemetry Scope Convention

- Keep Send-THEvent calls in public exported functions.
- Do not add telemetry in internal/private functions under PowerPlatformChecker/internal/functions.

## 9. Test Execution Workflow

Recommended sequence when implementing changes:

1. Add/adjust tests first (red).
2. Implement minimal code changes (green).
3. Run focused tests for affected files/functions.
4. Regenerate snapshots only for intentional behavior changes.
5. Run full tests via tests/pester.ps1.
6. Run full validation via build/vsts-validate.ps1.
7. Confirm coverage remains at or above 95 percent.

## 10. Practical Checklist for New Public Functions

- Keep one function per file.
- Add function-specific tests in tests/functions.
- If telemetry is emitted:
  - assert exact telemetry key set
  - assert deny-list key name rules
  - assert confidential values are absent
- Add parameter-set and edge-case tests.
- Add deterministic fixtures/snapshots if output is structured text/graph.
- Verify cloud-path behavior does not regress unless explicitly intended.

## 11. Notes for Upcoming External Interaction Feature

Testing obligations derived from this research:

- Direction classifier tests must be data-driven.

## 12. Canvas msapp enrichment notes (2026-08-26)

- Canvas `*_DocumentUri.msapp` packages are ZIP archives that can be parsed safely offline.
- In observed solutions, archive entries used backslash separators (for example `References\DataSources.json` and `Src\Course Screen.pa.yaml`), so parsing must support both slash styles.
- `References/DataSources.json` provides reliable external target hints (`DatasetName`) and connector identity (`ApiId`) for connected sources.
- `Src/*.pa.yaml` provides formula-level interaction evidence that can infer read/write tendencies per datasource (best effort).
- For conservative behavior:
  - prefer explicit connected datasource domains as destination evidence,
  - keep interaction direction `Unknown` when formula evidence is absent,
  - avoid over-asserting verb certainty beyond normalized `Read/Write/Mixed/Unknown`.
- External interaction projection should prefer edge-level direction metadata when available, instead of only node-level direction, to preserve datasource-specific granularity.
- Narrow formula classification is safer than broad line-window scanning. A +/-1 line fallback works for multiline datasource references without contaminating read/write inference with adjacent properties.
- Canvas-only fixtures should include a packaged `.msapp` and be covered by external-interaction snapshots, not only by TestDrive-generated helper tests.

## 13. Mermaid image support and connector icons (2026-08-27)

- Mermaid flowcharts in modern syntax support image nodes via object syntax such as:
  - `A@{ img: "https://example.com/image.png", label: "SharePoint", pos: "t", h: 60, constraint: "on" }`
- Mermaid also supports icon-based nodes via registered icon packs:
  - `A@{ icon: "fa:user", form: "square", label: "User" }`
- Practical limitation for this repository:
  - the downstream wiki/doc renderers used in this workflow were already sensitive to Mermaid syntax changes,
  - and this image/object-node syntax is newer than the baseline syntax already validated in this repo.
- Because the environment does not permit safe external validation of internal diagrams, image-node rendering should be treated as compatibility-risky until verified in the target renderer.
- Real canvas app metadata can contain connector icon URLs directly in `ConnectionReferences` payloads (`iconUri` was confirmed in the E-Learning canvas app metadata).
- The local connector catalog used by this module does not expose an obvious stable icon-url field for all connector groups, so canvas metadata is currently the strongest confirmed icon source.
- Recommended implementation posture:
  - keep image-node support documented in research,
  - preserve parser-safe text-only Mermaid output by default,
  - if image rendering is attempted later, gate it behind explicit testing in the actual target renderer.

## 14. Module review findings after scriptblock-helper cleanup (2026-08-27)

- Remaining local scriptblock pseudo-function patterns still exist and should be refactored into real top-level helpers:
  - `PowerPlatformChecker/functions/Get-PowerPlatformCheckerFlowConnectorTier.ps1`
  - `PowerPlatformChecker/internal/functions/Get-PowerPlatformCheckerFlowActionInteractionProfile.ps1`
  - `PowerPlatformChecker/internal/functions/Get-PowerPlatformCheckerFlowDestinationMetadata.ps1`
  - `PowerPlatformChecker/internal/functions/Get-PowerPlatformCheckerWebResourceExternalDomain.ps1`
  - `PowerPlatformChecker/internal/functions/Resolve-PowerPlatformCheckerFlowExpressionValue.ps1`
- These are maintainability issues, not currently failing-behavior issues, but they violate the clarified instruction standard and are the next obvious cleanup targets.
- Trigger mode inference tests must include webhook/polling/manual fixtures.
- Destination extraction tests must include connector-specific and generic URL/domain cases.
- Mermaid and Graph output for the new command must have snapshot coverage.
- Telemetry tests for the new public command must remain option-only and privacy-safe.

If these are not met, the feature is not complete.

## 12. External Interaction Diagram GAP Analysis (2026-08-25)

### 12.1 Requested capability (target state)

For all selected solutions, produce a diagram that shows how artifacts interact with external systems outside Power Platform, including:

- Connector usage across cloud flows and apps.
- Direction of interaction (read/get vs write/set where possible).
- Destination details (site/domain/system endpoint when derivable).
- Trigger mode visibility:
  - polling triggers should appear as pull behavior.
  - webhook triggers should appear as internet/webhook behavior.
- Web resource outbound domains referenced from JavaScript.
- External interaction graph command should support a condensed view where each solution and its internal components are represented as a single block with outbound edges to external systems.
- Outbound edge labels should reflect interaction intent (Get/Set/Unknown confidence-based), not raw internal component fan-out.

### 12.2 What exists already (strong reuse candidates)

Existing architecture graph pipeline already supports node/edge composition and can be reused with minimal structural change:

- Public graph entry point:
  - PowerPlatformChecker/functions/Get-PowerPlatformCheckerArchitectureDiagram.ps1
- Flow graph contribution:
  - PowerPlatformChecker/internal/functions/Get-PowerPlatformCheckerArchitectureFlowGraphContent.ps1
- Flow action parser:
  - PowerPlatformChecker/internal/functions/Get-PowerPlatformCheckerFlowActionListInternal.ps1
- Canvas app parser:
  - PowerPlatformChecker/functions/Get-PowerPlatformCheckerCanvasApp.ps1
- Model-driven app parser:
  - PowerPlatformChecker/functions/Get-PowerPlatformCheckerModelDrivenApp.ps1
- Web resource parser:
  - PowerPlatformChecker/functions/Get-PowerPlatformCheckerWebResource.ps1
  - PowerPlatformChecker/internal/functions/Get-PowerPlatformCheckerWebResourceJavaScriptMethod.ps1

Catalog data and refresh scripts already present:

- Connector catalog refresh:
  - build/helper/Get-PowerPlatformConnectors.ps1
- Operations catalog refresh:
  - build/helper/Get-PowerPlatformFlowOperations.ps1
- Runtime catalog files:
  - PowerPlatformConnectors.json
  - PowerPlatformOperations.json

### 12.3 Practical validation performed

#### Solution-level payload validation (HamexCatalogus)

Confirmed in unpacked flow JSON under Solutions/Energy/HamexCatalogus:

- Trigger kinds present:
  - Request (manual/http)
  - Recurrence (polling)
  - OpenApiConnectionWebhook (connector webhook)
- Action kinds present:
  - OpenApiConnection for connector operations
  - Response/Http for inbound/outbound webhook patterns
- For connector operations, trigger/actions consistently expose:
  - inputs.host.apiId
  - inputs.host.operationId
  - inputs.parameters (often containing connector-specific routing values like entityName, table, dataset, company, bcenvironment)

This confirms the raw solution payload has enough signal for trigger mode and operation intent classification.

#### Live endpoint payload shape validation

Validated against live APIs used by module build helpers:

- Power Automate operations endpoint returns richer properties than persisted:
  - operationType, usage, operationKind, trigger, manifest (where present), etc.
- Connectivity connectors endpoint returns richer properties than persisted:
  - runtimeUrls, primaryRuntimeUrl, interfaces, metadata, connectionParameters, capabilities, etc.

Conclusion: key metadata is available upstream, but much of it is currently dropped during catalog persistence or parser output shaping.

### 12.4 GAP matrix

#### A. Connector/action direction (GET vs SET)

Status now:

- Flow parser outputs connector group and operation id, but not explicit direction semantics.

Missing:

- Deterministic mapping from operation to interaction direction classification.

Acquisition approach:

- Primary: use operation metadata in PowerPlatformOperations.json (and/or live operation payload fields) to infer usage semantics.
- Secondary fallback: heuristic on operationId/name patterns (for example list/get/read/find vs create/update/delete/post/send).
- Output as normalized enum (Read, Write, Mixed, Unknown) instead of over-claiming exact HTTP verb when unavailable.

Risk:

- Some connectors abstract verbs; exact HTTP method is not always available in current persisted catalog.

Mitigation:

- Confidence scoring plus Unknown fallback.
- Optional future enhancement to persist deeper manifest/openapi fields when available.

#### B. Trigger mode visibility (polling vs webhook vs manual)

Status now:

- Trigger type exists in flow definition, but diagram output does not expose mode.

Missing:

- Trigger mode annotation on nodes/edges.

Acquisition approach:

- Classify from trigger type and recurrence/connector metadata:
  - Recurrence -> Polling
  - OpenApiConnectionWebhook -> Webhook
  - Request + kind Http -> Manual/Inbound HTTP
- Show explicit direction for poll/webhook behavior in graph properties and Mermaid labels.

#### C. Connector destination details (sites/domains/systems)

Status now:

- Connector identity is shown; destination endpoint details are not.

Missing:

- Normalized destination target per connector usage.

Acquisition approach:

- Use layered extraction:
  1. From flow action parameters (for example entityName, dataset/table/company, URL-like fields).
  2. From environment variables referenced by flow parameters.
  3. From connector catalog metadata (runtimeUrls/primaryRuntimeUrl where available).
  4. Connector-specific enrichers for high-value connectors (Dataverse, SharePoint, Business Central, Office 365, custom/HTTP-like connectors).

Risk:

- Many connectors do not expose tenant/site host directly in unpacked flow JSON.

Mitigation:

- Emit destination as best-effort with confidence and source field provenance.

#### D. Web resource outbound domain discovery

Status now:

- JS parser extracts method names only; no URL/domain scanning.

Missing:

- Domain extraction from JavaScript content and graph linking to internet/external endpoints.

Acquisition approach:

- Extend web resource analysis with conservative URL/domain detectors:
  - absolute URL literals
  - protocol-relative URLs
  - common network call patterns (fetch, XMLHttpRequest, axios, window.open/navigation)
- Normalize and deduplicate domains; avoid false positives with allow/deny regex guards.

Risk:

- Dynamic string construction can hide domains.

Mitigation:

- Mark static-only detection and Unknown for dynamic/unresolved cases.

#### E. Canvas app destination extraction

Status now:

- Canvas parser returns connection references and database reference names only.

Missing:

- Concrete destination host/domain extraction from canvas artifacts.

Acquisition approach:

- Support both existing metadata and CLI unpacked source shapes:
  - Connection/DataSources folders from unpacked msapp layouts.
  - pa.yaml source references where available.
- Enrich from connection reference to connector metadata and optional environment settings.

Risk:

- Newer source control format is evolving; fields differ by format.

### 12.5 Canvas datasource destination precision finding (2026-08-26)

Observed current behavior:

- `Get-PowerPlatformCheckerCanvasDestinationProfile` currently classifies destinations from connector ids only (for example `shared_sharepointonline` -> `sharepoint`) with low-confidence service-level output.
- Current logic does not use concrete datasource endpoint fields even when available.

Validated datasource signal from unzipped canvas apps:

- In `References/DataSources.json`, connector-backed entries (`Type = ConnectedDataSourceInfo`) contain destination-bearing fields:
  - `ApiId` (connector identity)
  - `DatasetName` (often concrete endpoint/site URL, e.g. SharePoint site)
  - `TableName` (dataset object/list identifier)
- Example verified in local reference app data:
  - `ApiId = /providers/microsoft.powerapps/apis/shared_sharepointonline`
  - `DatasetName = https://autosysops.sharepoint.com/sites/dev-ELearningApp`

Implementation implication:

- Destination extraction should prioritize datasource metadata (`DatasetName`) over connector-only fallback.
- For URI-shaped dataset values, normalize to host/domain (and optionally preserve full URL as evidence context).
- For non-URI dataset values (for example `default.cds`), maintain explicit service fallback and evidence markers.

Execution-order update:

- Add a dedicated pre-stabilization phase for canvas destination extraction hardening (Phase E4 in PLAN.MD).
- Phase F stabilization must remain paused until E4 implementation and tests are completed.

### 12.6 External interaction goal verification against real solutions (2026-08-26)

Verdict:

- The current implementation only partially meets the intended goal.
- Some action-level HTTP/API endpoint extraction works already.
- The condensed external interaction graph still misses several required signals and currently collapses too aggressively.

Verified current strengths:

- Cloud HTTP/WebContents-style actions can already resolve direct URL endpoints and protocol/domain metadata when the action carries a resolvable `uri`/`request/url` or parameter-backed URL.
- In the 4PSDSPassignmentdocument flow, action-level extraction currently resolves:
  - `https://4psconstruct.api.bc.dynamics.com/`
  - protocol `https`
  - domain `4psconstruct.api.bc.dynamics.com`
  - main domain `dynamics.com`
  - GET/SET semantics for actions such as `GET_company`, `POST_documentProperties`, and `PATCH_DspDocumentPropertiesNL`.

Verified current gaps:

- Flow action external-profile extraction does not inspect connector-specific endpoint parameters like `dataset`, `source`, or similar site/base-url fields for SharePoint/Excel-style connectors.
  - Result: flows such as PDFWPlanDataFiberWorkz classify GET/SET on actions like `CreateFile`, `GetFileContentByPath`, and `GetItems`, but do not resolve the SharePoint site URL even when it is available through parameter defaults.
- Flow-level destination aggregation currently keeps only one representative destination.
  - Result: a multi-endpoint flow such as 4PSDSPassignmentdocument exposes the Business Central/API domain in condensed graph output but drops the SharePoint site destination even though both are present in flow defaults.
- Webhook trigger presence is detected at flow level (`TriggerMode`), but the condensed external interaction graph does not currently emit an inbound internet/webhook relationship.
  - Result: HamexCatalogus does not visibly show an internet-to-solution connection for the webhook-triggered flow.
- Desktop-browser target discovery is not propagated into the condensed external interaction graph.
  - Current graph output for PDFWPlanDataFiberWorkz shows `acc.fiberworkz.dev`, but not the broader set of desktop-discovered identity-provider URLs such as `fiberworkzacc.b2clogin.com`.
  - The desktop invocation action (`RunUIFlow_V2`) itself does not carry the resolved external URL metadata; deeper desktop action parsing must be consumed for graph enrichment.
- Condensed graph edges preserve only aggregate GET/SET labels and drop representative action evidence.
  - Result: action names like `POST_documentProperties` are not visible in the condensed solution-level output.
- Solution identity in condensed graphs is currently derived from the analyzed leaf folder.
  - Result: nodes are labeled `Managed` instead of the actual solution name when a managed solution root is passed directly.

Implementation guidance derived from these findings:

- For cloud flows, destination extraction needs connector-aware parameter scanning before service fallback.
- For desktop flows, external interaction outputs must consume already-available desktop action external profiles.
- For condensed graph output, preserve multiple destinations and representative action evidence per target.
- For webhook triggers, add explicit inbound external source modeling.

### 12.7 Public API consolidation guidance (2026-08-26)

Requested public-surface direction:

- Prefer a unified `Get-PowerPlatformCheckerApp` command over forcing callers to choose `Get-PowerPlatformCheckerCanvasApp` vs `Get-PowerPlatformCheckerModelDrivenApp` up front.
- Provide a comparable `Get-PowerPlatformCheckerFlow` command for documentation-oriented flow retrieval.
- Normalize public filter parameters toward `-Name` where practical.

Deprecation policy for renamed public parameters:

- Keep the old public parameter name as an alias during the transition period.
- Emit a warning when a deprecated parameter name is used.
- Prefer implementing the warning in the public function that owns the alias rather than in shared infrastructure.

Documentation-focused retrieval guidance:

- Unified getters should return summary metadata by default.
- Larger nested payloads such as actions, parameters, components, entity web resources, and connector tiers should be opt-in through a `-Properties` switch so documentation generation can request only what it needs.

Naming decision update:

- When a public command serves the same documentation-oriented contract across app families, avoid app-family terms in the public command name.
- Keep family-specific parsing functions internal when they remain implementation details.
- Apply the same principle to file names where practical so exported command names and filenames stay aligned.

### 12.8 Entity metadata depth assessment for dedicated entity-details function (2026-08-26)

Goal assessed:

- Determine whether existing module capabilities already provide enough signal to build a dedicated entity/table details command that includes column-level information.

Verified current capability:

- `Get-PowerPlatformCheckerEntity` already parses entity metadata from `Entities/*/Entity.xml` and returns:
  - table logical name,
  - `EntitySetName`,
  - icon references,
  - `Attributes` (column-like metadata with `Name`, `DisplayName`, `Description`, `Type`),
  - optional `Relations` when `-Relations` is used.
- `Get-PowerPlatformCheckerEntityFormXmlWebResource` already adds per-entity form script dependency metadata.

Conclusion:

- The module already has enough local unpacked-solution data to provide a dedicated entity-details command with columns and relationship context without requiring new external APIs.

Remaining gaps for a richer entity-details surface:

- Current attribute payload is intentionally lightweight; it does not yet include deeper column metadata such as:
  - required level,
  - max length/precision/scale,
  - option-set members,
  - key/index flags,
  - audit/searchability flags.
- These deeper fields may exist in entity XML depending on export shape, but they are not currently mapped in output contracts.

Recommended follow-up implementation posture:

- Keep app commands focused on app dependencies (connections/datasources/related references).
- Introduce a dedicated entity-details function as a separate phase, reusing current entity parsing and expanding attribute mapping incrementally with fixture-backed tests.

Mitigation:

- Version-aware parser layers with graceful fallback.

### 12.5 Documentation validation and recency check

Validated documentation (with metadata timestamps captured during research):

- Logic Apps Workflow Definition Language schema reference
  - updated_at: 2025-10-06
- OpenAPI extensions for custom connectors
  - updated_at: 2026-02-21
- Model-driven app event handlers and JS library linkage
  - updated_at: 2025-09-19
- Power Automate trigger optimization (polling vs webhook)
  - updated_at: 2025-08-27
- Trigger troubleshooting (polling/webhook behavior details)
  - updated_at: 2026-08-11
- Power Platform CLI canvas command group
  - updated_at: 2026-05-05
- Canvas app source code files (pa.yaml)
  - updated_at: 2025-10-23

Broken link note:

- The previously referenced unpack-canvas-app URL returns 404.
- Replaced by currently valid canvas CLI and pa.yaml source pages listed above.

### 12.6 Recommended implementation posture

- Reuse current architecture graph model and extend node/edge Properties instead of redesigning render pipeline.
- Add external-interaction enrichment as isolated internal helpers so existing diagram behavior remains stable by default.
- Keep all new behavior behind explicit include options and/or a dedicated command mode first, then consider default inclusion after snapshot stabilization.

### 12.7 Acceptance criteria for the research request

Research is complete when implementation can prove:

- Trigger mode surfaced (polling/webhook/manual) for flow triggers.
- Connector interactions classified with direction and confidence.
- Destination extraction emitted with provenance and confidence.
- Web resource outbound domains detected statically and represented in graph.
- Deterministic snapshots and telemetry privacy assertions satisfy existing standards.

## 13. PDFW Documentation Regression Validation (Pipeline Artifact Guard)

### 13.1 Why this guard exists

The file below is treated as a pipeline-generated integration regression artifact and must remain unchanged for this implementation scope:

- c:/Temp/Power%20Platform/Docs/PDFWPlanDataFiberWorkz.md

### 13.2 Generation path used by pipeline

The pipeline template that builds documentation is:

- c:/Temp/Power%20Platform/Templates/CreateDocumentation.yml

It composes content by calling:

- c:/Temp/Power%20Platform/Scripts/Documentation/Create-ArchitectureDiagram.ps1
- c:/Temp/Power%20Platform/Scripts/Documentation/Create-FlowData.ps1
- c:/Temp/Power%20Platform/Scripts/Documentation/Create-CanvasAppData.ps1
- c:/Temp/Power%20Platform/Scripts/Documentation/Create-ModelDrivenAppData.ps1

for solution path:

- c:/Temp/Power%20Platform/Solutions/Telecom/PDFWPlanDataFiberWorkz/Managed

### 13.3 Current validation status (executed in this session)

- Final post-implementation validation completed after E5-E7:
  - `build/vsts-validate.ps1` passed,
  - coverage remained above target at `95.04%`,
  - the PDFW documentation regression guard passed with `CHANGED=False` when re-executed through the repository documentation scripts.

- Verified implementation outcomes:
  - connector-backed flow actions can now resolve endpoint metadata from parameter fields such as `dataset`, `source`, and `baseUrl`,
  - condensed external interaction output now preserves distinct outbound targets instead of collapsing to one destination,
  - webhook/manual HTTP flows now render inbound internet edges,
  - condensed graph solution labels now use the logical solution name instead of generic managed/unmanaged leaf folders,
  - representative action evidence is available on condensed graph edges through `Metadata.Evidence`.

Validation was executed with the current local PowerPlatformChecker module by generating to temp files and comparing hashes:

- Baseline file hash:
  - 68917E9209F958F65A3C15D90CB3F8303FDB818CB9AE290EE22E871F9A02013E
- Temp regenerated hash (pipeline-style string composition):
  - 80EDD05EF2EF36825F9C658EAE6DB7139F35EE5F7B1B293380E03B3A2F30F91D
- Temp regenerated hash (single-quote style variant):
  - DECBDBD2A0E97F5CD45F5D14ED8801B1C22C0A667E53C02394ACF3A1172AAAEC

Observed result:

- Hash mismatch is currently present (CHANGED=True) for both regeneration variants.

Interpretation:

- Regeneration flow is executable with current module and scripts.
- Output parity is not currently achieved against the checked-in baseline artifact.
- Any future implementation stage must treat this as a blocking regression condition and preserve/restore parity before completion.

Latest validation update (task-based gate):

- After fixing c:/Temp/Power%20Platform/.vscode/tasks.json, the task verify-doc-regen-module-source runs successfully.
- Task output now reports:
  - BEFORE_HASH=80EDD05EF2EF36825F9C658EAE6DB7139F35EE5F7B1B293380E03B3A2F30F91D
  - TEMP_HASH=80EDD05EF2EF36825F9C658EAE6DB7139F35EE5F7B1B293380E03B3A2F30F91D
  - CHANGED=False

Current conclusion:

- The fixed task is now a usable validation tool for the phase gate.
- Use the task result as authoritative regression signal for PDFW documentation stability.

### 13.4 Recommended validation action (repeatable)

Use a non-destructive hash gate:

1. Hash baseline file c:/Temp/Power%20Platform/Docs/PDFWPlanDataFiberWorkz.md.
2. Regenerate documentation for PDFWPlanDataFiberWorkz to a temp path only.
3. Compare baseline hash vs temp hash.
4. Fail stage if different.
5. Keep temp artifact for diff analysis.

### 13.5 Suggested optional task automation

Optional improvement for repeatability:

- Add a dedicated VS Code task in c:/Temp/Power%20Platform/.vscode/tasks.json, for example verify-doc-regen-pdfw-module-source, that:
  - imports module from local source,
  - regenerates only PDFW documentation to temp,
  - outputs BASELINE_HASH, TEMP_HASH, CHANGED, and temp file path,
  - never overwrites Docs/PDFWPlanDataFiberWorkz.md.

## 14. Research Addendum - Expanded External Interaction Scope (2026-08-25)

### 14.1 Objective refinement from latest user request

The active objective is expanded from architecture enrichment to a complete, multi-solution external interaction inventory.

The implementation target must include:

- Action-level interaction hints for flows (GET/SET-style semantics where derivable).
- Destination extraction per action where possible (full URL, protocol, host/domain, and optional main domain).
- Connector list plus connector tier extraction for canvas apps and model-driven apps, aligned with existing flow connector-tier behavior.
- External domain extraction surfaced as a selectable IncludeElements value and represented in both Mermaid and Graph outputs.
- Cloud flow URL resolution from parameterized expressions and default/environment sources where possible; unresolved values must return unknown.
- Desktop flow URL tracing from web automation and related actions, including variable/default fallback when derivable.
- A new public multi-solution graph command that accepts multiple solution roots, recursive traversal, and include/exclude solution-folder filters.

### 14.2 Explicit workspace constraints (hard policy)

No code changes are allowed in the following folders during this scope:

- C:/PowerShellModules/PowerShell_PlugEvents
- C:/Temp/PowerAppUnzipped
- C:/Temp/PowerAppUnzipped2

Interpretation:

- These folders are read-only research/fixture-source inputs.
- Any extracted knowledge from these folders must be implemented as anonymized fixtures inside PowerShell_PowerPlatformChecker/tests/fixtures.

### 14.3 Evidence from local artifacts (verified)

Verified local signals supporting implementation:

- Cloud flow action payloads can expose method and URL fields under OpenApiConnection-based actions (for example request/method and request/url), including parameterized expressions.
- Canvas unpacked artifacts include connector identity and dataset URL-style destination hints in References/DataSources content.
- Canvas source structure docs and local artifacts confirm Src/*.pa.yaml is the source-control-stable review surface; non-Src JSON is not stable as canonical source.
- Desktop web automation actions can include URL-bearing inputs (Initial URL, URL to go to, Go to web page URL, tab URL attach patterns), supporting best-effort extraction.

### 14.4 External references validated during this cycle

Current Learn references used for grounding:

- Power Platform CLI canvas command group (pack/unpack/download/list behavior and folder structures).
- Canvas source code guidance for .pa.yaml and Src-folder stability constraints.
- Canvas-to-flow invocation guidance showing .Run(...) reference behavior.
- Power Automate desktop web automation action reference for URL-bearing action parameters.

404 observations captured during research:

- Previously attempted URLs for some canvas pages returned 404 and were replaced with currently valid documentation pages.

### 14.5 Design conclusions for implementation

- Direction model should be explicit but conservative:
  - Normalize to Read/Write/Mixed/Unknown for architecture and action projections.
  - Map optional GET/SET projections from action evidence when possible.
- URL model should be layered:
  - Keep FullUrl when resolvable.
  - Derive Protocol and Domain from FullUrl.
  - Derive MainDomain optionally from Domain.
  - When unresolved, emit Unknown while preserving source evidence metadata.
- Canvas and model-driven connector/tier output should follow the existing flow connector-tier contract style to keep downstream graph logic consistent.
- Include policy must gain ExternalDomains as a first-class token and must not alter existing defaults unexpectedly.

### 14.6 Testing and fixture policy addendum (mandatory)

TDD and fixture-first are required for every new capability in this expansion:

1. Add failing tests first.
2. Add anonymized fixtures first (or alongside tests) before production changes.
3. Implement minimal code to pass tests.
4. Update snapshots only for intentional behavior shifts.

Additional fixture requirements:

- Any fixture derived from real msapp/solution artifacts must be anonymized (domains, tenant names, ids, emails, organization labels, and user-identifiable values).
- Keep deterministic fixture naming and include a short provenance note in test comments where needed.
- Add coverage for unknown/unresolved fallback paths, not only success paths.

### 14.7 Public contract expectations from this addendum

The following contract additions are expected in upcoming implementation phases:

- Flow action listing options to include:
  - Interaction method semantics (GET/SET-oriented projection and/or Read/Write normalized field).
  - Destination profile fields (FullUrl, Protocol, Domain, MainDomain, ResolutionState/Evidence).
- Architecture diagram include policy:
  - ExternalDomains selectable via IncludeElements.
- New public command:
  - Multi-solution external interaction graph generation.
  - Recursive traversal and include/exclude folder filtering.

### 14.8 Process governance for next execution cycle

- Before each implementation session, read:
  - RESEARCH.MD
  - PLAN.MD
  - LOG.MD
- During execution, record each completed step and validation result in LOG.MD.
- Do not begin coding phases until the revised plan section in PLAN.MD is reviewed/approved.
