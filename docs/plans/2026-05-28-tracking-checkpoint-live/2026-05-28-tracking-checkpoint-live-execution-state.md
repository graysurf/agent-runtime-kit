# Tracking Checkpoint Live (Part C) Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: not started; ready to implement
- Target scope: Sprint 1 upstream live posting (`sympoies/nils-cli`);
  Sprint 2 `plan-issue-cli` 0.25.6 release + tap bump; Sprint 3
  runtime-kit consumption PR (floor bump, fallback excision, golden
  re-render, happy-path probe, inbox archive)
- Execution window: Sprint 1 → Sprint 2 → Sprint 3 (serial; Sprint 3
  blocks on `plan-issue --version` on PATH = 0.25.6)
- Current task: none
- Next task: Task 1.1 — implement live posting in
  `run_tracking_checkpoint`
- Last updated: 2026-05-28
- Branch/commit/PR: feat/tracking-checkpoint-live; plan commit pending;
  PRs pending
- Source document: docs/plans/2026-05-28-tracking-checkpoint-live/2026-05-28-tracking-checkpoint-live-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: pending
- Source snapshot: pending
- Plan snapshot: pending
- Initial state snapshot: pending

## Validation Plan

- Sprint 1 (`sympoies/nils-cli`):
  - `cargo test -p plan-issue-cli` (existing suite plus new tests for
    dry-run / live / fixture / partial-post / repair-dashboard).
  - `cargo fmt --all -- --check` and `cargo clippy` clean before PR
    (prior CI failure on skipped `fmt` flagged in briefing).
  - Upstream CI lanes per the user's new-crate gate memory: rumdl fmt,
    third-party-artifacts, completion-asset-audit, Cargo.lock
    locked-build.
- Sprint 2:
  - `cargo publish --dry-run` (or upstream equivalent) passes for
    `plan-issue-cli@0.25.6`.
  - `plan-issue --version` on PATH prints `0.25.6` after tap bump +
    `brew upgrade`.
- Sprint 3 (`agent-runtime-kit`):
  - `rumdl check` on every touched Markdown file
    (`docs/source/nils-cli-surface.md`, both SKILL.md.tera files, both
    new doc files).
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain
    dispatch` — must reach 11/11 (10 existing + new
    `dispatch.plan-tracking-closeout-gate-happy-path`).
  - `bash scripts/ci/all.sh` positions 1-13 pass.
  - `heuristic-inbox verify
    tracking-closeout-review-state-complete-gap --strict` reports a
    valid archived record after `git mv` to `archive/2026/`.
- Cross-lane closeout proof: post a state checkpoint with
  `status=complete` on the tracking issue **through**
  `tracking checkpoint --live --post state` (no `record post`
  workaround); closeout preflight passes without manual prerequisite
  posting.

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | pending | Implement live posting in `run_tracking_checkpoint` | — | `sympoies/nils-cli`. Replace stub at `execute.rs:2044-2057`; iterate `rendered` in declaration order; abort-on-first-error; skip repair on partial failure. |
| 1.2 | pending | Fixture-mode parity for `--live` | — | `sympoies/nils-cli`. Synthesized URLs (`fixture://issue/<n>/<role>`) under `--fixture`; supports the runtime-kit happy-path smoke probe. Depends on 1.1. |
| 1.3 | pending | Tests, `--live` doc-comment refresh, version bump | — | `sympoies/nils-cli`. Branches (a)-(f) from plan; `Cargo.toml` 0.25.5 → 0.25.6; siblings lock-step. Depends on 1.1, 1.2. |
| 1.4 | pending | Open upstream PR against `sympoies/nils-cli` main | — | `sympoies/nils-cli`. Use forge-cli or active PR workflow; required upstream CI green. Depends on 1.3. |
| 2.1 | pending | Cut 0.25.6 release tag | — | `sympoies/nils-cli`. Per upstream release policy. Depends on 1.4 merged. |
| 2.2 | pending | Bump Homebrew tap formula | — | Homebrew tap. `plan-issue --version` on PATH = 0.25.6 after `brew upgrade`. Depends on 2.1. |
| 3.1 | pending | Bump `nils-cli-surface.md` plan-issue-cli row to v0.25.6 | — | `graysurf/agent-runtime-kit`. Move tracking surface out of vNext block. Depends on 2.2. |
| 3.2 | pending | Excise deliver fallback block + Open heuristic gap line | — | `graysurf/agent-runtime-kit`. `deliver-plan-tracking-issue/SKILL.md.tera` step 5 + bottom cross-ref. Depends on 3.1. |
| 3.3 | pending | Excise closeout fallback block + Open heuristic gap line | — | `graysurf/agent-runtime-kit`. `plan-tracking-issue-closeout/SKILL.md.tera` step 1 + bottom cross-ref; keep failure-modes scoping at 43-52. Depends on 3.1. |
| 3.4 | pending | Re-render Codex / Claude / shared goldens | — | `graysurf/agent-runtime-kit`. `agent-runtime render --update-golden`; review diff for unrelated drift. Depends on 3.2, 3.3. |
| 3.5 | pending | Add happy-path smoke probe + acceptance-matrix row | — | `graysurf/agent-runtime-kit`. New `run_tracking_closeout_gate_prereq_happy_path_probe`; row id `dispatch.plan-tracking-closeout-gate-happy-path`. Depends on 3.1. |
| 3.6 | pending | Promote inbox entry to `Status: promoted` + `git mv` to archive/2026/ | — | `graysurf/agent-runtime-kit`. Resolved subsection naming both PRs + plan-issue-cli@0.25.6. Depends on 1.4, 3.2, 3.3. |
| 3.7 | pending | Runtime-kit CI + deliver via `forge-cli pr deliver --kind feature` | — | `graysurf/agent-runtime-kit`. scripts/ci/all.sh positions 1-13; dispatch smoke 11/11; semantic-commit; forge-cli deliver. Depends on 3.1-3.6. |

## Session Log

- 2026-05-28: Authored this execution state alongside the plan and the
  shared discussion source. Preflight passed at session start
  (`agent-docs resolve --context startup` 4/4 present; `--context
  task-tools` 1/1 present). Confirmed key design decisions through
  reading: D1 (status derivation already implemented in
  `synthesize_state_payload` at `execute.rs:2151-2163`), D2 (one comment
  per role per taxonomy spec line 55), D3 (controller is
  profile-agnostic, so single upstream change fixes both profiles), D5
  (skill-body scope minimal per user confirmation), D6 (remove cross-ref
  lines per user confirmation), D7 (happy-path probe in C per user
  confirmation). User confirmed 0.25.6 patch bump. No implementation
  started; this state is prepared so `create-plan-tracking-issue` can
  open the tracker with a populated task ledger. Skill-usage envelope
  for the discussion source recorded at
  `/Users/terry/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260528-132615-skill-usage/skill-usage.record.json`
  (`ok=true, complete=true, status=pass`).

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `agent-docs resolve --context startup --strict --format checklist` | pass | 4/4 required docs present. | n/a |
| `agent-docs resolve --context task-tools --strict --format checklist` | pass | 1/1 required docs present. | n/a |
| `rumdl check docs/plans/2026-05-28-tracking-checkpoint-live/2026-05-28-tracking-checkpoint-live-discussion-source.md` | pass | No issues found. | n/a |

## Notes

- The plan's Sprint 1 + Sprint 2 `Location` entries point at
  `sympoies/nils-cli` paths; `plan-tooling` validates paths relative to
  `agent-runtime-kit`, so `nils-cli` file existence is not enforced by
  the bundle validator here. The implementation target is the
  `plan-issue-cli` crate under `sympoies/nils-cli`.
- Sprint 3 (Tasks 3.1-3.7) lands in `graysurf/agent-runtime-kit`; this is
  also where the tracking issue and this plan bundle live.
- The transitional fallback blocks were added by PR #143 (squash
  `f2fe7f5`) and the inbox entry was opened in the same session that
  closed `graysurf/agent-runtime-kit#135`. Both the deliver and closeout
  SKILL.md.tera bodies tag the fallback blocks as "remove once
  `tracking-checkpoint-live-not-implemented` resolves", which is the
  exact trigger Sprint 3 satisfies.
- The dispatch profile (`deliver-dispatch-plan`,
  `execute-plan-tracking-issue`) is fixed by the same upstream change
  (controller is profile-agnostic) but does NOT carry transitional
  fallback blocks; only the `tracking-checkpoint-live-not-implemented`
  Failure-modes propagation lines exist, and they stay in place because
  the non-`--live` controller path still emits the code (D5 rationale).
