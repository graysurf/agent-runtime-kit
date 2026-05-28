# Plan: Plan-Tracking Task Ledger Durability

## Overview

Make every plan-tracking issue carry a complete, faithful per-task record
that survives session boundaries and plan closure. Today the plan
bundle's `execution-state.md` ledger is hand-maintained Markdown that
silently drifts away from actual execution, and the `state` payload's
`tasks` array on the provider issue only reflects the run-state's
current `selected_task`. The C rollout's own closeout (issue #144,
2026-05-28) proved the gap: tasks 1.1–3.7 all ran, but the ledger
stayed at `pending` on every row and the `state` payload carried just
`Task 3.1`.

Two bundles ship together as one runtime-kit feature delivery:

- **Bundle A — per-task ledger durability.** Treat the
  `execution-state.md` ledger as the canonical per-task record. Add a
  one-call CLI (`plan-tooling ledger-update`) for row updates, wire the
  deliver / execute / closeout skill bodies to call it after every
  task, and add a new `ledger-rows-pending` blocker to
  `plan-issue tracking close-ready` so the gate refuses while ledger
  rows are still `pending` at `phase=ready_for_close`.
- **Bundle B — durable summary, drift reconciliation, and handoff
  dump.** Closeout writes a final summary note via
  `tracking run update --note`. Add a read-mostly
  `plan-tooling ledger-sync --from-issue` helper for drift
  reconciliation. Document the plan-tracking handoff dump pattern in
  `conversation:handoff-session-prompt`.

While the SKILL bodies are being touched anyway, fold in the related
fix the C plan deferred: switch the tracking-profile entrypoint
`tracking checkpoint --post …` invocations in
`deliver-plan-tracking-issue` and `execute-plan-tracking-issue` to
`tracking checkpoint --live --post …` so the prescribed lifecycle
posting actually writes to the provider by default. This piggy-backs
on the same goldens re-render as the ledger wiring.

After this rollout, plan-tracking issues close with a complete ledger,
a closing summary event in `events.jsonl`, and a `close-ready` gate
that refuses to let ledger and provider lifecycle evidence silently
disagree. The C rollout's other Future Work items —
`tracking-checkpoint-live-not-implemented` constant retirement,
dispatch-profile `--live` parity, and closing the broader
`plan-issue-v3-surface-drift` entry — remain out of scope and are
documented in [Future Work](#future-work-out-of-scope-for-this-tracker).

## Read First

- Primary source:
  `docs/plans/2026-05-28-plan-task-ledger-durability/2026-05-28-plan-task-ledger-durability-discussion-source.md`
- Source type: discussion-to-implementation-doc
- Predecessor rollouts:
  - `docs/plans/2026-05-28-tracking-checkpoint-live/` (C — live posting
    landed at `plan-issue-cli@0.25.6`; bundle still in source repo)
  - C tracking issue:
    `https://github.com/graysurf/agent-runtime-kit/issues/144`
    (closed 2026-05-28, ledger preserved as `pending` by design)
- Specs governing the design:
  - `docs/source/plan-issue-redesign/plan-tracking-issue-run-state-controller-v1.md`
  - `docs/source/plan-issue-redesign/plan-tracking-issue-cli-redesign-v1.md`
  - `docs/source/plan-issue-redesign/plan-tracking-issue-comment-taxonomy-v1.md`
- Key decisions carried into execution (from the discussion source's
  Decisions section):
  - [D1] `execution-state.md` task ledger is the canonical per-task
    record; `state` payload `tasks` array stays current-only.
  - [D2] Add `plan-tooling ledger-update` for one-call row updates.
  - [D3] Wire deliver / execute SKILL bodies to call `ledger-update`
    after every task.
  - [D4] Add `ledger-rows-pending` blocker to `tracking close-ready`.
  - [D5] Closeout writes a final summary note via
    `tracking run update --note`.
  - [D6] Add optional `plan-tooling ledger-sync --from-issue` helper.
  - [D7] Document the plan-tracking handoff prompt pattern in
    `conversation:handoff-session-prompt`.
  - [D8] Bundles A + B ship together as one runtime-kit feature PR.
  - [D9] Patch release: `plan-tooling` + `plan-issue-cli`
    `0.25.6 → 0.25.7`.
  - [D10] `state` payload `tasks` schema unchanged this rollout
    (payload accumulation deferred — separate `plan-issue-v4` topic).
- Open questions carried into execution: none. The
  payload-accumulation question (O1 in the discussion source's final
  response) is explicitly deferred — see Future Work below.

## Scope

- In scope:
  - **Lane 1 (`sympoies/nils-cli`)**
    - `plan-tooling ledger-update` subcommand ([D2]).
    - `plan-tooling ledger-sync --from-issue` subcommand ([D6]).
    - `plan-issue tracking close-ready` blocker
      `ledger-rows-pending` ([D4]).
    - Rust tests covering all new branches.
    - `--live` clap doc-comment touch-ups on any affected controller
      surface.
    - Workspace-level patch bump: `plan-tooling` and `plan-issue-cli`
      `0.25.6 → 0.25.7`.
  - **Lane 2 (release)**
    - Cut `v0.25.7` tag, build artifacts, bump Homebrew tap formula,
      confirm `plan-issue --version` and `plan-tooling --version` on
      PATH match `0.25.7`.
  - **Lane 3 (`agent-runtime-kit`, single feature PR)**
    - Bump the surface-floor doc (`docs/source/nils-cli-surface.md`)
      to mention `ledger-update`, `ledger-sync`, the new blocker code,
      and the `v0.25.7` floor.
    - Wire
      `core/skills/dispatch/execute-plan-tracking-issue/SKILL.md.tera`
      to call `plan-tooling ledger-update` after each task ([D3]) and
      to use `tracking checkpoint --live --post …` for the prescribed
      lifecycle posting (Item 1 fold-in).
    - Wire
      `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
      to call `plan-tooling ledger-update` after each task ([D3]) and
      to use `tracking checkpoint --live --post …` for both
      lifecycle-checkpoint and review-checkpoint invocations
      (Item 1 fold-in).
    - Wire
      `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`
      to require a final
      `plan-issue tracking run update --note "<closing summary>"`
      before `record close` ([D5]); add `ledger-rows-pending` to its
      Failure-modes list.
    - Update
      `core/skills/conversation/handoff-session-prompt/SKILL.md.tera`
      with a Plan-tracking handoff subsection per [D7].
    - Re-render Codex / Claude / shared goldens.
    - Add deterministic smoke probes
      `dispatch.plan-tracking-closeout-gate-ledger-pending` and
      `dispatch.plan-tracking-closeout-gate-ledger-clean`; register
      both in `tests/runtime-smoke/acceptance-matrix.yaml`.
    - Commit via `semantic-commit` (no `Co-Authored-By` trailer);
      deliver via `forge-cli pr deliver --kind feature`.
- Out of scope (see [Future Work](#future-work-out-of-scope-for-this-tracker)
  for follow-up framing):
  - Changing the `state` payload `tasks` array schema to accumulate
    history (deferred — see [D10] / O1).
  - Dispatch-profile parity for the ledger path or for `--live`
    propagation (`deliver-dispatch-plan`, `execute-dispatch-lane`,
    `review-dispatch-lane-pr`).
  - Retiring the `tracking-checkpoint-live-not-implemented` constant
    and removing it from every active SKILL Failure-modes list, smoke
    comments, and the upstream CLI.
  - Closing the broader `plan-issue-v3-surface-drift` heuristic-inbox
    entry.
  - Migrating the C plan bundle
    (`docs/plans/2026-05-28-tracking-checkpoint-live/`) into
    `agent-plan-archive`.
  - Backfilling issue #144's ledger or `events.jsonl` after the fact.
  - Changing `plan-archive-migrate`'s file enumeration to inject
    reconstructed ledgers.
  - Refactoring the Markdown ledger reader/writer beyond the additive
    subcommand wiring.

## Assumptions

1. `sympoies/nils-cli` workspace remains at `0.25.6` until Lane 1
   lands; the release bumps to `0.25.7` in one workspace-level patch.
2. `plan-tooling` already exposes a Markdown-aware reader/writer for
   `*-execution-state.md` ledgers ([F8] in the discussion source);
   the new subcommands and the `close-ready` blocker reuse it instead
   of forking a parser.
3. The run-state's `bundle` field reliably resolves to a directory
   containing `*-execution-state.md` for plans created by this repo's
   workflow. Legacy run-states without `bundle` are tolerated by the
   silent-skip path in the new blocker.
4. The Homebrew tap formula tracks `plan-tooling` and `plan-issue-cli`
   releases on the same cadence as other workspace crates.
5. `agent-runtime render --update-golden` regenerates Codex / Claude /
   shared targets idempotently; only the expected SKILL.md.tera diffs
   propagate into the goldens.
6. `bash scripts/ci/all.sh` continues to gate positions 1-13 as it did
   at `bc34b3f`.
7. The user does not require dispatch-profile parity bundled into this
   rollout — confirmed in the framing discussion that produced this
   plan.

## Sprint 1: Upstream CLI (sympoies/nils-cli)

**Goal**: Ship the `plan-tooling ledger-update` and `ledger-sync`
subcommands, the `plan-issue tracking close-ready`
`ledger-rows-pending` blocker, and the workspace patch bump in one PR
against `sympoies/nils-cli` main.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 1.1: Implement `plan-tooling ledger-update`

- **Location**:
  - `crates/plan-tooling/src/` (new subcommand module)
  - `crates/plan-tooling/src/commands.rs` (or equivalent dispatcher)
- **Description**: Add the `ledger-update` subcommand with the
  signature

  ```text
  plan-tooling ledger-update \
    --execution-state <path> \
    --task <id> \
    --status <status> \
    --evidence <text> \
    [--notes <text>] [--dry-run] [--format json|text]
  ```

  Status values: `pending | in-progress | done | blocked | waived`.
  Locate the row by exact `ID` column match; replace the `Status`
  cell; append to `Evidence` with `;` as the separator when existing
  evidence is non-empty; update `Notes` only when `--notes` is passed.
  Rewrite the Markdown file atomically (write-temp + rename). Fail
  closed on missing row, ambiguous row, or malformed table with the
  stable error codes from Task 1.4. The subcommand MUST reuse
  `plan-tooling`'s existing Markdown-aware table reader/writer; no
  duplicate parser.
- **Dependencies**:
  - none
- **Complexity**: 3
- **Acceptance criteria**:
  - `plan-tooling ledger-update --execution-state <path> --task
    "Task 3.1" --status done --evidence "PR#145 squash 28acb08"`
    rewrites only that row's `Status` and `Evidence` cells; every
    other byte of the file is identical.
  - `--dry-run` emits the would-be patch (or JSON envelope under
    `--format json`) without writing.
  - `--notes` is the only path that mutates the `Notes` column;
    omitting it leaves `Notes` untouched.
- **Validation**:
  - `cargo test -p plan-tooling` (new tests added in Task 1.4).

### Task 1.2: Implement `plan-tooling ledger-sync --from-issue`

- **Location**:
  - `crates/plan-tooling/src/` (new subcommand module)
- **Description**: Add the drift-reconciliation subcommand:

  ```text
  plan-tooling ledger-sync \
    --bundle <dir> \
    [--body-file <path> --comments-json <path> | --fixture <dir>] \
    [--write] [--format json|text]
  ```

  Without `--write`, emit a JSON or text drift report listing
  `{task_id, ledger_evidence, issue_evidence, action}` per row, where
  `action ∈ {match, drift, missing}`. With `--write`, patch the
  `Evidence` column from the matched issue URL for `match` and
  `drift` entries; default-empty `Evidence` cells take priority over
  non-empty cells to avoid stomping hand-curated notes. Reuse the
  same Markdown reader/writer as Task 1.1.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 3
- **Acceptance criteria**:
  - `plan-tooling ledger-sync --bundle <dir> --fixture <dir>` produces
    a JSON drift report whose `entries[]` length equals the ledger
    row count; each entry's `action` is one of
    `match | drift | missing`.
  - `--write` mode patches only cells where the existing `Evidence`
    is empty OR the matched issue URL is strictly more specific than
    the existing text; never overwrites a hand-curated cell with a
    weaker citation.
  - Without `--fixture` and without `--body-file` / `--comments-json`,
    the command exits non-zero with a usage error.
- **Validation**:
  - `cargo test -p plan-tooling`.

### Task 1.3: Add `ledger-rows-pending` blocker to `tracking close-ready`

- **Location**:
  - `crates/plan-issue-cli/src/execute.rs`
    (`run_tracking_close_ready` or equivalent)
  - `crates/plan-issue-cli/src/commands/tracking.rs`
    (`--live` clap doc-comment refresh as needed)
- **Description**: Add the blocker code `ledger-rows-pending` to
  `plan-issue tracking close-ready`. Fires when
  `phase ∈ {ready_for_close, closed}` AND the run-state's `bundle`
  field resolves to a plan directory containing a
  `*-execution-state.md` whose ledger has at least one row with
  `Status ∈ {pending, in-progress}`. Emit one blocker entry per
  stuck row:

  ```json
  {
    "code": "ledger-rows-pending",
    "task_id": "Task 3.1",
    "status": "pending",
    "message": "ledger row still pending at phase=ready_for_close",
    "suggested_unblock": "plan-tooling ledger-update ..."
  }
  ```

  The `suggested_unblock` payload value is the literal CLI string
  `plan-tooling ledger-update --task '<id>' --status done --evidence
  <evidence>` rendered for the offending row.

  Skip the check silently (do not raise) when `bundle` is absent or
  unreadable so legacy run-states keep working. Read the ledger via
  `plan-tooling`'s shared Markdown reader; do not fork a parser
  inside `plan-issue-cli`. Update the `--live` clap doc-comment if
  any wording changes are needed alongside this blocker.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 3
- **Acceptance criteria**:
  - `plan-issue tracking close-ready --expect-visible` against a
    fixture with `phase=ready_for_close` and a ledger row at
    `pending` reports `ready=false` with at least one
    `ledger-rows-pending` blocker carrying the correct `task_id` and
    `suggested_unblock`.
  - The same gate against a ledger with every row at `done` returns
    `ready=true, blockers=[]` (subject to other existing gates).
  - With `bundle` absent or unreadable, the gate produces no
    `ledger-rows-pending` entries (silent skip) regardless of phase.
  - Blocker entries serialize through the existing JSON envelope
    without schema regression.
- **Validation**:
  - `cargo test -p plan-issue-cli`.

### Task 1.4: Rust tests, stable error codes, version bump

- **Location**:
  - `crates/plan-tooling/tests/` (new tests for `ledger-update`,
    `ledger-sync`)
  - `crates/plan-issue-cli/tests/` (new tests for the
    `ledger-rows-pending` blocker)
  - `crates/plan-tooling/Cargo.toml` (version)
  - `crates/plan-issue-cli/Cargo.toml` (version)
  - Workspace `Cargo.toml` and any sibling crates that pin
    `plan-tooling` / `plan-issue-cli` in lock-step
- **Description**: Add unit / integration tests covering:
  - (a) `ledger-update` patches an existing row (Task 1.1 happy path);
  - (b) `ledger-update` fails closed with stable error codes
    `ledger-row-not-found`, `ledger-row-ambiguous`,
    `ledger-table-malformed`;
  - (c) `ledger-sync --fixture` reports drift correctly across
    `match` / `drift` / `missing`;
  - (d) `ledger-sync --write` honors the empty-cell preference rule;
  - (e) `tracking close-ready` adds `ledger-rows-pending` only when
    both phase and ledger conditions hold;
  - (f) `tracking close-ready` silent-skips when `bundle` is missing
    or unreadable;
  - (g) the new blocker survives serialization through the existing
    JSON envelope.

  Bump `crates/plan-tooling/Cargo.toml` and
  `crates/plan-issue-cli/Cargo.toml` from `0.25.6` to `0.25.7`;
  update workspace sibling references in lock-step where the
  workspace publishes together.
- **Dependencies**:
  - Task 1.1
  - Task 1.2
  - Task 1.3
- **Complexity**: 3
- **Acceptance criteria**:
  - New tests under existing `tests/` layouts pass and exercise
    branches (a)-(g).
  - `cargo fmt --all -- --check` and `cargo clippy --workspace --
    -D warnings` clean.
  - `Cargo.toml` versions are `0.25.7` for `plan-tooling` and
    `plan-issue-cli`; workspace siblings consistent with release
    cadence policy.
- **Validation**:
  - `cargo test -p plan-tooling -p plan-issue-cli`.
  - `cargo fmt --all -- --check`.
  - `cargo clippy --workspace -- -D warnings`.
  - User's documented `nils-cli` new-crate CI gates (rumdl fmt,
    third-party-artifacts, completion-asset-audit, Cargo.lock
    locked-build) run locally first per
    `feedback_nils_cli_new_crate_ci`.

### Task 1.5: Open the upstream PR against `sympoies/nils-cli` main

- **Location**:
  - PR in `sympoies/nils-cli` main
- **Description**: Open the implementation PR with title
  `feat(plan-tooling,plan-issue-cli): per-task ledger durability` (or
  matching upstream voice) describing the new `ledger-update` /
  `ledger-sync` subcommands, the `ledger-rows-pending` blocker, and
  the 0.25.7 patch bump. Link the runtime-kit tracking issue
  (opened by `create-plan-tracking-issue` per [Recommended Next
  Artifact] in the discussion source) once it exists. Use the
  upstream PR workflow (forge-cli or the active local policy); raw
  `gh pr create` is blocked by hook.
- **Dependencies**:
  - Task 1.4
- **Complexity**: 1
- **Acceptance criteria**:
  - PR opens with the standard `sympoies/nils-cli` template
    populated.
  - Required upstream CI lanes pass (rumdl fmt /
    third-party-artifacts / completion-asset-audit / Cargo.lock
    locked-build).
  - PR is linked from this plan's execution state and the tracking
    issue's `tracking run update --linked-pr` field once merged.
- **Validation**:
  - Upstream CI green; reviewer approval per upstream policy.

## Sprint 2: Release `plan-tooling` + `plan-issue-cli` 0.25.7

**Goal**: Ship the patch release so the runtime-kit floor bump in
Sprint 3 has a real installable binary to consume.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 2.1: Cut the 0.25.7 tag

- **Location**:
  - `sympoies/nils-cli` release surface
- **Description**: Per the upstream `sympoies/nils-cli` release
  policy, cut a `v0.25.7` tag once Sprint 1 lands. Run release
  artifact builds and publish to the registry / index used by the
  Homebrew tap. Do not push to `main` outside the normal release
  commit.
- **Dependencies**:
  - Task 1.5 merged
- **Complexity**: 2
- **Acceptance criteria**:
  - `git tag v0.25.7` exists in `sympoies/nils-cli`.
  - Release artifacts published per upstream policy.
- **Validation**:
  - `cargo publish --dry-run` (or upstream equivalent) passes for
    both `plan-tooling` and `plan-issue-cli`.

### Task 2.2: Bump the Homebrew tap formulas

- **Location**:
  - Homebrew tap formulas tracking `plan-tooling` and
    `plan-issue-cli`
- **Description**: Update each tap formula to track `v0.25.7` and
  confirm the installation flow (`brew upgrade`).
- **Dependencies**:
  - Task 2.1
- **Complexity**: 1
- **Acceptance criteria**:
  - Both formulas updated and merged.
  - `plan-issue --version` AND `plan-tooling --version` on PATH print
    `0.25.7` after `brew upgrade`.
- **Validation**:
  - Local `brew upgrade` then `plan-issue --version` and
    `plan-tooling --version` checks.

## Sprint 3: Runtime-Kit Consumption (agent-runtime-kit)

**Goal**: One feature PR that bumps the surface floor, wires the new
ledger flow plus the `--live` switchover into the tracking-profile
SKILL bodies, updates the handoff-prompt skill, refreshes goldens,
adds the new smoke probes, and lands the floor bump + skill wiring +
probes atomically.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 3.1: Bump the surface-floor doc

- **Location**:
  - `docs/source/nils-cli-surface.md`
- **Description**: Update the header `git describe --tags`, `Head
  commit`, and `Release` lines to reflect `v0.25.7`. Bump the
  `plan-tooling` row to mention the new `ledger-update` and
  `ledger-sync` subcommands. Bump the `plan-issue-cli` row to mention
  the new `ledger-rows-pending` blocker on `tracking close-ready`.
  Move any pre-`0.25.7` mentions of these surfaces out of any
  "vNext" block. No changes to unrelated rows.
- **Dependencies**:
  - Task 2.2 (released CLIs exist on PATH)
- **Complexity**: 1
- **Acceptance criteria**:
  - Header version block reads `v0.25.7`.
  - `plan-tooling` row mentions `ledger-update` AND `ledger-sync`.
  - `plan-issue-cli` row mentions `ledger-rows-pending` on
    `tracking close-ready`.
  - No "vNext" reference remains for any of these three surfaces.
- **Validation**:
  - `rumdl check docs/source/nils-cli-surface.md`.

### Task 3.2: Wire `execute-plan-tracking-issue` SKILL

- **Location**:
  - `core/skills/dispatch/execute-plan-tracking-issue/SKILL.md.tera`
- **Description**: In the lifecycle-checkpoint workflow section,
  prescribe `plan-tooling ledger-update --task <id> --status <status>
  --evidence <evidence>` as the closing action for every task,
  matching the existing voice with a concrete example. Switch the
  prescribed entrypoint `tracking checkpoint --post …` invocations
  to `tracking checkpoint --live --post …` (Item 1 fold-in) so the
  default execution path posts to the provider instead of returning
  a dry-run envelope. Add `ledger-rows-pending` to the Failure-modes
  list with a one-line `plan-tooling ledger-update …` remediation
  pointer. No changes outside the workflow / failure-modes blocks.
- **Dependencies**:
  - Task 3.1
- **Complexity**: 2
- **Acceptance criteria**:
  - Body prescribes `plan-tooling ledger-update --task <id> --status
    <status> --evidence <evidence>` as the per-task closing action
    with a concrete example block.
  - Every prescribed `tracking checkpoint --post …` invocation in
    the body carries `--live`.
  - Failure-modes list includes `ledger-rows-pending` with a
    remediation pointer.
- **Validation**:
  - `rumdl check core/skills/dispatch/execute-plan-tracking-issue/SKILL.md.tera`.

### Task 3.3: Wire `deliver-plan-tracking-issue` SKILL

- **Location**:
  - `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
- **Description**: Same per-task `plan-tooling ledger-update`
  prescription as Task 3.2; step ordering must align with the
  existing `tracking run update --selected-task` cadence so the
  ledger update follows phase transitions. Switch the entrypoint
  `tracking checkpoint --post …` invocations (Surface And Tools
  description bullets plus Workflow step bodies) to
  `tracking checkpoint --live --post …` so the prescribed lifecycle
  posting is live by default (Item 1 fold-in). Add
  `ledger-rows-pending` to the Failure-modes list with the same
  remediation pointer pattern.
- **Dependencies**:
  - Task 3.1
- **Complexity**: 2
- **Acceptance criteria**:
  - Body prescribes `plan-tooling ledger-update …` as the per-task
    closing action with a concrete example block.
  - Every prescribed `tracking checkpoint --post …` invocation in
    the body carries `--live`.
  - Failure-modes list includes `ledger-rows-pending` with a
    remediation pointer.
  - Step ordering: the `ledger-update` call immediately follows the
    matching `tracking run update --selected-task` call.
- **Validation**:
  - `rumdl check core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`.

### Task 3.4: Wire `plan-tracking-issue-closeout` SKILL

- **Location**:
  - `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`
- **Description**: Require, immediately before `record close`, a
  final `plan-issue tracking run update --note "<closing summary>"`
  call ([D5]). The summary must enumerate tasks done, linked PR(s),
  and any deferred follow-up; keep the format free-form (no schema)
  since `events.jsonl` already accepts free-form notes ([F10]). Add
  `ledger-rows-pending` to the Failure-modes list with a
  `plan-tooling ledger-update` remediation pointer. No changes to
  the preflight-repair scoping landed by the C rollout.
- **Dependencies**:
  - Task 3.1
- **Complexity**: 2
- **Acceptance criteria**:
  - Body requires a final `tracking run update --note "<closing
    summary>"` invocation immediately before `record close` with a
    concrete example.
  - Failure-modes list includes `ledger-rows-pending` with a
    remediation pointer.
  - Preflight-repair scoping landed by the C rollout is preserved
    verbatim.
- **Validation**:
  - `rumdl check core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`.

### Task 3.5: Update `handoff-session-prompt` SKILL

- **Location**:
  - `core/skills/conversation/handoff-session-prompt/SKILL.md.tera`
- **Description**: Add a "Plan-tracking handoff" subsection that
  documents the recommended dump pattern from [D7] in the discussion
  source: current `run-state.json` contents, the last N (default 5)
  entries of `events.jsonl`, every `execution-state.md` ledger row
  whose `Status ∈ {pending, in-progress}`, and the latest linked PR
  refs + `state` lifecycle comment URL. The subsection is additive
  guidance; do not change the existing handoff-prompt body.
- **Dependencies**:
  - Task 3.1
- **Complexity**: 2
- **Acceptance criteria**:
  - Body contains a new "Plan-tracking handoff" subsection that
    enumerates the four bundle elements listed above.
  - Existing handoff-prompt scaffolding is preserved.
- **Validation**:
  - `rumdl check core/skills/conversation/handoff-session-prompt/SKILL.md.tera`.

### Task 3.6: Re-render Codex / Claude / shared goldens

- **Location**:
  - Goldens regenerated by `agent-runtime render --update-golden`
- **Description**: Run `agent-runtime render --update-golden`;
  review the regenerated diff line by line; commit only the
  propagations of Task 3.2-3.5 edits into the rendered Codex / Claude
  / shared surfaces. If any unrelated drift appears, rebase to clean
  `main`, regenerate, and re-diff.
- **Dependencies**:
  - Task 3.2
  - Task 3.3
  - Task 3.4
  - Task 3.5
- **Complexity**: 2
- **Acceptance criteria**:
  - Goldens diff matches the SKILL.md.tera edits without unrelated
    drift.
  - Rendered targets carry the new `plan-tooling ledger-update`
    prescriptions, the `--live` switchover, the final summary-note
    requirement, the handoff-prompt subsection, and the new
    Failure-modes entries.
- **Validation**:
  - The repo's golden / governance check (e.g.
    `sync-runtime-skills` build or the governance validator) passes.

### Task 3.7: Add the new deterministic smoke probes

- **Location**:
  - `tests/runtime-smoke/cases/dispatch/run.sh`
  - `tests/runtime-smoke/acceptance-matrix.yaml`
- **Description**: Add two new probes next to the existing
  closeout-gate probes:
  - `run_tracking_closeout_gate_ledger_pending_probe`: build a
    fixture with a plan bundle whose `execution-state.md` has at
    least two rows at `pending`; drive the run-state to
    `phase=ready_for_close`; expect `plan-issue tracking close-ready
    --expect-visible` to refuse with `ready=false` and a
    `ledger-rows-pending` entry per pending row.
  - `run_tracking_closeout_gate_ledger_clean_probe`: same scaffold
    with every ledger row marked `done`; expect
    `ready=true, blockers=[]`.

  Register both rows in
  `tests/runtime-smoke/acceptance-matrix.yaml` as
  `dispatch.plan-tracking-closeout-gate-ledger-pending` and
  `dispatch.plan-tracking-closeout-gate-ledger-clean`. Existing
  refusal-side and happy-path probes from the C rollout must continue
  to pass without modification.
- **Dependencies**:
  - Task 2.2 (released CLI on PATH)
- **Complexity**: 3
- **Acceptance criteria**:
  - Both new probes pass.
  - Existing dispatch-domain probes continue to pass (no regression).
  - Acceptance matrix lists both new rows.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain
    dispatch` — must climb to **13/13** (11 existing + 2 new ledger
    probes).

### Task 3.8: CI gates, commit, and delivery

- **Location**:
  - `agent-runtime-kit` repo gate
- **Description**: Run `bash scripts/ci/all.sh` (positions 1-13) and
  `bash tests/runtime-smoke/run.sh --mode deterministic --domain
  dispatch`. Commit via `semantic-commit` (no `Co-Authored-By`
  trailer per the home-scope feedback memory). Deliver via
  `forge-cli pr deliver --kind feature`; PR body links the upstream
  `sympoies/nils-cli` PR (Task 1.5) and the `v0.25.7` release tag.
  Dogfood the new `ledger-update` workflow on this plan: every
  Sprint 3 task should call `ledger-update` immediately after
  completion so the tracker is the first plan to faithfully report
  per-task status through the new surface.
- **Dependencies**:
  - Task 3.1
  - Task 3.2
  - Task 3.3
  - Task 3.4
  - Task 3.5
  - Task 3.6
  - Task 3.7
- **Complexity**: 2
- **Acceptance criteria**:
  - `scripts/ci/all.sh` positions 1-13 pass.
  - Dispatch-domain smoke 13/13 pass.
  - PR merges through `forge-cli pr deliver --kind feature`.
  - Every Sprint 3 task's `Evidence` cell in this plan's
    `execution-state.md` was populated via `plan-tooling
    ledger-update` (dogfood evidence).
- **Validation**:
  - Workflow run on the PR is green; merge SHA recorded on the
    tracking issue via `tracking run update --note` and
    `tracking checkpoint --live --post state`.

## Issue Closeout Gate

The tracking issue is complete when:

- Sprint 1 (Tasks 1.1-1.5), Sprint 2 (Tasks 2.1-2.2), and Sprint 3
  (Tasks 3.1-3.8) are landed on `main` of their respective repos.
- The released `plan-tooling@0.25.7` and `plan-issue-cli@0.25.7` are
  on PATH (both `--version` checks confirm).
- The runtime-kit PR posts a state checkpoint with
  `status=complete` through `tracking checkpoint --live --post state`
  (proof the `--live` switchover took effect).
- The plan's own `execution-state.md` ledger has every row at `done`
  with a non-empty `Evidence` cell — that is the proof that the new
  `ledger-update` workflow was dogfooded end-to-end.
- The closeout comment is preceded by a final
  `tracking run update --note "<closing summary>"` event in
  `events.jsonl` (proof of [D5]).
- `bash scripts/ci/all.sh` positions 1-13 green;
  dispatch-domain smoke **13/13** green (refusal + happy-path +
  ledger-pending + ledger-clean probes all pass).
- `plan-issue tracking close-ready --expect-visible` reports
  `ready=true, blockers=[]` with the new `ledger-rows-pending`
  blocker absent because every ledger row is `done`.

## Future Work (Out Of Scope For This Tracker)

Carried forward from the C rollout's Future Work and reinforced by
the audit conducted during this plan's framing:

- **Retire `tracking-checkpoint-live-not-implemented` constant.**
  Larger than it looks: the code is still referenced in five active
  SKILL.md.tera Failure-modes blocks (`deliver-dispatch-plan`,
  `execute-dispatch-lane`, `review-dispatch-lane-pr`,
  `execute-plan-tracking-issue`, `deliver-plan-tracking-issue`),
  smoke-test comments at
  `tests/runtime-smoke/cases/dispatch/run.sh:283,566`, the
  `plan-issue-skill-family-redesign-v1.md` spec, every corresponding
  golden, and the upstream CLI constant. Needs its own coordinated
  PR — track as a separate inbox entry once another agent or session
  needs the failure-mode mention removed.
- **Dispatch-profile parity for `--live` and the ledger contract.**
  This rollout intentionally restricts the `--live` switchover and
  the per-task ledger wiring to the tracking-profile skills
  (`deliver-plan-tracking-issue`, `execute-plan-tracking-issue`,
  `plan-tracking-issue-closeout`). Dispatch-profile entrypoint sites
  — at minimum `review-dispatch-lane-pr/SKILL.md.tera:93`
  (`tracking checkpoint --post review`) — and any ledger
  implications for `deliver-dispatch-plan` / `execute-dispatch-lane`
  remain a separate workflow correction.
- **Close the broader `plan-issue-v3-surface-drift` entry.** High
  severity, separate scope. The ledger durability remediation does
  not retire this umbrella entry; it removes one tributary.
- **`state` payload `tasks` schema accumulation (true `plan-issue-v4`).**
  [D10] explicitly defers payload schema change because it risks
  regressing `record audit` callers and visible-completeness lint.
  The honest framing in the discussion source's response-only open
  question (O1) is: this rollout is `plan-issue-v3` hardening, not
  `plan-issue-v4`. Open a dedicated discussion source when the
  payload semantics revisit becomes warranted (e.g. visible-lint
  surfaces accumulated task history independently of the ledger).
- **Migrate the C plan bundle to `agent-plan-archive`.** User opted
  to skip apply during the C closeout; revisit independently. The
  bundle's stale ledger is preserved by design as a record of the
  pre-remediation state.
- **Backfill issue #144's ledger or `events.jsonl`.** The bundle is
  locked post-merge; remediation only applies to plans opened after
  this rollout lands.

## Retention Intent

Plan-source coordination document. Cleanup-eligible after all three
sprints deliver and the resulting tracking issue archives via
`plan-archive-migrate`. The per-task ledger contract has a high
probability of becoming broadly referenced by other skills (it
touches four SKILL bodies and adds a permanent CLI surface); revisit
at closeout whether to promote the relevant pieces into a maintained
runbook under `docs/source/`.
