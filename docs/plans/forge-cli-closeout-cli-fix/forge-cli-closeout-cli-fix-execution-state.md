# Execution State: Closeout CLI Documentation Fix

<!-- execute-from-tracking-issue:state:v1 -->
## Execution State

- Status: not-started
- Target scope: bring six SKILL.md.tera closeout / chained-closeout
  blocks in line with `forge-cli 0.17.6` by dropping `--reason
  completed` from every `forge-cli issue close` invocation and
  switching the `--comments-json` source to a `gh|glab issue view
  --json body,comments` substitute, then refresh the eight rendered
  golden snapshots and re-exercise the chained closeout against this
  plan's own tracking issue.
- Current task: Sprint 1 Task 1.1 — fix
  `plan-tracking-issue-closeout`.
- Next task: Sprint 1 Task 1.2 — fix `dispatch-plan-closeout`.
- Last updated: 2026-05-23
- Branch: feat/forge-cli-closeout-cli-fix
- Tracking issue: pending (created via
  `dispatch:create-plan-tracking-issue` after this bundle is
  committed; URL recorded back here in the same session).
  - Source comment: pending
  - Plan comment: pending
  - State comment: pending
- PR: pending (opened via `pr:deliver-github-pr` after Sprint 2.3).
- Source document: `docs/plans/forge-cli-closeout-cli-fix/forge-cli-closeout-cli-fix-plan.md`
- Discussion source: docs/plans/forge-cli-closeout-cli-fix/forge-cli-closeout-cli-fix-discussion-source.md
- Trigger: PR #71 Sprint 3.2 specialist review deferred findings
  (api-contract, info) — verified as real CLI rejections during the
  post-merge user follow-up.

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | pending | Fix plan-tracking-issue-closeout | — | Remove `--reason completed`; switch comments source to `gh issue view --json body,comments`. |
| 1.2 | pending | Fix dispatch-plan-closeout | — | Same shape against `--profile dispatch` / `--marker-family shared`. |
| 1.3 | pending | Fix deliver-plan-tracking-issue chained closeout | — | Step 11 + Entrypoint block. |
| 1.4 | pending | Fix deliver-dispatch-plan chained closeout | — | Step 12 + Entrypoint block. |
| 1.5 | pending | Fix deliver-github-pr Step 10 | — | GitHub Step 10 closeout block. |
| 1.6 | pending | Fix deliver-gitlab-mr Step 10 | — | GitLab Step 10 closeout block; uses `glab issue view`. |
| 1.7 | pending | Refresh golden snapshots | — | `agent-runtime render --update-golden` for codex + claude. |
| 2.1 | pending | Static validation | — | plan-tooling + grep gate + scripts/ci/all.sh. |
| 2.2 | pending | Multi-lens specialist review | — | testing + maintainability + api-contract; api-contract must verify PR #71 deferred findings are resolved. |
| 2.3 | pending | Commit via semantic-commit | — | Scope `(skills)` + optional `(test)` split. |
| 2.4 | pending | PR deliver + chained closeout exercise | — | Confirms the corrected commands let the chained closeout run without manual substitution. |

## Validation

| Command | Status | Summary |
| --- | --- | --- |
| `plan-tooling validate --file docs/plans/forge-cli-closeout-cli-fix/forge-cli-closeout-cli-fix-plan.md --format text --explain` | pending | Run before Sprint 2 commit. |
| `grep -rc -- '--reason completed' core/skills/ tests/golden/` | pending | Must total `0` after Sprint 1.7. |
| `bash scripts/ci/all.sh` | pending | Sprint 2.1 — positions 1–10. |
| `forge-cli issue close <id> --dry-run --format json` | pending | Sprint 2.2 api-contract — must return `ok=true`. |
| `gh issue view <id> --json body,comments` | pending | Sprint 2.2 api-contract — confirms substitute returns both fields. |
| Chained closeout against this plan's tracking issue | pending | Sprint 2.4 — corrected commands run without manual substitution. |

## Closeout Gate

- Close condition: PR merges to `main` with plan bundle + six SKILL
  source edits + eight golden refreshes in one PR. This plan's own
  tracking issue closes via the corrected chained closeout in
  `deliver-github-pr` Step 10, with the
  `tracking-issue-closeout:v1` comment present. No manual command
  substitution was required at run time.
- Reopen triggers: `forge-cli` grows a `--reason` flag (the docs
  should adopt it); a comments-aware `forge-cli issue view` lands
  (skills should prefer it over `gh|glab`); any future deliver-* /
  closeout skill reintroduces the rejected flag or the broken
  `--comments-json` source.
