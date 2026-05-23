<!-- execute-from-tracking-issue:state:v1 -->

## Execution State

- Path: `docs/plans/deliver-autonomous-closeout/deliver-autonomous-closeout-execution-state.md`
- Commit: `bd296d5698346c272496facd246130d397fcdcd0`

# Execution State: Deliver-* Skills Autonomous Closeout

<!-- execute-from-tracking-issue:state:v1 -->
## Execution State

- Status: not-started
- Target scope: make the four `deliver-*` skills self-contained so a
  single invocation closes the matching issue / PR through the same
  CLI atoms the `*-closeout` / `close-*` skills wrap, while keeping
  those closeout skills published as the canonical recovery surface.
- Current task: Sprint 1 Task 1.1 — inline closeout in
  `deliver-plan-tracking-issue`.
- Next task: Sprint 1 Task 1.2 — inline closeout in
  `deliver-dispatch-plan`.
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
| 1.1 | pending | Inline closeout in deliver-plan-tracking-issue | — | Replaces Step 11 handoff with inline `plan-issue record closeout-gate --profile tracking` + render + `forge-cli issue close`. |
| 1.2 | pending | Inline closeout in deliver-dispatch-plan | — | Same shape against `--profile dispatch`. |
| 1.3 | pending | Boundary contract callout | — | Both Boundary sections cross-link to the matching closeout skill and `--no-closeout`. |
| 2.1 | pending | Add post-merge issue closeout in deliver-github-pr | — | Step 10 detects `Refs #<issue>`, runs closeout-gate against the merged PR ref, then chained closeout. PR-body `Closes #N` ban stays. |
| 2.2 | pending | Add post-merge issue closeout in deliver-gitlab-mr | — | Mirror of Task 2.1 for GitLab. |
| 2.3 | pending | Shared --no-closeout opt-out contract | — | Identical Inputs paragraph in all four skill bodies; Boundary references the flag. |
| 3.1 | pending | Render tracking issue artifacts (dry-run) | — | Dashboard + source/plan/state comments under `docs/plans/deliver-autonomous-closeout/tracking-issue/`. |
| 3.2 | pending | Multi-lens specialist review | — | Forced lenses: testing, maintainability, api-contract. |
| 3.3 | pending | Apply review fixes | — | Zero blocking findings before commit. |
| 3.4 | pending | Commit via semantic-commit | — | Scope `(skills)` or split `(plans)` + `(skills)`. |
| 3.5 | pending | PR deliver to main | — | First end-to-end exercise of the new chained closeout path against this plan's own tracking issue. |

## Validation

| Command | Status | Summary |
| --- | --- | --- |
| `plan-tooling validate --file docs/plans/deliver-autonomous-closeout/deliver-autonomous-closeout-plan.md --format text --explain` | pending | Run before Sprint 3 commit. |
| `bash scripts/ci/all.sh` | pending | Full local gate before PR open. |
| `plan-issue record audit --profile tracking ...` | pending | Sprint 3.1 dry-run + Sprint 3.5 post-merge. |
| `for f in core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera core/skills/pr/deliver-github-pr/SKILL.md.tera core/skills/pr/deliver-gitlab-mr/SKILL.md.tera; do grep -q -- '--no-closeout' "$f" \|\| exit 1; done` | pending | Sprint 2.3 acceptance. |
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
