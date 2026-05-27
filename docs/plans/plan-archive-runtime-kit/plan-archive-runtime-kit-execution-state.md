# Plan Archive — agent-runtime-kit Skill Bodies Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: complete; all sprints merged
- Target scope: Sprints 1–4 of the plan-archive runtime-kit plan bundle
- Execution window: Sprints 1, 2, 3, 4
- Current task: 4.2 (final)
- Next task: none — scope complete, ready for closeout
- Last updated: 2026-05-27
- Branch/commit/PR: graysurf/agent-runtime-kit#127 (Sprint 1), graysurf/agent-runtime-kit#130 (nils-cli v0.25.0 pin), graysurf/agent-runtime-kit#131 (Sprints 2–4 skills + governance)
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
| 2.1 | completed | Author the migration skill body | #131 | meta/plan-archive-migrate SKILL.md.tera |
| 2.2 | completed | Manifest and plugin registration for migration skill | #131 | skills.yaml + plugins.yaml + skill-usage-reminder |
| 2.3 | completed | Render goldens and fixtures for migration skill | #131 | codex + claude render goldens |
| 3.1 | completed | Author the query skill body | #131 | meta/plan-archive-query SKILL.md.tera |
| 3.2 | completed | Manifest and plugin registration for query skill | #131 | skills.yaml + plugins.yaml + skill-usage-reminder |
| 3.3 | completed | Render goldens and fixtures for query skill | #131 | codex + claude render goldens |
| 4.1 | completed | Skill-governance audit coverage | #131 | governance audit + count refresh (59→61) |
| 4.2 | completed | Sandbox install rehearsal and overlay smoke | #131 | sandbox expected-skills + runtime-smoke matrix rows + audit-drift clean |

## Session Log

- 2026-05-27: Created plan bundle (sibling discussion source, plan, initial execution state) from the master design at `docs/plans/plan-archive-system/plan-archive-system-discussion-source.md`. Tracker issue not yet opened.
- 2026-05-27: Sprint 1 implementation. Task 1.1 lands the `<YYYY-MM-DD>-<slug>/` naming rule in `docs/source/docs-placement-retention-policy-v1.md` (placement table row + dedicated Naming bullets covering both shapes and the pre-v1 exemption). Task 1.2 is a documented no-op: neither `AGENT_HOME.md` nor `AGENTS.md` references `docs/plans/` in a way that needs updating. Landed in graysurf/agent-runtime-kit#127 (merge c6de9d2).
- 2026-05-27: nils-cli surface pin bumped to v0.25.0 in graysurf/agent-runtime-kit#130 (merge 0cdc6bc), matching the Plan 1 release so the skill `required_clis` floors resolve.
- 2026-05-27: Sprints 2–4 landed bundled in graysurf/agent-runtime-kit#131 (merge 15bc2df): the `meta:plan-archive-migrate` and `meta:plan-archive-query` skill bodies, manifest/plugin/hook registration, codex + claude render goldens, runtime-smoke matrix rows + probes, sandbox expected-skills, and governance count refresh (59→61). audit-drift clean after rewording the query Boundary section.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `plan-tooling validate --file docs/plans/plan-archive-runtime-kit/plan-archive-runtime-kit-plan.md --format text --explain` | pass | Ran as part of pre-push for commits 9fd9aca, e8c2e21, 6f18b6e, fa61b11, a2e8f22. | pre-push log |
| `rumdl check docs/source/docs-placement-retention-policy-v1.md` | pass | Success: No issues found in 1 file. | local CLI |
| `agent-docs resolve --context project-dev --strict --format checklist` | pass | DEVELOPMENT.md + docs-placement-retention-policy-v1.md present. | local CLI |
| `bash scripts/ci/skill-governance-audit.sh` | pass | Both meta skills covered; counts refreshed 59→61. | PR #131 pre-push |
| `bash scripts/ci/validate-surfaces-manifest.sh` | pass | required_clis pins resolve against v0.25.0 surface. | PR #131 pre-push |
| `bash scripts/ci/all.sh` (incl. sandbox-install-rehearsal, runtime-smoke, audit-drift) | pass | Sandbox expected-skills + runtime-smoke probes green; audit-drift clean. | PR #130/#131 pre-push |

## Notes

- This bundle depends on the `plan-archive` binary release that lands under the sibling plan `plan-archive-nils-cli`. Bundle execution should not start the skill-body sprints until that release is available and the runtime-kit nils-cli pin is bumped to a matching tag.
- The archive repository itself is a one-shot prerequisite (Plan 2 in the master discussion source) and must exist before runtime-smoke fixtures exercise a real archive target.
