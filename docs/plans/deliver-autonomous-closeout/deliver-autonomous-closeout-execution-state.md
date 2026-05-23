# Execution State: Deliver-* Skills Autonomous Closeout

<!-- execute-from-tracking-issue:state:v1 -->
## Execution State

- Status: Sprints 1–3.3 complete; Sprint 3.4 (commit) and 3.5 (PR deliver
  with chained closeout exercise against this issue) remain.
- Target scope: make the four `deliver-*` skills self-contained so a
  single invocation closes the matching issue / PR through the same
  CLI atoms the `*-closeout` / `close-*` skills wrap, while keeping
  those closeout skills published as the canonical recovery surface.
- Current task: Sprint 3 Task 3.4 — commit via semantic-commit.
- Next task: Sprint 3 Task 3.5 — open the PR through
  `pr:deliver-github-pr`; the merge exercises the new Step 10 chained
  closeout against this plan's own tracking issue #67.
- Last updated: 2026-05-23
- Branch: feat/deliver-autonomous-closeout
- Tracking issue: https://github.com/graysurf/agent-runtime-kit/issues/67
  - Source comment: https://github.com/graysurf/agent-runtime-kit/issues/67#issuecomment-4525539159
  - Plan comment: https://github.com/graysurf/agent-runtime-kit/issues/67#issuecomment-4525539240
  - State comment: https://github.com/graysurf/agent-runtime-kit/issues/67#issuecomment-4525539317
- PR: pending (opened via `pr:deliver-github-pr` after Sprint 3.4).
- Source document: `docs/plans/deliver-autonomous-closeout/deliver-autonomous-closeout-plan.md`
- Discussion source: docs/plans/deliver-autonomous-closeout/deliver-autonomous-closeout-discussion-source.md

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | completed | Inline closeout in deliver-plan-tracking-issue | `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera` (+59 lines): Inputs `--no-closeout` paragraph, Outputs conditional closeout block, Entrypoint closeout commands block, Workflow Step 11 inline sequence, Boundary callout | Step 11 now runs `plan-issue record closeout-gate --profile tracking` + render-comment closeout + `forge-cli issue close` directly. |
| 1.2 | completed | Inline closeout in deliver-dispatch-plan | `core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera` (+56 lines): same shape as 1.1 against `--profile dispatch` and `--marker-family shared`, adds `--require-review` to the gate | Step 12 now runs dispatch closeout inline. |
| 1.3 | completed | Boundary contract callout | (bundled into 1.1 and 1.2) | Both Boundary sections cross-link to the matching closeout skill and `--no-closeout`. Satisfied as part of 1.1 and 1.2 rather than as a standalone change. |
| 2.1 | completed | Add post-merge issue closeout in deliver-github-pr | `core/skills/pr/deliver-github-pr/SKILL.md.tera` (+99 lines): new Step 10 with profile detection via `plan-issue record audit`, then gate + render + comment + edit + close. Inputs `--no-closeout` + ban on `Closes #N`, Outputs conditional closed-issue block, Entrypoint chained-closeout commands block, Boundary callout | Step 9 (merge) precedes Step 10 (closeout); Step 11 became "Record …" (was Step 10). Existing Closes #N auto-close ban preserved. |
| 2.2 | completed | Add post-merge issue closeout in deliver-gitlab-mr | `core/skills/pr/deliver-gitlab-mr/SKILL.md.tera` (+101 lines): mirror of 2.1 for GitLab provider; uses `!$MR_NUMBER` linked-pr form; bans GitLab auto-close keywords (`Closes !<issue>` etc.) | Wording stays symmetric with the GitHub skill so reviewers can diff the two skill bodies side by side. |
| 2.3 | completed | Shared --no-closeout opt-out contract | grep gate: all four bodies carry the flag (`deliver-plan-tracking-issue`: 6, `deliver-dispatch-plan`: 5, `deliver-github-pr`: 5, `deliver-gitlab-mr`: 5) | Identical Inputs paragraph plus Boundary cross-references. Satisfied as part of 1.1 / 1.2 / 2.1 / 2.2. |
| 3.1 | completed | Render tracking issue artifacts (dry-run) | `docs/plans/deliver-autonomous-closeout/tracking-issue/` (dashboard + source/plan/state comments, compat marker family, post-Sprint-3.3 HEAD SHA) | Dashboard `Source/Plan/State snapshot: pending` per dry-run convention; live URLs already in execution-state. |
| 3.2 | completed | Multi-lens specialist review | `${CODEX_AGENT_STATE_HOME or default}/out/projects/graysurf__agent-runtime-kit/20260523-221548-deliver-autonomous-closeout-review/` (findings.jsonl + specialist-review.md) | 6 findings, 0 blocking. Specialists: maintainability (3 low), api-contract (2 info), testing (1 info). Red-team not required (no critical finding triggered). |
| 3.3 | completed | Apply review fixes | This file (Task Ledger + Validation refresh, Task 1.3 bundle note, Sprint 3.5 e2e validation note); two api-contract info findings deferred to follow-up as pre-existing closeout-skill contracts | Zero blocking findings; two info-level pre-existing concerns (forge-cli issue close `--reason` flag, forge-cli issue view comments shape) deferred — they apply equally to the canonical `plan-tracking-issue-closeout` and `dispatch-plan-closeout` skills and are not regressions. |
| 3.4 | pending | Commit via semantic-commit | — | Scope `(skills)` for the four SKILL.md.tera edits + `(plans)` for plan-bundle updates + tracking-issue/. Two commits or one bundled commit per semantic-commit body rules. |
| 3.5 | pending | PR deliver to main | — | First end-to-end exercise of the new chained closeout against this plan's own tracking issue #67. Confirm `tracking-issue-closeout:v1` comment lands and issue closes via the deliver-* path, not via a manual `plan-tracking-issue-closeout` invocation. |

## Validation

| Command | Status | Summary |
| --- | --- | --- |
| `plan-tooling validate --file docs/plans/deliver-autonomous-closeout/deliver-autonomous-closeout-plan.md --format text --explain` | passed | exit 0 against the post-Sprint-3.3 plan bundle. |
| `bash scripts/ci/all.sh` | pending | Full local gate before PR open. |
| `plan-issue record audit --profile tracking ...` (Sprint 3.1 dry-run) | passed | Live issue #67 audit at create time returned `status=ok`, 3 markers recognised, `missing_required=[]`; the dry-run artifacts under `tracking-issue/` use the same compat marker family. |
| `plan-issue record audit --profile tracking ...` (Sprint 3.5 post-merge) | pending | Re-run against issue #67 after deliver-github-pr's chained closeout posts the `tracking-issue-closeout:v1` comment. |
| `for f in core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera core/skills/pr/deliver-github-pr/SKILL.md.tera core/skills/pr/deliver-gitlab-mr/SKILL.md.tera; do grep -q -- '--no-closeout' "$f" \|\| exit 1; done` | passed | All four bodies carry `--no-closeout`; per-file counts 6 / 5 / 5 / 5. |
| `review-specialists validate --input findings.jsonl` + `review-specialists merge --input findings.jsonl --summary-out specialist-review.md` | passed | 6 findings validated, 0 blocking, all info/low; review evidence dir recorded under Task 3.2 in the ledger. |
| `gh issue view "$TRACKING_ISSUE" --json state,closedAt` | pending | Sprint 3.5 confirms chained closeout actually closed this plan's tracking issue. |

## Closeout Gate

- Close condition: PR merges to `main` with the plan bundle, the
  four modified SKILL bodies, and the dry-run tracking-issue
  artifacts in one PR. This plan's own tracking issue closes via the
  new chained closeout path inside `deliver-github-pr` Step 10, with
  the `tracking-issue-closeout:v1` comment recorded on the issue.
  Reviewers confirm the closeout chain executed against the merged
  PR and not via a manual `plan-tracking-issue-closeout` invocation.
- Reopen triggers: a fifth deliver-* skill is added without picking
  up the chained-closeout contract; `plan-issue record closeout-gate`
  changes its CLI shape; `forge-cli issue close` arguments change;
  the closeout marker contract changes; or a deliver-* skill stops
  honoring `--no-closeout`.
