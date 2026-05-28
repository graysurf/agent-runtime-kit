# Plan-Issue v4 State Payload Accumulation Implementation Handoff

- Status: discussion source — significant upstream and spec work
  ahead of code generation. Plan generation is appropriate but the
  implementation has more design surface than topics 1 and 2.
- Date: 2026-05-28
- Source: deferred Future Work item #3 from the
  `2026-05-28-plan-task-ledger-durability` rollout — `[D10]` in the
  ledger-durability discussion source and open question `O1` in its
  closeout report. The ledger-durability rollout chose to ship per-task
  durability through the plan bundle's `execution-state.md` ledger
  ([D1] of that source) and explicitly deferred payload accumulation
  to avoid regressing downstream `record audit` callers and
  visible-completeness rendering ([D10] of that source).
- Intended next step: generate the single-plan bundle under
  `docs/plans/2026-05-28-plan-issue-v4-payload-accumulation/`,
  then open a tracking issue via `create-plan-tracking-issue`.
  This is a source artifact, not an implementation plan. Note the
  scope is larger than topics 1 and 2; expect a multi-sprint plan.

## Execution

This document feeds **one** plan executed in three sequential lanes
(upstream `sympoies/nils-cli` schema + controller + renderer changes
→ upstream release → runtime-kit consumption). The shape mirrors
the ledger-durability rollout's three-lane pattern; that rollout is
the canonical precedent for plan-issue surface migrations.

- Recommended plan: docs/plans/2026-05-28-plan-issue-v4-payload-accumulation/2026-05-28-plan-issue-v4-payload-accumulation-plan.md
- Recommended execution state: docs/plans/2026-05-28-plan-issue-v4-payload-accumulation/2026-05-28-plan-issue-v4-payload-accumulation-execution-state.md
- Status: ready to plan; implementation depends on Lane 1 (upstream)
  before Lanes 2 + 3 can proceed
- Next-task source: this document

## Purpose

A plan-tracking issue records lifecycle evidence at role granularity
(`source`, `plan`, `state`, `session`, `validation`, `review`,
`closeout`). The `state` lifecycle comment is the lifecycle's
per-task progress carrier — but today its hidden payload `tasks[]`
array is **single-current**, populated from the run-state's
`selected_task` field only. Per the v1 taxonomy
(`docs/source/plan-issue-redesign/plan-tracking-issue-comment-taxonomy-v1.md`)
the schema is:

```json
"tasks": [
  {"id": "1.1", "status": "pending|in-progress|done|deferred",
   "title": "<task title>"}
]
```

This is the `plan-issue-record.payload.v2` envelope's `state` body.
A single-current `tasks[]` array means:

- A multi-task issue's per-task history is **derived** by reading
  every `state` lifecycle comment in chronological order and unioning
  the entries. There is no point-in-time payload that shows "the
  full per-task table at this state".
- Handoff to a new session requires either (a) re-reading every
  `state` comment plus the run-state's `selected_task` field, or
  (b) trusting the plan bundle's `execution-state.md` ledger
  (which is what the ledger-durability rollout established as the
  canonical per-task durability surface).
- The visible Task Ledger table on the `state` comment shows the
  full per-task table because the renderer derives it from the
  run-state + ledger at render time; the hidden payload does not
  carry the same shape.

The ledger-durability rollout closed the user-facing gap by making
`execution-state.md` the canonical per-task surface, gated by
`tracking close-ready --ledger-rows-pending`. That works for the
in-repo workflow, but the issue itself still does not carry
self-contained per-task evidence: a downstream consumer who only
has provider-issue evidence (no local checkout, no run-state)
cannot reconstruct the full per-task table at any single payload.

The proposed v4 schema change makes `tasks[]` **accumulative** at
each `state` post: every post carries the full per-task table the
agent is aware of, not just the current `selected_task`. Combined
with the ledger-durability surfaces shipped in `0.25.7`/`0.25.8`,
this lets the provider issue stand alone as a per-task history
without invariant-breaking churn on downstream callers.

This source captures the agreed design space, the risks the
ledger-durability rollout cited when it deferred the schema change,
and the decisions needed before code generation can start.

## Confirmed Facts

- [U1] User accepted "v4 payload accumulation" as the third of the
  three open Future Work items from the
  `2026-05-28-plan-task-ledger-durability` rollout, and asked for
  it to land as its own plan bundle. The user has not specified
  schema details; this source captures the design surface, not
  premature decisions.
- [F1] Current `state` payload schema:
  `docs/source/plan-issue-redesign/plan-tracking-issue-comment-taxonomy-v1.md`
  lines 312-331. The `tasks` array carries one entry derived from
  the run-state's `selected_task`. The envelope marker is
  `plan-issue-record:v2` (`plan-issue-record-payload.v2`).
- [F2] Today's live state payload (per the close-ready checkpoint of
  the C tracking issue `graysurf/agent-runtime-kit#144`):

  ```json
  "data": {
    "status": "complete",
    "current": "Task 3.1",
    "tasks": [{"id": "Task 3.1", "status": "done",
               "title": "selected"}],
    ...
  }
  ```

  Single-entry. Reproduced from the
  ledger-durability discussion source ([F4] of that doc).
- [F3] Ledger-durability rollout's `[D10]` records the explicit
  deferral: "The `state` payload's `tasks` array stays current-only
  (single entry from the run-state's `selected_task`). Per-task
  durability is met by the .md ledger ([D1])." Listed under
  Non-Scope ([D10] of ledger-durability source line 330):
  "Changing the `state` payload `tasks` array schema to
  accumulate (see open question O1 in the final response)."
- [F4] Visible Task Ledger table renderer (per the taxonomy spec
  Task Ledger section) already shows the full per-task table at
  the visible body. The visible-completeness lint code
  `state-missing-task-ledger` (per the plan-issue-skill-family
  redesign v1 spec) refers to the visible body, not the hidden
  payload. The hidden payload's shape can change without
  necessarily breaking the visible lint.
- [F5] Downstream `record audit` callers consume the hidden
  payload by hex-decoding the
  `<!-- plan-issue-record-payload:hex:... -->` carrier. Today
  every active runtime-kit consumer reads `tasks[]` as the
  current-only single-entry shape. A schema change either:
  (a) versions the payload marker (e.g.
  `plan-issue-record-payload.v3`) and keeps `.v2` parsing for
  legacy comments, or (b) re-uses `.v2` and adds a feature flag
  for callers to opt into the new array semantics. (a) is the
  canonical migration pattern; (b) shifts complexity to
  consumers.
- [F6] The plan bundle's `execution-state.md` ledger is the
  canonical per-task durability surface as of the
  ledger-durability rollout (`plan-tooling ledger-update`,
  `tracking close-ready --ledger-rows-pending`, both in
  `plan-issue-cli`/`plan-tooling 0.25.7`+). The v4 payload
  schema change does **not** replace the ledger; it makes the
  provider issue self-contained for the same data.
- [F7] The taxonomy spec is the canonical source of truth for
  every lifecycle role's hidden payload shape. Any schema change
  must update the taxonomy spec, the lifecycle_vnext renderer
  in `crates/plan-issue-cli/src/lifecycle_vnext/`, the
  `record audit` consumer, the visible-completeness lint, and
  the runtime-smoke fixtures that exercise the
  `record audit --expect-visible` flow.
- [F8] Hidden payload size is encoded as hex; a multi-task
  accumulating array grows with N tasks. For typical runtime-kit
  plans this is small (under 50 tasks), but very large plans
  (3-5 sprints with 10+ tasks each) could push the hex payload
  into the multi-KB range. GitHub / GitLab comment-body limits
  are well above that, but `record audit` and dashboard repair
  parsing cost scales with N.

## Decisions

This source captures decisions that have **already been adopted**
during the ledger-durability rollout's deferral discussion, plus
decisions made explicitly to scope this follow-up plan. Open
questions are surfaced in the final response, not embedded here.

- **Decision 1**: Adopt accumulation, not replacement. The v4
  `tasks[]` array carries the full per-task history known at
  post-time, not just `selected_task`. This is the design
  inheritance from the ledger-durability rollout's `[D10]`
  deferral framing.
- **Decision 2**: Version the payload marker. Introduce
  `plan-issue-record-payload.v3` (or rev the schema version
  number once final design is locked) and keep `v2` parsing for
  legacy comments. The lifecycle_vnext writer emits v3; the
  reader auto-detects v2/v3 and unions data per stable rules.
  Versioning is the canonical migration pattern ([F5] option a)
  and avoids feature-flag complexity on every consumer.
- **Decision 3**: The plan bundle's `execution-state.md` ledger
  remains the canonical durability surface. The v4 payload
  change makes the **provider issue** self-contained, but the
  in-repo ledger is the source of truth for `tracking
  close-ready --ledger-rows-pending` gating. The payload is a
  derived view, populated from the same source the ledger
  is populated from (`plan-tooling ledger-update` writes both).
- **Decision 4**: Do not break `record audit --expect-visible`.
  The visible Task Ledger table already renders the full
  per-task table ([F4]); visible-completeness lint is unaffected
  by hidden-payload schema changes.
- **Decision 5**: Ship as a single rollout, not split across
  multiple releases. The taxonomy spec update, the
  lifecycle_vnext renderer change, the reader auto-detection,
  the runtime-smoke fixture refresh, and the runtime-kit
  consumer updates land together to avoid a window where v3
  posts coexist with v2-only readers.
- **Decision 6**: Acceptance criteria include a side-by-side
  payload comparison test: a synthetic multi-task plan emits
  both v2 (legacy, single-current) and v3 (accumulative,
  multi-task) at the same lifecycle event, and the reader
  produces the same `record audit` result from both inputs.
- **Decision 7**: Hidden payload size is acceptable up to the
  plan's natural task count (typically under 50). If real
  plans push past ~200 KB hex payload, add a per-state cap
  (e.g., emit only the last N tasks or chunked-by-sprint
  payloads) in a follow-up plan. Do not pre-optimize.
- **Decision 8**: Patch / minor release decision deferred to
  the plan: the schema change is additive (new fields on the
  payload, new marker version) but the reader semantics
  change. Plan generation should propose patch (0.25.x) vs
  minor (0.26.0) based on the version's own additive vs
  breaking call. Patch is consistent with
  `0.25.6` → `0.25.7` (additive new subcommand) and
  `0.25.7` → `0.25.8` (lock-step catch-up); a schema rev
  argues for minor.

## Scope

- **In** (Lane 1, upstream `sympoies/nils-cli`):
  - `crates/plan-issue-cli/src/lifecycle_vnext/payloads.rs` (or
    equivalent) — new v3 payload schema for `state` role;
    accumulative `tasks[]` writer.
  - `crates/plan-issue-cli/src/lifecycle_vnext/render.rs` (or
    equivalent) — v3 payload renderer + hidden carrier.
  - `crates/plan-issue-cli/src/lifecycle_vnext/visible_lint.rs`
    — no semantic change; verify visible lint still passes
    on the new payload.
  - `crates/plan-issue-cli/src/record.rs` (or audit reader) —
    v2/v3 auto-detection on read.
  - `crates/plan-tooling/src/ledger.rs` (or wherever
    `ledger-update` lives) — extend to emit per-task entries
    into the v3 payload writer when invoked through the
    tracking checkpoint hop.
  - Rust integration tests cover v3 emission, v2/v3 reader
    parity, mixed-version comment streams, and the side-by-side
    parity criterion ([Decision 6]).
- **In** (Lane 2, release): cut a `0.25.x` patch or `0.26.0`
  minor release per [Decision 8]; bump the Homebrew tap formula;
  confirm `plan-issue --version` and `plan-tooling --version`
  on PATH.
- **In** (Lane 3, runtime-kit):
  - Bump `docs/source/nils-cli-surface.md` rows for the new
    release.
  - Update
    `docs/source/plan-issue-redesign/plan-tracking-issue-comment-taxonomy-v1.md`
    to document the v3 payload schema alongside v2 (v2 retained
    for legacy comments, v3 is the active emit format).
  - Refresh the
    `docs/source/plan-issue-redesign/plan-tracking-issue-run-state-controller-v1.md`
    section on payload versioning to name the v3 marker.
  - Verify all five active dispatch / tracking SKILL bodies
    (the same five from topics 1 and 2) do not need surface
    updates — the SKILL bodies invoke `tracking checkpoint`
    abstractly; the payload version lives below the CLI surface
    and is invisible to the SKILL body. Confirm during
    implementation that this is true; if any SKILL body names
    `payload.v2` directly, update it.
  - Refresh deterministic smoke probes that exercise
    `record audit --expect-visible` if their fixtures pin
    `payload.v2` strings.
  - Render-pass refresh for Codex / Claude / shared goldens
    if any tera body changes.
- **Out**: Replacing the plan bundle's `execution-state.md`
  ledger with the payload. Ledger remains canonical
  ([Decision 3]).
- **Out**: Changing the `source`, `plan`, `session`,
  `validation`, `review`, or `closeout` payload schemas. v4
  payload accumulation is scoped to the `state` role.
- **Out**: Pruning old `state` lifecycle comments. Lifecycle
  comments are immutable; v3 emits the accumulative array
  going forward, but past v2 comments stay as-is.
- **Out**: Backfilling past issues' payloads. v2/v3
  auto-detection handles read parity; no retroactive rewriting.
- **Out**: Dispatch-profile parity. That is topic 2's plan.
- **Out**: Retiring the
  `tracking-checkpoint-live-not-implemented` constant. That
  is topic 1's plan.
- **Out**: Changing the visible Task Ledger table format. The
  visible body's renderer already shows the full per-task
  table ([F4]).
- **Out**: Changing visible-completeness lint codes. Visible
  lint is unaffected ([Decision 4]).

## Implementation Boundaries

- Schema migration must be backward-compatible on read. v2
  payloads remain parseable; the reader's union logic across a
  mixed-version stream must produce the same per-task table a
  pure-v3 stream would.
- v3 writer never emits a v2-shape payload. The transition is
  release-cut: post-release, every new `state` post is v3;
  pre-release posts stay v2.
- The taxonomy spec is the canonical schema description. The
  upstream code's payload struct definition must agree with the
  spec; the runtime-smoke fixture must agree with both. CI
  must catch drift (existing `record_compat_baseline`
  integration tests are the canonical lock — extend them to
  cover v3).
- Payload size growth is not a blocker, but the plan should
  measure it on a synthetic 20-task multi-sprint plan and
  report the delta. If the delta materially changes parse cost,
  document it.
- The `plan-tooling ledger-update` CLI does not need a flag
  change. The ledger-durability rollout already writes
  per-task entries into the ledger; the v3 payload writer
  reads from the same source the ledger writer reads from,
  so the surface is unchanged at the CLI level.

## Requirements

- R1: The taxonomy spec
  (`plan-tracking-issue-comment-taxonomy-v1.md`) documents v3
  alongside v2 with a clear deprecation note on v2 (legacy
  read-only, not emit) and the v3 accumulative schema.
- R2: `plan-issue-cli` emits v3-format hidden payloads on every
  new `state` lifecycle comment.
- R3: `plan-issue record audit` parses both v2 and v3 hidden
  payloads. Mixed-version comment streams produce the same
  per-task table a pure-v3 stream would.
- R4: A side-by-side acceptance test ([Decision 6]) demonstrates
  the parity property on a synthetic multi-task plan.
- R5: `record audit --expect-visible` continues to pass on the
  new payload format. Visible-completeness lint codes
  unchanged.
- R6: `tracking close-ready --ledger-rows-pending` gate semantics
  unchanged. The ledger remains canonical.
- R7: The runtime-kit floor bump (in Lane 3) raises
  `plan-issue` and `plan-tooling` to the v3-supporting release
  in `nils-cli-surface.md`; `scripts/ci/all.sh` Position 2
  probe stays on the `agent-runtime --version` floor probe
  contract ([Decision 8] release semantics).
- R8: Render-pass goldens regenerate cleanly after any tera
  edits.
- R9: `bash scripts/ci/all.sh` and the runtime-smoke
  deterministic probes pass after the consume.

## Acceptance Criteria

- AC1: `plan-issue record open` followed by a synthetic
  multi-task `state` checkpoint emits a v3 hidden carrier
  (`plan-issue-record-payload.v3` or chosen schema version
  string) and the payload's `tasks[]` contains every task
  known at post-time.
- AC2: `plan-issue record audit` on a comment stream containing
  one v2 `state` comment + one v3 `state` comment produces a
  per-task table equal to the table reconstructed from the
  same source data emitted as a pure-v3 stream
  ([Decision 6] + R3 + R4).
- AC3: `tracking close-ready --expect-visible` passes on a
  v3-only issue with a clean ledger.
- AC4: `tracking close-ready --expect-visible` fails with
  `ledger-rows-pending` on a v3-only issue with a pending
  ledger row — unchanged from the ledger-durability rollout's
  smoke probe contract.
- AC5: `record audit --expect-visible` passes on the new
  payload format. Visible-completeness codes unchanged.
- AC6: Runtime-kit `scripts/ci/all.sh` exits 0 across
  Positions 1-13 after Lane 3 consumption.
- AC7: Payload size on a synthetic 20-task plan stays below
  the project's natural threshold; the plan reports the
  observed hex-payload size delta.
- AC8: `record_compat_baseline` integration tests in
  `plan-issue-cli` extend to lock v3 schema constants.

## Validation Plan

- Upstream (Lane 1): `cargo test -p plan-issue-cli` on
  lifecycle_vnext + record_compat_baseline + new v3 parity
  tests; `cargo test -p plan-tooling`.
- Upstream (Lane 2): cut release through the same lock-step
  release flow used for `0.25.7` / `0.25.8`; the
  `workspace-version-lockstep.sh` audit (added in nils-cli
  commit `050976d`) is now a CI gate so partial bumps are
  caught upstream before tag.
- Runtime-kit (Lane 3): `bash scripts/ci/all.sh` full stack;
  `agent-runtime render --check`; runtime-smoke deterministic
  probes; one live tracking issue end-to-end (open + N task
  posts + close-ready + close) to verify v3 in production.
- Cross-cutting: side-by-side AC2 evidence captured as a
  test fixture + artifact under `tests/` or
  `crates/plan-issue-cli/tests/fixtures/` so future readers
  can diff the two payload shapes.

## Risks And Guardrails

- **Risk**: v2/v3 reader divergence — a consumer auto-detects
  the wrong version or unions data incorrectly across a mixed
  stream. **Guardrail**: AC2 is the parity contract; extend
  `record_compat_baseline` to lock it.
- **Risk**: Hidden payload size growth degrades audit parse
  cost. **Guardrail**: AC7 measures it; if delta exceeds a
  threshold (TBD by plan, suggested ~200 KB hex), schedule a
  follow-up plan to add per-state caps ([Decision 7]).
- **Risk**: Downstream consumer outside `agent-runtime-kit`
  reads v2-only and breaks on v3 comments. **Guardrail**:
  this is what payload versioning is for ([F5] option a plus
  [Decision 2]); document the v3 marker in the taxonomy spec
  and the `nils-cli-surface.md` row so external consumers
  see the change.
- **Risk**: Visible Task Ledger table renderer expects a
  certain `tasks[]` shape and breaks. **Guardrail**: AC5;
  the visible body's source data is the run-state + ledger,
  not the hidden payload ([F4]); the renderer is already
  shape-agnostic at the payload level.
- **Risk**: SKILL bodies pin `payload.v2` strings in their
  Failure-modes or Outputs sections. **Guardrail**: a
  pre-implementation `git grep "payload.v2"` across
  `core/skills/` is part of Lane 3 task list; any hits are
  scrubbed in the same PR.
- **Risk**: Taxonomy spec drift — v3 lands in code but the
  spec still describes v2 as canonical. **Guardrail**: Lane 3
  Task 1 is the spec update; spec edits land in the same PR
  as the runtime-kit consume.

## Retention Intent

- Plan-scoped source. Clean up after the v4 rollout lands and
  the consume PR closes. The durable knowledge (v3 schema
  shape) lives in the taxonomy spec, not in this source
  document. Migrate to `agent-plan-archive` per the active
  retention policy when the plan bundle closes.

## Read-First References

- `docs/source/plan-issue-redesign/plan-tracking-issue-comment-taxonomy-v1.md`
  (v1 taxonomy spec; state payload schema lines 312-331).
- `docs/source/plan-issue-redesign/plan-tracking-issue-run-state-controller-v1.md`
  (controller spec; payload write paths).
- `docs/source/plan-issue-redesign/plan-issue-skill-family-redesign-v1.md`
  (skill-family spec; Failure-modes authoring guidance).
- `docs/plans/2026-05-28-plan-task-ledger-durability/2026-05-28-plan-task-ledger-durability-discussion-source.md`
  ([D10] deferral, [F4] live payload example, [O1] open
  question framing).
- `docs/plans/2026-05-28-plan-task-ledger-durability/2026-05-28-plan-task-ledger-durability-plan.md`
  (precedent for three-lane upstream→release→consume
  rollouts).
- Upstream `crates/plan-issue-cli/src/lifecycle_vnext/`
  (payload writers, renderers, visible-lint, payloads,
  templates).
- Upstream `crates/plan-issue-cli/src/record.rs` (audit reader
  / hex-decoder).
- Upstream `crates/plan-issue-cli/tests/integration/record_compat_baseline.rs`
  (compat lock-in; the extension point for v3 lock).
- Upstream `crates/plan-tooling/src/ledger.rs` (ledger-update
  surface; per-task data source shared with v3 payload writer).
- Sibling plan bundles:
  - `docs/plans/2026-05-28-checkpoint-live-constant-retirement/`
    (topic 1; constant retirement — may share render-pass
    window).
  - `docs/plans/2026-05-28-dispatch-profile-live-ledger-parity/`
    (topic 2; dispatch parity — touches the same five SKILL
    bodies but for `--live` + ledger wiring, not payload
    schema).

## Recommended Next Artifact

- `docs/plans/2026-05-28-plan-issue-v4-payload-accumulation/2026-05-28-plan-issue-v4-payload-accumulation-plan.md`
  — task-by-task plan with three lanes (upstream schema +
  controller + tests → release → runtime-kit consume) and an
  expected 2-3 sprint shape. Lane 1 has the most surface;
  expect 4-6 tasks (schema, writer, reader, audit, tests,
  visible-lint verification). Lane 2 is the smallest (release
  cut). Lane 3 has 3-5 tasks (taxonomy spec, surface row,
  SKILL grep, render-pass, smoke probes).
- `docs/plans/2026-05-28-plan-issue-v4-payload-accumulation/2026-05-28-plan-issue-v4-payload-accumulation-execution-state.md`
  — empty ledger seeded from the plan's task list.
