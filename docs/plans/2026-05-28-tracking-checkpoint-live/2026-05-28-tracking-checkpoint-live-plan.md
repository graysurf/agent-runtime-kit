# Plan: Tracking Checkpoint Live (Part C)

## Overview

Implement `plan-issue tracking checkpoint --live --post <roles> [--repair-dashboard]`
in `sympoies/nils-cli` `crates/plan-issue-cli/` so it posts real provider
lifecycle comments instead of returning the
`tracking-checkpoint-live-not-implemented` blocked code. Cut a `0.25.6` patch
release with the fix, then consume it in `agent-runtime-kit`: bump the surface
floor, remove the two transitional `record post` fallback blocks landed by
PR #143, re-render goldens, add a happy-path smoke probe, and promote the
inbox entry `tracking-closeout-review-state-complete-gap` to the
`error-inbox/archive/2026/` archive.

After C, the canonical write surface and the documented skill bodies agree on
one live post path. The dispatch profile is fixed by the same upstream change
because the controller is profile-agnostic; no parallel dispatch work is in
scope.

## Read First

- Primary source: docs/plans/2026-05-28-tracking-checkpoint-live/2026-05-28-tracking-checkpoint-live-discussion-source.md
- Source type: discussion-to-implementation-doc
- Inbox entry being promoted: core/policies/heuristic-system/error-inbox/tracking-closeout-review-state-complete-gap/ENTRY.md
- Predecessor (A + B): PR `graysurf/agent-runtime-kit#143` (squash `f2fe7f5`)
- Specs governing the design:
  - docs/source/plan-issue-redesign/plan-tracking-issue-run-state-controller-v1.md
  - docs/source/plan-issue-redesign/plan-tracking-issue-cli-redesign-v1.md
  - docs/source/plan-issue-redesign/plan-tracking-issue-comment-taxonomy-v1.md
- Key decisions carried into execution:
  - [D1] Run-state → `state.status=complete` reuses the existing
    `phase ∈ {ReadyForClose, Closed}` mapping in `synthesize_state_payload`.
    No new flag.
  - [D2] One comment per role; `--post state,review` emits two comments,
    mirroring `record post`.
  - [D3] Dispatch profile is fixed by the same upstream change; no parallel
    dispatch CLI work; existing dispatch entrypoint `tracking checkpoint
    --post …` calls stay as-is.
  - [D4] `plan-issue-cli` 0.25.6 patch bump.
  - [D5] Skill-body scope is minimal: replace only the two transitional
    fallback blocks; keep closeout Failure-modes scoping verbatim; keep
    `tracking-checkpoint-live-not-implemented` propagation in existing
    Failure-modes lists.
  - [D6] Remove `Open heuristic gap` cross-reference lines from both
    deliver-plan-tracking-issue and plan-tracking-issue-closeout bodies.
  - [D7] Add `dispatch.plan-tracking-closeout-gate-happy-path` smoke probe
    next to the existing refusal-side probe.
- Open questions carried into execution: none

## Scope

- In scope:
  - Upstream live posting in `run_tracking_checkpoint`
    (`crates/plan-issue-cli/src/execute.rs`).
  - Fixture-mode live posting (no provider mutation) for deterministic
    smoke.
  - Per-role posting iteration with abort-on-first-error, partial-result
    surfacing, and dashboard-repair only on full success.
  - `--live` clap doc-comment refresh in
    `crates/plan-issue-cli/src/commands/tracking.rs`.
  - Rust tests for dry-run / live / fixture branches and visible-lint
    short-circuit.
  - `plan-issue-cli` 0.25.6 release tag + Homebrew tap formula bump.
  - `docs/source/nils-cli-surface.md` plan-issue-cli row bump.
  - Excise the transitional `record post` fallback blocks from
    `deliver-plan-tracking-issue/SKILL.md.tera` Workflow step 5 and
    `plan-tracking-issue-closeout/SKILL.md.tera` Workflow step 1; remove
    the `Open heuristic gap` cross-reference lines.
  - Re-render Codex / Claude / shared goldens via `agent-runtime render
    --update-golden`.
  - New happy-path smoke probe + acceptance-matrix row
    `dispatch.plan-tracking-closeout-gate-happy-path`.
  - Promote the inbox entry to `Status: promoted` and `git mv` it under
    `error-inbox/archive/2026/`.
- Out of scope:
  - Adding `--live` to existing entrypoint `tracking checkpoint --post …`
    calls in deliver / execute / deliver-dispatch-plan (separate workflow
    correction).
  - Refactoring `synthesize_state_payload` or the run-state schema.
  - Touching `record post` public surface or behavior.
  - Closing the broader `plan-issue-v3-surface-drift` entry (high
    severity, broader scope than C).
  - Dispatch-profile transitional fallbacks (none exist).
  - Removing the `tracking-checkpoint-live-not-implemented` constant
    upstream; it remains defined for forward compatibility.

## Assumptions

1. `plan-issue-cli` workspace remains at `0.25.5` until Lane 1 lands; the
   release bumps to `0.25.6` in one workspace-level patch.
2. The Homebrew tap formula tracks `plan-issue-cli` releases on the same
   cadence as other workspace crates (no separate tap policy needed).
3. `agent-runtime render --update-golden` regenerates Codex / Claude /
   shared targets idempotently; only the expected SKILL.md.tera diff
   propagates into the goldens.
4. `agent-runtime-kit`'s `bash scripts/ci/all.sh` continues to gate
   positions 1-13 as it did at `f2fe7f5`.
5. The user does not require dispatch-profile parity work bundled into C.

## Sprint 1: Upstream Live Posting (sympoies/nils-cli)

**Goal**: Make `plan-issue tracking checkpoint --live` post real lifecycle
comments, with fixture-mode parity for deterministic tests; ship one PR
against `sympoies/nils-cli` main.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 1.1: Implement live posting in `run_tracking_checkpoint`

- **Location**:
  - `crates/plan-issue-cli/src/execute.rs`
- **Description**: Replace the stub at `execute.rs:2044-2057`. When
  `args.live` is true AND `blocked.is_empty()` AND every rendered role
  passed visible-completeness lint, iterate over `rendered` in declaration
  order and post each role through the same hop `run_record_post` uses
  at lines 1094-1108: `resolve_repo_info_for_live` →
  `provider::select_adapter` → `write_temp_markdown` →
  `adapter.comment_issue(&repo, issue_number, &comment_path)`. Capture
  the returned URL per role into a `posted: [{role, comment_url}]`
  array. On first per-role error, stop iteration; return both the
  already-posted URLs and the failed role's stable error code; skip
  `--repair-dashboard` on partial failure. Flip `mode` to `"live"` and
  remove `tracking-checkpoint-live-not-implemented` from `blocked` on
  the `--live` path. Preserve the non-`--live` (default dry-run) path
  byte-identically.
- **Dependencies**:
  - none
- **Complexity**: 4
- **Acceptance criteria**:
  - `--live --post state,review` against a clean run-state posts exactly
    two comments via `adapter.comment_issue` and returns `posted` with
    two URL entries; `mode="live"`.
  - On the second role's posting failure, the response carries the first
    URL in `posted`, names the failed role with its error code in
    `blocked`, and `repair_dashboard_result` is absent.
  - Visible-completeness failure on any rendered role short-circuits
    **before** any `adapter.comment_issue` call.
  - Non-`--live` (default dry-run) response shape is byte-identical to
    `0.25.5`.
- **Validation**:
  - `cargo test -p plan-issue-cli` (existing suite continues to pass).
  - New unit tests added in Task 1.3.

### Task 1.2: Fixture-mode parity for `--live`

- **Location**:
  - `crates/plan-issue-cli/src/execute.rs`
- **Description**: When `args.fixture.is_some()` and `args.live` is true,
  skip the adapter call entirely and emit synthesized URLs of the form
  `fixture://issue/<n>/<role>` (one per posted role); set
  `mode="fixture"` and `dry_run=true` in the response, mirroring
  `run_record_post`'s fixture branch (`execute.rs:1066-1079`). When
  `args.repair_dashboard` is true under fixture mode, simulate dashboard
  repair against the in-memory fixture (no provider mutation), recording
  a synthesized `repair_dashboard_result` entry. This is the mechanism
  the new smoke probe relies on.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 2
- **Acceptance criteria**:
  - `--live --fixture <dir> --post state,review` returns
    `mode="fixture"`, `dry_run=true`, `posted` with synthesized URLs,
    and never invokes `provider::select_adapter`.
  - `--repair-dashboard` under fixture mode does not write to the
    provider; the simulated repair result is present.
- **Validation**:
  - `cargo test -p plan-issue-cli` (fixture-mode unit tests added in
    Task 1.3).

### Task 1.3: Tests, doc-comment refresh, version bump

- **Location**:
  - `crates/plan-issue-cli/tests/` (new tests for tracking checkpoint
    live + fixture)
  - `crates/plan-issue-cli/src/commands/tracking.rs` (lines 227-231)
  - `crates/plan-issue-cli/Cargo.toml` (version)
- **Description**: Add unit/integration tests covering: (a)
  `--live --fixture` posts two roles with synthesized URLs and no
  adapter call; (b) `--live` without the live binary returns the
  existing usage error; (c) visible-completeness failure short-circuits
  before posting; (d) `--post state,review` posts exactly two comments;
  (e) `--repair-dashboard` after a successful post triggers the repair
  path; (f) partial-post failure path returns both `posted` and a
  `blocked` entry for the failed role. Update the `--live` clap
  doc-comment in `commands/tracking.rs:227-231` to remove "Task 6.1;
  until then…" and document the new behavior. Bump
  `crates/plan-issue-cli/Cargo.toml` `version = "0.25.5"` → `"0.25.6"`;
  update workspace sibling references (`nils-common`, `nils-markdown`,
  `nils-plan-tooling`) to `0.25.6` if the workspace publishes in
  lock-step.
- **Dependencies**:
  - Task 1.1
  - Task 1.2
- **Complexity**: 3
- **Acceptance criteria**:
  - New tests added under existing `tests/` layout pass and exercise
    branches (a)-(f).
  - `--live` clap doc-comment names the new live-posting behavior
    without referencing "Task 6.1".
  - `Cargo.toml` version is `0.25.6`; workspace siblings consistent.
- **Validation**:
  - `cargo test -p plan-issue-cli`.
  - `cargo fmt --all -- --check` and `cargo clippy` clean (prior CI
    failure on skipped `fmt` flagged in briefing).

### Task 1.4: Open the upstream PR against `sympoies/nils-cli` main

- **Location**:
  - PR in `sympoies/nils-cli` main
- **Description**: Open the implementation PR with title
  `feat(plan-issue-cli): implement tracking checkpoint --live posting`
  describing the rendering-pipeline reuse, fixture-mode parity, and the
  `tracking-checkpoint-live-not-implemented` shutdown for the
  `--live` path. Link the runtime-kit tracking issue (Sprint 3) once
  opened. Use the upstream PR workflow (forge-cli or the active local
  policy); do not use raw `gh pr create`.
- **Dependencies**:
  - Task 1.3
- **Complexity**: 1
- **Acceptance criteria**:
  - PR opens with the standard `sympoies/nils-cli` template populated.
  - Required upstream CI lanes pass (rumdl fmt / third-party-artifacts /
    completion-asset-audit / Cargo.lock locked-build per the user's CLI
    new-crate gate memory).
  - PR is linked from this plan's execution state once merged.
- **Validation**:
  - Upstream CI green; reviewer approval per upstream policy.

## Sprint 2: Release `plan-issue-cli` 0.25.6

**Goal**: Ship the patch release so the runtime-kit floor bump in Sprint 3
has a real installable binary to consume.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 2.1: Cut the 0.25.6 tag

- **Location**:
  - `sympoies/nils-cli` release surface
- **Description**: Per the upstream `sympoies/nils-cli` release policy,
  cut a `0.25.6` tag once Sprint 1 lands. Run release artifact builds and
  publish to the registry/index used by Homebrew tap. Do not push to
  `main` outside of the normal release commit.
- **Dependencies**:
  - Task 1.4 merged
- **Complexity**: 2
- **Acceptance criteria**:
  - `git tag v0.25.6` exists in `sympoies/nils-cli`.
  - Release artifacts published per upstream policy.
- **Validation**:
  - `cargo publish --dry-run` (or upstream equivalent) passes.

### Task 2.2: Bump the Homebrew tap formula

- **Location**:
  - Homebrew tap formula tracking `plan-issue-cli`
- **Description**: Update the tap formula to track `v0.25.6` and confirm
  installation flow (`brew upgrade`).
- **Dependencies**:
  - Task 2.1
- **Complexity**: 1
- **Acceptance criteria**:
  - Formula updated and merged.
  - `plan-issue --version` on PATH prints `0.25.6` after `brew upgrade`.
- **Validation**:
  - Local `brew upgrade plan-issue-cli` (or equivalent tap binary name)
    then `plan-issue --version` check.

## Sprint 3: Runtime-Kit Consumption + Cleanup (agent-runtime-kit)

**Goal**: One feature PR that bumps the surface floor, removes the
transitional fallback blocks, refreshes goldens, adds the happy-path
probe, and archives the inbox entry.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 3.1: Bump the surface-floor doc

- **Location**:
  - `docs/source/nils-cli-surface.md`
- **Description**: Update the `plan-issue-cli` row: move the
  `tracking checkpoint` surface description out of the "vNext (pending
  the next nils-cli release)" block into an "As of `v0.25.6`" sentence;
  explicitly state that `tracking checkpoint --live --post <roles>
  --repair-dashboard` posts live lifecycle comments and the dashboard
  repair.
- **Dependencies**:
  - Task 2.2 (released CLI exists on PATH)
- **Complexity**: 1
- **Acceptance criteria**:
  - `plan-issue-cli` row mentions `v0.25.6` and live
    `tracking checkpoint --live`.
  - No "vNext" reference remains for tracking-controller live posting.
- **Validation**:
  - `rumdl check docs/source/nils-cli-surface.md`.

### Task 3.2: Excise the deliver fallback block + cross-reference

- **Location**:
  - `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
- **Description**: Remove the transitional fallback block at current
  lines 131-152 in Workflow step 5. Replace with the canonical
  `tracking checkpoint --live` invocation: first `tracking run update
  --phase ready_for_close --review-decision <decision>`, then
  `tracking checkpoint --live --post state,review --repair-dashboard`.
  Remove the `Open heuristic gap` cross-reference at the bottom (lines
  187-189).
- **Dependencies**:
  - Task 3.1
- **Complexity**: 2
- **Acceptance criteria**:
  - Body contains no `record post --kind state` or `record post --kind
    review` examples in Workflow step 5.
  - Body contains no `tracking-checkpoint-live-not-implemented`
    reference in Workflow step 5 (it stays in Failure modes per D5).
  - Body contains no link to the active inbox-entry path.
- **Validation**:
  - `rumdl check core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`.

### Task 3.3: Excise the closeout fallback block + cross-reference

- **Location**:
  - `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`
- **Description**: Remove the transitional fallback block at current
  lines 99-117 in Workflow step 1. Replace with
  `tracking checkpoint --live --post review,state --repair-dashboard`
  for preflight repair when blockers are `review-missing` /
  `state_complete-missing`. Keep the Failure-modes scoping at lines
  43-52 verbatim (defensive contract). Remove the `Open heuristic gap`
  cross-reference at the bottom (lines 164-167).
- **Dependencies**:
  - Task 3.1
- **Complexity**: 2
- **Acceptance criteria**:
  - Body contains no `record post --kind review` or `record post --kind
    state` examples in Workflow step 1.
  - Failure-modes section retains the "after `record close` succeeds"
    scoping and the "preflight repair is in scope" sentence.
  - Body contains no link to the active inbox-entry path.
- **Validation**:
  - `rumdl check core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`.

### Task 3.4: Re-render Codex / Claude / shared goldens

- **Location**:
  - Goldens regenerated by `agent-runtime render --update-golden`
- **Description**: Run `agent-runtime render --update-golden`; review
  the regenerated diff line by line; commit only the propagations of
  Task 3.2 + 3.3 edits into the rendered Codex / Claude / shared
  surfaces. If any unrelated drift appears, rebase to clean `main`,
  regenerate, and re-diff.
- **Dependencies**:
  - Task 3.2
  - Task 3.3
- **Complexity**: 2
- **Acceptance criteria**:
  - Goldens diff matches the SKILL.md.tera edits without unrelated
    drift.
  - Rendered targets contain no transitional fallback block.
- **Validation**:
  - The repo's golden / governance check (e.g.
    `sync-runtime-skills` build or the governance validator) passes.

### Task 3.5: Add the happy-path smoke probe

- **Location**:
  - `tests/runtime-smoke/cases/dispatch/run.sh`
  - acceptance-matrix file referenced by the smoke suite
- **Description**: Add `run_tracking_closeout_gate_prereq_happy_path_probe`
  next to `run_tracking_closeout_gate_prereq_blockers_probe`. Build a
  starting fixture missing `role=review` and carrying `role=state`
  `status=in-progress` (reuse
  `write_missing_review_state_complete_comments_json`). Invoke
  `plan-issue tracking checkpoint --live --fixture <dir> --profile
  tracking --post state,review --repair-dashboard` with a run-state
  whose `phase=ready_for_close` and `review.decision=approve`. Write
  the rendered post bodies back into the fixture's `comments.json` and
  dashboard. Run `plan-issue tracking close-ready --expect-visible`
  against the updated fixture and assert `ready=true` with `blockers:
  []`. Register the new row id
  `dispatch.plan-tracking-closeout-gate-happy-path` in the acceptance
  matrix.
- **Dependencies**:
  - Task 3.1 (released CLI on PATH)
- **Complexity**: 3
- **Acceptance criteria**:
  - New probe passes; existing `dispatch.plan-tracking-closeout-gate`
    refusal probe still passes (no regression).
  - Acceptance-matrix file lists both rows.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain
    dispatch` — 11/11 pass.

### Task 3.6: Promote and archive the inbox entry

- **Location**:
  - `core/policies/heuristic-system/error-inbox/tracking-closeout-review-state-complete-gap/ENTRY.md`
- **Description**: Set `Status: promoted` in the ENTRY.md Status block.
  Add a "Resolved" subsection naming the Sprint 1 nils-cli PR, the
  Sprint 3 runtime-kit PR, the released `plan-issue-cli@0.25.6`, and a
  one-paragraph summary of what landed. Then `git mv` the entire entry
  directory to
  `core/policies/heuristic-system/error-inbox/archive/2026/tracking-closeout-review-state-complete-gap/`.
- **Dependencies**:
  - Task 1.4
  - Task 3.2
  - Task 3.3
- **Complexity**: 2
- **Acceptance criteria**:
  - Entry now lives under `archive/2026/` with `Status: promoted` and
    the Resolved subsection populated.
  - `git log --follow` on the archived ENTRY.md surfaces the
    pre-promotion history.
- **Validation**:
  - `heuristic-inbox verify tracking-closeout-review-state-complete-gap
    --strict` reports the entry as a valid archived record.

### Task 3.7: CI gates + delivery

- **Location**:
  - `agent-runtime-kit` repo gate
- **Description**: Run `bash scripts/ci/all.sh` (positions 1-13) and
  `bash tests/runtime-smoke/run.sh --mode deterministic --domain
  dispatch`. Commit via `semantic-commit`. Deliver via `forge-cli pr
  deliver --kind feature` (or `--kind docs` if only Task 3.1 + 3.6
  remain).
- **Dependencies**:
  - Task 3.1
  - Task 3.2
  - Task 3.3
  - Task 3.4
  - Task 3.5
  - Task 3.6
- **Complexity**: 2
- **Acceptance criteria**:
  - `scripts/ci/all.sh` positions 1-13 pass.
  - Dispatch domain smoke 11/11 pass.
  - PR merges through forge-cli deliver macro.
- **Validation**:
  - Workflow run on the PR is green; merge SHA recorded on the tracking
    issue.

## Issue Closeout Gate

The tracking issue is complete when:

- Sprint 1 (Tasks 1.1-1.4), Sprint 2 (Tasks 2.1-2.2), and Sprint 3
  (Tasks 3.1-3.7) are landed on `main` of their respective repos.
- The released `plan-issue-cli@0.25.6` is on PATH (`plan-issue --version`
  confirms).
- The runtime-kit PR posts a state checkpoint with `status=complete`
  **through** `tracking checkpoint --live --post state` — no
  `record post` workaround used (this is the proof that C closed the
  gap).
- `bash scripts/ci/all.sh` positions 1-13 green, dispatch domain smoke
  11/11 green (refusal + happy-path probes both pass).
- The inbox entry lives under `error-inbox/archive/2026/` with
  `Status: promoted` and a populated Resolved subsection.
- `heuristic-inbox verify tracking-closeout-review-state-complete-gap
  --strict` reports the entry as a valid archived record.

## Future Work (Out Of Scope For This Tracker)

- Adding `--live` to existing entrypoint `tracking checkpoint --post …`
  calls in deliver / execute / deliver-dispatch-plan to fix the
  dry-run-by-default workflow surprise. Open as a separate inbox entry
  if validation evidence becomes available.
- Closing the broader `plan-issue-v3-surface-drift` entry (high
  severity, separate scope).
- Optional retirement of the `tracking-checkpoint-live-not-implemented`
  constant if no caller depends on it (deferred follow-up).
