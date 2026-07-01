---
name: deliver-plan-tracking-issue
description: >
  Carry one lightweight issue-backed plan tracker through implementation, validation, review, PR delivery, final state, and non-mutating close-ready handoff.
---

# Deliver Plan Tracking Issue

## Contract

Prereqs:

- Profile: `tracking`.
- CLI floors: `plan-issue >=1.0.13`, `plan-tooling >=1.0.1`,
  `forge-cli >=1.17.0`, `review-specialists`.
- The tracking issue is open, visible, and reconciled with
  `run-state.json`; FSM is not blocked or stale.
- PR delivery runs the shared pre-merge review gate
  (`code-review-pre-merge-gate`) and posts native review events per
  `core/skills/code-review/code-review-specialists/references/REVIEW_OUTCOME_POSTING_CONTRACT.md`.
  Every tracking PR runs the full gate; there is no single-author self-review
  shortcut.
- Shared family rules apply from
  `core/skills/dispatch/plan-issue-spec/skill-family.md`.

Inputs:

- `OWNER_REPO`, `ISSUE`, `RUN_STATE`, `PLAN_BUNDLE`, `SLUG`, `BRANCH`,
  `PR_NUMBER`, `PROVIDER`, `BASE_REF`.
- Optional `LINKED_PR` when a PR already exists and should be verified
  instead of created.
- Approval evidence for the later close-ready probe.
- Review-gate artifacts: per-lens `REVIEW_LENS`,
  `SPECIALIST_REVIEW_COMMENT_FILE`, optional GitHub `REVIEW_THREAD_FILE` for
  actionable findings, `REVIEW_DECISION`, and `DELIVERY_REVIEW_OUTCOME`
  (combined outcome body).
- `REVIEW_OUTCOME_COMMENT`: the native review event URL produced by
  `forge-cli pr review --submit-review` (or a retained evidence path).
  `REVIEW_FINDINGS_JSON` is optional and contains finding rows when findings
  exist.

Outputs:

- Progress checkpoints: `tracking checkpoint --live --post
  state[,session[,validation]]`.
- PR delivery through `forge-cli pr deliver --no-merge`, or adoption of an
  already linked PR, so the review gate runs before merge.
- Native review events through `forge-cli pr review --submit-review`: one
  `COMMENT` per specialist lens (mapped reviewer bot profile) and one combined
  `APPROVE`/`REQUEST_CHANGES` outcome (`FORGE_BOT_PROFILE=dobi`), with a
  `--mirror-issue` breadcrumb to the tracking issue.
- Pre-merge disposition of every review thread (`pr review-threads`) and
  unchecked task item (`pr tasks`).
- Delivery checkpoint: `tracking checkpoint --live --post state,review`, whose
  `review` role records the native review outcome URL and is posted before merge.
- Per-task ledger sync through `plan-tooling ledger-update`.
- `forge-cli pr merge` after the gate, sweeps, and review checkpoint pass.
- Non-mutating `tracking close-ready --expect-visible` handoff result.

Failure modes:

- Stop on `run-state-stale`, `issue-evidence-missing`, `RECORD_BLOCKED`,
  `visible-completeness-failed`, PR delivery failure, or any
  `close-ready` blocker.
- Stop on provider payload privacy failures such as `local_path_present`; rewrite
  useful evidence paths to `$HOME/...` and omit remote-useless local artifact
  paths before retrying.
- Stop on `ledger-rows-pending`; repair the named task rows with
  `plan-tooling ledger-update` before retrying the gate.
- Stop when `pr merge` fails closed on `unresolved_review_threads` or
  `unchecked_task_items`; disposition every thread and task item, then retry.
- Forbidden writes: `record open`, `record attach`, `record close`,
  dispatch-profile posts, raw lifecycle comments, raw `gh pr review` /
  `glab mr approve` for recorded review evidence, or merging before the review
  gate, sweeps, and `review` checkpoint complete.

## Entrypoint

```bash
plan-issue --format json tracking status \
  --provider-repo "$OWNER_REPO" \
  --issue "$ISSUE" \
  --profile tracking \
  --run-state "$RUN_STATE" \
  --expect-visible

plan-tooling ledger-update \
  --execution-state "$PLAN_BUNDLE/$SLUG-execution-state.md" \
  --task "$TASK_ID" \
  --status done \
  --evidence "$EVIDENCE"

plan-issue --format json tracking run update \
  --run-state "$RUN_STATE" \
  --phase validating \
  --validation-overall pass \
  --validation-command "$VALIDATION_COMMAND" \
  --validation-status pass \
  --validation-evidence "$VALIDATION_LOG" \
  --now "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

plan-issue --format json tracking checkpoint \
  --provider-repo "$OWNER_REPO" \
  --issue "$ISSUE" \
  --profile tracking \
  --run-state "$RUN_STATE" \
  --live \
  --post state,session,validation \
  --repair-dashboard

# Deliver the PR without merging so the review gate has a window (adopt and
# verify LINKED_PR through pr deliver existing-PR adoption when it already exists).
forge-cli pr deliver --repo "$OWNER_REPO" \
  --kind feature --title "$PR_TITLE" \
  --head "$BRANCH" --base main \
  --body-file "$PR_BODY_FILE" \
  --test-first-evidence "$EVIDENCE_DIR" \
  --no-merge --format json

# Shared read-only specialist gate (min testing + maintainability).
review-specialists scope --base "$BASE_REF" --testing --maintainability --format json

# Native review events (GitHub) per REVIEW_OUTCOME_POSTING_CONTRACT.md: one
# COMMENT per lens with its reviewer bot profile as each lens returns, then the
# combined APPROVE/REQUEST_CHANGES outcome as dobi.
SUBMIT_REVIEW=(); [ "$PROVIDER" = github ] && SUBMIT_REVIEW=(--submit-review)

# Repeat this specialist block once for each returned lens: testing,
# maintainability, plus any risk lens selected by code-review-pre-merge-gate.
THREAD_FILE_ARGS=()
if [ "$PROVIDER" = github ] && [ -n "${REVIEW_THREAD_FILE:-}" ]; then
  THREAD_FILE_ARGS=(--thread-file "$REVIEW_THREAD_FILE")
fi
case "$REVIEW_LENS" in
  red-team) REVIEW_BOT_PROFILE=review-red-team ;;
  testing) REVIEW_BOT_PROFILE=review-testing-bot ;;
  maintainability) REVIEW_BOT_PROFILE=review-maintainability ;;
  performance) REVIEW_BOT_PROFILE=review-performance ;;
  security) REVIEW_BOT_PROFILE=review-security ;;
  api-contract) REVIEW_BOT_PROFILE=review-api-contract ;;
  data-migration) REVIEW_BOT_PROFILE=review-data-migration ;;
  *) REVIEW_BOT_PROFILE=dobi ;;
esac
FORGE_BOT_PROFILE="$REVIEW_BOT_PROFILE" forge-cli --provider "$PROVIDER" pr review "$PR_NUMBER" \
  --repo "$OWNER_REPO" \
  --decision comments-only \
  "${SUBMIT_REVIEW[@]}" \
  "${THREAD_FILE_ARGS[@]}" \
  --comment-file "$SPECIALIST_REVIEW_COMMENT_FILE" \
  --lens "$REVIEW_LENS" \
  --issue "$ISSUE" --mirror-issue --format json

FORGE_BOT_PROFILE=dobi forge-cli --provider "$PROVIDER" pr review "$PR_NUMBER" \
  --repo "$OWNER_REPO" \
  --decision "$REVIEW_DECISION" \
  "${SUBMIT_REVIEW[@]}" \
  --comment-file "$DELIVERY_REVIEW_OUTCOME" \
  --lens testing --lens maintainability \
  --issue "$ISSUE" --mirror-issue --format json

# Disposition every review thread and task-list item before merge.
forge-cli --provider "$PROVIDER" --format json pr review-threads list "$PR_NUMBER"
forge-cli --provider "$PROVIDER" --format json pr tasks "$PR_NUMBER"

# Record issue-side review evidence from the native outcome, then post the final
# state + review checkpoint before merging.
plan-issue --format json tracking run update \
  --run-state "$RUN_STATE" \
  --phase ready-for-close \
  --linked-pr "$OWNER_REPO#$PR_NUMBER" \
  --review-decision approve \
  --review-lens testing \
  --review-lens maintainability \
  --review-outcome-comment "$REVIEW_OUTCOME_COMMENT" \
  --now "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

plan-issue --format json tracking checkpoint \
  --provider-repo "$OWNER_REPO" \
  --issue "$ISSUE" \
  --profile tracking \
  --run-state "$RUN_STATE" \
  --live \
  --post state,review \
  --repair-dashboard

# Merge only after the gate, sweeps, and review checkpoint pass.
forge-cli --provider "$PROVIDER" pr merge "$PR_NUMBER" --method squash

plan-issue --format json tracking close-ready \
  --provider-repo "$OWNER_REPO" \
  --issue "$ISSUE" \
  --profile tracking \
  --run-state "$RUN_STATE" \
  --linked-pr "$OWNER_REPO#$PR_NUMBER" \
  --approval "$APPROVAL" \
  --expect-visible
```

`forge-cli pr deliver --no-merge` creates, checks, and marks the PR ready without
merging, leaving the window for the review gate; `forge-cli pr merge` performs the
merge only after the gate, the thread/task sweeps, and the issue-side `review`
checkpoint complete. When `LINKED_PR` already exists, adopt and verify it through
`pr deliver` existing-PR adoption instead of re-creating it, and record the ref
with `tracking run update --linked-pr`.

Post one compact specialist review comment per lens as it returns — before any
repair — using the mapped reviewer bot profile (`FORGE_BOT_PROFILE=dobi` for
unmapped lenses), with `--thread-file "$REVIEW_THREAD_FILE"` for actionable GitHub
findings; the combined delivery outcome posts last as `dobi`.
`code-review-pre-merge-gate` owns the read-only lenses and the bot-profile
resolver, this skill owns the provider writes, the sweeps, and the merge, and
reviewer subagents never post. `pr merge` fails closed on
`unresolved_review_threads` / `unchecked_task_items`, so disposition every thread
and task item first.

Plan-tracking PRs are `--kind feature` records, so when the test-first gate is
enabled (`[test_first].require = true` in a repo `.forge-cli.toml` or the
user-global `${XDG_CONFIG_HOME:-~/.config}/forge-cli/config.toml`) the deliver
above requires `--test-first-evidence "$EVIDENCE_DIR"` — the `verify`-clean
directory the `test-first-evidence` skill produces — or it fails closed with
`test_first_evidence_required`.

## Workflow

1. **Preflight** — run `tracking status --expect-visible`; stop on stale,
   missing, blocked, or non-visible evidence.
2. **Implementation / validation** — do local work, update the task ledger
   after every task transition, and checkpoint only changed roles.
3. **PR branch** — deliver with `forge-cli pr deliver --no-merge` (or adopt and
   verify `LINKED_PR` through `pr deliver` existing-PR adoption). Do not merge
   yet; the review gate runs first.
4. **Review gate** — run `code-review-pre-merge-gate` (min `testing` +
   `maintainability`; add risk lenses per scope). Post each lens's specialist
   review comment through `forge-cli pr review` as it returns (native `COMMENT`
   on GitHub via `--submit-review`, mapped reviewer bot profile; `--thread-file`
   for actionable findings), then the combined delivery outcome (native
   `APPROVE`/`REQUEST_CHANGES`, `FORGE_BOT_PROFILE=dobi`, `--mirror-issue`), per
   `REVIEW_OUTCOME_POSTING_CONTRACT.md`. Every tracking PR runs the full gate —
   there is no single-author self-review shortcut. Repair concrete findings in
   this delivery branch and rerun affected lenses before continuing.
5. **Pre-merge sweeps** — disposition every unresolved review thread
   (`pr review-threads`, `unresolved==0`) and unchecked task item (`pr tasks`,
   `unchecked==0`); `pr merge` fails closed otherwise.
6. **Review + final checkpoint** — set `phase=ready-for-close`, record the linked
   PR, review decision, lenses, and `--review-outcome-comment` (the native review
   event URL); add `--review-findings-file "$REVIEW_FINDINGS_JSON"` when findings
   exist; then post `state,review` in one live checkpoint. This issue-side
   `review` evidence is posted before merge.
7. **Merge** — `forge-cli pr merge` once the gate, sweeps, and review checkpoint
   pass.
8. **Close-ready probe** — run `tracking close-ready --expect-visible`. If
   `ready: true`, hand off to `plan-tracking-issue-closeout`; if `ready: false`,
   surface blockers and stop.
9. **Never close** — this skill does not call `record close`.

## Boundary

Owns:

- Delivery-scope judgement, validation strength, review-gate orchestration and
  the provider review writes (per-lens specialist comments + the combined native
  outcome), pre-merge thread/task disposition, final state/review checkpoint
  timing, the merge, and the non-mutating close-ready handoff.

Must not:

- Open the original tracker, close the issue, use dispatch-profile
  semantics, let reviewer subagents post provider comments, or merge before the
  review gate, sweeps, and `review` checkpoint complete.

Handoff:

- Upstream: `execute-plan-tracking-issue` or
  `create-plan-tracking-issue`.
- Review gate: `code-review-pre-merge-gate` (read-only lenses + bot-profile
  resolver).
- Closeout: `plan-tracking-issue-closeout`.
