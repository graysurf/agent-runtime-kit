# Plan: SUPPORT_MATRIX Rendered + Acceptance-In-Manifest

## Overview

Promote `SUPPORT_MATRIX.md` from a hand-authored cheatsheet into a
manifest-rendered build artifact, and make the per-row acceptance
columns typed in `manifests/` so `agent-runtime doctor` can execute
them. Plan F4 from the closed `docs/plans/2026-05-23-support-matrix/` plan
carries forward unchanged: no tool may parse the markdown matrix; the
manifests stay canonical. Gap B (new `--class support-matrix` doctor
class) and Gap D (sandbox post-install doctor pass) are explicitly
deferred to separate later plans.

## Read First

- Primary source: docs/plans/2026-05-23-support-matrix-rendered/support-matrix-rendered-discussion-source.md
- Source type: discussion-to-implementation-doc
- Recommended plan: docs/plans/2026-05-23-support-matrix-rendered/support-matrix-rendered-plan.md
- Recommended execution state: docs/plans/2026-05-23-support-matrix-rendered/support-matrix-rendered-execution-state.md
- Closed plan to cite for background:
  - docs/plans/2026-05-23-support-matrix/support-matrix-discussion-source.md (origin of Plan F4)
  - docs/plans/2026-05-23-support-matrix/support-matrix-execution-state.md (17/17 row evidence trail)
- Closed tracking issue (do not reopen):
  <https://github.com/graysurf/agent-runtime-kit/issues/64>
  (closeout comment
  <https://github.com/graysurf/agent-runtime-kit/issues/64#issuecomment-4525489698>)
- Open questions carried into execution: surface registry location;
  cross-product render mode; build path for rendered matrix;
  `success` predicate semantics for acceptance entries; Claude-side
  asymmetry encoding. Each Sprint 1/2/3 task names which open
  question it resolves.

## PR Split

- Sprint 1 ships as one PR (`feat/support-matrix-rendered-sprint-1`):
  surface registry location, schema, registry rows, success
  predicate semantics, Claude-side asymmetry encoding.
- Sprint 2 ships as one PR (`feat/support-matrix-rendered-sprint-2`):
  render-mode rationale, renderer implementation, CI integration,
  golden fixture, root-file header + cross-links, perturbation
  test.
- Sprint 3 ships as one PR (`feat/support-matrix-rendered-sprint-3`):
  pick ≥2 executable rows, CI lane that runs them, schema-validation
  negative test.
- Sprint 4 (this plan-bundle PR) and Sprint 5 (live-issue follow-up)
  ship as separate PRs each. Sprint 4 is the
  `feat/support-matrix-rendered` plan-bundle PR; Sprint 5.3 is a
  small `feat/support-matrix-rendered-live-issue` follow-up.
- Sprint 1, 2, 3 PRs all attach to the live tracking issue created
  in Sprint 5.2.

## Scope

- In scope:
  - New `docs/plans/2026-05-23-support-matrix-rendered/` plan bundle (this
    file plus the discussion source and execution state).
  - One canonical manifest entry-point for the matrix's 17-surface
    row set (location decided in Sprint 1).
  - New JSON schema (or extension of an existing one) under
    `core/docs/schemas/` covering the surface registry and the
    acceptance entry shape locked in the discussion source.
  - Renderer support that emits a cross-product
    `build/.../SUPPORT_MATRIX.md` byte-equal to the committed root
    file (modulo the locked `<!-- generated ... -->` header).
  - `scripts/ci/all.sh` gate update so audit-drift catches
    source-vs-rendered diffs.
  - Golden fixture under `tests/golden/` for the rendered matrix.
  - At least 2 executable acceptance entries (Gap C non-vacuity
    rule) plus the CI lane that runs them.
  - Cross-link update in `SUPPORT_MATRIX.md` itself noting it is
    now generated; cross-link in
    `docs/source/inventory-target-architecture.md`.
  - Dry-run tracking-issue artifacts under
    `docs/plans/2026-05-23-support-matrix-rendered/tracking-issue/`.
- Out of scope (deferred plans):
  - **Gap B**: a new `agent-runtime doctor --class support-matrix`
    (or `surface-coverage`) class that probes manifest-listed
    surfaces against the live runtime home.
  - **Gap D**: running `agent-runtime doctor --live-home <sandbox>`
    after the sandbox install rehearsal CI gate.
  - Re-deriving `harness-shape-{codex,claude}.md` from the same
    manifest source.
  - Renaming or moving `SUPPORT_MATRIX.md` away from the repo root.
  - Cutting a nils-cli release. The renderer change is contained
    inside agent-runtime-kit's own CLI / library code.
  - Adding new harness primitives that the existing 17-surface set
    does not already cover.

## Sprint 1: Manifest registry + schema

**Goal**: Decide the surface registry location, land a typed schema
that covers both the surface registry and acceptance entries, and
populate the registry rows the renderer will later consume.

**PR grouping intent**: `group`
**Execution Profile**: `serial`

### Task 1.1: Pin surface registry location

- **Location**:
  - `docs/plans/2026-05-23-support-matrix-rendered/support-matrix-rendered-execution-state.md`
    (Decision record).
  - `manifests/` (chosen file path; either new
    `manifests/surfaces.yaml` or extended
    `manifests/product-capabilities.yaml`).
- **Description**: Resolve the "Surface registry location" open
  question from the discussion source. Compare new-file vs
  in-place-extension on three axes: schema-per-file convention
  fit, manifest-count creep, and `agent-runtime` reader path
  ergonomics. Record the decision and rationale.
- **Dependencies**:
  - none
- **Acceptance criteria**:
  - The decision is recorded with a one-paragraph rationale.
  - The chosen file path is created (empty or with a top-of-file
    schema_version stanza only) so later tasks have a stable
    target.
- **Validation**:
  - `git diff --stat manifests/` shows the chosen file added or
    extended exactly once.

### Task 1.2: Add surface registry + acceptance schema

- **Location**:
  - `core/docs/schemas/<chosen-schema>.schema.json` (new file or
    extension of an existing schema; chosen to match Task 1.1).
- **Description**: Encode the surface registry row shape and the
  acceptance entry shape locked in the discussion source: fields
  `kind` ∈ `{ci, live}`, exactly one of `command` or `note`, an
  optional `descriptive_only: true` flag, and an optional
  `success` predicate whose shape Task 1.4 will pin. The schema
  must be additive against existing `manifests/*.yaml` shapes; do
  not invalidate any currently-committed manifest.
- **Dependencies**:
  - Task 1.1
- **Acceptance criteria**:
  - JSON Schema validates with a standards-compliant validator
    (the validator used by the rest of `core/docs/schemas/`).
  - The schema permits `descriptive_only: true` rows that omit
    `command` and `success`.
  - The schema rejects rows that have both `command` and `note`
    populated, or that omit both.
- **Validation**:
  - First, audit what JSON Schema validator (if any) the repo
    runs against `core/docs/schemas/` today by grepping
    `scripts/ci/all.sh`, `tests/`, and `Cargo.toml`. If none
    exists, add a minimal validator step in this task's scope
    (e.g. `cargo test` against the `jsonschema` crate). Record
    the chosen validator in the execution state.
  - A negative test: a fixture manifest violating the schema is
    rejected by the chosen validator.

### Task 1.3: Populate registry rows

- **Location**:
  - The manifest file from Task 1.1.
- **Description**: Add the 17-surface canonical row set, with the
  Claude-side asymmetry encoded per the open-question resolution
  in Task 1.5 (either `applicable_products: [codex]` for
  codex-only surfaces or explicit per-product `state` entries).
  Every row must reproduce the data currently visible in the
  hand-authored `SUPPORT_MATRIX.md`. No new fact may be
  introduced that is not already in `SUPPORT_MATRIX.md` or the
  closed plan's evidence trail.
- **Dependencies**:
  - Task 1.2
- **Acceptance criteria**:
  - 17 codex rows and 17 claude rows materialise from the
    manifest registry once the renderer (Sprint 2) consumes it.
    Sprint 1 only requires that the rows exist in the manifest;
    Sprint 2 verifies the count downstream.
  - All currently-committed `SUPPORT_MATRIX.md` row content can be
    derived from the registry plus the existing
    `manifests/{runtime-roots,skills,plugins,cli-tools}.yaml`
    entries; nothing in the matrix needs to be hand-fed beyond
    what is already in `manifests/`.
- **Validation**:
  - Cross-reference each row against
    `docs/source/harness-shape-codex.md` (17 primitives) and
    `docs/source/harness-shape-claude.md` (14 primitives + 3
    codex-only asymmetry rows).

### Task 1.4: Pin `success` predicate semantics (exit-status only)

- **Location**:
  - The schema file from Task 1.2.
  - `docs/plans/2026-05-23-support-matrix-rendered/support-matrix-rendered-execution-state.md`
    (Decision record).
- **Description**: The `success` predicate is locked to
  exit-status-only for this plan: `{exit_status: 0}` or
  `{exit_status: <integer>}`. Richer predicates (regex on stdout,
  JSON-path on a typed envelope) are explicitly out of scope and
  belong to Gap B's follow-up plan if they are ever needed. Task
  1.4 encodes the locked shape in the schema and records the
  rationale (avoids dragging a regex engine / JSON-path evaluator
  into `agent-runtime`'s ABI for the ≥2 executable rows that Gap
  C needs).
- **Dependencies**:
  - Task 1.2
- **Acceptance criteria**:
  - Schema accepts `{exit_status: <int>}` and rejects every other
    `success` predicate shape (regex, JSON-path, string).
  - The Gap-B-deferral rationale is recorded in execution state.
- **Validation**:
  - Same negative-test fixture as Task 1.2 extended with a
    `success: {regex: ...}` row to confirm rejection.

### Task 1.5: Resolve Claude-side asymmetry encoding

- **Location**:
  - The manifest file from Task 1.1.
  - `docs/plans/2026-05-23-support-matrix-rendered/support-matrix-rendered-execution-state.md`
    (Decision record).
- **Description**: Pick one: (a) `applicable_products: [codex]`
  on codex-only surfaces, with the renderer auto-emitting
  `not-applicable` rows on the other side; or (b) explicit
  per-product `state` rows in the registry. Encode the choice in
  the registry rows.
- **Dependencies**:
  - Task 1.3
- **Acceptance criteria**:
  - The 3 codex-only surfaces (15 `$CODEX_HOME/skills`, 16
    `config.toml` managed block, 17 prompt-mode delegation
    policy) are encoded such that the renderer can emit
    `support_state = not-applicable` on the Claude side.
- **Validation**:
  - The renderer in Sprint 2 produces 17 claude rows including
    these 3 `not-applicable` entries with no manual list.

## Sprint 2: Renderer + CI integration

**Goal**: Implement the cross-product renderer, wire it into the
existing CI gate stack, add a golden fixture, and prove the closed
plan's reopen triggers fire automatically through audit-drift.

**PR grouping intent**: `group`
**Execution Profile**: `serial`

### Task 2.1: Record render-mode rationale

- **Location**:
  - `docs/plans/2026-05-23-support-matrix-rendered/support-matrix-rendered-execution-state.md`
    (Decision record).
- **Description**: The cross-product render mode is already
  locked to option (b) `--target support-matrix` in the discussion
  source (the locked header `<!-- generated by agent-runtime render
  --target support-matrix; do not edit -->` pre-decides it). Task
  2.1 records the rationale (option (b) keeps the build-tree walk
  one level under `build/`, lets `audit-drift` reach the rendered
  file through the existing per-product entry points, adds the
  smallest CLI surface) and the impact on `scripts/ci/all.sh`
  (extends gate 2/3, no new gate). No option may read
  `SUPPORT_MATRIX.md` as input (Plan F4 carry-forward).
- **Dependencies**:
  - none
- **Acceptance criteria**:
  - The rationale is recorded as a Decision row in execution state.
  - `scripts/ci/all.sh` impact is recorded as part of the same row.
- **Validation**:
  - `agent-runtime render --help` shows `--target support-matrix`
    after Task 2.2 lands.

### Task 2.2: Implement renderer

- **Location**:
  - `agent-runtime` source (Rust) for the chosen render mode.
- **Description**: Implement the render mode pinned in Task 2.1.
  Consume the surface registry from Task 1.3 and the per-product
  data already in `manifests/runtime-roots.yaml`,
  `manifests/skills.yaml`, etc. Emit
  `build/<chosen-path>/SUPPORT_MATRIX.md` starting with the locked
  header comment `<!-- generated by agent-runtime render
  --target support-matrix; do not edit -->`, an empty line, then
  the matrix content. Trailing newline policy: exactly one.
- **Dependencies**:
  - Task 1.5
  - Task 2.1
- **Acceptance criteria**:
  - `diff -u` between the root `SUPPORT_MATRIX.md` and the
    renderer output differs only in the locked header line (the
    renderer adds it; the root file does not yet have it — Task
    2.5 wires the root file to the same shape).
  - No `drift-audit.allow.yaml` entry is added to mask any cosmetic
    delta; if the diff is non-empty beyond the header, hand-edit
    the renderer until it is empty.
- **Validation**:
  - `agent-runtime render` (with whichever flag combination Task
    2.1 picked) exits `0`.
  - `diff -u` between the root `SUPPORT_MATRIX.md` and the
    renderer output returns empty after Task 2.5 lands.

### Task 2.3: Wire renderer into `scripts/ci/all.sh`

- **Location**:
  - `scripts/ci/all.sh`.
  - `DEVELOPMENT.md` lines 157-168 (gate list).
- **Description**: Add the renderer invocation to the CI gate stack
  so that audit-drift (gate 5) sees the rendered file under
  `build/`. If Task 2.1 chose option (a) or (b), this folds into
  the existing render gates 2/3; if (c) or (d), it is a new gate
  positioned before gate 5.
- **Dependencies**:
  - Task 2.2
- **Acceptance criteria**:
  - `bash scripts/ci/all.sh` passes from a fresh clone with the
    rendered matrix step included.
  - `DEVELOPMENT.md` gate list updated to match.
- **Validation**:
  - `bash scripts/ci/all.sh` exits `0`.

### Task 2.4: Golden fixture for rendered matrix

- **Location**:
  - `tests/golden/<chosen-path>/SUPPORT_MATRIX.md`.
- **Description**: Add a golden fixture so render-golden refresh
  (gate 4) catches accidental matrix content shifts the same way
  it catches per-product render output shifts today.
- **Dependencies**:
  - Task 2.2
- **Acceptance criteria**:
  - `agent-runtime render --update-golden` writes the fixture.
  - `git diff --exit-code -- tests/golden/` is clean after a
    second render.
- **Validation**:
  - Same as gate 4 today: render, refresh golden, diff exit code 0.

### Task 2.5: Cross-link update and root-file header

- **Location**:
  - `SUPPORT_MATRIX.md` (root) — add the locked header so root
    and rendered files match.
  - `docs/source/inventory-target-architecture.md` (architecture
    pointer + revisions entry).
- **Description**: Add the `<!-- generated by ... -->` header to
  the root `SUPPORT_MATRIX.md`. Add a paragraph in
  `inventory-target-architecture.md` noting the matrix is now
  rendered and pointing at the surface registry path from Task
  1.1.
- **Dependencies**:
  - Task 2.2
- **Acceptance criteria**:
  - Root and rendered file diff is empty (the byte-equal first
    cut from the discussion source's Decisions).
  - Architecture doc has exactly one new pointer paragraph and
    one revisions entry.
- **Validation**:
  - `diff -u` between the root `SUPPORT_MATRIX.md` and the
    renderer output returns empty.
  - `grep -l SUPPORT_MATRIX docs/source/inventory-target-architecture.md`
    succeeds.

### Task 2.6: Perturbation test for reopen-trigger automation

- **Location**:
  - Implementation worktree only (no committed change).
- **Description**: Verify the closed plan's three reopen triggers
  now fire through audit-drift rather than human notice. Run
  three perturbations in sequence, each followed by
  `agent-runtime audit-drift`, with a worktree revert in between:
  1. Append a fake primitive to
     `docs/source/harness-shape-codex.md` (a new `### 18.
     fake-primitive` block) and confirm audit-drift surfaces a
     finding on the rendered matrix (the new primitive has no
     matching registry row → renderer output diverges from root).
  2. Bump `manifests/runtime-roots.yaml` codex `min_version`
     (e.g. `0.130.0` → `0.131.0`) and confirm audit-drift
     surfaces a source-vs-rendered finding on the rendered
     matrix (the version column shifts under the renderer but
     not the root file).
  3. Edit `docs/source/nils-cli-surface.md` snapshot version pin
     (e.g. `v0.17.6` → `v0.17.7`) and confirm audit-drift
     surfaces a finding the same way.
- **Dependencies**:
  - Task 2.3
  - Task 2.5
- **Acceptance criteria**:
  - All three perturbations produce an audit-drift finding citing
    the rendered matrix path.
  - The worktree is clean at the end (each perturbation reverted).
- **Validation**:
  - Three `agent-runtime audit-drift` runs whose findings are
    captured in the execution-state evidence column.
  - `git status` clean afterwards.

## Sprint 3: Gap C executable acceptance

**Goal**: Take at least 2 acceptance entries from prose to
executable, wire a CI lane that runs them, and prove the executable
path works end-to-end.

**PR grouping intent**: `group`
**Execution Profile**: `serial`

### Task 3.1: Pick ≥2 executable acceptance rows

- **Location**:
  - `docs/plans/2026-05-23-support-matrix-rendered/support-matrix-rendered-execution-state.md`
    (Decision record).
  - The manifest file from Task 1.1.
- **Description**: Choose ≥2 cross-product acceptance entries to
  promote from `descriptive_only: true` to an executable
  `command` + `success: {exit_status: 0}` predicate. The
  implementer should inspect the current 34-row matrix on
  inspection and pick rows whose acceptance is genuinely
  shell-runnable on a host that has the runtime homes set up
  (e.g. rows whose `mechanism` already names a symlink or a
  binary version probe). Record the chosen rows and the rationale.
- **Dependencies**:
  - Task 1.4
- **Acceptance criteria**:
  - ≥2 entries flip from `descriptive_only: true` to executable.
  - The promoted rows cover both `kind=ci` and `kind=live` at
    least once across them.
- **Validation**:
  - `grep -c 'descriptive_only: true' <manifest>` decreases by ≥2.

### Task 3.2: CI lane that executes the promoted entries

- **Location**:
  - `scripts/ci/all.sh` (new gate after audit-drift) or
    `tests/<existing-runner>.sh`.
- **Description**: Add a CI step that iterates promoted acceptance
  entries, runs each `command`, and asserts the `success`
  predicate passes. Failures are blocking. Use the same JSON
  envelope shape as other `agent-runtime` doctor checks for
  consistency.
- **Dependencies**:
  - Task 3.1
- **Acceptance criteria**:
  - The new CI step runs ≥2 commands and exits `0` when all
    `success` predicates pass.
  - The CI step fails fast if any `command` is missing on `PATH`
    or any `success` predicate fails.
- **Validation**:
  - `bash scripts/ci/all.sh` exits `0`.
  - Force-fail one promoted entry locally and confirm the gate
    blocks.

### Task 3.3: Schema-validation negative test

- **Location**:
  - `tests/<negative-fixture-path>/`.
- **Description**: Add a negative-test fixture where an acceptance
  entry is malformed (missing required field, both `command` and
  `note` set, `success` predicate violating the locked shape).
  CI must catch it.
- **Dependencies**:
  - Task 1.4
- **Acceptance criteria**:
  - The fixture file is committed under `tests/`.
  - Running the schema validator on the fixture yields a non-zero
    exit and a clear error message naming the violation.
- **Validation**:
  - Same schema validator invocation as Task 1.2 against the
    fixture.

## Sprint 4: Plan-bundle tracking artifacts + PR delivery

**Goal**: Render the dry-run tracking-issue artifacts alongside this
plan bundle, run the multi-lens code review, apply fixes, and deliver
the bundle to `main` via a single PR. This is the only Sprint
executed in the bundle PR itself; Sprints 1-3 execute in later PRs
that attach to the live tracking issue.

**PR grouping intent**: `group`
**Execution Profile**: `serial`

### Task 4.1: Render tracking-issue artifacts (dry-run)

- **Location**:
  - `docs/plans/2026-05-23-support-matrix-rendered/tracking-issue/` (new
    directory).
- **Description**: Run `plan-issue record render-dashboard` plus
  three `render-comment --kind {source,plan,state}` invocations
  with `--marker-family compat` (matching #64). Output four files:
  `dashboard.md`, `source-comment.md`, `plan-comment.md`,
  `state-comment.md`. Sprint 1-3 tasks are still pending at this
  point; Task 4.1 produces artifacts against the plan-bundle
  authoring state, not an executed state. Render-dashboard flag
  set (mirrors #64's working set, confirmed in the closeout dry
  run earlier this session): `--profile tracking --status
  in-progress --target-scope "<one-line scope>" --current "Sprint
  1 Task 1.1 — pin surface registry location" --next-action
  "Sprint 1 Task 1.2 — add surface registry + acceptance schema"
  --validation pending --approval pending --title "<plan title>"
  --source-url <source-comment-url-after-post>
  --plan-url <plan-comment-url-after-post>
  --state-url <state-comment-url-after-post>`. Source-/plan-/state-
  URLs land only after Sprint 5.2 posts the live comments; in
  Sprint 4.1 they stay blank or carry the in-tree path until
  rerun in Sprint 5.1.
- **Dependencies**:
  - none
- **Acceptance criteria**:
  - Four files under `tracking-issue/`, each carrying the
    documented compat marker.
  - Dashboard `Status: in-progress`; `Current: Sprint 1 Task 1.1`;
    `Next: Sprint 1 Task 1.2`.
- **Validation**:
  - `plan-tooling validate --file docs/plans/2026-05-23-support-matrix-rendered/support-matrix-rendered-plan.md --explain`
  - Re-render each artifact and `diff -u` against the committed
    copy to confirm determinism.

### Task 4.2: Multi-lens specialist review

- **Location**:
  - New evidence record under
    `<state_home>/out/projects/<repo>/<run-id>-support-matrix-rendered-review/`.
- **Description**: Allocate the evidence directory through
  `agent-out project --topic support-matrix-rendered-review --mkdir`.
  Run `code-review:code-review-specialists` across the plan
  bundle (this file, the discussion source, the execution state,
  the four tracking-issue artifacts). Capture findings as
  `findings.jsonl` then run
  `review-specialists validate / merge / bundle`. The discussion
  source itself was already reviewed and folded in this session;
  this review's primary target is the plan and tracking-issue
  artifacts.
- **Dependencies**:
  - Task 4.1
- **Acceptance criteria**:
  - Review evidence directory exists with at least one finding
    file.
  - Blocking findings (if any) reference exact paths and lines.
- **Validation**:
  - `review-specialists merge --input findings.jsonl
    --summary-out specialist-review.md --format json` exits `0`.

### Task 4.3: Apply review fixes

- **Location**:
  - Any of: plan-doc, execution-state, tracking-issue artifacts.
- **Description**: Fold blocking findings; fold warn findings
  unless explicitly deferred with a waiver row in the execution
  state. Re-render tracking-issue artifacts after any material
  edit and re-diff.
- **Dependencies**:
  - Task 4.2
- **Acceptance criteria**:
  - Zero blocking findings remain.
  - Deferred warn findings have waiver rows.
- **Validation**:
  - `plan-tooling validate` exits `0`.
  - `diff` after re-render returns empty.

### Task 4.4: Commit via semantic-commit

- **Location**:
  - working tree on `feat/support-matrix-rendered`.
- **Description**: Stage the entire plan bundle (this file, the
  discussion source, the execution state, the four tracking-issue
  artifacts). Commit through `semantic-commit` (or
  `semantic-commit-autostage`); direct `git commit` is
  hook-blocked. Scope: `(plans)`.
- **Dependencies**:
  - Task 4.3
- **Acceptance criteria**:
  - HEAD shows one commit with a `semantic-commit`-shaped message.
  - `git status` is clean.
- **Validation**:
  - `git log --oneline -1`
  - `git status`

### Task 4.5: PR deliver to main

- **Location**:
  - GitHub `graysurf/agent-runtime-kit` `main`.
- **Description**: Use `pr:deliver-github-pr` (i.e. `forge-cli pr
  deliver`) to open the PR against `main`. Confirm a 1-2 sentence
  summary with the user before the skill opens the PR — never
  derive the title or body from `git log -1`. Wait for CI; merge
  after green.
- **Dependencies**:
  - Task 4.4
- **Acceptance criteria**:
  - PR opens, CI green, PR merges to `main`.
  - PR description links the plan bundle.
- **Validation**:
  - `forge-cli pr view <N> --format json` shows `state=merged`.

## Sprint 5: Live tracking issue (post-merge)

**Goal**: After the plan-bundle PR merges to `main`, open the live
GitHub tracking issue from the now-committed plan bundle so the
Sprint 1-3 implementation work has a real issue to attach to.

**PR grouping intent**: `per-sprint`
**Execution Profile**: `serial`

### Task 5.1: Re-render dashboard with post-merge commit SHA

- **Location**:
  - rendered output only (no repo file change).
- **Description**: Re-run `plan-issue record render-dashboard` and
  `render-comment --kind source/plan/state` using the merge
  commit SHA on `main`. Confirm the resulting markdown is
  byte-equal to the committed tracking-issue artifacts apart
  from the commit field.
- **Dependencies**:
  - Task 4.5
- **Acceptance criteria**:
  - Diff against committed artifacts is empty except for the
    commit field updates.
- **Validation**:
  - `diff -u` against committed artifacts shows only the
    `Commit:` field diff per file.

### Task 5.2: forge-cli issue create + lifecycle comments

- **Location**:
  - GitHub `graysurf/agent-runtime-kit` issues.
- **Description**: Preflight first — `forge-cli issue list --repo
  graysurf/agent-runtime-kit --label plan --state open --format
  json | jq '.[] | select(.title=="SUPPORT_MATRIX rendered + acceptance-in-manifest")'`.
  If a match exists from an earlier partial run, resume by
  posting any missing lifecycle comments and editing the
  dashboard rather than creating a duplicate. Otherwise run
  `forge-cli issue create --provider github --label plan` with
  the re-rendered dashboard, record the returned issue number in
  a scratch file in the worktree, then post the three lifecycle
  comments and edit the issue body with the resulting comment
  URLs. This is the only live mutation in the plan; confirm with
  the user before executing.
- **Dependencies**:
  - Task 5.1
- **Acceptance criteria**:
  - Issue exists with `plan` label and the three lifecycle
    comments attached.
  - Issue body Current Dashboard references the three comment
    URLs.
  - Exactly one open issue carries the plan title; rerunning the
    task with the preflight check produces zero duplicates.
- **Validation**:
  - `forge-cli issue list --repo graysurf/agent-runtime-kit
    --label plan --state open --format json`
  - `gh issue view "$(jq -r .number issue-number.json)" --json comments > comments.json && plan-issue record audit --profile tracking --body-file dashboard.md --comments-json comments.json --format text`

### Task 5.3: Record issue URL in execution state

- **Location**:
  - `docs/plans/2026-05-23-support-matrix-rendered/support-matrix-rendered-execution-state.md`.
- **Description**: Update the execution state with the live issue
  URL and the three lifecycle comment URLs. Open a small
  follow-up PR (single commit through `semantic-commit`) so
  `main` records the linkage.
- **Dependencies**:
  - Task 5.2
- **Acceptance criteria**:
  - Execution state shows live issue URL and lifecycle comment
    URLs.
  - Follow-up PR is open or merged.
- **Validation**:
  - `gh pr list --head feat/support-matrix-rendered-live-issue
    --json state,number`
  - `git grep -n 'issues/' docs/plans/2026-05-23-support-matrix-rendered/support-matrix-rendered-execution-state.md`

## Validation

| Command | When | Notes |
| --- | --- | --- |
| `plan-tooling validate --file docs/plans/2026-05-23-support-matrix-rendered/support-matrix-rendered-plan.md --format text --explain` | before Sprint 4 commit | Run inside the worktree. |
| `agent-runtime audit-drift` | before Sprint 4 commit | Must exit `0`; allowlist entry is forbidden per Decisions. |
| `bash scripts/ci/all.sh` | before PR open | Full local gate. |
| `plan-issue record audit --profile tracking ...` | Sprint 4.1 + 5.1 | Confirms marker compatibility. |
| `agent-runtime audit-drift` (post-perturbation) | Sprint 2.6 | Confirms reopen triggers auto-fire. |

## Closeout Gate

- Close condition: PR with the plan bundle, dry-run tracking-issue
  artifacts merges to `main`; Sprint 1-3 implementation PRs all
  merge attached to the live tracking issue; live GitHub tracking
  issue created via Sprint 5 with the post-merge SHA, lifecycle
  comments + dashboard wired, and the close-readiness flow run
  through `dispatch:plan-tracking-issue-closeout` once Sprint 1-3
  are done.
- Reopen triggers (forward-looking, replace those of the closed
  plan once Gap A lands):
  - A new harness primitive lands in either shape doc without a
    matching surface registry row.
  - The surface registry schema adds a new required field that
    pre-existing rows do not satisfy.
  - The renderer's golden fixture diverges from the rendered
    output without a corresponding manifest change in the same
    commit (audit-drift gate 5 catches this automatically; the
    trigger fires when audit-drift reports a finding citing the
    rendered matrix path).
  - A new acceptance entry is added with neither `command` nor
    `note`, or with both, or with a `success` predicate violating
    the locked shape.
