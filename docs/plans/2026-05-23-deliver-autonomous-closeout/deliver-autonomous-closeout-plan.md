# Plan: Deliver-* Skills Autonomous Closeout

## Overview

Make the four `deliver-*` skills self-contained: when readiness gates
pass, a single deliver invocation closes the matching issue and/or
PR through the same CLI atoms the closeout skills wrap, instead of
stopping at "closeout-ready" and handing off to a second invocation.
The closeout skills (`plan-tracking-issue-closeout`,
`dispatch-plan-closeout`, `close-github-pr`, `close-gitlab-mr`) stay
published as the recovery surface and as the canonical reference for
the closeout sequence.

## Read First

- Primary source: docs/plans/2026-05-23-deliver-autonomous-closeout/deliver-autonomous-closeout-discussion-source.md
- Source type: discussion-to-implementation-doc
- Open questions carried into execution:
  - Order of operations for PR-level deliveries: chained closeout
    before or after `forge-cli pr merge`.
  - Whether `--no-closeout` should be a shared deliver-* flag or
    per-skill.
  - Whether dispatch closeout comments need any new "closed via
    chained deliver" metadata (default: no).

## Scope

- In scope:
  - New `docs/plans/2026-05-23-deliver-autonomous-closeout/` plan bundle (this
    file plus the discussion source and execution state).
  - Edits to `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
    so it inlines the `plan-tracking-issue-closeout` sequence after
    the closeout-readiness check passes.
  - Edits to `core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera`
    so it inlines the `dispatch-plan-closeout` sequence after final
    approval gates pass.
  - Edits to `core/skills/pr/deliver-github-pr/SKILL.md.tera` so that
    after `forge-cli pr merge` succeeds, the skill body invokes the
    inlined `plan-tracking-issue-closeout` or `dispatch-plan-closeout`
    sequence when the PR is linked to a closeout-ready tracking or
    dispatch issue.
  - Edits to `core/skills/pr/deliver-gitlab-mr/SKILL.md.tera` mirroring
    the GitHub variant for GitLab.
  - A shared `--no-closeout` opt-out documented in every modified
    deliver-* skill body.
  - Tracking-issue artifacts under
    `docs/plans/2026-05-23-deliver-autonomous-closeout/tracking-issue/`.
- Out of scope:
  - Editing `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`,
    `core/skills/dispatch/dispatch-plan-closeout/SKILL.md.tera`,
    `core/skills/pr/close-github-pr/SKILL.md.tera`, or
    `core/skills/pr/close-gitlab-mr/SKILL.md.tera`. These remain the
    canonical closeout reference.
  - Any change to `plan-issue record closeout-gate`, `forge-cli issue
    close`, or `forge-cli pr close` behavior.
  - Renaming or deprecating any skill.
  - Touching the `<!-- tracking-issue-closeout:v1 -->` marker contract
    or any marker emitted by `plan-issue record`.
  - PR-body `Closes #N` auto-close — `deliver-github-pr` /
    `deliver-gitlab-mr` continue to refuse it; closeout still goes
    through `plan-issue record closeout-gate` then `forge-cli issue
    close`.

## Sprint 1: Issue-level deliver chaining

**Goal**: Let `deliver-plan-tracking-issue` and `deliver-dispatch-plan`
run their matching closeout sequences inline when readiness gates
pass, without changing the closeout skills themselves.

**PR grouping intent**: `group`
**Execution Profile**: `serial`

### Task 1.1: Inline closeout in deliver-plan-tracking-issue

- **Location**:
  - `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`.
- **Description**: Replace Step 11 ("Close through
  `plan-tracking-issue-closeout` after completion approval") with an
  inline sequence that runs the closeout-gate, renders the closeout
  comment, edits the final dashboard, and runs `forge-cli issue close
  --reason completed` — the same sequence
  `plan-tracking-issue-closeout` runs. Stop the chain if any step
  fails and surface the same unblock message the closeout skill would
  emit. Add an opt-out paragraph documenting `--no-closeout`. Update
  the Outputs section to mention the closed issue and the
  `tracking-issue-closeout:v1` comment when closeout chaining
  succeeds.
- **Dependencies**:
  - none
- **Acceptance criteria**:
  - Step 11 in the rendered SKILL body references `plan-issue record
    closeout-gate --profile tracking` and `forge-cli issue close
    --reason completed` directly.
  - Step 11 still names `plan-tracking-issue-closeout` as the
    canonical fallback when the chained closeout aborts.
  - The Outputs section lists "closed provider issue" and "rendered
    `tracking-issue-closeout:v1` comment" as conditional outputs.
  - The Boundary section keeps `plan-issue record` and `forge-cli`
    ownership statements unchanged.
- **Validation**:
  - `grep -nE 'plan-issue record closeout-gate' core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
  - `grep -nE 'forge-cli issue close' core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
  - Render the build target and confirm Step 11 contains both
    commands.

### Task 1.2: Inline closeout in deliver-dispatch-plan

- **Location**:
  - `core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera`.
- **Description**: Replace Step 12 ("Close through
  `dispatch-plan-closeout` after final approval") with the equivalent
  inline sequence that runs `plan-issue record closeout-gate --profile
  dispatch`, renders the dispatch closeout comment, repairs the
  dashboard, and runs `forge-cli issue close --reason completed`. Keep
  the failure-mode list current — dispatch closeout gate rejections
  still stop the chain and recommend `dispatch-plan-closeout` for
  manual rerun. Add the same `--no-closeout` documentation paragraph
  as Sprint 1 Task 1.1.
- **Dependencies**:
  - Task 1.1 (so the wording stays aligned across the two skills)
- **Acceptance criteria**:
  - Step 12 references `plan-issue record closeout-gate --profile
    dispatch` and `forge-cli issue close --reason completed` directly.
  - Step 12 still names `dispatch-plan-closeout` as the canonical
    fallback when the chained closeout aborts.
  - Outputs lists the dispatch closeout comment and closed issue as
    conditional outputs.
- **Validation**:
  - `grep -nE 'plan-issue record closeout-gate --profile dispatch' core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera`
  - `grep -nE 'forge-cli issue close' core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera`

### Task 1.3: Boundary contract callout

- **Location**:
  - both modified SKILL bodies under `core/skills/dispatch/`.
- **Description**: Add a short Boundary callout immediately under the
  Boundary section explaining that the chained closeout does not move
  ownership: `plan-issue record` still owns marker rendering and gate
  evaluation, `forge-cli` still owns provider close, and the
  closeout skills remain the canonical recovery surface. Cross-link
  from each deliver-* Boundary section to the matching closeout
  skill name and to `--no-closeout` for the opt-out path.
- **Dependencies**:
  - Task 1.1
  - Task 1.2
- **Acceptance criteria**:
  - Both deliver-* Boundary sections mention the closeout skill by
    name and the `--no-closeout` opt-out.
  - No language in the Boundary section claims deliver-* now owns
    closeout-gate evaluation or provider close.
- **Validation**:
  - `grep -nE 'plan-tracking-issue-closeout|--no-closeout' core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
  - `grep -nE 'dispatch-plan-closeout|--no-closeout' core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera`

## Sprint 2: PR-level deliver chaining

**Goal**: Let `deliver-github-pr` and `deliver-gitlab-mr` run the
matching issue-level closeout inline when the merged PR is linked to
a closeout-ready tracking or dispatch issue, without enabling
PR-body `Closes #N` auto-close.

**PR grouping intent**: `group`
**Execution Profile**: `serial`

### Task 2.1: Add post-merge issue closeout in deliver-github-pr

- **Location**:
  - `core/skills/pr/deliver-github-pr/SKILL.md.tera`.
- **Description**: After Step 9 (`forge-cli pr merge`), add a Step 10
  that detects whether the PR body references a tracking or dispatch
  issue via `Refs #<issue>`. If yes, run `plan-issue record audit` to
  determine the profile, then `plan-issue record closeout-gate
  --profile {tracking|dispatch}` with the merged PR ref. On gate
  pass, run the matching closeout sequence — render the closeout
  comment, edit the final dashboard, and `forge-cli issue close
  --reason completed`. On gate fail, stop and surface the same
  unblock message the closeout skill would emit, recommending
  `plan-tracking-issue-closeout` or `dispatch-plan-closeout` for the
  manual rerun. Update the existing "MR/PR would close a … issue
  before … cleared the gate" failure mode so it covers the new
  chained closeout: PR-body `Closes #N` is still refused, but
  post-merge chained closeout via the closeout-gate path is the
  intended replacement.
- **Dependencies**:
  - Task 1.1
  - Task 1.2
- **Acceptance criteria**:
  - The new step references `plan-issue record closeout-gate`,
    `plan-issue record render-comment --kind closeout`, and
    `forge-cli issue close --reason completed`.
  - The failure-mode list still rejects PR-body `Closes #N`
    auto-close but documents the chained closeout path as the
    permitted issue-close mechanism.
  - The Outputs section lists the closed linked issue as a
    conditional output.
- **Validation**:
  - `grep -nE 'plan-issue record closeout-gate' core/skills/pr/deliver-github-pr/SKILL.md.tera`
  - `grep -nE 'forge-cli issue close' core/skills/pr/deliver-github-pr/SKILL.md.tera`
  - `grep -nE 'Closes #' core/skills/pr/deliver-github-pr/SKILL.md.tera`
    (confirms the auto-close ban remains intact)

### Task 2.2: Add post-merge issue closeout in deliver-gitlab-mr

- **Location**:
  - `core/skills/pr/deliver-gitlab-mr/SKILL.md.tera`.
- **Description**: Mirror Task 2.1 for GitLab. Use the GitLab-shaped
  `forge-cli --provider gitlab` invocations and keep the existing
  ban on MR description `Closes #N` auto-close. Reuse the same
  closeout chaining contract — closeout-gate must pass before
  `forge-cli issue close` runs.
- **Dependencies**:
  - Task 2.1
- **Acceptance criteria**:
  - Same as Task 2.1 against the GitLab skill body.
  - Wording stays symmetric with the GitHub skill so reviewers can
    diff the two skill bodies side by side.
- **Validation**:
  - `grep -nE 'plan-issue record closeout-gate' core/skills/pr/deliver-gitlab-mr/SKILL.md.tera`
  - `grep -nE 'forge-cli issue close|forge-cli --provider gitlab issue close' core/skills/pr/deliver-gitlab-mr/SKILL.md.tera`

### Task 2.3: Shared --no-closeout opt-out contract

- **Location**:
  - all four modified SKILL bodies.
- **Description**: Document the `--no-closeout` flag in the Inputs
  section of every modified deliver-* skill body with identical
  wording — "Stops the workflow after delivery readiness checks and
  before any chained closeout. Use when closeout is owned by a
  separate downstream skill invocation or by a human reviewer." Note
  that `--no-closeout` does not bypass the merge step for PR-level
  deliveries; it only suppresses post-merge issue closeout chaining.
- **Dependencies**:
  - Task 1.1
  - Task 1.2
  - Task 2.1
  - Task 2.2
- **Acceptance criteria**:
  - All four skill bodies carry an identical `--no-closeout`
    paragraph under Inputs.
  - The opt-out is also referenced in each skill's Boundary section.
- **Validation**:
  - `for f in core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera core/skills/pr/deliver-github-pr/SKILL.md.tera core/skills/pr/deliver-gitlab-mr/SKILL.md.tera; do grep -q -- '--no-closeout' "$f" || { echo "missing in $f"; exit 1; }; done`

## Sprint 3: Tracking artifacts, review, and PR delivery

**Goal**: Render dry-run tracking-issue artifacts, run the multi-lens
specialist review across the four modified skill bodies, commit, and
deliver to `main`.

**PR grouping intent**: `group`
**Execution Profile**: `serial`

### Task 3.1: Render tracking issue artifacts (dry-run)

- **Location**:
  - `docs/plans/2026-05-23-deliver-autonomous-closeout/tracking-issue/` (new
    directory).
- **Description**: Run `create-plan-tracking-issue` in dry-run /
  artifact-only mode. `plan-issue record render-dashboard` produces
  `tracking-issue/dashboard.md`; `plan-issue record render-comment
  --kind {source,plan,state}` produces three comment markdown files
  with `--marker-family compat`. Dashboard `Status` is `in-progress`,
  `Current` references Sprint 1 Task 1.1, `Next Action` references
  Sprint 1 Task 1.2.
- **Dependencies**:
  - none
- **Acceptance criteria**:
  - Four files exist under `tracking-issue/`.
  - Each file carries the compat marker family.
  - Dashboard `Target scope` matches the plan Overview.
- **Validation**:
  - `plan-tooling validate --file docs/plans/2026-05-23-deliver-autonomous-closeout/deliver-autonomous-closeout-plan.md --explain`
  - Re-render to a temp file and `diff` against the committed copy.

### Task 3.2: Multi-lens specialist review

- **Location**:
  - new evidence record under `<state_home>/out/projects/<repo>/<run-id>-deliver-autonomous-closeout-review/`.
- **Description**: Allocate the directory through `agent-out project
  --topic deliver-autonomous-closeout-review --mkdir`; capture its
  absolute path before the review starts. Run
  `code-review:code-review-specialists` across the four modified
  SKILL bodies and the plan bundle. Force `testing` and
  `maintainability`; add `api-contract` because the skill bodies are
  public agent-facing contracts. Capture findings in
  `findings.jsonl`, then run `review-specialists validate / merge /
  render`.
- **Dependencies**:
  - Task 3.1
- **Acceptance criteria**:
  - Review evidence directory exists with at least the three forced
    lenses recorded.
  - Blocking findings (if any) reference exact paths and lines.
- **Validation**:
  - `review-specialists scope --base origin/main --testing --maintainability --api-contract --format json`

### Task 3.3: Apply review fixes

- **Location**:
  - SKILL bodies, plan bundle, tracking-issue artifacts as flagged
    by Task 3.2.
- **Description**: Address every blocking finding; address warn
  findings unless explicitly deferred with a one-line waiver in the
  execution state. Re-run `plan-tooling validate` and re-render
  tracking-issue artifacts if content changed. The lifecycle-comment
  `--commit` SHA stays at the pre-commit base; Sprint 3 Task 3.5
  re-renders against the post-merge SHA.
- **Dependencies**:
  - Task 3.2
- **Acceptance criteria**:
  - Zero blocking findings remain.
  - Any deferred warn finding has a waiver row in the execution-state
    Validation table.
- **Validation**:
  - `plan-tooling validate --file docs/plans/2026-05-23-deliver-autonomous-closeout/deliver-autonomous-closeout-plan.md --explain`
  - Re-run `plan-issue record render-*` and `diff` against the
    committed tracking-issue artifacts.

### Task 3.4: Commit via semantic-commit

- **Location**:
  - working tree on `feat/deliver-autonomous-closeout`.
- **Description**: Stage the plan bundle, the four modified SKILL
  bodies, and the tracking-issue artifacts. Commit through
  `semantic-commit` (or `semantic-commit-autostage`). Use scope
  `(plans)` for the plan bundle commit and `(skills)` for the
  deliver-* skill edits when splitting; otherwise group as one
  commit with scope `(skills)` and a body that calls out both the
  plan bundle and the skill edits.
- **Dependencies**:
  - Task 3.3
- **Acceptance criteria**:
  - HEAD shows one or two `semantic-commit`-shaped commits.
  - `git status` is clean afterwards.
- **Validation**:
  - `git log --oneline -3`
  - `git status`

### Task 3.5: PR deliver to main

- **Location**:
  - GitHub `graysurf/agent-runtime-kit` `main`.
- **Description**: Use `pr:deliver-github-pr` (`forge-cli pr deliver`)
  to open the PR against `main`. Confirm a 1-2 sentence summary with
  the user before the skill opens the PR — never derive title or body
  from `git log -1`. Wait for CI; merge after green. This is the
  first invocation that exercises the new chained closeout end-to-end
  against this plan's own tracking issue, so the merge step will
  trigger the new Step 10 in `deliver-github-pr` and close this
  plan's tracking issue inline.
- **Dependencies**:
  - Task 3.4
- **Acceptance criteria**:
  - PR opens, CI lights up green, PR merges to `main`.
  - PR description links the plan bundle and the four modified
    skill bodies.
  - This plan's tracking issue closes through the new chained
    closeout path, with a `tracking-issue-closeout:v1` comment
    recorded.
- **Validation**:
  - `gh pr view --json state,mergedAt,statusCheckRollup`
  - `gh issue view "$TRACKING_ISSUE" --json state,closedAt`
  - `plan-issue record audit --profile tracking --body-file <(gh issue view "$TRACKING_ISSUE" --json body --jq .body) --comments-json <(gh issue view "$TRACKING_ISSUE" --json comments) --format text`

## Validation

| Command | When | Notes |
| --- | --- | --- |
| `plan-tooling validate --file docs/plans/2026-05-23-deliver-autonomous-closeout/deliver-autonomous-closeout-plan.md --format text --explain` | before Sprint 3 commit | Run inside the worktree. |
| `bash scripts/ci/all.sh` | before PR open | Full local gate. |
| `plan-issue record audit --profile tracking ...` | Sprint 3.1 + 3.5 | Confirms marker compatibility and final closeout marker. |
| `for f in core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera core/skills/pr/deliver-github-pr/SKILL.md.tera core/skills/pr/deliver-gitlab-mr/SKILL.md.tera; do grep -q -- '--no-closeout' "$f" \|\| exit 1; done` | Sprint 2.3 | Confirms the shared opt-out shipped everywhere. |

## Closeout Gate

- Close condition: PR merges to `main` with the plan bundle, the
  four modified SKILL bodies, and the dry-run tracking-issue
  artifacts landed in one PR. This plan's own tracking issue closes
  via the new chained closeout in `deliver-github-pr` Step 10, with
  the `tracking-issue-closeout:v1` comment present on the issue.
  Reviewers confirm the closeout chain executed against the merged
  PR and not via a manual `plan-tracking-issue-closeout` invocation.
- Reopen triggers: a fifth deliver-* skill is added without picking
  up the chained-closeout contract; `plan-issue record closeout-gate`
  changes its CLI shape; `forge-cli issue close` arguments change;
  the closeout marker contract changes; or a deliver-* skill stops
  honoring `--no-closeout`.
