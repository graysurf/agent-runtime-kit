# plan-issue v3 surface drift in runtime-kit skills

## Status

- Status: promoted
- First observed: 2026-05-24
- Area: plan-issue record contract; dispatch and PR skills
- Severity: high

## Signal

Skill `meta/heuristic-inbox` ended with `pass`. Summary: Prepared source evidence for curated heuristic-system inbox entry tracking plan-issue v3 surface drift

## Evidence

- Raw record: `<workspace>/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260524-212652-plan-issue-v3-surface-drift/skill-usage/skill-usage.record.json`
- Summary: linked `skill-usage.record.v1` envelope; raw runtime details remain in the evidence location.
- Tracking issue: https://github.com/graysurf/agent-runtime-kit/issues/93
- Plan bundle:
  `docs/plans/plan-issue-v3-surface-alignment/plan-issue-v3-surface-alignment-plan.md`
- Ingested evidence:
  `evidence/issue-132-closeout-surface-drift.md` — issue #132 closeout showed
  `tracking close-ready --provider-repo --issue` can still classify a live,
  close-ready tracking issue as `RECORD_UNOPENED`, while deterministic
  body/comments evidence and `record close --dry-run` / `record close` succeed.

## Impact

Future agents may repeat this workflow gap unless the retained entry is triaged,
routed, and later promoted into a durable fix, runbook, test, script, or skill
policy.

Confirmed drift:

- Installed `plan-issue 0.20.0` exposes `record open`, `record post`,
  `record repair-dashboard`, `record close`, and `record audit` as the primary
  v3 issue-backed plan record surface.
- `record render-dashboard`, `record render-comment`, `record closeout-gate`,
  and `record build-dispatch-ledger` are still callable but explicitly marked
  as retired transitional helpers.
- Runtime-kit source skills, rendered skills, runtime-smoke probes, acceptance
  matrix text, and `docs/source/nils-cli-surface.md` still describe or test the
  retired helpers as the normal workflow.
- `nils-cli` should remove the retired helper support and documentation instead
  of carrying compatibility forward.

Affected runtime-kit source skills:

- `core/skills/dispatch/create-plan-tracking-issue/SKILL.md.tera`
- `core/skills/dispatch/execute-plan-tracking-issue/SKILL.md.tera`
- `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
- `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`
- `core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera`
- `core/skills/dispatch/dispatch-plan-closeout/SKILL.md.tera`
- `core/skills/dispatch/execute-dispatch-lane/SKILL.md.tera`
- `core/skills/dispatch/review-dispatch-lane-pr/SKILL.md.tera`
- `core/skills/pr/create-dispatch-lane-pr/SKILL.md.tera`
- `core/skills/pr/deliver-github-pr/SKILL.md.tera`
- `core/skills/pr/deliver-gitlab-mr/SKILL.md.tera`

## Current Workaround

Use only the primary v3 surface for new work. Prefer `record open` for source,
plan, dashboard, and initial state creation; prefer `record post` for state,
session, validation, review, and closeout lifecycle comments; prefer
`record repair-dashboard` for dashboard recomputation; and prefer `record close`
for strict closeout plus provider close. Avoid documenting the retired helpers
as a supported path even while the installed CLI still accepts them.

For final lightweight tracking closeout, treat `record close --dry-run` plus
`record close` as the authoritative live gate when the `tracking close-ready`
controller cannot reconcile provider evidence. Do not respond to a false
`RECORD_UNOPENED` by reposting source/plan/progress evidence if `record audit`
already sees the lifecycle comments.

## Promotion Criteria

Promote after the durable fix or accepted-risk decision is implemented,
validated, and linked from this entry.

## Next Action

None. Kit-side v3 surface drift is resolved: tracking issue #93 closed, PR #233 migrated the kit to the plan-issue.* v1.0.0 contract, and the retired transitional helpers (render-dashboard / render-comment / closeout-gate / build-dispatch-ledger) now have 0 references in core/skills. The 'tracking close-ready RECORD_UNOPENED' reconciliation observation was tied to the retired v3 payload format and is NOT covered by this closure; re-verify against plan-issue v1.0.0 and file a focused nils-cli finding if it still reproduces.

Lifecycle link: `https://github.com/graysurf/agent-runtime-kit/issues/93`

## Archive

- Archived: 2026-06-01
- Reason: Kit-side v3 surface drift resolved (#93 closed, #233 plan-issue.* v1.0.0 migration, 0 retired-helper refs)
- Durable link: `https://github.com/graysurf/agent-runtime-kit/issues/93`
