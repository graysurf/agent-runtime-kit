# Plan: Closeout CLI Documentation Fix

## Overview

Bring six SKILL.md.tera closeout / chained-closeout blocks in line
with the `forge-cli 0.17.6` surface: drop the rejected `--reason
completed` flag from every `forge-cli issue close` invocation and
switch the `--comments-json` source from `forge-cli issue view
--format json` (which omits comments) to a `gh|glab issue view
--json body,comments` substitute. Refresh the eight rendered golden
snapshots and re-exercise the chained closeout against this plan's
own tracking issue to confirm the fix is end-to-end correct.

## Read First

- Primary source: docs/plans/2026-05-23-forge-cli-closeout-cli-fix/forge-cli-closeout-cli-fix-discussion-source.md
- Source type: discussion-to-implementation-doc
- Open questions carried into execution:
  - Exact GitLab substitute shape (`glab issue view --comments`
    vs `--output json`); finalize in Sprint 1 Task 1.6.
  - Whether to tighten variable derivation in the canonical closeout
    skills or only in the deliver-* blocks; lean toward tightening
    both in this PR.

## Scope

- In scope:
  - New `docs/plans/2026-05-23-forge-cli-closeout-cli-fix/` plan bundle (this
    file plus the discussion source and execution state).
  - Edit `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`:
    drop `--reason completed`; switch comments source.
  - Edit `core/skills/dispatch/dispatch-plan-closeout/SKILL.md.tera`:
    same.
  - Edit `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`:
    same.
  - Edit `core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera`:
    same.
  - Edit `core/skills/pr/deliver-github-pr/SKILL.md.tera`: same.
  - Edit `core/skills/pr/deliver-gitlab-mr/SKILL.md.tera`: same.
  - Refresh eight golden snapshots under
    `tests/golden/{codex,claude}/plugins/{dispatch,pr}/skills/{plan-tracking-issue-closeout,dispatch-plan-closeout,deliver-plan-tracking-issue,deliver-dispatch-plan,deliver-github-pr,deliver-gitlab-mr}/expected/SKILL.md`
    via `agent-runtime render --update-golden`.
  - Tracking-issue artifacts under
    `docs/plans/2026-05-23-forge-cli-closeout-cli-fix/tracking-issue/`.
- Out of scope:
  - Adding `forge-cli issue view --include-comments` (lives in
    `sympoies/nils-cli`; separate PR if pursued).
  - Touching `close-github-pr` / `close-gitlab-mr` skill bodies
    (they do not drive issue closeout).
  - Reworking `plan-issue record` or the closeout marker contract.
  - Any change to merge or audit logic.

## Sprint 1: Source SKILL body edits

**Goal**: Remove the rejected `--reason completed` flag and replace
the broken `--comments-json` source across the six affected skill
bodies, with explicit variable derivation.

**PR grouping intent**: `group`
**Execution Profile**: `serial`

### Task 1.1: Fix plan-tracking-issue-closeout

- **Location**:
  - `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`.
- **Description**: In the Entrypoint and Workflow sections,
  (a) remove every `--reason completed` argument from `forge-cli
  issue close` invocations and (b) replace the underspecified
  `$ISSUE_BODY` / `$ISSUE_COMMENTS_JSON` handoff with explicit
  derivation: `gh issue view "$ISSUE" --repo "$OWNER_REPO" --json
  body,comments >"$ISSUE_COMMENTS_JSON"` followed by `jq -r .body
  "$ISSUE_COMMENTS_JSON" >"$ISSUE_BODY"`. Update the Prereqs to add
  `gh` to the required-on-PATH list. Update the Boundary if the
  ownership statement needs adjustment (it should not).
- **Dependencies**:
  - none
- **Acceptance criteria**:
  - `grep -n -- '--reason completed' core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`
    returns no matches.
  - `grep -n -- 'forge-cli issue view' core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`
    no longer feeds the audit / closeout-gate `--comments-json` arg.
  - The Prereqs list includes `gh`.
- **Validation**:
  - `grep -c -- '--reason completed' core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`
    returns `0`.

### Task 1.2: Fix dispatch-plan-closeout

- **Location**:
  - `core/skills/dispatch/dispatch-plan-closeout/SKILL.md.tera`.
- **Description**: Same shape as 1.1. Use the dispatch-profile audit
  / closeout-gate invocations (`--profile dispatch`,
  `--marker-family shared`, plus `--require-review`).
- **Dependencies**:
  - Task 1.1 (keeps wording aligned across the two canonical
    closeout skills)
- **Acceptance criteria**:
  - Same as 1.1 against the dispatch closeout file.
- **Validation**:
  - `grep -c -- '--reason completed' core/skills/dispatch/dispatch-plan-closeout/SKILL.md.tera`
    returns `0`.

### Task 1.3: Fix deliver-plan-tracking-issue chained closeout block

- **Location**:
  - `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`.
- **Description**: In the Entrypoint chained-closeout block and the
  Workflow Step 11 prose, drop `--reason completed` and replace the
  `forge-cli issue view ... | --comments-json` conflation with the
  `gh issue view --json body,comments` substitute. The block shipped
  in PR #71 needs both changes plus a cleaner variable derivation.
- **Dependencies**:
  - Task 1.1 (so the canonical reference uses the same idiom first)
- **Acceptance criteria**:
  - `grep -c -- '--reason completed' core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
    returns `0`.
  - The Entrypoint closeout block fetches comments via `gh issue
    view --json body,comments`, not via `forge-cli issue view
    --format json`.
- **Validation**:
  - `grep -n -- 'gh issue view' core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
    shows at least one match in the closeout block.

### Task 1.4: Fix deliver-dispatch-plan chained closeout block

- **Location**:
  - `core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera`.
- **Description**: Same shape as 1.3 against the dispatch
  Entrypoint closeout block and Workflow Step 12. Keep
  `--require-review` on the closeout-gate.
- **Dependencies**:
  - Task 1.3
- **Acceptance criteria**:
  - Same as 1.3 against the dispatch deliver file.
- **Validation**:
  - `grep -c -- '--reason completed' core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera`
    returns `0`.

### Task 1.5: Fix deliver-github-pr Step 10

- **Location**:
  - `core/skills/pr/deliver-github-pr/SKILL.md.tera`.
- **Description**: Update the Step 10 Entrypoint block to fetch
  comments via `gh issue view "$ISSUE" --repo "$OWNER_REPO" --json
  body,comments`. Drop `--reason completed` from the final
  `forge-cli issue close` line. Keep the profile-detection prose,
  the `Closes #<issue>` ban, and the `--no-closeout` opt-out
  unchanged.
- **Dependencies**:
  - Task 1.1
- **Acceptance criteria**:
  - `grep -c -- '--reason completed' core/skills/pr/deliver-github-pr/SKILL.md.tera`
    returns `0`.
  - Step 10 block fetches comments via `gh`.
- **Validation**:
  - `grep -n -- 'gh issue view' core/skills/pr/deliver-github-pr/SKILL.md.tera`
    shows at least one match in Step 10.

### Task 1.6: Fix deliver-gitlab-mr Step 10

- **Location**:
  - `core/skills/pr/deliver-gitlab-mr/SKILL.md.tera`.
- **Description**: Mirror 1.5 for GitLab. Use `glab issue view "$ISSUE"
  --repo "$OWNER_REPO" --comments --output json` (or the closest
  equivalent that returns both body and comments). Drop `--reason
  completed` from the `forge-cli --provider gitlab issue close`
  line. Keep `!$MR_NUMBER` linked-pr form.
- **Dependencies**:
  - Task 1.5
- **Acceptance criteria**:
  - `grep -c -- '--reason completed' core/skills/pr/deliver-gitlab-mr/SKILL.md.tera`
    returns `0`.
  - Step 10 block fetches comments via `glab`.
- **Validation**:
  - `grep -n -- 'glab issue view' core/skills/pr/deliver-gitlab-mr/SKILL.md.tera`
    shows at least one match in Step 10.

### Task 1.7: Refresh golden snapshots

- **Location**:
  - `tests/golden/codex/plugins/dispatch/skills/plan-tracking-issue-closeout/expected/SKILL.md`
  - `tests/golden/codex/plugins/dispatch/skills/dispatch-plan-closeout/expected/SKILL.md`
  - `tests/golden/codex/plugins/dispatch/skills/deliver-plan-tracking-issue/expected/SKILL.md`
  - `tests/golden/codex/plugins/dispatch/skills/deliver-dispatch-plan/expected/SKILL.md`
  - `tests/golden/codex/plugins/pr/skills/deliver-github-pr/expected/SKILL.md`
  - `tests/golden/codex/plugins/pr/skills/deliver-gitlab-mr/expected/SKILL.md`
  - `tests/golden/claude/plugins/dispatch/skills/plan-tracking-issue-closeout/expected/SKILL.md`
  - `tests/golden/claude/plugins/dispatch/skills/dispatch-plan-closeout/expected/SKILL.md`
  - `tests/golden/claude/plugins/dispatch/skills/deliver-plan-tracking-issue/expected/SKILL.md`
  - `tests/golden/claude/plugins/dispatch/skills/deliver-dispatch-plan/expected/SKILL.md`
  - `tests/golden/claude/plugins/pr/skills/deliver-github-pr/expected/SKILL.md`
  - `tests/golden/claude/plugins/pr/skills/deliver-gitlab-mr/expected/SKILL.md`
- **Description**: Run `agent-runtime render --product codex
  --update-golden` and `--product claude --update-golden` to
  refresh the rendered expected/SKILL.md snapshots for the touched
  skills. Do not hand-edit golden files.
- **Dependencies**:
  - Task 1.6
- **Acceptance criteria**:
  - `git diff --exit-code -- tests/golden/` returns exit 0 after the
    rerender.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `git diff --exit-code -- tests/golden/`

## Sprint 2: Validation, review, and delivery

**Goal**: Confirm the fix passes static and runtime gates, run the
multi-lens specialist review (with the explicit re-check that the
two earlier `api-contract` findings are now resolved), commit, and
deliver the PR. After merge, exercise the (corrected) chained
closeout against this plan's own tracking issue.

**PR grouping intent**: `group`
**Execution Profile**: `serial`

### Task 2.1: Static validation

- **Location**:
  - working tree on `feat/forge-cli-closeout-cli-fix`.
- **Description**: Run `plan-tooling validate` against this plan;
  run the `--reason completed` grep gate across all six modified
  source files plus the eight golden files (count must be `0`);
  run `scripts/ci/all.sh` locally to confirm positions 1–10 pass.
- **Dependencies**:
  - Task 1.7
- **Acceptance criteria**:
  - `plan-tooling validate` exit 0.
  - `grep -rc -- '--reason completed' core/skills/ tests/golden/`
    sums to `0`.
  - `scripts/ci/all.sh` exit 0.
- **Validation**:
  - `plan-tooling validate --file docs/plans/2026-05-23-forge-cli-closeout-cli-fix/forge-cli-closeout-cli-fix-plan.md --format text --explain`
  - `bash scripts/ci/all.sh`

### Task 2.2: Multi-lens specialist review

- **Location**:
  - new evidence record under `<state_home>/out/projects/<repo>/<run-id>-forge-cli-closeout-cli-fix-review/`.
- **Description**: Allocate via `agent-out project --topic
  forge-cli-closeout-cli-fix-review --mkdir`. Run
  `code-review:code-review-specialists` with forced lenses
  `testing`, `maintainability`, `api-contract`. The api-contract
  pass must explicitly verify the two PR #71 deferred findings are
  resolved by running dry-runs against the corrected commands:
  `forge-cli issue close <id> --dry-run` and `gh issue view <id>
  --json body,comments`. Capture findings.jsonl.
- **Dependencies**:
  - Task 2.1
- **Acceptance criteria**:
  - Review evidence directory exists.
  - The two PR #71 deferred findings are confirmed resolved in the
    api-contract specialist output.
- **Validation**:
  - `review-specialists scope --base origin/main --testing --maintainability --api-contract --format json`
  - `review-specialists validate / merge / render`

### Task 2.3: Commit via semantic-commit

- **Location**:
  - working tree.
- **Description**: One commit with scope `(skills)` for the six
  source SKILL bodies, one commit with scope `(test)` for the
  golden refresh (or one bundled `(skills)` commit covering both
  per semantic-commit body rules). Plan bundle is staged in the
  same commit set.
- **Dependencies**:
  - Task 2.2
- **Acceptance criteria**:
  - HEAD shows two or three `semantic-commit`-shaped commits.
  - `git status` clean.
- **Validation**:
  - `git log --oneline -5`
  - `git status`

### Task 2.4: PR deliver and chained closeout exercise

- **Location**:
  - GitHub `graysurf/agent-runtime-kit`.
- **Description**: Use `pr:deliver-github-pr` (`forge-cli pr
  deliver`) to open the PR against `main`. Confirm a 1–2 sentence
  summary with the user before opening. Post the delivery review
  outcome comment, mark ready, merge. After merge, execute the new
  Step 10 chained closeout against this plan's own tracking issue.
  Follow the **corrected** commands from this PR — `gh issue view
  --json body,comments` for the comments fetch, no `--reason
  completed` on the close — and confirm the sequence runs without
  any manual command substitution.
- **Dependencies**:
  - Task 2.3
- **Acceptance criteria**:
  - PR opens, CI green, merges to `main`.
  - This plan's tracking issue closes via the chained closeout
    using the corrected commands.
  - `tracking-issue-closeout:v1` comment is present on the issue.
- **Validation**:
  - `gh pr view --json state,mergedAt`
  - `gh issue view "$TRACKING_ISSUE" --json state,closedAt`
  - `plan-issue record audit --profile tracking ...` against the
    closed issue confirms all six markers are present.

## Validation

| Command | When | Notes |
| --- | --- | --- |
| `plan-tooling validate --file docs/plans/2026-05-23-forge-cli-closeout-cli-fix/forge-cli-closeout-cli-fix-plan.md --format text --explain` | before Sprint 2 commit | Exit 0. |
| `grep -rc -- '--reason completed' core/skills/ tests/golden/` | Sprint 1.7 acceptance | Must total `0` after golden refresh. |
| `bash scripts/ci/all.sh` | Sprint 2.1 | Full local gate; positions 1–10. |
| `forge-cli issue close <id> --dry-run --format json` | Sprint 2.2 api-contract lens | Must return `ok=true` without `--reason`. |
| `gh issue view <id> --json body,comments` | Sprint 2.2 api-contract lens | Must return an object with both fields. |

## Closeout Gate

- Close condition: PR merges to `main` carrying the plan bundle,
  six source SKILL.md.tera edits, and eight refreshed golden
  snapshots in one PR. This plan's own tracking issue closes via
  the corrected chained closeout, with a `tracking-issue-closeout:v1`
  comment present. The closeout sequence runs without any manual
  command substitution (no `gh|forge-cli` swaps at run time).
- Reopen triggers: `forge-cli` grows a `--reason` flag and the
  documented command needs to use it; a comments-aware `forge-cli
  issue view` lands and the skill bodies should prefer it over
  `gh|glab`; or any future deliver-* / closeout skill reintroduces
  the rejected flag or the broken `--comments-json` source.
