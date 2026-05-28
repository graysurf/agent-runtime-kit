# Plan-Tracking Task Ledger Durability Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: ready-to-start; tracking issue not yet opened.
- Target scope: Sprint 1 upstream CLI in `sympoies/nils-cli`
  (`plan-tooling` `ledger-update` + `ledger-sync`, `plan-issue-cli`
  `tracking close-ready` `ledger-rows-pending` blocker, workspace
  `0.25.6 → 0.25.7` patch bump); Sprint 2 release tag + Homebrew tap
  bump; Sprint 3 runtime-kit consumption PR (surface-floor bump,
  ledger-update wiring + `--live` switchover in three tracking-profile
  SKILLs, handoff-prompt subsection, goldens re-render, two new
  ledger-aware smoke probes, CI + delivery).
- Execution window: Sprint 1 → Sprint 2 → Sprint 3 (serial; Sprint 3
  blocks on `plan-tooling --version` and `plan-issue --version` on
  PATH = `0.25.7`).
- Current task: none (tracking issue not yet opened).
- Next task: Task 1.1 — implement `plan-tooling ledger-update` in
  `sympoies/nils-cli`.
- Last updated: 2026-05-28
- Branch/commit/PR: tbd (Sprint 1 PR target: `sympoies/nils-cli` main;
  Sprint 2 release target: `sympoies/nils-cli` + `sympoies/homebrew-tap`;
  Sprint 3 PR target: `graysurf/agent-runtime-kit` main with branch
  prefix `feat/plan-task-ledger-durability`).
- Source document: docs/plans/2026-05-28-plan-task-ledger-durability/2026-05-28-plan-task-ledger-durability-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: tbd (to be opened by `create-plan-tracking-issue`
  against `graysurf/agent-runtime-kit`)
- Source snapshot: pending — posted by `create-plan-tracking-issue`
  at issue open
- Plan snapshot: pending — posted by `create-plan-tracking-issue` at
  issue open
- Initial state snapshot: pending — posted by
  `create-plan-tracking-issue` at issue open

## Validation Plan

- Sprint 1 (`sympoies/nils-cli`):
  - `cargo test -p plan-tooling -p plan-issue-cli` (new
    `ledger-update`, `ledger-sync`, and `ledger-rows-pending`
    branches).
  - `cargo fmt --all -- --check` and `cargo clippy --workspace --
    -D warnings` clean before PR open.
  - Upstream CI lanes per the user's new-crate gate memory: rumdl
    fmt, third-party-artifacts, completion-asset-audit, Cargo.lock
    locked-build.
- Sprint 2:
  - `cargo publish --dry-run` (or upstream equivalent) passes for
    both `plan-tooling@0.25.7` and `plan-issue-cli@0.25.7`.
  - `plan-tooling --version` AND `plan-issue --version` on PATH
    report `0.25.7` after tap formula bump + `brew upgrade`.
- Sprint 3 (`agent-runtime-kit`):
  - `rumdl check` on every touched Markdown file
    (`docs/source/nils-cli-surface.md`, four SKILL.md.tera files).
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain
    dispatch` must reach **13/13** (11 existing + two new ledger
    probes `dispatch.plan-tracking-closeout-gate-ledger-pending` and
    `dispatch.plan-tracking-closeout-gate-ledger-clean`).
  - `bash scripts/ci/all.sh` positions 1-13 pass.
- Cross-lane dogfood proof: every Sprint 3 task must populate its
  `execution-state.md` `Evidence` cell through `plan-tooling
  ledger-update`; the closing `tracking checkpoint --live --post
  state` proves the `--live` switchover is the default execution
  path. The closeout comment is preceded by a final
  `tracking run update --note "<closing summary>"` event in
  `events.jsonl` per [D5].

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | done | Implement `plan-tooling ledger-update` | sympoies/nils-cli#607 | `sympoies/nils-cli`. New subcommand module under `crates/plan-tooling/src/`. Reuses existing Markdown-aware table reader/writer. |
| 1.2 | done | Implement `plan-tooling ledger-sync --from-issue` | sympoies/nils-cli#607 | `sympoies/nils-cli`. Depends on 1.1 (shared reader/writer). Default emits drift report; `--write` honors empty-cell preference rule. |
| 1.3 | done | Add `ledger-rows-pending` blocker to `tracking close-ready` | sympoies/nils-cli#607 | `sympoies/nils-cli`. Depends on 1.1. Reads ledger via `plan-tooling`'s shared reader; silent-skip when `bundle` is absent. |
| 1.4 | done | Rust tests, stable error codes, version bump 0.25.6 → 0.25.7 | sympoies/nils-cli#607 | `sympoies/nils-cli`. Depends on 1.1, 1.2, 1.3. Covers all branches plus the new error codes `ledger-row-not-found`, `ledger-row-ambiguous`, `ledger-table-malformed`. |
| 1.5 | done | Open the upstream PR against `sympoies/nils-cli` main | https://github.com/sympoies/nils-cli/pull/607 (draft, awaiting CI) | `sympoies/nils-cli`. Depends on 1.4. forge-cli workflow; raw `gh pr create` blocked by hook. |
| 2.1 | done | Cut the `v0.25.7` tag | sympoies/nils-cli v0.25.7 release: https://github.com/sympoies/nils-cli/releases/tag/v0.25.7 | `sympoies/nils-cli`. Depends on 1.5 merged. Workspace lock-step release for both crates. |
| 2.2 | done | Bump the Homebrew tap formulas | sympoies/homebrew-tap nils-cli-v0.25.7 (commit 71c1f23); brew upgrade -> 0.25.7 verified on PATH | `sympoies/homebrew-tap`. Depends on 2.1. Both `plan-tooling` and `plan-issue-cli` formulas. |
| 3.1 | pending | Bump the surface-floor doc to `v0.25.7` |  | `graysurf/agent-runtime-kit`. Depends on 2.2 (released CLIs on PATH). |
| 3.2 | pending | Wire `execute-plan-tracking-issue` SKILL |  | `graysurf/agent-runtime-kit`. Depends on 3.1. Prescribes `plan-tooling ledger-update` + switches entrypoint `tracking checkpoint --post …` to `--live`. |
| 3.3 | pending | Wire `deliver-plan-tracking-issue` SKILL |  | `graysurf/agent-runtime-kit`. Depends on 3.1. Same wiring as 3.2; ledger-update follows the existing `tracking run update --selected-task` cadence. |
| 3.4 | pending | Wire `plan-tracking-issue-closeout` SKILL |  | `graysurf/agent-runtime-kit`. Depends on 3.1. Requires final `tracking run update --note <summary>` before `record close`; adds `ledger-rows-pending` to Failure-modes. |
| 3.5 | pending | Update `handoff-session-prompt` SKILL |  | `graysurf/agent-runtime-kit`. Depends on 3.1. Adds "Plan-tracking handoff" subsection per [D7]. |
| 3.6 | pending | Re-render Codex / Claude / shared goldens |  | `graysurf/agent-runtime-kit`. Depends on 3.2, 3.3, 3.4, 3.5. `agent-runtime render --update-golden`; review diff for unrelated drift. |
| 3.7 | pending | Add new deterministic smoke probes (ledger-pending + ledger-clean) |  | `graysurf/agent-runtime-kit`. Depends on 2.2. Two new rows in acceptance-matrix; dispatch domain climbs to 13/13. |
| 3.8 | pending | Runtime-kit CI + deliver via `forge-cli pr deliver --kind feature` |  | `graysurf/agent-runtime-kit`. Depends on 3.1-3.7. Dogfood `ledger-update` on this plan's own rows. |

## Session Log

- 2026-05-28: Authored this execution state alongside the plan after
  the framing discussion that folded Item 1 (`--live` switchover in
  tracking-profile entrypoints) from the C plan's Future Work into
  Sprint 3 of this rollout. Items 2 (`plan-issue-v3-surface-drift`)
  and 3 (`tracking-checkpoint-live-not-implemented` constant
  retirement) deliberately remain in this plan's Future Work because
  the audit conducted during framing showed the constant is still
  referenced in five active SKILL.md.tera Failure-modes blocks plus
  smoke comments plus a spec doc — retirement needs its own
  coordinated PR. Pre-open preflight: `agent-docs resolve --context
  project-dev --strict --format checklist` → 2/2 present;
  `plan-tooling validate` → green after `Open questions carried into
  execution: none` line fix. No implementation started; this state
  is prepared so `create-plan-tracking-issue` can open the tracker
  with a populated task ledger.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `agent-docs resolve --context project-dev --strict --format checklist` | pass | 2/2 required docs present. | n/a |
| `plan-tooling validate --file <plan>` | pass | No issues reported after `Open questions carried into execution` line normalized. | n/a |
| `rumdl check docs/plans/2026-05-28-plan-task-ledger-durability/2026-05-28-plan-task-ledger-durability-plan.md` | pass | No issues found. | n/a |

## Notes

- The plan's Sprint 1 + Sprint 2 `Location` entries point at
  `sympoies/nils-cli` paths; `plan-tooling validate` enforces bundle
  paths relative to `agent-runtime-kit`, so `nils-cli` file existence
  is not enforced by the bundle validator here. The implementation
  target is the `plan-tooling` + `plan-issue-cli` crates under
  `sympoies/nils-cli`.
- Sprint 3 (Tasks 3.1-3.8) lands in `graysurf/agent-runtime-kit`;
  this is also where the tracking issue and this plan bundle live.
- Item 1 (`--live` switchover) folded into Tasks 3.2 and 3.3 of this
  rollout because the audit showed only two active entrypoint
  `tracking checkpoint --post …` sites inside the tracking-profile
  SKILLs (`deliver-plan-tracking-issue:33,35,119` and
  `execute-plan-tracking-issue:35`). Dispatch-profile parity
  (notably `review-dispatch-lane-pr:93`) remains a separate
  follow-up.
- Item 3 (`tracking-checkpoint-live-not-implemented` constant
  retirement) is documented as Future Work in the plan and is larger
  than the C plan implied: removal requires coordinated edits across
  five active SKILL.md.tera Failure-modes blocks, two smoke-test
  comment blocks, the `plan-issue-skill-family-redesign-v1.md` spec,
  and every corresponding golden, in addition to the upstream CLI
  constant. Open as a dedicated tracking issue once another agent
  or session needs the failure-mode mention removed.
- This plan is the first to dogfood the `plan-tooling ledger-update`
  contract: every Sprint 3 task is expected to write its `Evidence`
  cell back via the new CLI immediately after completion, proving the
  flow end-to-end before the runtime-kit PR closes.
