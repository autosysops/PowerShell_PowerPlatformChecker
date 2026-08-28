# Copilot Instructions for PowerPlatformChecker

This repository builds and maintains the PowerShell module PowerPlatformChecker, which analyzes unpacked Microsoft Power Platform solutions from files (JSON/XML) without requiring live Dataverse or Power Automate connectivity.

## Module Mental Model

PowerPlatformChecker has three layers:

1. Public command layer (`PowerPlatformChecker/functions`)
- User-facing commands for flows, apps, entities, diagrams, and external interactions.
- Public commands may emit telemetry via `Send-THEvent`.

2. Internal implementation layer (`PowerPlatformChecker/internal/functions`)
- Parsing and graph-construction helpers.
- No telemetry in internal/private functions.

3. Test and fixture layer (`tests`)
- Pester tests under `tests/functions` and `tests/general`.
- Deterministic fixtures/snapshots under `tests/fixtures` and `tests/fixtures/expected`.

## Key Capabilities to Preserve

- Flow analysis:
  - `Get-PowerPlatformCheckerFlowActionList`
  - `Get-PowerPlatformCheckerFlowType`
  - `Get-PowerPlatformCheckerFlowParameter`
  - `Get-PowerPlatformCheckerFlowConnectorTier`
  - `Get-PowerPlatformCheckerFlow`
- App analysis:
  - `Get-PowerPlatformCheckerApp`
  - `Get-PowerPlatformCheckerAppConnectorTier`
  - `Get-PowerPlatformCheckerWebResource`
- Diagram generation:
  - `Get-PowerPlatformCheckerArchitectureDiagram` (`Mermaid` or `Graph`)
  - `Get-PowerPlatformCheckerFlowChart`
  - `Get-PowerPlatformCheckerExternalInteraction`
- Styling:
  - Session defaults via `Set-PowerPlatformCheckerStyle`
  - Per-call overrides via `-StyleOverrides` where supported

## External Interaction Contract (Critical)

`Get-PowerPlatformCheckerExternalInteraction` generates a condensed multi-solution view:

- One solution block per solution.
- Outbound edges to external targets (connections/domains).
- Inbound `internet` edges for webhook/manual HTTP flow triggers.
- Labels carry source resource context and operation class (Get/Set/Unknown).

Mermaid parser safety rules are mandatory:

- For classDiagram edges, there must be only one label delimiter colon (`:`) per edge line.
- Do not emit label payloads containing extra `:` separators after the edge label starts.
- Avoid malformed `classDef` lines with empty style values.

## Research/Plan/Log Working Rules (Must Follow)

Before significant implementation work, read:
- `RESEARCH.MD`
- `PLAN.MD`
- `LOG.MD`

Execution policy:

1. Tests first (red-green-refactor).
2. Keep one function per file.
3. Do not use local scriptblocks as pseudo-functions (for example `$helper = { param(...) ... }`) to sidestep the one-function-per-file rule. If logic deserves reuse or a name, extract a real top-level function in its own file.
3. Keep behavior deterministic and snapshot-friendly.
4. Keep coverage at or above 95%.
5. Do not leave skipped tests in critical suites.
6. Capture expected warnings in tests without noisy console output where possible.
7. Keep PLAN/RESEARCH/LOG aligned when steering changes.

## Testing Standards

- Prefer fixture-backed tests over ad-hoc generated payloads.
- Add/maintain deterministic snapshots for graph/mermaid outputs when behavior changes.
- Telemetry tests must validate:
  - exact key set
  - no sensitive keys
  - no confidential input values in payload
- Use `InModuleScope PowerPlatformChecker` for internal helpers.

## Snapshot Guidance

- Normalize before compare (line endings and trailing whitespace).
- Store expected snapshots in `tests/fixtures/expected`.
- For graph snapshots, use stable ordering of nodes/edges/styles.
- Ensure expected files are UTF-8 BOM where file-integrity tests require it.

## Documentation and Regression Gate

The broader docs gate in the companion workspace must remain stable:

- Task: `verify-doc-regen-module-source`
- Required outcome: `CHANGED=False`

When changing architecture/flow behavior, regenerate and validate docs deliberately.

## Style and Safety

- Keep code readable and minimal.
- Comment module code as open-source production code.
- Explain both what a block does and why it exists when a new reader would not infer that quickly from the code alone.
- Prefer short comments above a block over cryptic inline comments.
- Avoid comment-free dense logic in graph builders, parsers, and normalization helpers.
- Never leak solution contents into telemetry.
- Prefer explicit Unknown/low-confidence fallbacks over false certainty.

## Maintainability Expectations

- Optimize for readers who have never seen this module before.
- When code coordinates multiple normalization or aggregation steps, add enough comments that a first-time contributor can follow the data flow without reverse engineering it.
- If a helper mutates shared state, document the expected inputs and side effects clearly in comment-based help and local comments where needed.

## Practical Workflow for Future Changes

1. Read relevant README + RESEARCH/PLAN/LOG sections.
2. Add failing tests (including snapshot updates when contract changes).
3. Implement minimal code changes.
4. Run focused tests.
5. Regenerate intentional snapshots.
6. Run full validation (`build/vsts-validate.ps1`).
7. Validate docs regression gate (`verify-doc-regen-module-source`).

## Current Known Pitfalls

- Mermaid can fail if edge labels include multiple colons in a classDiagram edge line.
- Web resource URL extraction can mis-detect protocol-relative token strings (e.g., `//set`) as domains unless filtered.
- Desktop flow action extraction is best-effort; warning behavior should stay intentional and low-noise.
