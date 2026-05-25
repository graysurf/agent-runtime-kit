# Plan Issue Lifecycle Comment Visibility Implementation Handoff

- Status: ready for plan generation
- Date: 2026-05-25
- Source: user request to repair issue #112 final Execution State visibility, to
  fix both the runtime-kit skills and the `nils-cli` `plan-issue` contract, to
  keep non-final task ledgers collapsed by default, and to ensure review,
  validation, session, and closeout lifecycle comments are not effectively empty
  in the visible issue timeline.
- Intended next step: create a focused implementation plan that updates
  `nils-cli` first, then updates runtime-kit skill contracts and smoke coverage.
- Source type: discussion-to-implementation-doc

## Execution

- Recommended plan: docs/plans/plan-issue-lifecycle-comment-visibility/plan-issue-lifecycle-comment-visibility-plan.md
- Recommended execution state: docs/plans/plan-issue-lifecycle-comment-visibility/plan-issue-lifecycle-comment-visibility-execution-state.md
- Recommended first implementation task: add first-class visible lifecycle
  content rendering in `nils-cli`, starting with
  `plan-issue record post --kind state --execution-state-file <path>`.

## Purpose

Plan-tracking issues should leave human-readable lifecycle comments in the issue
timeline whenever state, session, validation, review, or closeout evidence is
posted. The hidden `plan-issue-record-payload:hex` carrier is still required for
machine audit and closeout, but it is not enough for humans reviewing a closed
issue.

The issue #112 incident proved that the current stack can pass machine gates
while the visible final state comment lacks the detailed Task Ledger. The fix
must therefore live in both layers:

- `nils-cli` must expose and validate a state-specific execution-state markdown
  input for `record post`.
- `nils-cli` must refuse or synthesize away Profile-only lifecycle comments for
  session, validation, review, and closeout records.
- runtime-kit tracking skills must require issue-visible evidence whenever they
  post state, validation, review, session, or closeout lifecycle comments.
- Non-final state comments should collapse the Task Ledger by default; the final
  state comment should show the full ledger expanded by default.

## Confirmed Facts

- [U1] The user decided that both sides must be fixed: the skill layer needs a
  hard workflow constraint and `nils-cli` also needs a contract change.
- [U2] The user asked to repair issue #112 first by adding the final Execution
  State Task Ledger back to the issue-visible comment.
- [U3] The user requested a visibility behavior change: only the final Execution
  State comment should show the full Task Ledger by default; earlier Execution
  State comments should keep the Task Ledger collapsed so the issue timeline is
  shorter and easier to scan.
- [U4] The user clarified that the problem is not only the visible
  `Execution State` comment. `Review Evidence`, `Tracking Issue Closeout`, and
  other lifecycle comments must also be checked so they do not leave only a
  heading and `Profile: tracking` while the detailed evidence exists only in the
  hidden payload.
- [A1] Issue #112 final state comment was repaired in place at
  <https://github.com/graysurf/agent-runtime-kit/issues/112#issuecomment-4534882256>.
  The live read-back contains `## Task Ledger`, all plan rows through Task 3.3,
  and the hidden payload marker.
- [A2] A fresh `plan-issue record audit --profile tracking` read-back for issue
  #112 returned `status=ok` after the repair and still recognized source, plan,
  state, session, validation, review, and closeout evidence.
- [F1] `create-plan-tracking-issue` already requires source, plan, and
  execution-state files before `record open`; it explicitly warns that a missing
  execution-state file produces no visible task table while hidden payload gates
  can still pass. See
  `core/skills/dispatch/create-plan-tracking-issue/SKILL.md.tera:127-135`.
- [F2] `execute-plan-tracking-issue` currently posts state with
  `--summary-file "$STATE_MD"` and does not guarantee that `STATE_MD` is the
  canonical `<slug>-execution-state.md` file. See
  `core/skills/dispatch/execute-plan-tracking-issue/SKILL.md.tera:78-104`.
- [F3] `deliver-plan-tracking-issue` verifies that the execution-state file
  exists, but its posted lifecycle examples and workflow text do not require a
  final state post whose visible body is the full execution-state markdown. See
  `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera:21-26` and
  `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera:180-185`.
- [F4] `plan-tracking-issue-closeout` gates on complete state payload, approval,
  validation, and merged PR evidence, but it does not validate that the latest
  state comment visibly contains the full Task Ledger. See
  `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera:77-85`.
- [F5] runtime-smoke dispatch fixtures post state with `--summary-file`, but the
  state summary is a short four-line status and the assertion only checks the
  `record.post` envelope, not visible `## Task Ledger` content. See
  `tests/runtime-smoke/cases/dispatch/run.sh:166-183` and
  `tests/runtime-smoke/cases/dispatch/run.sh:237-247`.
- [F6] `docs/source/nils-cli-surface.md` documents that issue-backed records are
  owned by `plan-issue record` and that payload carriers are hidden from visible
  issue comments. See `docs/source/nils-cli-surface.md:50-63`.
- [F7] In `nils-cli`, `record open` and `record attach` already accept
  `--execution-state-file`, but `record post` only accepts `--payload-file` and
  `--summary-file`. See
  `crates/plan-issue-cli/src/commands/record.rs:94-211` in the `sympoies/nils-cli`
  repo.
- [F8] In `nils-cli`, `record open` reads the execution-state file and passes
  its trimmed markdown as the visible state summary. See
  `crates/plan-issue-cli/src/execute.rs:410-453` in the `sympoies/nils-cli`
  repo.
- [F9] In `nils-cli`, `record post` reads only `--summary-file` as visible
  markdown and forwards it to `render_record_post_comment`; the renderer then
  appends the hidden payload carrier. See
  `crates/plan-issue-cli/src/execute.rs:969-980` and
  `crates/plan-issue-cli/src/lifecycle_record.rs:1500-1544` in the
  `sympoies/nils-cli` repo.
- [F10] Existing `nils-cli` tests prove that `record open` can inline an
  execution-state markdown file and that `record post --summary-file` renders a
  visible summary, but they do not prove that `record post --kind state` leaves
  a visible Task Ledger. See
  `crates/plan-issue-cli/tests/integration/live_record_ops.rs:136-175` and
  `crates/plan-issue-cli/tests/integration/live_record_ops.rs:1240-1330`.
- [F11] runtime-kit development policy already supports coupled `nils-cli` work
  by building a local debug binary and scoping it into validation commands,
  while keeping the Homebrew-installed released binary as the consumer contract.
  See `DEVELOPMENT.md:96-139`.
- [F12] `plan-issue record close` currently renders closeout through the same
  post-comment renderer with a short generated summary, so linked PRs,
  approvals, merge SHAs, checks, overrides, and closeout notes can remain
  machine-readable but not fully issue-visible. See
  `crates/plan-issue-cli/src/execute.rs:1325-1357` in the `sympoies/nils-cli`
  repo.

## Decisions

- [D1] Fix the invariant in `nils-cli`; do not rely on prompt wording alone.
- [D2] Add `--execution-state-file <path>` to
  `plan-issue record post --kind state`.
- [D3] For `record post --kind state`, `--execution-state-file` is the preferred
  visible markdown source. It must read the full file, trim only surrounding
  whitespace, and preserve the hidden payload carrier.
- [D4] Reject `--execution-state-file` for non-state lifecycle kinds. Session,
  validation, review, and closeout comments continue to use visible summaries.
- [D5] Treat `--execution-state-file` and `--summary-file` as mutually exclusive
  for `record post`; this prevents a short summary from overriding or masking
  the full state document.
- [D6] When `--execution-state-file` is supplied, fail if the file is missing,
  empty, or lacks `## Task Ledger`.
- [D7] Preserve backward compatibility for existing non-state `--summary-file`
  usage. State `--summary-file` may remain accepted for external callers during
  the first release, but runtime-kit skills must stop using it for state posts.
- [D8] Update runtime-kit skills so every tracking state post uses the canonical
  `<slug>-execution-state.md` path, not a short ad hoc summary.
- [D9] Add acceptance coverage that inspects the rendered comment body for
  visible `## Task Ledger` content. Hidden payload recognition alone is not an
  adequate pass condition.
- [D10] Do not make the payload JSON visibly rendered as the normal fix. The
  hidden payload stays machine-oriented; the markdown execution-state document
  is the human-readable source.
- [D11] Add a state-ledger display mode to the renderer. The recommended CLI
  shape is `--task-ledger-display auto|collapsed|expanded`, defaulting to
  `auto` for state comments.
- [D12] In `auto` mode, final state comments render the Task Ledger expanded by
  default. Non-final state comments render the `## Task Ledger` heading and wrap
  the ledger table/body in a GitHub-supported `<details>` block.
- [D13] Final-state detection should not rely only on issue position. Use the
  state payload as the default signal: `status=complete` and every task row is
  terminal (`done` or `deferred`). Skills may pass `expanded` explicitly for a
  known final state before closeout, and `collapsed` explicitly for intermediate
  progress updates.
- [D14] Apply the collapsed-by-default behavior to initial `record open` /
  `record attach` state comments as well as later `record post --kind state`
  comments. Initial state is non-final unless the caller explicitly requests
  otherwise.
- [D15] Use a nils-cli-first execution sequence: implement and test the
  `plan-issue` CLI change in `sympoies/nils-cli`, consume the resulting local
  debug binary in runtime-kit validation, then update runtime-kit skills and
  smoke coverage.
- [D16] Release the next `nils-cli` version after the CLI behavior is validated
  and while runtime-kit integration is being finalized. Treat this as the next
  release version (`z+1`) according to nils-cli release policy; runtime-kit must
  land against the released version floor before final delivery.
- [D17] A lifecycle comment must never be considered complete when its visible
  body contains only the marker heading and `Profile: tracking` /
  `Profile: dispatch`. This is a CLI contract, not only a skill prompt rule.
- [D18] Validation, review, session, and closeout comments should get
  role-specific visible renderers from their structured payloads. A
  `--summary-file` may add human notes, but hidden payload must not be the only
  detailed evidence.
- [D19] `record close` must render a closeout evidence body that includes final
  status, approval basis, linked PRs, merge SHAs, check status, overrides, and
  notes when present.
- [D20] runtime-kit smoke and skill contracts must check visible completeness for
  state, validation, review, session, and closeout comments together.

## Scope

- Update `sympoies/nils-cli` `plan-issue-cli` command args, execution logic,
  renderer tests, and integration tests for state execution-state markdown
  posting, Task Ledger display mode, and role-specific visible evidence for
  validation, review, session, and closeout comments.
- Release or otherwise consume a `nils-cli` version that includes the new
  `record post --kind state --execution-state-file` surface.
- Update runtime-kit tracking skills that post, deliver, or close lightweight
  plan-tracking issues:
  - `create-plan-tracking-issue`
  - `execute-plan-tracking-issue`
  - `deliver-plan-tracking-issue`
  - `plan-tracking-issue-closeout`
- Update runtime-kit dispatch smoke fixtures so state, validation, review,
  session, and closeout comments are tested for visible evidence, not only
  hidden payload markers.
- Update `docs/source/nils-cli-surface.md`, manifests, rendered skill output,
  and goldens if the consumed CLI floor changes.

## Execution Sequencing

This approach is feasible and is the preferred order because the behavior is a
shared command contract, not only runtime-kit prompt text.

1. Implement the `nils-cli` change in `sympoies/nils-cli`.
   - Add `record post --kind state --execution-state-file`.
   - Add `--task-ledger-display auto|collapsed|expanded`.
   - Add role-specific visible renderers for validation, review, session, and
     closeout payloads.
   - Reject Profile-only rendered lifecycle comments.
   - Add focused CLI, renderer, and integration tests.
2. Validate `nils-cli` locally.
   - Run the focused `plan-issue-cli` tests first.
   - Build the local debug binary.
   - Use the local binary directly or via a command-scoped `PATH` override for
     runtime-kit validation. Do not permanently replace the Homebrew binary as
     the consumer contract.
3. Update runtime-kit against the local binary.
   - Change tracking skills to call the new state execution-state file surface.
   - Update runtime-smoke so dry-run state comments must contain visible
     `## Task Ledger` content, with non-final comments collapsed and final
     comments expanded.
   - Update runtime-smoke so validation, review, session, and closeout dry-run
     comments contain role-specific visible evidence.
   - Regenerate Codex and Claude rendered skill output and goldens.
4. Release nils-cli `z+1` while runtime-kit integration is finalizing.
   - Cut the next nils-cli release after tests pass and the CLI behavior is
     accepted.
   - Update the Homebrew tap and verify the released binary exposes the new
     flags.
5. Finalize runtime-kit on the released floor.
   - Update `docs/source/nils-cli-surface.md` and any manifest `required_clis`
     floor to the released `z+1` version.
   - Re-run focused runtime-kit checks using the released binary, then run the
     full gate before delivery.

## Non-Scope

- Do not change the hidden payload marker format.
- Do not remove `--summary-file` for session, validation, review, or closeout
  lifecycle comments.
- Do not rewrite existing historical plan issues in bulk.
- Do not introduce a second source-of-truth state file outside
  `docs/plans/<slug>/<slug>-execution-state.md`.
- Do not make issue body dashboards the durable state ledger; dashboards remain
  mutable summaries.
- Do not collapse validation, review, session, or closeout content as part of
  this change. This display mode is specific to the Task Ledger section inside
  state comments.
- Do not require callers to hand-write duplicated visible tables when the
  structured payload already contains enough data for a deterministic renderer.
  Prefer renderer-generated visible evidence and let summaries add context.

## Implementation Boundaries

- `nils-cli` owns the stable command-line contract, read errors, comment
  rendering, fixture mode, dry-run mode, live provider posting, and integration
  tests.
- runtime-kit skills own workflow discipline: resolving the plan bundle,
  updating the execution-state file before state posts, choosing the right
  command flags, and checking live read-back evidence.
- `plan-tooling validate` does not currently enforce execution-state file
  presence or visible Task Ledger content; do not treat it as sufficient for
  this invariant.
- Provider comments remain append-only in normal lifecycle use. Direct edit of
  issue #112 was a one-time repair of an already closed historical record whose
  dashboard already pointed at that comment.
- Task Ledger collapsing is a visible markdown transformation only. It must not
  alter the structured payload, state payload validation, or the canonical
  execution-state file on disk.
- The transformation should be narrow and deterministic: find the `## Task
  Ledger` section, preserve the heading, and wrap only the content until the
  next same-level or higher-level heading. If the section cannot be parsed
  safely, fail instead of silently posting an ambiguous state comment.
- Role-specific visible evidence renderers must be deterministic and compact.
  They should summarize payload data into issue-readable Markdown tables or
  bullets and keep the hidden payload as the machine source of truth.

## Requirements

- `plan-issue record post --kind state --execution-state-file <path>` must
  render a visible state comment that includes the full markdown file and still
  carries the hidden v2 payload marker.
- `plan-issue record post` must fail or synthesize role-specific visible content
  rather than emitting a Profile-only comment for state, session, validation,
  review, or closeout kinds.
- The rendered state comment must support three Task Ledger display modes:
  `expanded`, `collapsed`, and `auto`.
- In collapsed mode, the visible comment must keep `## Task Ledger` visible and
  wrap the ledger rows and notes in `<details><summary>Show task ledger</summary>`.
- In expanded mode, the Task Ledger must render as ordinary markdown with no
  surrounding `<details>` wrapper.
- In auto mode, the renderer must expand final state comments and collapse
  non-final state comments. The payload-driven final signal is `status=complete`
  plus all task rows terminal (`done` or `deferred`).
- The command must fail with a clear usage or input error when:
  - `--execution-state-file` is used with a non-state kind.
  - the execution-state file is missing or empty.
  - the execution-state file lacks `## Task Ledger`.
  - both `--execution-state-file` and `--summary-file` are supplied.
- Runtime-kit state-posting workflows must update and post the canonical
  execution-state markdown file before merge, closeout, or final success
  reporting.
- Closeout skills must verify that the latest valid state comment is both
  machine-complete and visibly ledger-complete before running `record close`.
- Dry-run and fixture outputs must expose the rendered comment body so tests can
  assert visible Task Ledger content without live provider mutation.
- Validation comments must visibly show overall status and the command/status
  rows from the validation payload.
- Review comments must visibly show decision, lenses, finding disposition rows,
  and linked retained review evidence when present.
- Session comments must visibly show session summary plus branch, PR, merge, or
  other structured session fields when present.
- Closeout comments must visibly show final status, approval basis, linked PRs,
  merge SHAs, check status, overrides, and notes when present.

## Acceptance Criteria

- `nils-cli` CLI contract exposes `--execution-state-file` on `record post`.
- `record post --kind state --execution-state-file sample-execution-state.md
  --payload-file state.json --dry-run --format json` returns a comment body
  containing:
  - `<!-- plan-issue-record:v2 role=state profile=tracking -->`
  - `## Execution State`
  - `## Task Ledger`
  - at least one task ledger row
  - `<!-- plan-issue-record-payload:hex:`
- A non-final state post in default `auto` mode returns a comment body where:
  - `## Task Ledger` remains visible.
  - the task ledger rows are inside a `<details>` block.
  - the hidden payload marker is still present.
- A final state post in default `auto` mode returns a comment body where:
  - `## Task Ledger` is visible.
  - task ledger rows are not wrapped in a `<details>` block.
  - the hidden payload marker is still present.
- `record open` and `record attach` initial state comments collapse the Task
  Ledger by default when the initial state is not terminal.
- Negative `nils-cli` tests cover non-state use, missing file, empty file, file
  without `## Task Ledger`, and conflict with `--summary-file`.
- runtime-kit skill source no longer tells tracking state posts to use a short
  `STATE_MD` summary; it points at the canonical execution-state file.
- runtime-kit runtime-smoke fails if the rendered state post lacks visible
  `## Task Ledger`, even when the hidden payload marker is present.
- A live or dry-run read-back for a plan-tracking issue proves the latest state
  comment has both the visible Task Ledger and hidden payload marker.
- runtime-kit closeout flow posts the final state with expanded ledger before
  `record close`, while earlier progress updates use collapsed ledger mode.
- Validation, review, session, and closeout dry-run comment tests fail when the
  visible body contains only the heading and profile line.
- A closeout comment generated by `record close` visibly includes linked PR and
  approval evidence, not only a one-line success sentence.

## Validation Plan

- `nils-cli` focused tests:
  - `cargo test -p plan-issue-cli record_post_state_execution_state_file`
  - `cargo test -p plan-issue-cli state_task_ledger_display`
  - `cargo test -p plan-issue-cli live_record_ops`
  - `cargo test -p plan-issue-cli cli_contract`
- runtime-kit focused checks after the CLI floor is consumed:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch`
  - `agent-runtime audit-drift`
- Full runtime-kit delivery check:
  - `bash scripts/ci/all.sh`

## Risks And Guardrails

- A skill-only fix is fragile because an agent can still pass a short
  `--summary-file`; the CLI needs an explicit state markdown input.
- A payload-only renderer would make comments harder to read and would lose the
  curated validation notes and guardrails that belong in the markdown
  execution-state file.
- Making `--summary-file` invalid for all state posts immediately could break
  external callers. runtime-kit should migrate immediately; broader deprecation
  can be handled in the `nils-cli` release notes.
- Closeout gates currently see machine completeness. Add visible ledger checks
  at the skill/test layer first, and only promote stricter CLI closeout checks
  if there is a clean way to inspect comment text without breaking old records.
- Collapsing markdown is feasible because GitHub supports `<details>` /
  `<summary>` blocks in issue comments. The implementation risk is not provider
  support; it is making the markdown section transform narrow enough that it
  does not accidentally fold validation, closeout, or hidden payload content.
- CLI-only auto detection cannot know future issue timeline intent. The
  recommended contract uses payload terminal state as the default and lets
  runtime-kit skills override the display mode explicitly when they know a state
  post is final or intermediate.
- Rendering visible evidence from payload introduces formatting decisions, but
  it is lower risk than relying on every caller to author detailed summaries.
  Keep the generated sections compact and test them with stable payload
  fixtures.

## Read-First References

- Issue #112 final state comment:
  <https://github.com/graysurf/agent-runtime-kit/issues/112#issuecomment-4534882256>
- `docs/source/nils-cli-surface.md`
- `core/skills/dispatch/create-plan-tracking-issue/SKILL.md.tera`
- `core/skills/dispatch/execute-plan-tracking-issue/SKILL.md.tera`
- `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
- `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`
- `tests/runtime-smoke/cases/dispatch/run.sh`
- `sympoies/nils-cli:crates/plan-issue-cli/src/commands/record.rs`
- `sympoies/nils-cli:crates/plan-issue-cli/src/execute.rs`
- `sympoies/nils-cli:crates/plan-issue-cli/src/lifecycle_record.rs`
- `sympoies/nils-cli:crates/plan-issue-cli/tests/integration/live_record_ops.rs`

## Recommended Next Artifact

Create
`docs/plans/plan-issue-lifecycle-comment-visibility/plan-issue-lifecycle-comment-visibility-plan.md`
from this source document, then implement in this order:

1. `nils-cli` CLI, renderer, and tests.
2. `nils-cli` release or local floor update.
3. runtime-kit skill contract updates.
4. runtime-kit runtime-smoke, render, golden, and surface pin updates.

## Retention Intent

This document is coordination material under `docs/plans/`. Revisit after the
fix lands: delete it if the final plan and implemented docs supersede it, or
promote only the durable `plan-issue` state-posting contract into the relevant
skill source and `nils-cli` surface documentation.
