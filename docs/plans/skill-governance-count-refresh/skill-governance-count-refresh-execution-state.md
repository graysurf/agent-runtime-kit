# Skill Governance Count Refresh Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: planned
- Target scope: active skill-count refresh integration in skill governance and lifecycle workflows
- Execution window: Sprint 1-3
- Current task: Task 1.1
- Next task: implement count-refresh fixture coverage after governance count modes exist
- Last updated: 2026-05-25
- Branch/commit/PR: pending
- Source document: docs/plans/skill-governance-count-refresh/skill-governance-count-refresh-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: pending
- Source snapshot: pending
- Plan snapshot: pending
- Initial state snapshot: pending

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | pending | Add count modes to skill governance audit | n/a | Add read-only check and whitelist-only update modes. |
| 1.2 | pending | Add count-refresh fixture coverage | n/a | Prove stale detection, update behavior, and historical-doc exclusion. |
| 2.1 | pending | Update create and remove skill workflows | n/a | Lifecycle update mode runs after apply-mode skill surface mutations. |
| 2.2 | pending | Update sync runtime skill workflow | n/a | Runtime sync remains read-only for repo count files. |
| 3.1 | pending | Run full source and runtime validation | n/a | Focused checks plus full CI. |
| 3.2 | pending | Prepare issue-backed closeout evidence | n/a | Update issue lifecycle comments after implementation. |

## Validation Plan

- `bash scripts/ci/skill-governance-audit.sh --check-counts`
- `bash scripts/ci/skill-governance-audit.sh --update-counts`
- `bash scripts/ci/skill-governance-audit.sh --fixture count-refresh`
- `bash scripts/ci/skill-governance-audit.sh`
- `agent-runtime render --product codex --update-golden`
- `agent-runtime render --product claude --update-golden`
- `bash scripts/ci/sandbox-install-rehearsal.sh`
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`
- `bash scripts/ci/all.sh`

## Session Log

- 2026-05-25: Created source, plan, and initial execution-state bundle from
  user-approved design direction: integrate count refresh into
  `skill-governance-audit`, update create/remove workflows, and keep
  `sync-runtime-skills` check-only for repository files.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `plan-tooling validate --file docs/plans/skill-governance-count-refresh/skill-governance-count-refresh-plan.md --format text --explain` | passed | Plan bundle structural validation passed. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260525-015315-skill-governance-count-refresh/plan-tooling-validate.txt` |
| `plan-issue record open --dry-run --format json --repo graysurf/agent-runtime-kit --bundle docs/plans/skill-governance-count-refresh` | pending | Preview before live issue creation. | n/a |
| `plan-issue record open --format json --repo graysurf/agent-runtime-kit --bundle docs/plans/skill-governance-count-refresh` | pending | Open tracking issue after bundle commit is pushed. | n/a |
| `plan-issue record audit --profile tracking --body-file "$ISSUE_BODY" --comments-json "$ISSUE_JSON" --format json` | pending | Read-back audit after live issue creation. | n/a |

## Residual Risk

- The exact implementation may choose `--check-counts` as an explicit alias
  while keeping default governance audit as the CI-facing check. Preserve both
  if it improves agent ergonomics without duplicating behavior.
