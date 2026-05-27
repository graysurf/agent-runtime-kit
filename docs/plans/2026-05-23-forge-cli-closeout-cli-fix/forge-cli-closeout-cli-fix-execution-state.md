# Execution State: Closeout CLI Documentation Fix

<!-- execute-from-tracking-issue:state:v1 -->
## Execution State

- Status: Sprint 1 + Sprint 2.1 + Sprint 2.2 complete on disk; Sprint
  2.3 (commit) and 2.4 (PR deliver + chained closeout exercise)
  remain.
- Target scope: bring six SKILL.md.tera closeout / chained-closeout
  blocks in line with `forge-cli 0.17.6` by dropping `--reason
  completed` from every `forge-cli issue close` invocation and
  switching the `--comments-json` source to a `gh|glab issue view
  --json body,comments` substitute, then refresh the rendered golden
  snapshots and re-exercise the chained closeout against this
  plan's own tracking issue.
- Current task: Sprint 2 Task 2.3 — commit via semantic-commit.
- Next task: Sprint 2 Task 2.4 — open the PR through
  `pr:deliver-github-pr`; the merge exercises the corrected Step 10
  chained closeout against issue #73.
- Last updated: 2026-05-23
- Branch: feat/forge-cli-closeout-cli-fix
- Tracking issue: https://github.com/graysurf/agent-runtime-kit/issues/73
  - Source comment: https://github.com/graysurf/agent-runtime-kit/issues/73#issuecomment-4525685246
  - Plan comment: https://github.com/graysurf/agent-runtime-kit/issues/73#issuecomment-4525685334
  - State comment: https://github.com/graysurf/agent-runtime-kit/issues/73#issuecomment-4525685423
- PR: pending (opened via `pr:deliver-github-pr` after Sprint 2.3).
- Source document: `docs/plans/2026-05-23-forge-cli-closeout-cli-fix/forge-cli-closeout-cli-fix-plan.md`
- Discussion source: docs/plans/2026-05-23-forge-cli-closeout-cli-fix/forge-cli-closeout-cli-fix-discussion-source.md
- Trigger: PR #71 Sprint 3.2 specialist review deferred findings
  (api-contract, info) — verified as real CLI rejections during the
  post-merge user follow-up.

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | completed | Fix plan-tracking-issue-closeout | `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera` (Entrypoint block + Prereqs gh requirement) | Drops `--reason completed`; switches comments fetch to `gh issue view --json body,comments`. |
| 1.2 | completed | Fix dispatch-plan-closeout | `core/skills/dispatch/dispatch-plan-closeout/SKILL.md.tera` (Entrypoint block + Prereqs) | Same shape against `--profile dispatch` / `--marker-family shared`. |
| 1.3 | completed | Fix deliver-plan-tracking-issue chained closeout | `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera` (Entrypoint closeout block + Step 11 prose) | Step 11 and Entrypoint block use the gh fetch + no-reason close. |
| 1.4 | completed | Fix deliver-dispatch-plan chained closeout | `core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera` (Entrypoint closeout block + Step 12 prose) | Same shape against dispatch profile. |
| 1.5 | completed | Fix deliver-github-pr Step 10 | `core/skills/pr/deliver-github-pr/SKILL.md.tera` (Entrypoint Step 10 block + Workflow Step 10 prose) | GitHub path: gh issue view --json body,comments. |
| 1.6 | completed | Fix deliver-gitlab-mr Step 10 | `core/skills/pr/deliver-gitlab-mr/SKILL.md.tera` (Entrypoint Step 10 block + Workflow Step 10 prose) | GitLab path: glab issue view --comments --output json + jq reshape into {body, comments}. |
| 1.7 | completed | Refresh golden snapshots | 12 files under `tests/golden/{codex,claude}/plugins/{dispatch,pr}/skills/*/expected/SKILL.md` (6 skills × 2 products) | `agent-runtime render --product codex/claude --update-golden` regenerated all expected/SKILL.md bodies. |
| 2.1 | completed | Static validation | plan-tooling exit 0; grep gate sum 0 across core/skills + tests/golden; bash scripts/ci/all.sh exit 0 (positions 1–10) | All static gates green. |
| 2.2 | completed | Multi-lens specialist review | `${CODEX_AGENT_STATE_HOME or default}/out/projects/graysurf__agent-runtime-kit/20260523-224224-forge-cli-closeout-cli-fix-review/` (findings.jsonl + specialist-review.md) | 6 findings, 0 blocking. 2 positive confirmations that PR #71 deferred findings are resolved; 1 low-confidence residual risk on the unverified GitLab payload shape; 3 info/low maintainability + testing notes deferred or kept-as-is. |
| 2.3 | pending | Commit via semantic-commit | — | Bundled commit covering 6 source SKILL.md.tera + 12 golden expected/SKILL.md + execution-state refresh. |
| 2.4 | pending | PR deliver + chained closeout exercise | — | Confirms the corrected commands let the chained closeout run without manual substitution against issue #73. |

## Validation

| Command | Status | Summary |
| --- | --- | --- |
| `plan-tooling validate --file docs/plans/2026-05-23-forge-cli-closeout-cli-fix/forge-cli-closeout-cli-fix-plan.md --format text --explain` | passed | exit 0. |
| `grep -rc -- '--reason completed' core/skills/ tests/golden/` | passed | Sum = 0 across all paths. |
| `bash scripts/ci/all.sh` | passed | Positions 1–10 OK locally. |
| `forge-cli issue close 99999 --dry-run --format json` | passed | Returns `ok=true`, backend plan `['gh','issue','close','99999']`. With `--reason completed` returns `ok=false code=unknown-subcommand`. |
| `gh issue view 67 --json body,comments` | passed | Returns object with both `body` (string) and `comments` (array) — confirms the substitute. |
| Chained closeout against this plan's tracking issue #73 | pending | Sprint 2.4 — corrected commands run without manual substitution. |

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
