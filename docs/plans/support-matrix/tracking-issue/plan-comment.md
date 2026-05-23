<!-- plan-tracking-issue:snapshot:v1 kind=plan -->

## Plan Snapshot

- Path: `docs/plans/support-matrix/support-matrix-plan.md`
- Commit: `0aae4cc90500872b3261fcb6b25cae1c3f3fa5d1`

- Snapshot mode: local committed Markdown

<details>
<summary>Plan snapshot</summary>

# Plan: SUPPORT_MATRIX.md Design And Delivery

## Overview

Ship a root-level `SUPPORT_MATRIX.md` as the single human-readable view
over the per-product harness shape inventories. The matrix follows a
long-format normalized schema (one row per surface × product) so
Codex-only, Claude-only, and shared primitives can coexist without
forcing N/A cells. Manifests remain the source of truth; the matrix is
a derived view kept honest by drift audit, not a parsed gate.

## Read First

- Primary source: docs/plans/support-matrix/support-matrix-discussion-source.md
- Source type: discussion-to-implementation-doc
- Open questions carried into execution: render-vs-hand-authored
  cadence; root vs `docs/source/` placement; whether `drift-audit`
  grows a dedicated `support-matrix` class or re-renders + diffs.

## Scope

- In scope:
  - New `docs/plans/support-matrix/` plan bundle (this file plus the
    discussion source and execution state).
  - New root-level `SUPPORT_MATRIX.md` with the long-format schema
    defined in Sprint 1.
  - A short "How this matrix is maintained" section in
    `SUPPORT_MATRIX.md` pointing back at the canonical manifests.
  - Reference from `docs/source/inventory-target-architecture.md` to
    `SUPPORT_MATRIX.md` as the human-readable view.
  - Drift-audit allowlist or schema scaffolding only if necessary to
    avoid false positives on the new file.
- Out of scope:
  - Implementing `agent-runtime render --target support-matrix` in
    nils-cli (logged as an extraction candidate; separate plan in
    `sympoies/nils-cli` if and when chosen).
  - Adding a Claude-side `agent-runtime doctor --class skill-surface
    --product claude` diagnostic (recorded in matrix notes as a known
    asymmetry; separate plan).
  - Editing `manifests/*.yaml`; the matrix consumes these unchanged.
  - Modifying the existing `harness-shape-{claude,codex}.md` shape
    docs except to add a one-line "see SUPPORT_MATRIX.md" pointer.
  - Renaming or relocating either shape doc.
  - Adding a Tera template that renders the matrix; the first cut is
    hand-authored.

## Sprint 1: Schema + first authored cut

**Goal**: Define the long-format schema and land the hand-authored
first cut of `SUPPORT_MATRIX.md` so reviewers see the intended shape
before any automation discussion.

**PR grouping intent**: `group`
**Execution Profile**: `serial`

### Task 1.1: Pin the row schema

- **Location**:
  - `SUPPORT_MATRIX.md` (new file, "Schema" section near the top).
- **Description**: Define the row schema as a markdown table with the
  exact column set:
  `surface`, `product` (`codex` | `claude`), `support_state`
  (`shipped` | `partial` | `planned-not-shipped` | `not-shipped` |
  `not-applicable`), `mechanism`, `source_artifact` (newline-separated
  list when multi-path), `min_product_version`, `min_nils_cli`,
  `ci_acceptance`, `live_acceptance`, `source_manifest`. Column
  semantics + state legend are explained inline so the file is
  self-contained for a first-time reader.
- **Dependencies**:
  - none
- **Acceptance criteria**:
  - Schema section lists every column with one-line semantics.
  - `support_state` legend matches the five-value enum in
    `docs/source/harness-shape-claude.md:286-294`.
  - `live_acceptance` is documented as separate from
    `ci_acceptance` so the live Codex Desktop / live Claude session
    gap is visible.
- **Validation**:
  - `grep -E '^\\| surface ' SUPPORT_MATRIX.md` returns the column
    header row.
  - `grep -E 'not-applicable' SUPPORT_MATRIX.md` confirms the legend
    distinguishes it from `not-shipped`.

### Task 1.2: Populate Codex rows

- **Location**:
  - `SUPPORT_MATRIX.md` (Codex section).
- **Description**: Walk through every primitive in
  `docs/source/harness-shape-codex.md` and emit one row per primitive
  with `product=codex`. Cite `source_manifest` per row pointing at the
  manifest entry the row was sourced from. Mark Claude-only primitives
  (marketplace, settings.json, output-styles, statusLine, agents,
  commands, plugin-scoped skill discovery) with `support_state =
  not-applicable` and a short note linking to Resolved Decision #10 in
  `docs/source/inventory-target-architecture.md:2049-2073`.
- **Dependencies**:
  - Task 1.1
- **Acceptance criteria**:
  - Every primitive in `harness-shape-codex.md` has exactly one row.
  - Every `not-applicable` row cites the reality-check section.
  - `min_product_version` reads `0.130.0` for every Codex row
    sourced from `manifests/runtime-roots.yaml`.
  - The two row counts emitted by the validation block are equal.
- **Validation**:
  - `expected=$(grep -c '^### [0-9]\\+\\.' docs/source/harness-shape-codex.md); actual=$(grep -c '^| .* | codex |' SUPPORT_MATRIX.md); echo expected=$expected actual=$actual; [ "$expected" = "$actual" ]`

### Task 1.3: Populate Claude rows

- **Location**:
  - `SUPPORT_MATRIX.md` (Claude section).
- **Description**: Same as 1.2 but for
  `docs/source/harness-shape-claude.md`. Codex-only primitives (the
  `config.toml` managed block, `$CODEX_HOME/skills` direct discovery
  root, prompt-mode subagents) get `support_state = not-applicable`
  on the Claude side with a note citing the Codex reality check.
- **Dependencies**:
  - Task 1.1
- **Acceptance criteria**:
  - Every primitive in `harness-shape-claude.md` has exactly one row.
  - `min_product_version` reads `2.1.145` for every Claude row sourced
    from `manifests/runtime-roots.yaml`.
  - `min_nils_cli` matches the surface-level pin `v0.17.5` unless a
    skill-level `required_clis` floor is tighter (heuristic-inbox,
    state_home rows).
  - The two row counts emitted by the validation block are equal.
- **Validation**:
  - `expected=$(grep -c '^### [0-9]\\+\\.' docs/source/harness-shape-claude.md); actual=$(grep -c '^| .* | claude |' SUPPORT_MATRIX.md); echo expected=$expected actual=$actual; [ "$expected" = "$actual" ]`

### Task 1.4: Cross-link from inventory doc and shape docs

- **Location**:
  - `docs/source/inventory-target-architecture.md` (single revisions
    entry + one paragraph pointer near the top of the document).
  - `docs/source/harness-shape-claude.md` (one-line pointer).
  - `docs/source/harness-shape-codex.md` (one-line pointer).
- **Description**: Add a brief pointer in each upstream doc to
  `SUPPORT_MATRIX.md` as the human-readable view; do not move or
  rewrite content already in the shape docs.
- **Dependencies**:
  - Task 1.2
  - Task 1.3
- **Acceptance criteria**:
  - Each touched file has exactly one new pointer paragraph or line.
  - `git diff --stat` for this task shows three files touched and
    edits localised to a single hunk per file.
- **Validation**:
  - `grep 'SUPPORT_MATRIX.md' docs/source/inventory-target-architecture.md docs/source/harness-shape-claude.md docs/source/harness-shape-codex.md`
    returns at least one match per file.

### Task 1.5: Drift audit accommodation

- **Location**:
  - `drift-audit.allow.yaml` (new entry, if needed).
- **Description**: If `agent-runtime audit-drift` flags
  `SUPPORT_MATRIX.md` because of the unsafe-score keyword heuristic
  (the row text repeats `token` / `secret`-shaped words in the legend
  / examples), add a single allowlist entry with `path:
  SUPPORT_MATRIX.md` and a short reason. Otherwise this task closes
  with no change.
- **Dependencies**:
  - Task 1.2
  - Task 1.3
- **Acceptance criteria**:
  - `agent-runtime audit-drift` exits `0` against the working tree.
  - Either `drift-audit.allow.yaml` gained one new entry with a
    `reason` pointing at this plan, or the execution-state task
    ledger Notes column for Task 1.5 records that no allowlist entry
    was needed. The decision must be visible in either the YAML or
    the ledger so a future reviewer can audit the choice.
- **Validation**:
  - `agent-runtime audit-drift`
  - `agent-runtime audit-drift --format json | jq '.findings'`

## Sprint 2: Tracking issue artifacts and PR delivery

**Goal**: Render the dry-run plan-tracking issue artifacts alongside
the bundle, run the multi-lens code review, and deliver the bundle to
`main` via a single PR.

**PR grouping intent**: `group`
**Execution Profile**: `serial`

### Task 2.1: Render tracking issue artifacts (dry-run)

- **Location**:
  - `docs/plans/support-matrix/tracking-issue/` (new directory).
- **Description**: Run the `create-plan-tracking-issue` skill in
  dry-run mode. `plan-issue record render-dashboard` produces
  `tracking-issue/dashboard.md`; `plan-issue record render-comment
  --kind {source,plan,state}` produces three comment markdown files.
  Use `--marker-family compat` to match the lifecycle comment shape
  used by tracking issue #43.
- **Dependencies**:
  - Task 1.5
- **Acceptance criteria**:
  - Four files exist under `tracking-issue/` (dashboard plus three
    comments).
  - Each file carries the documented compat marker family.
  - Dashboard `Status` is `in-progress`; `Current` references Sprint
    1 Task 1.1; `Next Action` references the first Sprint 2 task.
- **Validation**:
  - `plan-tooling validate --file docs/plans/support-matrix/support-matrix-plan.md --explain`
  - Re-render each artifact to a temp file and diff against the
    committed copy to confirm determinism:
    `plan-issue record render-dashboard --profile tracking --status in-progress --target-scope "ship root-level SUPPORT_MATRIX.md as unified harness coverage view" --current "Sprint 1 Task 1.1 — pin row schema" --next-action "Sprint 1 Task 1.2 — populate Codex rows" --validation pending --approval pending --title "SUPPORT_MATRIX.md design and delivery" --out /tmp/dashboard.rerender.md && diff -u docs/plans/support-matrix/tracking-issue/dashboard.md /tmp/dashboard.rerender.md`
  - `plan-issue record audit` is deferred to Sprint 3 Task 3.2,
    when a live `gh issue view --json comments` payload is available
    as the audit input.

### Task 2.2: Multi-lens specialist review

- **Location**:
  - new evidence record under `<state_home>/out/projects/<repo>/<run-id>-support-matrix-review/`.
- **Description**: Allocate the evidence directory through
  `agent-out project --topic support-matrix-review --mkdir`; capture
  its absolute path before the review starts so re-runs reuse the
  same record. Run the `code-review:code-review-specialists` skill
  across the plan bundle and the tracking-issue artifacts. Capture
  blocking, warn, and informational findings with file:line cites in
  the allocated dir as `findings.jsonl`, then run
  `review-specialists validate / merge / render` to produce the
  specialist report. Do not auto-apply fixes; record findings for the
  next task.
- **Dependencies**:
  - Task 2.1
- **Acceptance criteria**:
  - Review evidence directory exists with at least one finding file
    per lens (api-contract / maintainability / red-team / testing as
    relevant to a docs-only change).
  - Blocking findings (if any) reference exact paths and lines.
- **Validation**:
  - `review-specialists --plan docs/plans/support-matrix/support-matrix-plan.md ...`
    (exact invocation per the rendered skill body).

### Task 2.3: Apply review fixes

- **Location**:
  - `SUPPORT_MATRIX.md`, plan bundle files, tracking-issue artifacts
    as flagged by 2.2.
- **Description**: Address every blocking finding; address warn
  findings unless explicitly deferred with a one-line waiver in the
  execution state. Re-run `plan-tooling validate` and re-render
  tracking-issue artifacts if content changed. The lifecycle-comment
  `--commit` SHA stays at the pre-commit base (the `origin/main` HEAD
  the worktree branched from); Sprint 3 Task 3.1 re-renders against
  the post-merge SHA, and the only expected diff at that point is the
  `Commit:` field of each lifecycle comment.
- **Dependencies**:
  - Task 2.2
- **Acceptance criteria**:
  - Zero blocking findings remain.
  - Any deferred warn finding has a waiver row in the execution-state
    Validation table.
- **Validation**:
  - `plan-tooling validate --file docs/plans/support-matrix/support-matrix-plan.md --explain`
  - Re-run `plan-issue record render-*` and `diff` against committed
    tracking-issue artifacts.

### Task 2.4: Commit via semantic-commit

- **Location**:
  - working tree on `feat/support-matrix`.
- **Description**: Stage the plan bundle, `SUPPORT_MATRIX.md`, the
  tracking-issue artifacts, the cross-link edits in upstream docs, and
  any drift-audit allowlist entry. Commit through `semantic-commit`
  (or `semantic-commit-autostage`) — direct `git commit` is hook-
  blocked. Use scope `(plans)` for the plan bundle commit and
  `(docs)` for the matrix + pointer commit when splitting; otherwise
  group as one commit with scope `(plans)`.
- **Dependencies**:
  - Task 2.3
- **Acceptance criteria**:
  - HEAD shows one or two commits with `semantic-commit`-shaped
    messages.
  - `git status` is clean afterwards.
- **Validation**:
  - `git log --oneline -3`
  - `git status`

### Task 2.5: PR deliver to main

- **Location**:
  - GitHub `graysurf/agent-runtime-kit` `main`.
- **Description**: Use `pr:deliver-github-pr` (i.e. `forge-cli pr
  deliver`) to open the PR against `main`. Confirm a 1-2 sentence
  summary with the user before the skill opens the PR — never derive
  the title or body from `git log -1`. Wait for CI; merge after green.
- **Dependencies**:
  - Task 2.4
- **Acceptance criteria**:
  - PR opens, CI lights up green, PR merges to `main`.
  - PR description links the plan bundle and `SUPPORT_MATRIX.md`.
- **Validation**:
  - `gh pr view --json state,mergedAt,statusCheckRollup`
  - `git log --oneline -3 origin/main`

## Sprint 3: Live tracking issue (post-merge)

**Goal**: After the PR merges to `main`, open the live GitHub
tracking issue from the now-committed plan bundle so subsequent
implementation work has a real issue to attach to.

**PR grouping intent**: `per-sprint`
**Execution Profile**: `serial`

### Task 3.1: Re-render dashboard with post-merge commit SHA

- **Location**:
  - rendered output only (no repo file change unless the dashboard
    needs to be updated in-tree).
- **Description**: Re-run `plan-issue record render-dashboard` and
  `render-comment --kind source/plan/state` using the merge commit
  SHA on `main`. Confirm the resulting markdown is byte-equal to the
  committed tracking-issue artifacts apart from the commit field.
- **Dependencies**:
  - Task 2.5
- **Acceptance criteria**:
  - Diff against committed artifacts is empty except for the commit
    field updates.
- **Validation**:
  - `diff -u docs/plans/support-matrix/tracking-issue/dashboard.md "$(plan-issue record render-dashboard --profile tracking --status in-progress --target-scope support-matrix --current 'Sprint 1 Task 1.1' --next-action 'Sprint 1 Task 1.2' --validation pending --approval pending --title support-matrix --out /dev/stdout)"`
  - `plan-issue record audit --profile tracking --marker-family compat --dir docs/plans/support-matrix/tracking-issue`

### Task 3.2: forge-cli issue create and lifecycle comments

- **Location**:
  - GitHub `graysurf/agent-runtime-kit` issues.
- **Description**: Preflight first — `forge-cli issue list --repo
  graysurf/agent-runtime-kit --label plan --state open --format
  json | jq '.[] | select(.title=="SUPPORT_MATRIX.md design and
  delivery")'`. If a match exists from an earlier partial run,
  resume by posting any missing lifecycle comments and editing the
  dashboard rather than creating a duplicate. Otherwise run
  `forge-cli issue create --provider github --label plan` with the
  re-rendered dashboard, immediately record the returned issue
  number into a scratch file in the worktree, then post the three
  lifecycle comments and edit the issue body with the resulting
  comment URLs. This is the only live mutation in the plan; confirm
  with the user before executing.
- **Dependencies**:
  - Task 3.1
- **Acceptance criteria**:
  - Issue exists with `plan` label and the three lifecycle comments
    attached.
  - Issue body Current Dashboard references the three comment URLs.
  - The scratch file holding the issue number is created before any
    `issue comment` call so a mid-flight failure can resume against
    the same issue.
  - Exactly one open issue carries the plan title; rerunning the
    task with the preflight check produces zero duplicates.
- **Validation**:
  - `forge-cli issue list --repo graysurf/agent-runtime-kit --label plan --state open --format json`
  - `gh issue view "$(jq -r .number issue-number.json)" --json comments > comments.json && plan-issue record audit --profile tracking --body-file dashboard.md --comments-json comments.json --format text`

### Task 3.3: Record issue URL in execution state

- **Location**:
  - `docs/plans/support-matrix/support-matrix-execution-state.md`.
- **Description**: Update the execution state with the live issue URL
  and snapshot URLs. Open a small follow-up PR (single commit through
  `semantic-commit`) so `main` records the linkage.
- **Dependencies**:
  - Task 3.2
- **Acceptance criteria**:
  - Execution state shows live issue URL and lifecycle comment URLs.
  - Follow-up PR is open or merged.
- **Validation**:
  - `gh pr list --head feat/support-matrix-live-issue --json state,number`
  - `git grep -n 'issues/' docs/plans/support-matrix/support-matrix-execution-state.md`

## Validation

| Command | When | Notes |
| --- | --- | --- |
| `plan-tooling validate --file docs/plans/support-matrix/support-matrix-plan.md --format text --explain` | before Sprint 2 commit | Run inside the worktree. |
| `agent-runtime audit-drift` | before Sprint 2 commit | Must exit `0`; allowlist entry is acceptable. |
| `bash scripts/ci/all.sh` | before PR open | Full local gate. |
| `plan-issue record audit --profile tracking ...` | Sprint 2.1 + 3.1 | Confirms marker compatibility. |

## Closeout Gate

- Close condition: PR merges to `main` with `SUPPORT_MATRIX.md`,
  plan bundle, dry-run tracking-issue artifacts, cross-links, and any
  drift-audit allowlist landed in one PR. Live GitHub issue created
  via Sprint 3 with the post-merge SHA, and its URL recorded in
  execution state through a follow-up PR.
- Reopen triggers: a new harness primitive enters either shape doc
  and is not reflected in `SUPPORT_MATRIX.md`; `runtime-roots.yaml`
  bumps `min_version` or `min_version_effective_from` without a
  matrix update; nils-cli surface pin rolls past `v0.17.5` and the
  matrix still cites the old pin.


</details>
