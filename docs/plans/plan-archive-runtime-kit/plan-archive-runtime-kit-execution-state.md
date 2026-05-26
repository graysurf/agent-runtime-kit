# Plan Archive — agent-runtime-kit Skill Bodies Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: pending; tracker about to open
- Target scope: Sprints 1–4 of the plan-archive runtime-kit plan bundle
- Execution window: Sprints 1, 2, 3, 4
- Current task: 1.1
- Next task: 1.1 Add date-prefix naming rule to placement policy
- Last updated: 2026-05-27
- Branch/commit/PR: pending; tracker to be opened in agent-runtime-kit
- Source document: docs/plans/plan-archive-runtime-kit/plan-archive-runtime-kit-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: pending
- Source snapshot: pending
- Plan snapshot: pending
- Initial state snapshot: pending

## Validation Plan

- `plan-tooling validate --file docs/plans/plan-archive-runtime-kit/plan-archive-runtime-kit-plan.md --format text --explain`
- `rumdl check docs/source/docs-placement-retention-policy-v1.md`
- `agent-docs resolve --context project-dev --strict --format checklist`
- `bash scripts/ci/skill-governance-audit.sh`
- `bash scripts/ci/validate-surfaces-manifest.sh`
- `bash scripts/ci/all.sh`
- `bash scripts/ci/sandbox-install-rehearsal.sh`

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | pending | Add date-prefix naming rule to placement policy | — | — |
| 1.2 | pending | Update repo policy hooks if needed | — | — |
| 2.1 | pending | Author the migration skill body | — | — |
| 2.2 | pending | Manifest and plugin registration for migration skill | — | — |
| 2.3 | pending | Render goldens and fixtures for migration skill | — | — |
| 3.1 | pending | Author the query skill body | — | — |
| 3.2 | pending | Manifest and plugin registration for query skill | — | — |
| 3.3 | pending | Render goldens and fixtures for query skill | — | — |
| 4.1 | pending | Skill-governance audit coverage | — | — |
| 4.2 | pending | Sandbox install rehearsal and overlay smoke | — | — |

## Session Log

- 2026-05-27: Created plan bundle (sibling discussion source, plan, initial execution state) from the master design at `docs/plans/plan-archive-system/plan-archive-system-discussion-source.md`. Tracker issue not yet opened.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `plan-tooling validate --file docs/plans/plan-archive-runtime-kit/plan-archive-runtime-kit-plan.md --format text --explain` | pending | Will run as part of the tracker open preflight. | n/a |

## Notes

- This bundle depends on the `plan-archive` binary release that lands under the sibling plan `plan-archive-nils-cli`. Bundle execution should not start the skill-body sprints until that release is available and the runtime-kit nils-cli pin is bumped to a matching tag.
- The archive repository itself is a one-shot prerequisite (Plan 2 in the master discussion source) and must exist before runtime-smoke fixtures exercise a real archive target.
