# Skill Lifecycle Management Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: pending implementation
- Target scope: Sprint 1 define governance contract and checks
- Execution window: Sprint 1
- Current task: Task 1.1 - define `skill-governance` workflow surface
- Next task: Task 1.2 - add governance validation coverage
- Last updated: 2026-05-24
- Branch/commit/PR: feat/skill-lifecycle-management-plan (plan bundle); implementation branch pending
- Source document: docs/plans/skill-lifecycle-management/skill-lifecycle-management-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: pending
- Source snapshot: pending
- Plan snapshot: pending
- Initial state snapshot: pending
- Predecessor issue: none

## Validation Plan

- `plan-tooling validate --file docs/plans/skill-lifecycle-management/skill-lifecycle-management-plan.md --format text --explain`
- `agent-runtime render --product codex`
- `agent-runtime render --product claude`
- `agent-runtime render --product codex --update-golden`
- `agent-runtime render --product claude --update-golden`
- `agent-runtime audit-drift`
- `agent-runtime doctor --class skill-surface --product codex`
- `agent-runtime doctor --class skill-surface --product claude`
- `bash scripts/ci/sandbox-install-rehearsal.sh`
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`
- `bash tests/projects/project-local-smoke/run.sh`
- `bash tests/hooks/run.sh`
- `bash scripts/ci/all.sh`

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | pending | Define `skill-governance` workflow surface | pending | Decide whether governance is an agent skill, CI validator, or both before adding metadata. |
| 1.2 | pending | Add governance validation coverage | pending | Source/manifest/plugin/reminder/acceptance consistency checks. |
| 2.1 | pending | Add `create-skill` workflow surface | pending | Runtime-kit native source, manifest, plugin, product, golden, sandbox, and smoke shape. |
| 2.2 | pending | Prove `create-skill` with a sample low-risk skill | pending | Fixture or real low-risk prose skill accepted by governance checks. |
| 3.1 | pending | Add `remove-skill` workflow surface | pending | Dry-run-first active-reference cleanup; keep `docs/plans/**` history by default. |
| 3.2 | pending | Prove `remove-skill` against a fixture | pending | Dry-run reports full delta; apply leaves no active references. |
| 4.1 | pending | Update stable docs for lifecycle policy | pending | Promote only durable maintainer-facing policy out of the tracker. |
| 4.2 | pending | Resolve nils-cli extraction boundary | pending | Link upstream extraction issue/PR if needed; otherwise record no-extraction decision. |

## Session Log

- 2026-05-24: Created initial plan bundle from the skill lifecycle management
  discussion source. Scoped the tracker to governance, create, remove, and
  extraction-boundary decisions; deferred `create-project-skill`.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `plan-tooling validate --file docs/plans/skill-lifecycle-management/skill-lifecycle-management-plan.md --format text --explain` | pending | Bundle structural validation. | n/a |
| `agent-runtime render --product codex` | pending | Codex render remains valid after lifecycle surface changes. | n/a |
| `agent-runtime render --product claude` | pending | Claude render remains valid after lifecycle surface changes. | n/a |
| `agent-runtime audit-drift` | pending | Rendered outputs and manifests stay aligned. | n/a |
| `agent-runtime doctor --class skill-surface --product codex` | pending | Codex skill-surface shape passes. | n/a |
| `agent-runtime doctor --class skill-surface --product claude` | pending | Claude skill-surface shape passes. | n/a |
| `bash scripts/ci/sandbox-install-rehearsal.sh` | pending | Sandbox expected skill pins remain correct. | n/a |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta` | pending | Meta skill surfaces behave in runtime smoke. | n/a |
| `bash tests/projects/project-local-smoke/run.sh` | pending | Project-local smoke remains compatible. | n/a |
| `bash tests/hooks/run.sh` | pending | Hook and reminder metadata checks pass. | n/a |
| `bash scripts/ci/all.sh` | pending | Full repo gate after implementation. | n/a |

## Notes

- The initial tracker uses the existing `meta` domain by default. A new plugin
  domain requires explicit approval because it changes both product surfaces.
- Historical references under `docs/plans/**` are retained by removal workflows
  unless the caller explicitly asks for cleanup.
- Stable mutation, YAML parsing, reference graphs, or JSON contracts belong in
  released `nils-cli`; repo-local scripts should remain Bash glue.
