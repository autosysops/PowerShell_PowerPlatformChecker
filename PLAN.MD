# Plan - External Interaction Diagram

Date: 2026-08-25
Module: PowerShell_PowerPlatformChecker

## 1. Objective

Deliver a diagram capability for selected solutions that shows interactions with external systems, including:

- connector usage,
- interaction direction (read/write/unknown confidence-based),
- destination hints (site/domain/system where derivable),
- trigger mode visibility (polling, webhook, manual),
- web resource outbound domains.

## 2. Scope and Constraints

### In scope

- Cloud flow trigger/action enrichment from unpacked workflow JSON.
- Destination and direction enrichment in architecture graph properties.
- Mermaid and Graph output support for enriched metadata.
- Web resource static outbound domain detection from JavaScript files.
- Test coverage additions (unit + snapshot + telemetry privacy).

### Out of scope (phase 1)

- Runtime validation against live tenant instances during normal module execution.
- Deep dynamic JavaScript execution to resolve runtime-computed URLs.
- Full connector-specific HTTP verb certainty for all connectors.

### Non-negotiables

- Keep telemetry option-only and privacy-safe.
- Follow strict TDD: write failing tests first, then implement, then refactor.
- Keep one function per file; no nested functions.
- Keep documentation regression guard for PDFWPlanDataFiberWorkz.md green in every phase.
- Preserve deterministic snapshots.
- Maintain >=95 percent coverage.

### Implementation policy

- Every change starts with tests that describe expected behavior before production code is changed.
- For public functions, prefer fixture-driven contract tests and snapshots where possible.
- Do not merge an implementation step unless the new tests fail first and then pass after implementation.

## 3. High-Level Design

### Reuse-first principle

Reuse existing architecture graph pipeline and add enrichment layers rather than replacing rendering.

### Proposed additions

- Internal classification helpers for:
  - trigger mode,
  - direction semantics,
  - destination extraction,
  - domain extraction from JS.
- Optional enrichment fields on graph nodes/edges, for example:
  - InteractionDirection
  - DirectionConfidence
  - TriggerMode
  - Destination
  - DestinationType
  - DestinationConfidence
  - SourceEvidence

## 4. Phased Execution Plan

Cross-phase rule:

1. Define behavior with tests first (red).
2. Implement minimal code to satisfy tests (green).
3. Refactor without changing behavior while keeping tests green.
4. Preserve one-function-per-file and avoid nested functions in all new or modified files.
5. Regenerate PDFW documentation to a temp output and verify hash equality with Docs/PDFWPlanDataFiberWorkz.md before closing the phase.

Documentation regression gate (required for every phase):

1. Run task verify-doc-regen-module-source from c:/Temp/Power%20Platform/.vscode/tasks.json.
2. Require task output CHANGED=False.
3. Fail the phase immediately if CHANGED=True or task execution fails.
4. Keep the task-generated temp artifact path for diff analysis when failures occur.

## Phase 0 - Baseline and safety net

1. Run focused baseline tests for architecture diagram, flow parsing, web resources.
2. Add or adjust failing baseline guard tests where current coverage is missing.
3. Save baseline snapshots and verify green before changes.
4. Add targeted fixture cases only where current fixtures are insufficient.
5. Run the PDFW documentation regression gate and store the baseline hash for later phases.

Exit criteria:

- Baseline tests green.
- No unexplained snapshot drift.
- PDFW documentation hash unchanged.

## Phase 1 - Trigger mode enrichment

1. Create failing tests for trigger mode classification and output mapping.
2. Add internal helper to classify trigger type:
  - Recurrence -> Polling
  - OpenApiConnectionWebhook -> Webhook
  - Request + kind Http -> ManualHttp
  - fallback -> Unknown
3. Surface classification in graph output for flow triggers.
4. Update fixture-backed snapshots after tests pass.
5. Run PDFW documentation regression gate.

Exit criteria:

- Trigger mode visible in Graph output.
- Mermaid rendering stable and tested.
- PDFW documentation hash unchanged.

## Phase 2 - Direction classification

1. Create failing tests for direction classification using fixtures and representative operation samples.
2. Add operation-direction classifier using operation metadata where available.
3. Add fallback heuristic from operation names/ids.
4. Return normalized direction enum:
  - Read, Write, Mixed, Unknown.
5. Add confidence and evidence fields.
6. Run PDFW documentation regression gate.

Exit criteria:

- Direction appears for representative actions.
- Unknown used safely when evidence is weak.
- PDFW documentation hash unchanged.

## Phase 3 - Destination extraction

1. Create failing fixture-driven tests for destination extraction and provenance.
2. Add extraction layer from flow action parameters and environment variables.
3. Add connector catalog enrichment from connector metadata fields.
4. Add connector-specific extractors for high-value connectors:
  - Dataverse
  - Dynamics 365 Business Central
  - SharePoint
  - Office 365
5. Emit normalized destination values and provenance.
6. Run PDFW documentation regression gate.

Exit criteria:

- Destination shown for at least known connector patterns in fixtures.
- No false certainty claims when data is partial.
- PDFW documentation hash unchanged.

## Phase 4 - Web resource outbound domains

1. Create failing tests for static domain detection from web resource fixtures.
2. Extend JS parser with static URL/domain extraction patterns.
3. Normalize domains and remove duplicates.
4. Add graph edges from web resource nodes to external domain nodes.
5. Ensure tests cover:
  - absolute URLs,
  - protocol-relative URLs,
  - common network call patterns,
  - false-positive avoidance.
6. Run PDFW documentation regression gate.

Exit criteria:

- Domain extraction works for static literals.
- Snapshot tests include representative web resource internet links.
- PDFW documentation hash unchanged.

## Phase 5 - Canvas app enrichment (best effort)

1. Create failing fixture-driven tests for canvas destination enrichment.
2. Extend canvas app parser for available source formats:
  - current metadata extraction,
  - unpacked source structure where present.
3. Connect canvas references to connector metadata and destinations.
4. Add graceful fallback when detailed fields are absent.
5. Run PDFW documentation regression gate.

Exit criteria:

- Canvas connectors represented without regressions.
- Best-effort destination info appears when data exists.
- PDFW documentation hash unchanged.

## Phase 6 - Stabilization and release readiness

1. Run full test suite.
2. Run build validation scripts.
3. Verify coverage threshold.
4. Verify telemetry safety assertions for any new public function options.
5. Regenerate snapshots only for intentional changes.
6. Run PDFW documentation regression gate as final release block.

Exit criteria:

- Full suite green.
- Coverage >=95 percent.
- No telemetry privacy regressions.
- PDFW documentation hash unchanged.

## 5. Testing Strategy

### Unit tests

- Add one test file per new function.
- Write tests before implementation changes (TDD red-green-refactor cycle).
- Use data-driven test cases for classifier matrices.
- Cover edge cases and unknown behavior paths.
- For final public functions, prioritize fixture-based behavior tests as primary contract coverage.

### Snapshot tests

- Add deterministic Graph and Mermaid snapshots for enriched external interactions.
- Normalize output before comparison consistent with existing conventions.
- Keep PDFWPlanDataFiberWorkz.md as a fixed end-to-end regression artifact validated by hash.

### Telemetry tests

- For any new/changed public function telemetry:
  - strict expected key set,
  - confidential value exclusion,
  - deny-list key checks.

## 6. Risks and Mitigations

1. Risk: over-asserting direction where connector abstractions hide HTTP methods.
Mitigation: confidence levels + Unknown fallback + evidence fields.

2. Risk: destination false positives from generic string scanning.
Mitigation: connector-aware extraction first, regex extraction second, confidence/provenance required.

3. Risk: Mermaid snapshot churn from formatting changes.
Mitigation: isolate rendering changes and update snapshots only after semantic verification.

4. Risk: telemetry leakage through enriched metadata.
Mitigation: keep telemetry limited to options/shape, never payload-derived data.

## 7. Deliverables

1. Updated internal parsers/enrichers for trigger mode, direction, destination, and web resource domains.
2. Updated architecture graph output (Graph and Mermaid) with external-interaction details.
3. Expanded tests, fixtures, and snapshots.
4. Updated documentation in RESEARCH.MD and this Plan.MD.

## 8. Operational Checklist

1. Start each increment by adding failing tests.
2. Implement smallest safe code change to satisfy tests.
3. Keep one function per file and no nested functions.
4. Run focused tests immediately after each increment.
5. Resolve failures before proceeding.
6. Run full suite before completion.
7. Record any new lessons in RESEARCH.MD.
8. Run the PDFW documentation regression gate and block completion on any hash change.

## 9. Plan Revision - Expanded Scope (Review Required Before Coding)

Date: 2026-08-25
Status: Pending user review/approval before implementation

### 9.1 Historical phase preservation status

The original plan content above is preserved and considered historical context.

Completion marker for previously executed scope:

- Phase 0 (Baseline and safety net): Done
- Phase 1 (Trigger mode enrichment): Done
- Phase 2 (Direction classification): Done
- Phase 3 (Destination extraction): Done
- Phase 4 (Web resource outbound domains): Done
- Phase 5 (Canvas app enrichment, best effort): Done
- Phase 6 (Stabilization and release readiness): Done

Note:

- New requirements below are additional scope and must be handled as a new execution cycle.

### 9.2 Scope expansion summary

This revision adds implementation work for:

- ActionList enrichment with action interaction method and external destination profile.
- Canvas and model-driven connector+tier reporting aligned with flow tier reporting behavior.
- Cloud and desktop flow URL/domain/protocol/main-domain extraction with unknown fallback.
- IncludeElements support for ExternalDomains and full representation in Mermaid and Graph.
- New public multi-solution external interaction graph command with recursion and folder filters.

### 9.3 Hard execution constraints

No modifications are allowed in:

- C:/PowerShellModules/PowerShell_PlugEvents
- C:/Temp/PowerAppUnzipped
- C:/Temp/PowerAppUnzipped2

These paths are read-only reference inputs only.

### 9.4 Recurring process instructions (must be repeated each session)

1. Read RESEARCH.MD, PLAN.MD, and LOG.MD before making changes.
2. Track all progress, failures, and validations in LOG.MD.
3. Keep fixture-first TDD (red -> green -> refactor) for every requirement.
4. Keep PDFW documentation regression gate green after each phase.
5. Keep progress reporting synchronized: LOG.MD records execution state, and any steering-critical updates must be reflected in PLAN.MD and RESEARCH.MD.

### 9.5 New phased plan (pending approval)

Cross-phase gate (applies to all phases below):

1. Add failing tests first.
2. Add/adjust anonymized fixtures first when needed; prefer reusable fixture files over inline TestDrive-generated flow payloads.
3. Implement minimal production code.
4. Run focused tests, then run regression gate verify-doc-regen-module-source.
5. Log outcomes in LOG.MD.

Fixture-first clarification:

1. For behavior intended to survive as product contract (cloud/desktop flow content, connector metadata, architecture output), add fixture files under tests/fixtures and consume them from tests.
2. Use TestDrive-generated payloads only for narrow parser/tokenizer edge-case fuzzing where fixture reuse would reduce readability or require excessive fixture sprawl.
3. Where feasible, ensure new fixture scenarios are also represented in snapshot-protected outputs.

Documentation gate policy update for this revision:

1. Before ExternalDomains are enabled as a default architecture output element, `verify-doc-regen-module-source` must stay `CHANGED=False`.
2. In the phase where ExternalDomains become a default generated element, documentation drift is expected and must be accepted as intentional (`CHANGED=True`) exactly once.
3. After the baseline documentation is intentionally updated, all subsequent gates must return `CHANGED=False` again.

#### Phase A - ActionList contract enrichment

Objective:

- Extend flow action list outputs with optional interaction method and destination profile data.

Tasks:

1. Add failing tests for new ActionList properties and include-parameter behavior.
2. Add/extend internal helper(s) to derive:
  - InteractionDirection (Read/Write/Mixed/Unknown)
  - Optional GetSetProjection (Get/Set/Unknown where appropriate)
  - URL resolution state and provenance
3. Emit optional destination fields:
  - FullUrl
  - Protocol
  - Domain
  - MainDomain (optional behavior)
  - ResolutionState/Evidence
4. Ensure unresolved cases emit Unknown without throwing.

Exit criteria:

- ActionList tests cover both cloud and desktop patterns plus unresolved fallbacks.
- Telemetry remains option-only and privacy-safe.

#### Phase B - Canvas and model-driven connector tier parity

Objective:

- Provide connector and tier inventory for canvas and model-driven apps, comparable to flow output style.

Tasks:

1. Add failing tests for canvas connector+tier extraction using anonymized fixtures.
2. Add failing tests for model-driven connector+tier extraction where supported by available metadata.
3. Build enrichment layer that maps connector references/api ids to connector catalog tier data.
4. Keep best-effort behavior explicit and deterministic when metadata is incomplete.

Exit criteria:

- Tests validate stable connector/tier lists for both app types.
- No regressions in existing flow connector tier behavior.

#### Phase C - External domain/profile extraction across artifacts

Objective:

- Unify external URL/domain/protocol extraction logic for flows and apps.

Tasks:

1. Add failing tests for:
  - Cloud flow parameter/default/env-var URL resolution
  - Desktop web automation URL tracing
  - App-derived dataset/domain extraction
2. Implement reusable normalization helpers for protocol/domain/main-domain extraction.
3. Add unknown fallback and evidence markers for unresolved values.

Exit criteria:

- Contract fields are consistent across supported artifact types.
- Unknown paths are tested and deterministic.

#### Phase D - IncludeElements ExternalDomains support and rendering parity

Objective:

- Make ExternalDomains selectable via IncludeElements and correctly represented in both Mermaid and Graph outputs.

Tasks:

1. Add failing tests for include policy selection behavior.
2. Update include policy normalization and public ValidateSet/argument help.
3. Ensure node/edge/style behavior is stable in Mermaid and Graph snapshots.

Exit criteria:

- ExternalDomains can be toggled via IncludeElements.
- Snapshot suite verifies render parity and no unrelated drift.
- If ExternalDomains is promoted to default generation output in this phase, documentation regeneration drift is recorded as expected and baseline docs are updated.

#### Phase E - New public multi-solution external interaction graph command

Objective:

- Deliver a command that accepts multiple solution roots and builds a combined external interaction graph.
- Represent each source solution as one condensed internal block, with outward edges to external data sources labeled by interaction semantics (Get/Set/Unknown as confidence allows).

Tasks:

1. Define command contract tests first:
  - multiple input roots
  - recursive traversal
  - include solution folder filter
  - exclude solution folder filter
2. Implement command with non-breaking integration to existing architecture helpers.
3. Add graph and Mermaid snapshot coverage for combined output.
4. Add telemetry tests for option usage only.
5. Add fixture-backed tests for condensed-block behavior:
  - one solution node per included solution
  - no internal component fan-out in condensed mode
  - outgoing edges from solution block to external destinations carry interaction labels

Exit criteria:

- Command works with array-like multi-path input and folder filters.
- Combined graph output is deterministic and snapshot-protected.
- Condensed mode output is deterministic and clearly communicates external interaction direction.

#### Phase E2 - App/flow parity and invalid-input resilience hardening

Objective:

- Complete parity normalization and invalid-fixture resilience work before final stabilization.

Tasks:

1. Normalize app-type detection public ergonomics to align with flow-type path-first usage where feasible.
2. Ensure Get-PowerPlatformCheckerAppConnectorTier no longer requires app-type selector input.
3. Add fixture-backed invalid app/flow coverage across detection and list-style analyzers.
4. Ensure graceful behavior for invalid payloads:
  - classification commands return Unknown,
  - list-style commands return empty collections,
  - warnings clearly indicate invalid app/flow input.
5. Update README/module exports/tests for parity and resilience contracts.
6. Record implementation and verification details in LOG.MD and mirror steering-critical policy updates in RESEARCH.MD.
7. Run a fixture-compliance audit for tests still using inline snippets/TestDrive payload construction.
8. Migrate remaining contract-style snippet tests to committed fixtures (including web resource external-domain cases), and document any approved parser-fuzz exceptions.

Exit criteria:

- Parity and resilience work is fully completed and tested before final stabilization.
- No skipped placeholder tests remain in coverage-critical suites.
- Fixture-first compliance is explicitly verified, with any non-migrated snippet tests justified as parser-fuzz exceptions.

#### Phase E3 - Fixture structure normalization and test-hygiene enforcement

Objective:

- Normalize fixture layout to mirror real unpacked solution structures and enforce pipeline-friendly test output hygiene.

Tasks:

1. Reorganize fixture sets to follow solution-like folder structures where practical (for example Managed/Workflows, Managed/WebResources, Managed/AppModules).
2. Consolidate related fixture scenarios when shared structure improves solution-wide test realism.
3. Remove or refactor scattered ad-hoc snippet fixtures that should be represented as committed files.
4. Enforce strict no-skipped-tests policy in functional suites (tests must pass or fail; no deferred skip placeholders).
5. For expected warning scenarios, capture warning streams in tests without polluting console output (WarningVariable with WarningAction SilentlyContinue, or equivalent stream redirection).
6. Document approved parser-fuzz exceptions explicitly in RESEARCH.MD and LOG.MD.

Exit criteria:

- Fixture layout is aligned with solution structure conventions.
- No skipped tests remain.
- Expected warnings are asserted without pipeline-noise output.

#### Phase E4 - Canvas destination extraction hardening from app datasource metadata

Objective:

- Improve canvas destination extraction so connector-backed canvas data sources resolve concrete destination hosts/sites when available (for example SharePoint site URLs), instead of service-only labels.

Tasks:

1. Add fixture-backed failing tests for canvas destination extraction using realistic unzipped-app datasource metadata shapes.
2. Extend canvas destination extraction to inspect `CanvasApp.DataSources.DataSources` records (including `Type`, `ApiId`, `DatasetName`, `TableName`) before connector-only fallback.
3. For URI-style `DatasetName` values, extract normalized destination host/domain (and preserve full dataset URL where useful as evidence payload in graph properties).
4. For known service connectors with non-URI dataset values (for example `default.cds`), keep deterministic service fallback and mark confidence/evidence accordingly.
5. Update architecture canvas node destination metadata contract/tests so SharePoint-like datasource records resolve to site/domain-level destination when present.
6. Update external interaction graph tests/snapshots if canvas destination precision changes outbound target nodes/labels.
7. Run documentation regression gate after changes.

Exit criteria:

- Canvas destination metadata resolves concrete site/domain from datasource metadata when available.
- Service-only fallback is still deterministic for non-URI datasource types.
- Snapshot and contract tests cover at least one SharePoint datasource case with concrete destination extraction.

#### Phase E4a - Public app/flow API consolidation and naming normalization

Objective:

- Introduce documentation-oriented unified retrieval commands for apps and flows, and normalize public parameter naming so the module surface is easier to learn and use.

Tasks:

1. Add failing tests for unified `Get-PowerPlatformCheckerApp` and `Get-PowerPlatformCheckerFlow` commands.
2. Implement `Get-PowerPlatformCheckerApp` so it returns both canvas and model-driven app metadata through one command and type-detects results without requiring the caller to choose a specialized function.
3. Implement `Get-PowerPlatformCheckerFlow` as a documentation-oriented flow metadata command that can return summary information plus optional properties such as parameters, actions, and connector tiers.
4. Normalize public app filter parameter naming to `-Name` where practical.
5. Keep old public parameter names as aliases for now and emit a deprecation warning when the legacy parameter name is used.
6. Update exports, tests, and README usage examples for the unified retrieval surface.
7. Record naming conventions and deprecation guidance in RESEARCH.MD and execution details in LOG.MD.

Exit criteria:

- A caller can retrieve app metadata through one public app command and flow metadata through one public flow command.
- Public app retrieval uses a consistent `-Name` filter while preserving legacy aliases with warnings.
- Unified getters are validated with focused tests before later external-interaction enrichment phases resume.

#### Phase E4b - Property model refinement and app-entity semantic restructuring

Objective:

- Add trigger-specific flow metadata, make app/flow getters default to full-property output with `-Properties` as a narrowing filter, and make solution-object sections selectable.
- Restructure app dependency semantics so entities/flows are represented as related dependencies rather than implied top-level ownership.
- Validate whether current entity extraction already supports a dedicated richer entity-details surface (including columns) and record remaining gaps.

Tasks:

1. Add failing tests for `Get-PowerPlatformCheckerFlow` trigger-property output and default-all property behavior.
2. Implement `Trigger` as a selectable property in `Get-PowerPlatformCheckerFlow`.
3. Change `Get-PowerPlatformCheckerFlow` and `Get-PowerPlatformCheckerApp` so when `-Properties` is omitted they include the full default property set; when `-Properties` is provided it narrows output.
4. Add app dependency-level output structure so related entities/flows/web resources are grouped under a dedicated dependency property while preserving backward-compatible optional legacy fields.
5. Extend `Get-PowerPlatformCheckerSolutionObject` with selectable `-Properties` sections and keep default behavior equivalent to selecting all sections.
6. Research current entity metadata retrieval depth (tables, columns/attributes, relations, script usage) and capture whether new external sources are required for a richer entity-details command.
7. Update RESEARCH.MD and LOG.MD with findings, implementation details, and validation results.

Exit criteria:

- Flow output can include a dedicated `Trigger` property.
- App/flow getters default to full properties and support property-filter narrowing.
- Solution-object section output is selectable with no default-regression.
- Entity capability research is documented with clear gaps and proposed follow-up path.

#### Phase E5 - Flow connector-parameter destination extraction and action-level endpoint fidelity

Objective:

- Extract concrete external endpoints from flow actions and flow parameter values instead of collapsing most connector-backed actions to service-only names.

Tasks:

1. Add failing fixture-backed tests for connector-specific destination extraction from flow actions and parameter-backed values.
2. Extend flow action external-profile resolution beyond `uri` and `request/url` to inspect connector parameter keys such as `dataset`, `source`, `siteAddress`, `baseUrl`, and similar endpoint-bearing fields.
3. Expand expression resolution to support direct parameter references and inline interpolation forms used in flow definitions.
4. Preserve action-level protocol, full URL, domain, and main-domain when resolvable.
5. Add tests using representative solution fixtures for:
  - SharePoint and Excel Online actions that reference site URLs through parameters,
  - WebContents/HTTP-style actions that reference Business Central/API base URLs,
  - multi-endpoint flows where more than one external destination exists.
6. Update flow destination aggregation so it can keep multiple external targets instead of selecting only the first sorted domain.
7. Run documentation regression gate after changes.

Exit criteria:

- Flow action profiles resolve concrete endpoints for connector-backed actions where the endpoint is available in parameters or definition defaults.
- Multi-endpoint flows preserve more than one external destination.
- Protocol/domain extraction is visible for representative SharePoint and Business Central/API scenarios.

#### Phase E6 - Inbound trigger modeling and desktop external target harvesting

Objective:

- Represent inbound internet-triggered flows and propagate desktop-flow discovered web targets into external interaction outputs.

Tasks:

1. Add failing tests for inbound webhook/internet trigger rendering in the external interaction graph.
2. Add graph modeling for inbound internet/webhook sources when trigger mode indicates webhook-style ingress.
3. Extend architecture/external interaction assembly to consume desktop action external profiles, not only flow-level default parameters.
4. Add representative tests for desktop binary-derived targets such as FiberWorkz and identity-provider URLs discovered from desktop flow content.
5. Preserve protocol metadata for desktop-discovered URLs where available.
6. Run documentation regression gate after changes.

Exit criteria:

- Webhook-triggered flows can render an inbound external/internet relationship.
- Desktop-discovered external URLs appear in the external interaction outputs when present in desktop flow artifacts.
- Protocol/domain extraction is visible for representative desktop-browser targets.

#### Phase E7 - External interaction graph fidelity, action evidence, and solution identity fixes

Objective:

- Make the external interaction graph reflect real solution identity and preserve useful action-level evidence in condensed output.

Tasks:

1. Add failing tests for multi-solution condensed output where solution nodes use real solution names rather than generic `Managed` or `Unmanaged` leaf names.
2. Fix solution-node naming to derive the logical solution folder name when the analyzed root is a managed/unmanaged subfolder.
3. Preserve multiple outbound targets per solution and avoid collapsing distinct sites/domains into a single representative destination.
4. Enrich condensed edges with action evidence metadata so GET/SET labels can also expose representative action names in graph output (for example `POST_documentProperties`).
5. Update snapshots for representative real-world scenarios:
  - 4PSDSPassignmentdocument with SharePoint plus Business Central/API destinations,
  - HamexCatalogus with inbound webhook plus Business Central read/write activity,
  - PDFWPlanDataFiberWorkz with FiberWorkz, identity-provider, and SharePoint targets.
6. Run documentation regression gate after changes.

Exit criteria:

- Solution nodes identify the actual solution, not only the leaf managed folder.
- Condensed graph output preserves distinct external targets per solution.
- Edge labels/metadata retain representative action evidence alongside GET/SET semantics.

#### Phase F - Final stabilization for expanded scope

Objective:

- Validate full regression, coverage, and documentation gates before release.

Tasks:

1. Run full Pester suite.
2. Run build/vsts-validate.ps1.
3. Confirm coverage >=95 percent.
4. Confirm verify-doc-regen-module-source reports CHANGED=False against the new post-ExternalDomains baseline.
5. Update module README with all new capabilities and usage examples.
6. Update module manifest exports so all new public functions are exported.
7. Update LOG.MD final execution summary.
8. Complete invalid-input resilience verification using invalid app/flow fixtures across detection and list-style commands; ensure graceful warnings and deterministic fallback outputs.

Exit criteria:

- All tests and gates pass.
- Expanded scope is fully documented in LOG.MD and RESEARCH.MD.
- Invalid fixture behavior is covered by tests and does not regress coverage or analyzer gates.

### 9.6 Stop condition

As requested, execution stops at planning after this revision until user review/approval is provided.

### 9.7 Execution status update (2026-08-26)

- Phases `E5`, `E6`, `E7`, and `F` have now been executed and validated.
- Current status:
  - external interaction enrichment complete,
  - full validation green,
  - documentation hash gate green (`CHANGED=False`).
