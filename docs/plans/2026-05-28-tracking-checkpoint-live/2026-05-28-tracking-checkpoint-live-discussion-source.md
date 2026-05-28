# Tracking Checkpoint Live Implementation Handoff

- Status: ready for plan generation
- Date: 2026-05-28
- Source: user-driven design session for "Part C" of the lifecycle-role
  ownership fix between `dispatch:deliver-plan-tracking-issue` and
  `dispatch:plan-tracking-issue-closeout`. Parts A + B landed in
  `graysurf/agent-runtime-kit` PR #143 (squash `f2fe7f5`); this document
  carries the canonical write-path fix and the cleanup that promotes the
  inbox entry.
- Intended next step: generate the single-plan bundle under
  `docs/plans/2026-05-28-tracking-checkpoint-live/`, then open the tracking
  issue via `create-plan-tracking-issue`. This is a source artifact, not an
  implementation plan.

## Execution

This document feeds **one** plan executed in three sequential lanes
(upstream implementation → upstream release → runtime-kit consumption).

- Recommended plan: docs/plans/2026-05-28-tracking-checkpoint-live/2026-05-28-tracking-checkpoint-live-plan.md
- Recommended execution state: docs/plans/2026-05-28-tracking-checkpoint-live/2026-05-28-tracking-checkpoint-live-execution-state.md
- Status: ready to implement immediately; Lane 1 (upstream CLI) blocks
  Lanes 2 + 3.
- Next-task source: this document.

## Purpose

`plan-issue tracking checkpoint --live` is the canonical write surface for
lifecycle comments in the lightweight tracking workflow and, by inheritance,
for dispatch-level orchestrator evidence. Today the controller refuses
every `--live` invocation with the blocked code
`tracking-checkpoint-live-not-implemented` ([F4]). To meet the strict
`tracking close-ready` gate, single-author tracking closeouts have had to
exit the deliver skill, hand-post `record post --kind review` plus
`record post --kind state` (`status=complete`), refresh the dashboard, then
return to closeout ([F2] §Current Workaround). PR #143 documented that
workaround as a transitional fallback inside both deliver and closeout skill
bodies and locked a deterministic refusal-side smoke probe
(`dispatch.plan-tracking-closeout-gate`) over the gate's blocker contract
([F1], [F12]).

Part C closes the gap at the source:

1. Implement live posting in `plan-issue-cli` so `tracking checkpoint
   --live` actually mutates the provider, reusing the same internal hop
   that `record post` already uses ([F6], [F9]).
2. Cut a `sympoies/nils-cli` patch release that ships the working surface.
3. Bump the runtime-kit floor, excise the transitional `record post`
   fallback blocks from both skill bodies, regenerate goldens, add the
   happy-path smoke probe, and promote/archive the inbox entry.

After C, the canonical surface (`tracking checkpoint --live --post …`) and
the documented skill bodies agree on a single live write path. Both the
tracking and dispatch profiles benefit from one upstream change because the
controller is profile-agnostic ([F10]).

## Confirmed Facts

- [U1] The user authorized C after A + B with the explicit instruction
  "等等要做c的設計 所以在做ab時記得不要做跟c衝突的事" (do not introduce
  anything that conflicts with C while landing A + B).
- [U2] The user resolved four bottleneck decisions in this session:
  release cadence = 0.25.6 patch; skill-body scope = minimal (only the two
  transitional fallback blocks); cross-references = remove the
  `Open heuristic gap` lines entirely; happy-path probe = add in C.
- [F1] PR #143 squash `f2fe7f5` ("docs(skills): align deliver/closeout
  prerequisite ownership") landed A + B on 2026-05-28. Branch `main` is at
  `f2fe7f5`, clean, in sync with `origin/main`.
- [F2] Inbox entry
  `core/policies/heuristic-system/error-inbox/tracking-closeout-review-state-complete-gap/ENTRY.md`
  (severity medium, status open) defines the gap, records the transitional
  mitigation, ties promotion to the `tracking-checkpoint-live-not-implemented`
  fix, and lists the closeout that hit it
  (`#135#issuecomment-4560851379`). Promotion criteria #1 maps directly to
  C: "`deliver-plan-tracking-issue`'s skill body explicitly owns posting the
  final `state=complete` (and, for single-author plans, the `review`
  approval) as part of its close-ready handoff."
- [F3] The transitional fallback blocks exist at:
  `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera` Workflow
  step 5 (lines 131-152) and
  `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera` Workflow
  step 1 (lines 99-117). Both blocks are explicitly demarcated as "remove
  once `tracking-checkpoint-live-not-implemented` resolves" and link the
  inbox entry.
- [F4] Upstream live-mode stub:
  `sympoies/nils-cli/crates/plan-issue-cli/src/execute.rs` lines 2044-2057
  unconditionally appends
  `{"code": "tracking-checkpoint-live-not-implemented", "message": "live
  tracking checkpoint posting will arrive in Task 6.1", …}` to the response's
  `blocked` array whenever `args.live` is true. The rendering pipeline above
  the stub (lines 1902-2042) is already complete: it loads run state,
  reconciles against issue truth, synthesizes per-role payloads, renders
  comment bodies through `lifecycle_record::render_record_post_comment_with_display`,
  applies visible-completeness lint, and writes rendered bodies under
  `rendered/`. Only the live posting hop is absent.
- [F5] Run-state → state payload mapping is already implemented in
  `synthesize_state_payload` at `execute.rs:2151-2163`. The mapping is:
  `phase ∈ {ReadyForClose, Closed}` → `status=complete` and ledger
  `task_status=done`; `phase=Blocked` → `status=blocked` and ledger
  `task_status=blocked`; any other phase → `status=in-progress` and ledger
  `task_status=in-progress`. The agent updates phase via `tracking run
  update --phase ready_for_close`; the controller derives `status=complete`
  with no additional flag.
- [F6] `record post` live posting path
  (`execute.rs:1094-1108`) is the reuse target. After rendering the body, it
  calls `resolve_repo_info_for_live` → `provider::select_adapter` →
  `write_temp_markdown` → `adapter.comment_issue(&repo, issue_number,
  &comment_path)`, returning the provider comment URL. Fixture mode at
  lines 1066-1079 returns a simulated `{mode: "fixture", dry_run: true,
  comment_url: null}` payload without provider mutation.
- [F7] `plan-issue-cli` workspace version is `0.25.5`
  (`crates/plan-issue-cli/Cargo.toml:3`; sibling crates also at `0.25.5`).
  The next release on this surface is `0.25.6`.
- [F8] `docs/source/plan-issue-redesign/plan-tracking-issue-comment-taxonomy-v1.md`
  Design Principle line 55: "One lifecycle role means one comment template."
  Line 89 inventory: `state` is owned by `tracking checkpoint /
  record post --kind state`. Line 119 controller rule: "The same role
  templates apply whether the body is rendered by `tracking checkpoint` or
  lower-level `record post`." Line 315 state payload `status` enum:
  `in-progress | complete | blocked`. Line 340 posting policy: "Post a
  final expanded state before closeout."
- [F9] `docs/source/plan-issue-redesign/plan-tracking-issue-run-state-controller-v1.md`
  §"Proposed CLI Surface → `plan-issue tracking checkpoint`" line 358-359:
  "In live mode, call the same internal path as `record post`, then repair
  the dashboard if requested." Implementation Sequence (`plan-tracking-issue-cli-redesign-v1.md`
  step 7, around line 523): "Add `tracking checkpoint --dry-run`, then live
  checkpoint posting" — C delivers the second half.
- [F10] Controller is profile-agnostic. `TrackingCheckpointArgs.profile:
  RecordProfile` defaults to `Tracking`
  (`commands/tracking.rs:200-202`). Dispatch-profile skills
  `deliver-dispatch-plan/SKILL.md.tera` (line 62) and
  `execute-plan-tracking-issue/SKILL.md.tera` (line 51) propagate
  `tracking-checkpoint-live-not-implemented` as a controller refusal code
  but carry no transitional `record post` fallback block.
  `dispatch-plan-closeout/SKILL.md.tera` references neither the refusal
  code nor any fallback; it stays untouched in C.
- [F11] `core/policies/heuristic-system/HEURISTIC_SYSTEM.md` compression
  rule: "After a gap is fixed, validated, and has no remaining next
  action, keep its status as `promoted` or `wontfix` and move the entry
  under `error-inbox/archive/YYYY/`." The archive directory
  `core/policies/heuristic-system/error-inbox/archive/` already exists.
- [F12] Refusal-side smoke probe
  `run_tracking_closeout_gate_prereq_blockers_probe`
  (`tests/runtime-smoke/cases/dispatch/run.sh` lines 537-581) asserts
  `tracking close-ready --expect-visible` returns `ready=false` with
  blockers `review-missing` AND `state_complete-missing` against a fixture
  that drops `role=review` and downgrades `role=state` payload `status`
  from `complete` to `in-progress`. Its inline comment (lines 545-547)
  explicitly states the probe "Stays valid through the
  `tracking-checkpoint-live-not-implemented` fix in `sympoies/nils-cli`
  because that fix changes the posting path, not the gate's blocker codes."
- [F13] `docs/source/nils-cli-surface.md` plan-issue-cli row currently
  notes "**vNext (pending the next nils-cli release):** … the `tracking`
  controller surface (`tracking status`, `tracking run init`, `tracking
  run update`, `tracking checkpoint`, `tracking close-ready`) backed by
  `plan-issue.execution-run.v1` run state and `plan-issue.execution-event.v1`
  events." Floor bump moves this content from "vNext" to "as of `v0.25.6`".
- [I1] Live posting is small to implement because the rendering pipeline
  is already complete ([F4]) and the per-role posting hop already exists
  as a reusable code path ([F6]). The change is one loop and one branch in
  `run_tracking_checkpoint`.
- [I2] The happy-path smoke probe is feasible without provider mutation
  because `record post` already supports fixture mode ([F6] lines
  1066-1079), and `TrackingCheckpointArgs` carries `fixture: Option<PathBuf>`
  (`commands/tracking.rs:215-217`). The same convention extends to live
  mode: when `--fixture` is set, `--live` should return a simulated
  `mode=fixture` payload with synthesized URLs and no provider hit.

## Decisions

### D1 — Run-state → `state.status=complete` derivation reuses the existing rule

The controller derives `state.status=complete` from `run.phase ∈
{ReadyForClose, Closed}` ([F5]). No new `--status` flag is introduced; no
auto-derivation from `tasks-done + validation-pass + review-approve` is
added. Skill bodies must call `tracking run update --phase ready_for_close`
before the final `tracking checkpoint --live --post state,review`. This
keeps run state as the single source of "what to post" and preserves the
deterministic mapping documented in the controller and taxonomy specs
([F8], [F9]).

### D2 — One comment per role; `--post state,review` emits two comments

Per the taxonomy spec ([F8] line 55) and the existing rendering loop
([F4]), each role renders into its own comment body. C must not introduce
a combined comment shape; `tracking checkpoint --live --post state,review`
iterates over the rendered entries and calls `adapter.comment_issue` once
per role, mirroring `record post` semantics. The response gains a
`posted: [{role, comment_url}]` array (one entry per actually-posted role)
on top of the existing `rendered`/`roles_planned`/`roles_skipped` arrays.

### D3 — Dispatch profile fixed by same upstream change; no parallel CLI work

Because the controller is profile-agnostic ([F10]), the C upstream change
fixes both `--profile tracking` and `--profile dispatch` simultaneously.
Skill-body cleanup for dispatch profile is **out of scope for C**:
`deliver-dispatch-plan` and `execute-plan-tracking-issue` already
propagate the refusal code but carry no transitional fallback block, and
their entrypoint `tracking checkpoint --post …` invocations (which today
default to dry-run since `--live` is false) are left as-is. This keeps C
focused on the inbox-entry promotion criteria ([F2]) and avoids entangling
the wider dry-run-by-default workflow concern.

### D4 — `plan-issue-cli` 0.25.6 patch bump

The `--live` flag already exists at `0.25.5` ([F7]); C removes the
rejection and starts posting. No new flag, no behavioral change for
non-`--live` callers, no breaking surface change. A patch bump is the
correct semver scope.

### D5 — Skill-body scope: replace only the two transitional fallback blocks

In C, the only skill-body edits in the *tracking* family are:

- `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
  Workflow step 5 (current lines 131-152): replace the transitional
  `record post` block with the canonical `tracking checkpoint --live
  --post state,review --repair-dashboard` invocation against the
  run state updated to `phase=ready_for_close` and `review_decision`.
- `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`
  Workflow step 1 (current lines 99-117): replace the parallel
  transitional `record post` block with the same canonical invocation
  for preflight repair.

The Failure-modes scoping in closeout (lines 43-52) — which scopes
`forbidden-role-for-skill` to writes "after `record close` succeeds" and
keeps preflight repair in-scope — stays correct post-C; that is a
defensive contract, not transitional. The Failure-modes propagation of
`tracking-checkpoint-live-not-implemented` in deliver, closeout, execute,
and deliver-dispatch-plan stays because the non-`--live` controller path
still emits it for older callers.

### D6 — Remove the `Open heuristic gap` cross-reference lines

After promotion the inbox entry archives to
`core/policies/heuristic-system/error-inbox/archive/2026/tracking-closeout-review-state-complete-gap/`
([F11]). The "Open heuristic gap" lines at the bottom of
`deliver-plan-tracking-issue/SKILL.md.tera` (lines 187-189) and
`plan-tracking-issue-closeout/SKILL.md.tera` (lines 164-167) are removed
entirely in C. Historical context is preserved in the archived entry, the
C PR description, and the C tracking issue.

### D7 — Add a happy-path smoke probe sibling to the refusal-side gate probe

Add `dispatch.plan-tracking-closeout-gate-happy-path` next to the existing
refusal-side probe in `tests/runtime-smoke/cases/dispatch/run.sh`. The new
probe runs `tracking checkpoint --live --fixture <dir> --post state,review
--repair-dashboard` against a starting fixture missing `role=review` and
carrying `role=state` `status=in-progress`, then re-runs `tracking
close-ready --expect-visible` against the **post-checkpoint** comments and
asserts `ready=true` with `blockers: []`. The acceptance-matrix row to add
is `dispatch.plan-tracking-closeout-gate-happy-path`. The existing
refusal-side probe stays unchanged; together they lock both halves of the
gate contract.

Fixture-mode live posting (D2 implementation detail) is the mechanism that
makes this probe deterministic without provider mutation ([I2]).

## Scope

- Lane 1 (sympoies/nils-cli): implement live posting inside
  `run_tracking_checkpoint`; update the `--live` clap doc-comment; add
  Rust tests covering the dry-run / live / fixture branches and visible
  failure paths; ship a PR against `sympoies/nils-cli` main.
- Lane 2 (sympoies/nils-cli): cut release `0.25.6` (patch), update the
  Homebrew tap formula, confirm `plan-issue --version` on PATH matches.
- Lane 3 (agent-runtime-kit, single feature PR): bump
  `docs/source/nils-cli-surface.md` plan-issue-cli row to note `v0.25.6`
  ships live `tracking checkpoint --live`; rewrite the two transitional
  fallback blocks in the SKILL.md.tera files per D5; remove the
  cross-reference lines per D6; re-render Codex / Claude / shared
  goldens; add the happy-path probe per D7; promote the inbox entry to
  `Status: promoted` and move it under
  `error-inbox/archive/2026/`; update `plan-issue-v3-surface-drift` only
  if any of its affected-skills bullets are materially resolved by C.

## Non-Scope

- Adding `--live` to existing entrypoint `tracking checkpoint --post …`
  calls in deliver / execute / deliver-dispatch-plan (the
  dry-run-by-default workflow gap). Tracked as a separate concern; not
  required for the inbox-entry promotion.
- Refactoring `synthesize_state_payload` or the run-state schema.
- Touching `record post`'s public surface or behavior.
- Closing the broader `plan-issue-v3-surface-drift` entry (high severity);
  C does not retire the transitional helpers listed there.
- Dispatch-profile transitional fallbacks (none exist; nothing to remove).
- Background sync, auto-refresh, or any change to provider-fetch policy.
- Changing the `tracking-checkpoint-live-not-implemented` code itself; it
  stays as the blocked code for non-`--live` invocations to preserve the
  contract for callers that intentionally request the rejection.

## Implementation Boundaries

- Upstream code change is confined to
  `sympoies/nils-cli/crates/plan-issue-cli/src/execute.rs`
  (`run_tracking_checkpoint` and helpers) and the `--live` doc-comment in
  `crates/plan-issue-cli/src/commands/tracking.rs`. The live posting path
  reuses `provider::select_adapter` and `adapter.comment_issue` exactly as
  `run_record_post` does; no new adapter API is introduced.
- Fixture mode in live posting returns the same shape `record post`
  returns under `--fixture` (synthesized URLs, `mode: "fixture"`,
  `dry_run: true`).
- Runtime-kit PR makes **no** code changes outside SKILL.md.tera files,
  the surface doc, the goldens regenerated by `agent-runtime render
  --update-golden`, the smoke run.sh, the acceptance-matrix text, and the
  inbox entry move + Status update.
- Goldens for Codex/Claude/shared targets are regenerated, not
  hand-edited.
- The runtime-kit PR ships floor bump + skill-body cleanup + probe
  addition + inbox promotion **atomically** so the documentation contract
  and the installed CLI floor never disagree on the same `main` (briefing
  constraint).

## Requirements

### Lane 1 — `sympoies/nils-cli` implementation

- R1.1 Replace the stub at `execute.rs:2044-2057`. When `args.live` is
  true AND `blocked.is_empty()` AND every rendered role passed visible
  lint, iterate over `rendered` and post each role through the
  `record post` live hop (`resolve_repo_info_for_live` →
  `provider::select_adapter` → `write_temp_markdown` →
  `adapter.comment_issue`). Capture the returned URL per role.
- R1.2 When `args.fixture` is set, skip the adapter call and emit
  synthesized fixture URLs (e.g. `fixture://issue/<n>/role/<role>`) so
  the probe in R3.4 is deterministic; mark `mode: "fixture"` in the
  response.
- R1.3 After all roles post, if `args.repair_dashboard` is true and
  posting succeeded, call the existing record-repair-dashboard live path
  with the same repo / issue / adapter; capture its result under
  `repair_dashboard_result`.
- R1.4 Augment the JSON response with a `posted: [{role, comment_url}]`
  array, flip `mode` to `"live"` (or `"fixture"` per R1.2), and remove
  the `tracking-checkpoint-live-not-implemented` blocked code from the
  `--live` path. Preserve the existing emission on the non-`--live`
  path (default dry-run).
- R1.5 Update the `--live` clap doc-comment in
  `commands/tracking.rs:227-231` to remove "Task 6.1; until then…" and
  document the new behavior (live posting; one comment per `--post` role;
  optional `--repair-dashboard`).
- R1.6 Tests cover: (a) `--live --fixture <dir>` → fixture mode returns
  `posted` entries with synthesized URLs and no adapter call; (b)
  `--live` without provider (forced binary mismatch) returns the existing
  usage error; (c) visible-completeness failure on any rendered role
  short-circuits before posting; (d) `--post state,review` posts exactly
  two comments; (e) `--repair-dashboard` after a successful post triggers
  the repair path. Use existing test scaffolding for `record post` /
  `tracking checkpoint --dry-run` as the template.
- R1.7 No change to the `tracking checkpoint --dry-run` path; the only
  branch added is the `args.live` true-and-clean path inside the
  existing function.

### Lane 2 — release

- R2.1 Bump workspace crate `plan-issue-cli` from `0.25.5` to `0.25.6`
  per upstream policy (`sympoies/nils-cli`). If the workspace publishes
  sibling crates in lock-step, follow the established cadence; otherwise
  bump only `plan-issue-cli`.
- R2.2 Tag the release and update the Homebrew tap formula to track
  `0.25.6`.
- R2.3 Confirm `plan-issue --version` on PATH (post-tap-bump) matches
  `0.25.6`.

### Lane 3 — `agent-runtime-kit` PR

- R3.1 Update `docs/source/nils-cli-surface.md` plan-issue-cli row: move
  the `tracking checkpoint` surface description out of the "vNext" block
  into a "As of `v0.25.6`" sentence; explicitly note that
  `tracking checkpoint --live --post <roles> --repair-dashboard` posts
  live lifecycle comments and the dashboard repair.
- R3.2 Edit
  `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
  Workflow step 5: remove the transitional fallback block (current lines
  131-152) and replace it with the canonical `tracking checkpoint --live`
  invocation against an updated run state (`tracking run update --phase
  ready_for_close --review-decision <decision>` then `tracking checkpoint
  --live --post state,review --repair-dashboard`). Remove the
  `Open heuristic gap` cross-reference line block at the bottom (lines
  187-189).
- R3.3 Edit
  `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`
  Workflow step 1: remove the transitional fallback block (current lines
  99-117) and replace it with `tracking checkpoint --live --post
  review,state --repair-dashboard` for preflight repair when blockers are
  `review-missing` / `state_complete-missing`. Keep the Failure-modes
  scoping at lines 43-52 verbatim (defensive contract). Remove the
  `Open heuristic gap` cross-reference line block at the bottom (lines
  164-167).
- R3.4 Add `run_tracking_closeout_gate_prereq_happy_path_probe` next to
  `run_tracking_closeout_gate_prereq_blockers_probe` in
  `tests/runtime-smoke/cases/dispatch/run.sh`. The probe must:
  (a) build a starting fixture missing `role=review` and carrying
  `role=state` `status=in-progress` (reuse
  `write_missing_review_state_complete_comments_json`);
  (b) invoke `plan-issue tracking checkpoint --live --fixture <dir>
  --profile tracking --post state,review --repair-dashboard` with a run
  state whose `phase=ready_for_close` and `review.decision=approve`;
  (c) write the rendered post bodies back into the fixture's
  `comments.json` and dashboard;
  (d) run `plan-issue tracking close-ready --expect-visible` against the
  updated fixture and assert `ready=true` with `blockers: []`.
- R3.5 Register the new probe in the acceptance matrix with the row id
  `dispatch.plan-tracking-closeout-gate-happy-path`.
- R3.6 Re-render Codex / Claude / shared targets via
  `agent-runtime render --update-golden`; check the regenerated goldens
  for unrelated diff drift before committing.
- R3.7 Promote the inbox entry: set `Status: promoted` in
  `core/policies/heuristic-system/error-inbox/tracking-closeout-review-state-complete-gap/ENTRY.md`,
  add a "Resolved" subsection naming the Lane 1 nils-cli PR + the
  runtime-kit PR + the released `plan-issue-cli` version, then `git mv`
  the directory to
  `core/policies/heuristic-system/error-inbox/archive/2026/tracking-closeout-review-state-complete-gap/`.
- R3.8 If `plan-issue-v3-surface-drift/ENTRY.md` lists `tracking
  checkpoint` retired-helper traffic as an affected item that C resolves,
  update its Status section accordingly. Otherwise leave it open
  (severity high; broader scope than C).
- R3.9 Optionally update `execute-plan-tracking-issue/SKILL.md.tera` and
  `deliver-dispatch-plan/SKILL.md.tera` to drop
  `tracking-checkpoint-live-not-implemented` from their Failure-modes
  lists **only** if the non-`--live` controller path stops emitting it
  upstream. By default keep the propagation (D5 rationale).

## Acceptance Criteria

### Lane 1

- A1.1 `plan-issue tracking checkpoint --live --post state,review
  --fixture <dir>` against a run state with `phase=ready_for_close` and
  `review.decision=approve` returns `mode="fixture"`, `posted` with two
  entries (one per role), no `tracking-checkpoint-live-not-implemented`
  in `blocked`.
- A1.2 The same invocation without `--live` (default dry-run) still
  emits the rendered bodies under `rendered/` and **does not** include
  the `posted` array; behavior is byte-identical to `0.25.5` on this
  path.
- A1.3 The `tracking-checkpoint-live-not-implemented` constant remains
  defined and reachable in the codebase so any future regression that
  reintroduces a refusal branch on the `--live` path keeps emitting the
  same stable code. This is documented intent rather than a runtime gate
  (no current invocation path emits it after C).
- A1.4 Visible-completeness failure on any rendered role short-circuits
  before any `adapter.comment_issue` call.
- A1.5 Rust tests added under existing `tests/` layout cover R1.6
  scenarios.

### Lane 2

- A2.1 `cargo publish --dry-run` (or the local equivalent) passes for
  `plan-issue-cli` at `0.25.6`.
- A2.2 After tap bump and `brew upgrade`, `plan-issue --version` on PATH
  prints `0.25.6`.

### Lane 3

- A3.1 `docs/source/nils-cli-surface.md` plan-issue-cli row mentions
  `v0.25.6` and live `tracking checkpoint --live` (no "vNext" reference
  remains for tracking-controller live posting).
- A3.2 Neither `deliver-plan-tracking-issue/SKILL.md.tera` nor
  `plan-tracking-issue-closeout/SKILL.md.tera` contains the string
  `tracking-checkpoint-live-not-implemented` (the transitional fallback
  block is fully removed; the closeout Failure-modes scoping stays).
- A3.3 Neither skill body links the inbox-entry path. Both bodies are
  self-contained and survive the inbox archive move.
- A3.4 Goldens regenerated via `agent-runtime render --update-golden`
  show only the expected SKILL.md.tera diff plus expected propagations
  into rendered Codex/Claude surfaces (no unrelated drift).
- A3.5 `bash tests/runtime-smoke/run.sh --mode deterministic --domain
  dispatch` passes with **11/11** cases (10 existing + 1 new
  happy-path), including the unchanged
  `dispatch.plan-tracking-closeout-gate` refusal probe.
- A3.6 `bash scripts/ci/all.sh` positions 1-13 pass.
- A3.7 The inbox entry directory now lives at
  `core/policies/heuristic-system/error-inbox/archive/2026/tracking-closeout-review-state-complete-gap/`
  with `Status: promoted` and a Resolved subsection naming both PRs +
  `plan-issue-cli@0.25.6`. `heuristic-inbox verify
  tracking-closeout-review-state-complete-gap --strict` reports the
  entry as a valid archived record.

## Validation Plan

- Lane 1: `cargo test -p plan-issue-cli` (full crate test suite plus the
  R1.6 additions); `cargo fmt --all -- --check` and `cargo clippy` before
  PR (briefing flagged a prior CI failure on skipped `fmt`).
- Lane 2: per `sympoies/nils-cli` release runbook (tag, build, smoke
  release artifacts, bump tap, brew upgrade locally, version check).
- Lane 3: `bash scripts/ci/all.sh` (positions 1-13), `bash
  tests/runtime-smoke/run.sh --mode deterministic --domain dispatch`,
  `heuristic-inbox verify tracking-closeout-review-state-complete-gap
  --strict`, plus `rumdl` on the new + edited Markdown.
- Cross-lane: after Lane 3 merges, run
  `/plan-tracking-issue-closeout` and `/plan-archive-migrate` on the C
  tracking issue. Closeout preflight should succeed **without** the
  manual `record post` workaround — proof that C closed the gap.

## Risks and Guardrails

- **Live posting could partially succeed.** If `adapter.comment_issue`
  succeeds for `state` but fails for `review` (or vice versa), the issue
  ends up in an inconsistent half-posted state. Guardrail: the C
  implementation should post in `--post` declaration order, capture each
  URL into `posted`, and on first error stop iteration and return both
  the successful URLs and the failed role's error code. The caller
  decides whether to retry.
- **Dashboard repair after partial post.** If R1.3 runs after a partial
  post, the dashboard may be repaired against an incomplete record.
  Guardrail: only invoke repair when **every** role in `--post`
  succeeded; on any post failure, omit repair and surface the failure
  to the caller.
- **Skill-body goldens drift.** Regenerating goldens via
  `agent-runtime render --update-golden` may produce unrelated diffs if
  the source tree drifted. Guardrail: review the regenerated golden diff
  line by line before committing; if drift appears, rebase to clean
  `main`, regenerate, and re-diff.
- **Inbox archive move + Status update visibility.** `git mv` plus a
  Status edit produces a single rename-plus-diff. Guardrail: confirm
  `git log --follow` on the archived ENTRY.md still surfaces the
  pre-promotion history.
- **The `tracking-checkpoint-live-not-implemented` propagation lines stay
  in Failure-modes lists.** This is intentional (D5) since the
  non-`--live` controller path still emits the code. If a future cleanup
  retires the code upstream, those lines become obsolete; track that as
  a future follow-up, not as C scope.
- **Lane 1 PR can land before Lane 2 release.** Guardrail: Lane 3 PR
  must wait for the released `plan-issue-cli@0.25.6` to be on PATH
  (verified via A2.2); the runtime-kit PR description references the
  exact release tag.

## Retention Intent

Plan-source document for execution coordination. Cleanup-eligible after
all three lanes deliver and the C tracking issue archives via
`plan-archive-migrate`. Promote to a durable runbook only if the
`tracking checkpoint --live` posting contract becomes broadly referenced
by other skills — currently unlikely since the canonical write surface
is already captured in
`plan-tracking-issue-run-state-controller-v1.md` and
`plan-tracking-issue-comment-taxonomy-v1.md`.

## Read First References

- Inbox entries (active state during C, archived during R3.7):
  - `core/policies/heuristic-system/error-inbox/tracking-closeout-review-state-complete-gap/ENTRY.md`
  - `core/policies/heuristic-system/error-inbox/plan-issue-v3-surface-drift/ENTRY.md`
- Skill bodies edited by C (Source type: discussion-to-implementation-doc):
  - `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
  - `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`
- Skill bodies referenced (no edits in C):
  - `core/skills/dispatch/execute-plan-tracking-issue/SKILL.md.tera`
  - `core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera`
  - `core/skills/dispatch/dispatch-plan-closeout/SKILL.md.tera`
- Specs governing the controller and templates:
  - `docs/source/plan-issue-redesign/plan-tracking-issue-run-state-controller-v1.md`
  - `docs/source/plan-issue-redesign/plan-tracking-issue-cli-redesign-v1.md`
  - `docs/source/plan-issue-redesign/plan-tracking-issue-comment-taxonomy-v1.md`
- Surface contract and policy:
  - `docs/source/nils-cli-surface.md` (plan-issue-cli row)
  - `core/policies/heuristic-system/HEURISTIC_SYSTEM.md` (compression
    rule + archive convention)
- Smoke probe baseline:
  - `tests/runtime-smoke/cases/dispatch/run.sh`
    (`run_tracking_closeout_gate_prereq_blockers_probe` lines 537-581 +
    `write_missing_review_state_complete_comments_json` helper)
- Upstream implementation surface (Source type: source-code):
  - `sympoies/nils-cli/crates/plan-issue-cli/src/execute.rs`
    (`run_tracking_checkpoint` lines 1902+; live-blocked stub lines
    2044-2057; `synthesize_state_payload` lines 2135-2178;
    `render_checkpoint_role` lines 2078-2133; `record post` live hop
    lines 1094-1108)
  - `sympoies/nils-cli/crates/plan-issue-cli/src/commands/tracking.rs`
    (`TrackingCheckpointArgs` lines 189-242)
  - `sympoies/nils-cli/crates/plan-issue-cli/Cargo.toml` (version
    `0.25.5` → `0.25.6`)
- Workflow history:
  - PR #143 squash `f2fe7f5` (lands A + B transitional mitigation)
  - Issue `graysurf/agent-runtime-kit#135` (concrete instance of the
    gap, closed 2026-05-28)

## Recommended Next Artifact

Generate `2026-05-28-tracking-checkpoint-live-plan.md` (single plan with
three sprints / sequenced lanes per Lane 1 / Lane 2 / Lane 3 above), then
open the tracking issue via `create-plan-tracking-issue` in
`graysurf/agent-runtime-kit`. Cross-link the upstream nils-cli
implementation PR into the tracking-issue run state via `tracking run
update --linked-pr` once Lane 1 lands.
