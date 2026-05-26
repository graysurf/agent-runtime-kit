# Plan Archive — agent-runtime-kit Skill Bodies Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: Sprint 1 in progress
- Target scope: Sprints 1–4 of the plan-archive runtime-kit plan bundle
- Execution window: Sprints 1, 2, 3, 4
- Current task: 2.1
- Next task: 2.1 Author the migration skill body (blocked on Plan 1 release)
- Last updated: 2026-05-27
- Branch/commit/PR: feat/plan-archive-placement-policy; PR pending
- Source document: docs/plans/plan-archive-runtime-kit/plan-archive-runtime-kit-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: <https://github.com/graysurf/agent-runtime-kit/issues/126>
- Source snapshot: <https://github.com/graysurf/agent-runtime-kit/issues/126#issuecomment-4546160858>
- Plan snapshot: <https://github.com/graysurf/agent-runtime-kit/issues/126#issuecomment-4546161197>
- Initial state snapshot: <https://github.com/graysurf/agent-runtime-kit/issues/126#issuecomment-4546161484>

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
| 1.1 | completed | Add date-prefix naming rule to placement policy | feat/plan-archive-placement-policy | docs/source/docs-placement-retention-policy-v1.md updated; rumdl + project-dev preflight pass |
| 1.2 | completed | Update repo policy hooks if needed | feat/plan-archive-placement-policy | No-op: AGENT_HOME.md / AGENTS.md carry no `docs/plans/` path references that needed updating |
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
- 2026-05-27: Sprint 1 implementation. Task 1.1 lands the `<YYYY-MM-DD>-<slug>/` naming rule in `docs/source/docs-placement-retention-policy-v1.md` (placement table row + dedicated Naming bullets covering both shapes and the pre-v1 exemption). Task 1.2 is a documented no-op: neither `AGENT_HOME.md` nor `AGENTS.md` references `docs/plans/` in a way that needs updating. Branch `feat/plan-archive-placement-policy`; PR pending.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `plan-tooling validate --file docs/plans/plan-archive-runtime-kit/plan-archive-runtime-kit-plan.md --format text --explain` | pass | Ran as part of pre-push for commits 9fd9aca, e8c2e21, 6f18b6e, fa61b11, a2e8f22. | pre-push log |
| `rumdl check docs/source/docs-placement-retention-policy-v1.md` | pass | Success: No issues found in 1 file. | local CLI |
| `agent-docs resolve --context project-dev --strict --format checklist` | pass | DEVELOPMENT.md + docs-placement-retention-policy-v1.md present. | local CLI |

## Notes

- This bundle depends on the `plan-archive` binary release that lands under the sibling plan `plan-archive-nils-cli`. Bundle execution should not start the skill-body sprints until that release is available and the runtime-kit nils-cli pin is bumped to a matching tag.
- The archive repository itself is a one-shot prerequisite (Plan 2 in the master discussion source) and must exist before runtime-smoke fixtures exercise a real archive target.
