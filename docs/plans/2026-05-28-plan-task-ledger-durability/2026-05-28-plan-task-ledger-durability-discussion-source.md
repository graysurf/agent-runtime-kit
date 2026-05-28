# Plan-Tracking Task Ledger Durability Implementation Handoff

- Status: ready for plan generation
- Date: 2026-05-28
- Source: user-driven design session at the tail of the
  tracking-checkpoint-live (C) rollout in `graysurf/agent-runtime-kit`.
  Triggered by audit of the C tracking issue #144 closeout, which
  surfaced two related gaps: (1) the plan bundle's
  `execution-state.md` task ledger never moved off `pending` even
  though tasks 1.1-3.7 all ran; (2) the `state` lifecycle comment's
  payload `tasks` array reflected only the run-state's current
  `selected_task` (singular), so the provider issue itself does not
  carry per-task evidence.
- Intended next step: generate the single-plan bundle under
  `docs/plans/2026-05-28-plan-task-ledger-durability/`, then open the
  tracking issue via `create-plan-tracking-issue`. This is a source
  artifact, not an implementation plan.

## Execution

This document feeds **one** plan executed in three sequential lanes
(upstream `sympoies/nils-cli` implementation → upstream release →
runtime-kit consumption).

- Recommended plan: docs/plans/2026-05-28-plan-task-ledger-durability/2026-05-28-plan-task-ledger-durability-plan.md
- Recommended execution state: docs/plans/2026-05-28-plan-task-ledger-durability/2026-05-28-plan-task-ledger-durability-execution-state.md
- Status: ready to implement immediately; Lane 1 (CLI) blocks
  Lanes 2 + 3
- Next-task source: this document

## Purpose

A plan-tracking issue records lifecycle evidence at role granularity
(`state` / `session` / `validation` / `review` / `closeout`), but a
plan's task ledger lives at task granularity (Task 1.1, 1.2, ...).
Today there is no automated bridge between the two: the plan bundle's
`execution-state.md` task ledger is hand-maintained Markdown, and the
`state` payload's `tasks` array reflects only the run-state's current
`selected_task` (singular). When an agent runs straight through a
multi-sprint plan without per-task `tracking run update
--selected-task` calls, the durable per-task record on the provider
issue is incomplete — and the plan-bundle ledger silently drifts.

The C rollout proved this concretely: tracking issue #144 (closed
2026-05-28) ran tasks 1.1-3.7 across three lanes, but at close-ready
the `execution-state.md` ledger still showed every row as `pending`
and the state lifecycle comment's `tasks` array carried only
`Task 3.1` ([F1], [F2], [F4]). `plan-archive-migrate` dry-run preserved
this stale ledger as-is; user opted to skip apply this round so the
bundle remains at `docs/plans/2026-05-28-tracking-checkpoint-live/`
for now ([F6]).

This source captures the agreed remediation in two bundles delivered
together:

- **Bundle A — per-task ledger durability.** Treat the plan bundle's
  `execution-state.md` ledger as the canonical per-task record, add a
  one-call CLI to update a row, wire the deliver / execute skills to
  call it after each task finishes, and add a `tracking close-ready`
  blocker that refuses to close while any ledger row is still
  `pending` at `phase=ready_for_close`.
- **Bundle B — durable summary + handoff dump.** Have the closeout
  skill write a final summary note into `events.jsonl` via
  `tracking run update --note`, optionally add a `plan-tooling
  ledger-sync --from-issue` reconciliation helper, and document the
  recommended handoff-prompt pattern that bundles `run-state.json` +
  the last N events + the relevant ledger excerpt so a new session
  resumes with full per-task context.

After this rollout, every plan-tracking issue closeout carries a
complete per-task ledger backed by the plan bundle's
`execution-state.md` rows plus a closing summary event in
`events.jsonl`, and the `tracking close-ready` gate ensures the
ledger and provider lifecycle evidence never silently disagree at
close.

## Confirmed Facts

- [U1] User agreed on shipping Bundle A and Bundle B together:
  「1 2 3 應該要做」+「durable summary + handoff dump 也可以一起補上」.
- [U2] User framed the goal as: 「在 plan issue 裡要照實回報 execute state
  才能繼續往下做」. The remediation must keep both the issue and the
  plan bundle honest enough that a new session can resume without
  re-deriving per-task progress from git history.
- [F1] C tracking issue: `https://github.com/graysurf/agent-runtime-kit/issues/144`
  (state `CLOSED`, closeout comment `4561644146`).
  `record audit --expect-visible` against the closed issue reports
  7/7 roles present with `visible.overall_pass=true` and
  `missing_required=[]`.
- [F2] C plan bundle: `docs/plans/2026-05-28-tracking-checkpoint-live/`
  (still in `graysurf/agent-runtime-kit:main`; plan-archive-migrate
  dry-run only this round). The `execution-state.md` ledger rows
  1.1-3.7 all read `Status: pending` despite full execution.
- [F3] C run state:
  `~/.local/state/plan-issue/out/plan-issue-delivery/graysurf__agent-runtime-kit/issue-144/runs/20260528T053735Z-issue-144/run-state.json`
  reached final `phase=ready_for_close` and
  `selected_scope.task="Task 3.1"`; the matching `events.jsonl`
  carries 5 events (1 `run_started` + 4 `run_updated`) but no
  per-task transitions.
- [F4] Today's state payload (per the live close-ready checkpoint of
  #144):

  ```json
  "data": {
    "status": "complete",
    "current": "Task 3.1",
    "tasks": [{"id": "Task 3.1", "status": "done", "title": "selected"}],
    ...
  }
  ```

  The `tasks` array is single-current, not accumulated history; it
  derives from the run-state's `selected_task` field.
- [F5] The `execution-state.md` task ledger (Markdown table) is the
  existing per-task surface: every task row carries
  `ID | Status | Task | Evidence | Notes` and is hand-maintained.
- [F6] `plan-archive-migrate` already preserves the plan bundle
  (including `execution-state.md`) into `agent-plan-archive` on
  `--apply`; today's C bundle was dry-run only and remains in the
  source repo.
- [F7] Current released CLI floor is `plan-issue-cli@0.25.6` (cut by
  Lane 2 of the C rollout). Both `plan-issue` and `plan-tooling` ship
  from the `sympoies/nils-cli` workspace; tap-and-bump cadence
  applies (`docs/source/nils-cli-surface.md`).
- [F8] `plan-tooling` already validates plan bundles and exposes
  Markdown-aware operations on `*-plan.md` and `*-execution-state.md`;
  adding a `ledger-update` subcommand fits the existing surface
  scope.
- [F9] `plan-issue tracking close-ready` already supports a blocker
  contract (e.g. `review-missing`, `state_complete-missing`,
  `visible-completeness-failed`); adding a new blocker code follows
  the same pattern. The C happy-path probe at
  `tests/runtime-smoke/cases/dispatch/run.sh:run_tracking_closeout_gate_prereq_happy_path_probe`
  is the template for the matching deterministic smoke.
- [F10] `tracking run update --note` already appends a free-form note
  to `events.jsonl` (verified during C: 5 events recorded, including
  `run_updated` entries with `note`-driven changes). No new CLI
  surface is needed for the closeout summary event.
- [F11] No durable in-session task list survives a session boundary.
  `TaskCreate` state is ephemeral; only `run-state.json`,
  `events.jsonl`, provider lifecycle comments, git history, and the
  plan bundle's static files persist.
- [I1] The .md ledger and provider lifecycle comments solve different
  problems (per-task vs per-role). A single per-task surface — the
  ledger — is simpler than expanding the payload schema and
  re-routing visible-completeness lint to handle accumulated task
  history; see [D10] for the deferral and the open question reported
  in the final response.

## Decisions

### D1 — `execution-state.md` task ledger is the canonical per-task record

Per-task evidence lives in the plan bundle's `execution-state.md`
ledger Markdown table. Issue lifecycle comments stay role-grained;
the `state` payload's `tasks` array stays current-only (no schema
change here — see [D10] and open question O1 in the final response).
The bundle is preserved through `plan-archive-migrate`, so the
per-task record survives plan closeout. Two views of the same plan
are intentional — lifecycle comments are role-grained for closeout
gating, the ledger is task-grained for execution history.

### D2 — Add `plan-tooling ledger-update` for one-call row updates

Introduce a new `plan-tooling` subcommand:

```text
plan-tooling ledger-update \
  --execution-state <path> \
  --task <id> \
  --status <status> \
  --evidence <text> \
  [--notes <text>] [--dry-run] [--format json|text]
```

Status values: `pending | in-progress | done | blocked | waived`.
Locate the row by exact `ID` column match; replace the `Status` cell;
append to `Evidence` with `;` as the separator when existing evidence
is non-empty; update `Notes` only when `--notes` is passed. The command
rewrites the Markdown file atomically (write-temp + rename) and
fails closed on missing row, ambiguous row, or malformed table. A
typed CLI removes the friction of hand-editing the Markdown table
mid-flight (column alignment, escaping, duplicate rows).

### D3 — Wire deliver / execute SKILL bodies to call `ledger-update`

Update `core/skills/dispatch/execute-plan-tracking-issue/SKILL.md.tera`
and `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`:
in the "Implementation" / "Lifecycle checkpoints" workflow steps,
prescribe `plan-tooling ledger-update --task <id> --status done
--evidence <PR ref | commit | smoke run>` as the closing action for
each task. Wording must be prescriptive ("after each task completes,
run …"), not optional, so the agent treats it as part of the
per-task contract. The CLI in [D2] only helps if the skill bodies
actually invoke it.

### D4 — Add `ledger-rows-pending` blocker to `tracking close-ready`

`plan-issue tracking close-ready` gains the blocker code
`ledger-rows-pending`. Fires when `phase ∈ {ready_for_close, closed}`
AND the run-state's `bundle` resolves to a plan directory containing
a `*-execution-state.md` with at least one task row whose `Status` is
`pending` or `in-progress`. Emit one blocker entry per stuck row:
`{code: "ledger-rows-pending", task_id, status, message,
suggested_unblock: "run plan-tooling ledger-update --task <id> --status
done --evidence <evidence>"}`. The blocker is propagated through
`tracking-checkpoint-live` failure-mode lists. The gate is the only
common chokepoint between "agent forgot to update" and "actual
closure".

### D5 — Closeout writes a final summary note via `tracking run update --note`

Update `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`
to require, immediately before `record close`, a final
`plan-issue tracking run update --note "<closing summary>"` call. The
note format should list tasks done, linked PR(s), and any deferred
follow-up. This appends one final `run_updated` event to
`events.jsonl` so a future reader of the run can recover both
bookend events (`run_started` at the top, the closing summary at the
bottom) without parsing the whole intermediate log. `events.jsonl`
already accepts free-form notes ([F10]), so this is purely a skill
wiring change.

### D6 — Add optional `plan-tooling ledger-sync --from-issue` helper

A read-mostly helper that takes the plan bundle directory and fetched
issue evidence (`--body-file <path> --comments-json <path>` or
`--fixture <dir>`) and produces a drift report cross-referencing every
`execution-state.md` ledger row against task-id mentions in the
issue's role payloads / closeout body. Default mode emits a JSON
drift report with `{task_id, ledger_evidence, issue_evidence, action:
"match"|"drift"|"missing"}`. With `--write`, patches the `Evidence`
column from the matched issue comment URL for `match` and `drift`
entries; default-empty `Evidence` cells take priority over
non-empty ones to avoid stomping hand-curated notes. When handing
off mid-flight or recovering after a missed `ledger-update`, this is
the cheapest reconciliation path.

### D7 — Document the plan-tracking handoff prompt pattern

Update the `conversation:handoff-session-prompt` skill body to
recommend, for plan-tracking continuations, bundling:

- the current `run-state.json` contents
- the last N (default 5) entries of `events.jsonl`
- the `execution-state.md` ledger rows whose `Status` is `pending` or
  `in-progress`
- the linked PR refs and the latest `state` lifecycle comment URL

so the next session resumes with full per-task context. The durable
bits already exist on disk and on the provider; the gap is that
handoff prompts today don't routinely include them.

### D8 — Bundles A + B ship together as one runtime-kit feature PR

Bundles A ([D2] + [D3] + [D4]) and B ([D5] + [D6] + [D7]) ship in
lock-step rather than split into two trackers. [D4] (`close-ready`
blocker) and [D3] (skill wiring) only function on top of [D2] (the
new CLI); shipping them out of order leaves `close-ready` blocking
with no remediation path. [D5], [D6], [D7] are small additions on the
same SKILL.md.tera files [D3] touches; folding them into one PR
avoids two rounds of golden re-render.

### D9 — Patch release: `plan-tooling` + `plan-issue-cli` 0.25.6 → 0.25.7

Lane 1 changes touch both crates ([D2] + [D6] land in `plan-tooling`;
[D4] lands in `plan-issue-cli`). Following the C rollout's policy
(release in lock-step), bump both to `0.25.7` in the same release
PR. No new flags break existing callers (only additive: new
subcommand + new optional blocker code). Patch bump matches semver.

### D10 — State payload `tasks` schema is unchanged in this rollout

The `state` payload's `tasks` array stays current-only (single entry
from the run-state's `selected_task`). Per-task durability is met by
the .md ledger ([D1]). Accumulating task history into the payload is
deferred — changing payload semantics risks regressing downstream
`record audit` callers and visible-completeness rendering, and the
ledger path closes the user-facing gap without that risk. The open
question of revisiting payload enrichment in a later rollout is
reported in the final response (response-only open question).

## Scope

- Lane 1 (`sympoies/nils-cli`):
  - `plan-tooling` crate gains `ledger-update` subcommand ([D2]).
  - `plan-tooling` crate gains `ledger-sync --from-issue` subcommand
    ([D6]) in the same release.
  - `plan-issue-cli` `tracking close-ready` controller gains the
    `ledger-rows-pending` blocker ([D4]); the controller resolves the
    plan bundle from the run-state's `bundle` field and parses the
    `execution-state.md` ledger via `plan-tooling`'s existing
    Markdown-aware utilities (no duplicate parser).
  - Rust tests cover the new branches per [R1.5] below.
  - `--live` clap doc-comment refresh on any affected controller.
- Lane 2 (`sympoies/nils-cli`): cut `0.25.7` patch release, update
  Homebrew tap formula, confirm `plan-issue --version` and
  `plan-tooling --version` on PATH.
- Lane 3 (`agent-runtime-kit`, single feature PR):
  - Bump `docs/source/nils-cli-surface.md` rows for `plan-tooling`
    (new `ledger-update`, `ledger-sync`) and `plan-issue-cli` (new
    `ledger-rows-pending` blocker on `close-ready`); bump CLI floor
    mention to `0.25.7`.
  - Wire
    `core/skills/dispatch/execute-plan-tracking-issue/SKILL.md.tera`
    and
    `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
    to call `plan-tooling ledger-update` after each task completes
    ([D3]).
  - Wire
    `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`
    to require a final `tracking run update --note <summary>` before
    `record close`; add the `ledger-rows-pending` blocker to the
    Failure-modes list ([D5]).
  - Update the `conversation:handoff-session-prompt` skill body to
    document the plan-tracking handoff dump pattern ([D7]).
  - Re-render Codex / Claude / shared goldens.
  - Add deterministic smoke probes
    `dispatch.plan-tracking-closeout-gate-ledger-pending` and
    `dispatch.plan-tracking-closeout-gate-ledger-clean`; register both
    in `tests/runtime-smoke/acceptance-matrix.yaml`.
  - No changes to `plan-archive-migrate` semantics.

## Non-Scope

- Changing the `state` payload `tasks` array schema to accumulate
  (see open question O1 in the final response).
- Dispatch-profile parity for the ledger path. Track separately if
  needed; this rollout focuses on the tracking profile.
- Retiring the `tracking-checkpoint-live-not-implemented` constant.
  Still deferred from the C rollout.
- Closing the broader `plan-issue-v3-surface-drift` heuristic-inbox
  entry.
- Adding `--live` to existing entrypoint `tracking checkpoint --post
  …` calls. Separate dry-run-by-default concern surfaced during C;
  track as its own inbox entry.
- Migrating the C plan bundle
  (`docs/plans/2026-05-28-tracking-checkpoint-live/`) into
  `agent-plan-archive`. User opted to skip apply this round; revisit
  independently.
- Backfilling issue #144's ledger or events.jsonl after the fact.
- Changing `plan-archive-migrate`'s file enumeration to inject
  reconstructed ledgers.

## Implementation Boundaries

- Lane 1 CLI changes are confined to `crates/plan-tooling/` (new
  subcommand modules) and `crates/plan-issue-cli/src/execute.rs` plus
  `crates/plan-issue-cli/src/commands/tracking.rs` for the new
  blocker. No new adapter API, no provider-side change.
- The `ledger-update` and `ledger-sync` commands MUST share
  `plan-tooling`'s existing Markdown table reader/writer utilities;
  no duplicate parser.
- `tracking close-ready`'s new blocker reads `bundle` from the
  run-state; if `bundle` is absent or unreadable, the blocker is
  skipped (not a hard failure) so legacy run-states keep working.
- Runtime-kit PR makes no code changes outside SKILL.md.tera files,
  the surface doc, regenerated goldens, the smoke `run.sh`, and the
  acceptance-matrix text. Goldens are regenerated, not hand-edited.
- The runtime-kit PR ships floor bump + skill-body wiring + new
  probes atomically so the documentation contract and the installed
  CLI floor never disagree on the same `main` (constraint inherited
  from the C rollout policy).
- Commit policy: `semantic-commit` only; no `Co-Authored-By: Claude …`
  trailer.
- PR delivery: `forge-cli pr deliver --kind feature` for the
  runtime-kit PR; raw `gh pr create` is blocked by hook.

## Requirements

### Lane 1 — `sympoies/nils-cli` implementation

- R1.1 Add the new subcommand:

  ```text
  plan-tooling ledger-update \
    --execution-state <path> \
    --task <id> \
    --status <status> \
    --evidence <text> \
    [--notes <text>] [--dry-run] [--format json|text]
  ```

  Status values: `pending | in-progress | done | blocked | waived`.
  Locate the row by exact `ID` column match; replace `Status`; append
  to `Evidence` with `;` as the separator when existing evidence is
  non-empty; update `Notes` only when `--notes` is passed. Rewrite
  the Markdown file atomically (write-temp + rename).
- R1.2 Fail with stable error codes: `ledger-row-not-found` (no
  matching task id), `ledger-table-malformed` (table shape does not
  match expected header), `ledger-task-id-ambiguous` (multiple
  matching rows).
- R1.3 Add the drift-reconciliation subcommand:

  ```text
  plan-tooling ledger-sync \
    --bundle <dir> \
    [--body-file <path> --comments-json <path> | --fixture <dir>] \
    [--write] [--format json|text]
  ```

  Without `--write`, emit a drift report listing `{task_id,
  ledger_evidence, issue_evidence, action}` per row, where `action`
  is one of `match` / `drift` / `missing`. With `--write`, patch the
  `Evidence` column from the matched issue URL for `match` and
  `drift` entries; default-empty `Evidence` cells take priority over
  non-empty cells to avoid stomping hand-curated notes.
- R1.4 Add `plan-issue tracking close-ready` blocker code
  `ledger-rows-pending`. Fires when `phase ∈ {ready_for_close,
  closed}` AND the run-state's `bundle` resolves to a plan directory
  containing `*-execution-state.md` with at least one task row whose
  `Status` is `pending` or `in-progress`. Emit one blocker per stuck
  row with `task_id`, `status`, and a `suggested_unblock` naming the
  `ledger-update` command. Skip the check silently when `bundle` is
  absent or unreadable so legacy run-states never regress.
- R1.5 Rust tests cover: (a) `ledger-update` patches an existing row;
  (b) `ledger-update` fails closed on missing row, ambiguous row,
  and malformed table; (c) `ledger-sync --fixture` reports drift
  correctly across `match` / `drift` / `missing`; (d) `close-ready`
  adds `ledger-rows-pending` only when both phase and ledger
  conditions hold; (e) `close-ready` skips silently when `bundle` is
  missing; (f) the new blocker survives serialization through the
  existing JSON envelope.
- R1.6 Bump `plan-tooling` and `plan-issue-cli` crate versions from
  `0.25.6` to `0.25.7` per workspace lock-step policy; update
  siblings as the workspace dictates.
- R1.7 No change to existing happy-path callers; non-`--live`
  `tracking close-ready` and ledgers without pending rows retain
  byte-identical output to `0.25.6`.

### Lane 2 — release

- R2.1 Bump workspace `plan-tooling` and `plan-issue-cli` from
  `0.25.6` to `0.25.7`; follow established release runbook.
- R2.2 Tag `v0.25.7`, update Homebrew tap formula.
- R2.3 Confirm `plan-issue --version` AND `plan-tooling --version`
  on PATH match `0.25.7`.

### Lane 3 — `agent-runtime-kit` PR

- R3.1 Update `docs/source/nils-cli-surface.md`: bump the
  `plan-tooling` row to mention `ledger-update` + `ledger-sync`; bump
  the `plan-issue-cli` row to mention `ledger-rows-pending` on
  `tracking close-ready`. Update the header `git describe --tags`,
  `Head commit`, and `Release` lines to `v0.25.7`.
- R3.2 Edit
  `core/skills/dispatch/execute-plan-tracking-issue/SKILL.md.tera`:
  in the lifecycle-checkpoint section, prescribe `plan-tooling
  ledger-update --task <id> --status <status> --evidence <evidence>`
  as the closing action for every task. Include a concrete example
  block matching the existing voice.
- R3.3 Edit
  `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`:
  same per-task prescription as R3.2; ensure step ordering aligns
  with `tracking run update --selected-task` so the ledger update
  follows phase transitions.
- R3.4 Edit
  `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`:
  require, immediately before `record close`, a final
  `plan-issue tracking run update --note "<closing summary>"` call.
  Summary must enumerate tasks done, linked PR(s), and any deferred
  follow-up. Add `ledger-rows-pending` to the Failure-modes list.
- R3.5 Edit the `handoff-session-prompt` skill
  (`core/skills/conversation/handoff-session-prompt/SKILL.md.tera`):
  add a "Plan-tracking handoff" subsection that documents the dump
  pattern from [D7].
- R3.6 Run `agent-runtime render --update-golden` and review the
  regenerated Codex / Claude / shared golden diff for unrelated
  drift before committing.
- R3.7 Add two new deterministic smoke probes in
  `tests/runtime-smoke/cases/dispatch/run.sh`:
  - `run_tracking_closeout_gate_ledger_pending_probe`: build a
    fixture with a plan bundle whose `execution-state.md` has 2
    rows `pending`, drive run-state to `ready_for_close`, expect
    `tracking close-ready --expect-visible` to refuse with
    `ready=false` and two `ledger-rows-pending` blocker entries.
  - `run_tracking_closeout_gate_ledger_clean_probe`: same scaffold
    with every row marked `done`, expect `ready=true, blockers=[]`.
  Register both rows in `tests/runtime-smoke/acceptance-matrix.yaml`
  as `dispatch.plan-tracking-closeout-gate-ledger-pending` and
  `dispatch.plan-tracking-closeout-gate-ledger-clean`.
- R3.8 Validate locally: `bash scripts/ci/all.sh` (positions 1-13)
  and `bash tests/runtime-smoke/run.sh --mode deterministic --domain
  dispatch` (must climb to 13/13). Commit via `semantic-commit`,
  open via `forge-cli pr deliver --kind feature`. PR body links the
  upstream `sympoies/nils-cli` PRs and the `v0.25.7` release tag.

## Acceptance Criteria

### Lane 1

- A1.1 `plan-tooling ledger-update --execution-state <path>
  --task "Task 3.1" --status done --evidence "PR#145 squash 28acb08"`
  rewrites only that row's `Status` and `Evidence` cells; the rest
  of the file is byte-identical except for the patched line.
- A1.2 `plan-tooling ledger-update` against a missing task id
  returns the stable error code `ledger-row-not-found` and exits
  non-zero; no file mutation.
- A1.3 `plan-issue tracking close-ready --expect-visible` against a
  fixture with `phase=ready_for_close` and a ledger row at `pending`
  reports `ready=false` with at least one `ledger-rows-pending`
  blocker carrying the correct `task_id`.
- A1.4 The same gate against a ledger with every row at `done`
  returns `ready=true, blockers=[]` (subject to the other existing
  gates).
- A1.5 `plan-tooling ledger-sync --bundle <dir> --fixture <dir>`
  produces a JSON drift report whose `entries[]` length equals the
  ledger row count; each entry's `action` is one of
  `match` / `drift` / `missing`.
- A1.6 New Rust tests under existing `tests/` layout cover the R1.5
  branches.

### Lane 2

- A2.1 `cargo publish --dry-run` (or the local equivalent) passes
  for `plan-tooling` and `plan-issue-cli` at `0.25.7`.
- A2.2 After tap bump and `brew upgrade`, both `plan-issue --version`
  and `plan-tooling --version` on PATH print `0.25.7`.

### Lane 3

- A3.1 `docs/source/nils-cli-surface.md` `plan-tooling` row mentions
  `ledger-update` and `ledger-sync`; `plan-issue-cli` row mentions
  `ledger-rows-pending` on `tracking close-ready`. The header is
  bumped to `v0.25.7`.
- A3.2 `execute-plan-tracking-issue/SKILL.md.tera`,
  `deliver-plan-tracking-issue/SKILL.md.tera`, and
  `plan-tracking-issue-closeout/SKILL.md.tera` each carry a concrete
  `ledger-update` / `tracking run update --note` example matching
  the existing voice.
- A3.3 Goldens regenerated via `agent-runtime render --update-golden`
  show only the expected SKILL.md.tera diff plus the propagation
  into Codex / Claude surfaces (no unrelated drift).
- A3.4 `bash tests/runtime-smoke/run.sh --mode deterministic
  --domain dispatch` passes with **13/13** cases (11 existing + the
  two new ledger probes).
- A3.5 `bash scripts/ci/all.sh` positions 1-13 pass.

## Validation Plan

- Lane 1: `cargo test -p plan-tooling -p plan-issue-cli`;
  `cargo fmt --all -- --check`; `cargo clippy --workspace -- -D
  warnings`; the user's `nils-cli` new-crate CI gates (rumdl fmt,
  third-party-artifacts, completion-asset-audit, Cargo.lock
  locked-build).
- Lane 2: per `sympoies/nils-cli` release runbook (tag, build, smoke
  release artifacts, bump tap, brew upgrade locally, version check).
- Lane 3: `bash scripts/ci/all.sh` (positions 1-13);
  `bash tests/runtime-smoke/run.sh --mode deterministic --domain
  dispatch`; `rumdl check` on every touched Markdown file.
- Cross-lane dogfood: this rollout's own tracking issue should
  exercise the new `ledger-update` workflow end-to-end. Every Lane 3
  task must call `ledger-update` immediately after completion so the
  tracker is the first plan to faithfully report per-task status
  through the new surface. As a regression check, optionally re-run
  the C tracking issue #144 closeout against the new gate in
  fixture mode to confirm `ledger-rows-pending` would have refused
  the original close.

## Risks and Guardrails

- **Bundle path resolution.** The run-state's `bundle` field is the
  trust anchor for the new `close-ready` blocker. Guardrail: skip
  silently when `bundle` is absent or unreadable so legacy
  run-states never regress; tests cover the silent-skip path
  (A1.3 negative).
- **Markdown table parsing fragility.** Hand-edited ledger tables
  may have non-canonical pipe alignment, embedded HTML, or escaped
  pipes in `Evidence`. Guardrail: `plan-tooling`'s existing Markdown
  reader is the only parser; new code reuses it. Tests cover
  malformed-table fail-closed (R1.5 b).
- **Ledger drift between sessions.** Two sessions touching the same
  plan bundle could race the ledger. Guardrail: `ledger-update`
  operates one row at a time and rewrites the file atomically
  (write-temp + rename); document that concurrent multi-session
  updates require external coordination (semantic-commit-style
  branch discipline).
- **`ledger-sync --write` could overwrite hand-curated Evidence.**
  Guardrail: default to dry-run; prefer empty `Evidence` cells when
  writing; document the destructive mode explicitly in skill
  references.
- **Closeout summary note shape can drift.** Guardrail: keep it
  free-form (no schema) since `events.jsonl` already accepts
  free-form notes; rely on the closeout skill body to prescribe
  content shape.
- **Goldens regenerate noise.** Same risk pattern as the C rollout.
  Guardrail: review the regenerated golden diff line by line; rebase
  to clean `main` and re-render if unrelated drift appears.
- **No backfill for #144.** The C plan bundle's ledger stays stale
  by design (post-merge, the bundle is locked). Guardrail: document
  this in the plan retention intent so future readers understand the
  bundle preserves the original closed-state record, not a
  retroactively-completed ledger.

## Retention Intent

Plan-source document for execution coordination. Cleanup-eligible
after all three lanes deliver and the resulting tracking issue
archives via `plan-archive-migrate`. Promote to a durable runbook
only if the per-task ledger contract becomes broadly referenced by
other skills — likely, since the contract touches three SKILL bodies
and adds a permanent CLI surface; revisit at closeout.

## Read First References

- Bundles edited in `agent-runtime-kit`
  (Source type: discussion-to-implementation-doc):
  - `core/skills/dispatch/execute-plan-tracking-issue/SKILL.md.tera`
  - `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
  - `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`
  - `core/skills/conversation/handoff-session-prompt/SKILL.md.tera`
- Surface contract and policy:
  - `docs/source/nils-cli-surface.md`
    (`plan-tooling` and `plan-issue-cli` rows)
- Smoke probe baselines:
  - `tests/runtime-smoke/cases/dispatch/run.sh`
    (existing closeout-gate probes + helpers for the new ledger
    probes)
  - `tests/runtime-smoke/acceptance-matrix.yaml`
- Concrete C-rollout evidence:
  - `docs/plans/2026-05-28-tracking-checkpoint-live/` (the C plan
    bundle; ledger rows preserved as `pending` for the record)
  - <https://github.com/graysurf/agent-runtime-kit/issues/144> (closed
    C tracking issue; `record audit` reports 7/7 roles)
  - `~/.local/state/plan-issue/out/plan-issue-delivery/graysurf__agent-runtime-kit/issue-144/runs/20260528T053735Z-issue-144/`
    (`run-state.json` + `events.jsonl`)
- Upstream implementation surface (Source type: source-code):
  - `crates/plan-tooling/src/` (host for `ledger-update` and
    `ledger-sync`)
  - `crates/plan-issue-cli/src/execute.rs`
    (`tracking close-ready` blocker hook)
  - `crates/plan-issue-cli/src/commands/tracking.rs`
    (`tracking close-ready` clap surface)

## Recommended Next Artifact

Generate `2026-05-28-plan-task-ledger-durability-plan.md` (single
plan with three sprints / sequenced lanes per Lane 1 / Lane 2 /
Lane 3 above), then open the tracking issue via
`create-plan-tracking-issue` in `graysurf/agent-runtime-kit`.
Cross-link the upstream `sympoies/nils-cli` implementation PR into
the tracking-issue run state via `tracking run update --linked-pr`
once Lane 1 lands. Dogfood the new `ledger-update` workflow on this
plan — every Lane 3 task should call `ledger-update` immediately
after completion so the tracker is the first faithful per-task
record under the new contract.
