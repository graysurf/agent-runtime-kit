# SUPPORT_MATRIX Rendered + Acceptance-In-Manifest Discussion Source

- Status: ready for plan execution
- Date: 2026-05-23
- Source: in-session discussion immediately following the closeout of
  the previous `docs/plans/2026-05-23-support-matrix/` plan (issue
  <https://github.com/graysurf/agent-runtime-kit/issues/64>, closed
  via `dispatch:plan-tracking-issue-closeout`; closeout comment
  <https://github.com/graysurf/agent-runtime-kit/issues/64#issuecomment-4525489698>).
  The trigger was the user asking whether the just-landed
  `SUPPORT_MATRIX.md` can be used to drive doctor /
  install-completeness validation.
- Intended next step: execute a follow-up plan inside
  agent-runtime-kit that closes the two remaining gaps from the
  closed plan's reopen-trigger list without violating Plan F4 (no
  parsing the markdown matrix). Two more gaps are explicitly
  deferred to separate later plans.

## Execution

- Recommended plan: docs/plans/2026-05-23-support-matrix-rendered/support-matrix-rendered-plan.md
- Recommended execution state: docs/plans/2026-05-23-support-matrix-rendered/support-matrix-rendered-execution-state.md

## Purpose

`SUPPORT_MATRIX.md` shipped on `main` through three merged PRs
(<https://github.com/graysurf/agent-runtime-kit/pull/62> plan bundle,
<https://github.com/graysurf/agent-runtime-kit/pull/65> Sprint 1
implementation, <https://github.com/graysurf/agent-runtime-kit/pull/66>
nils-cli surface bump) as a hand-authored long-format table with 17
codex + 17 claude rows. The closed plan and the live issue closeout
recorded two known weaknesses (closed plan Open Questions section
`docs/plans/2026-05-23-support-matrix/support-matrix-discussion-source.md`
lines 81-93, and the live closeout comment
<https://github.com/graysurf/agent-runtime-kit/issues/64#issuecomment-4525489698>):

1. The matrix is hand-authored. Any change to `manifests/*.yaml`,
   `harness-shape-{codex,claude}.md`, or the nils-cli surface
   snapshot silently drifts the matrix until a human notices.
2. The `ci_acceptance` / `live_acceptance` columns are human prose
   (e.g. `— (home-policy cutover only)`, `live Codex Desktop
   session`). They are not executable, which means the matrix cannot
   participate in doctor or any other machine validation lane.

In a follow-up evaluation we confirmed the user's actual intent —
"use this matrix to do doctor / validate install completeness" — is
already 80% covered by existing machinery:

- `agent-runtime doctor --product codex` reports 164 checks (live
  sample 2026-05-23 on this host: `ok=164 warn=0 block=0`)
  [A1].
- `scripts/ci/all.sh` gates 5/6/7 already cover audit-drift,
  `--class skill-surface` doctor shape, and sandbox install
  rehearsal [F2].

What is missing is the link between the inventory view
(`SUPPORT_MATRIX.md`) and that machinery. This document scopes the
minimum work that closes that link without breaking the closed
plan's hard rule against parsing the markdown view.

## Confirmed Facts

- [U1] User wants the SUPPORT_MATRIX.md inventory to eventually
  drive doctor / install-completeness validation. The previous
  session's evaluation concluded direct parsing of the markdown view
  is the wrong path.
- [U2] User accepted the two-gap scope (Gap A renderer; Gap C
  acceptance-in-manifest) and explicitly deferred two further gaps
  (Gap B new doctor class; Gap D sandbox post-install doctor pass).
- [U3] User asked for this work to be tracked through the same
  issue-backed plan lifecycle that delivered the closed
  `docs/plans/2026-05-23-support-matrix/` plan, including the
  `create-plan-tracking-issue` → `execute-plan-tracking-issue` →
  `dispatch:plan-tracking-issue-closeout` chain.
- [F1] `SUPPORT_MATRIX.md` (`main` HEAD `b0df8e8` at authoring time)
  carries exactly 17 codex rows and 17 claude rows. The closed plan's
  execution-state ledger records this count in two rows:
  - Sprint 1 Task 1.2 — Evidence cell: "17 codex rows in
    `SUPPORT_MATRIX.md` matrix". Notes cell: "Matches
    `grep -c '^### [0-9]\+\.' docs/source/harness-shape-codex.md` = 17."
  - Sprint 1 Task 1.3 — Evidence cell: "17 claude rows in
    `SUPPORT_MATRIX.md` matrix". Notes cell: "Matrix uses the unified
    primitive set from `harness-shape-codex.md` (17).
    `harness-shape-claude.md` enumerates 14 directly; the extra 3
    rows on the Claude side are codex-only surfaces (15
    `$CODEX_HOME/skills`, 16 `config.toml` managed block, 17
    prompt-mode delegation policy) marked `not-applicable`."
- [F2] `DEVELOPMENT.md` lines 157-168 list the 10 CI gates. Gate 5
  is `agent-runtime audit-drift`, gate 6 is `agent-runtime doctor
  --class skill-surface --product codex`, gate 7 is the sandbox
  install rehearsal. The matrix is not (and per the closed plan
  must not become) a parsed gate.
- [F3] The closed plan's `F4` ("no parsing the markdown view")
  carries forward as a binding constraint into this plan. It is
  cited verbatim in `docs/plans/2026-05-23-support-matrix/support-matrix-discussion-source.md:75-79`.
- [F4] `manifests/` currently contains
  `product-capabilities.yaml`, `runtime-roots.yaml`, `skills.yaml`,
  `plugins.yaml`, `cli-tools.yaml`. None of them currently encode a
  per-surface acceptance command list. Schemas live under
  `core/docs/schemas/*.schema.json`.
- [F5] `agent-runtime render` is currently scoped per-product
  (`--product codex|claude` → `build/<product>/`). It does not have
  a cross-product target mode today. The renderer is the natural
  delivery vehicle for Gap A because `audit-drift` already
  source-vs-rendered diffs everything under `build/`.
- [F6] The closed plan's reopen triggers (recorded on issue #64's
  closeout comment) are: (i) a new harness primitive lands in
  either shape doc without a matching matrix row; (ii)
  `runtime-roots.yaml` bumps `min_version` /
  `min_version_effective_from` without a matrix refresh; (iii)
  nils-cli surface snapshot moves past `v0.17.6` and the matrix
  still cites the old pin. Gap A landing converts all three from
  "human notices" to "audit-drift fails".
- [F7] `agent-runtime doctor --help` exposes `--class skill-surface`
  as the only non-default class today. Gap B would add a second
  class; this plan does not implement Gap B and must not pre-shape
  the manifest for Gap B's convenience. Forward-compatibility is
  served by additive-only schema versioning, not by anticipating
  Gap B's field set.
- [A1] Local `agent-runtime doctor --product codex` run on
  2026-05-23 against this host returned
  `checks=164 ok=164 warn=0 block=0`, including 22 `required-cli`
  probes (e.g. `forge-cli >=0.17.5 parsed 0.17.6`,
  `plan-issue >=0.17.5 parsed 0.17.6`) and 7 `cli-tool` probes.
  This establishes the doctor surface as the canonical install-
  completeness lane for this work — not the matrix.

## Decisions

- Target this work to **agent-runtime-kit** (the renderer + doctor
  live here). No nils-cli changes required; this plan does not bump
  the nils-cli surface floor.
- Scope is **Gap A + Gap C only**. Gap B and Gap D are explicitly
  out of scope and recorded as the natural follow-ups in a separate
  plan each.
- **Manifests stay canonical**. The matrix becomes a `build/`
  artifact rendered from manifests; manifests are the source of
  truth for both human and machine consumers.
- **No markdown parsing**. Plan F4 from the closed plan carries
  forward unchanged. If a doctor class ever consumes acceptance
  commands, it reads them from `manifests/`, never from
  `SUPPORT_MATRIX.md`.
- **First-cut byte-equality**: the renderer's first output must
  reproduce the currently-committed `SUPPORT_MATRIX.md` row content
  byte-equal. To preserve a clean byte-equal signal, the rendered
  file starts with a single HTML comment marker
  `<!-- generated by agent-runtime render --target support-matrix; do not edit -->`
  on the first line, followed by an empty line, then the existing
  matrix content. Trailing newline policy: exactly one terminating
  newline. User has already reviewed and approved the 34-row
  content; the renderer must not silently re-shape it.
- **Acceptance schema shape (locked)**: each acceptance entry is
  structured with the fields `kind` ∈ `{ci, live}`, exactly one of
  `command` or `note`, and an optional `descriptive_only: true`
  flag. A pure-prose string is allowed via `descriptive_only: true`
  so existing "— (home-policy cutover only)" rows can be encoded
  without forcing executable commands prematurely. The `success`
  predicate semantics are open — see `Acceptance command schema
  details` under Open Questions.
- **Gap C non-vacuity rule**: schema landing alone is not
  sufficient. At least 2 acceptance entries total (across both
  products) must carry an executable `command` plus a non-trivial
  `success` predicate, so `agent-runtime doctor` (or its successor
  class in Gap B) can actually execute them. The remaining rows
  may use `descriptive_only: true` for honest "no executable
  acceptance yet" semantics. The plan that consumes this source
  must name the ≥2 rows it will promote to executable.
- **Gap C acceptance signals (machine-verifiable)**: the consuming
  plan ships (i) a schema-validation CI check that fails when an
  acceptance entry violates the locked schema, and (ii) a CI step
  that executes the ≥2 non-`descriptive_only` acceptance commands
  and asserts each `success` predicate passes. Both signals are
  required for Gap C to be considered delivered.
- **No drift-allowlist for first-cut delta**: hand-edit the
  renderer until `diff -u SUPPORT_MATRIX.md build/.../SUPPORT_MATRIX.md`
  is empty. Do not add an `drift-audit.allow.yaml` entry to mask a
  cosmetic delta; that would let silent drift recur the moment the
  allowlist entry expires from active review.
- **Reopen triggers from the closed plan become this plan's
  success signal**. Once Gap A lands, the three reopen triggers
  shift from "human notices" to `agent-runtime audit-drift` fail.
  Verify this on the implementation worktree by intentionally
  perturbing one manifest field and confirming audit-drift surfaces
  the SUPPORT_MATRIX.md diff.

## Scope

- In scope:
  - One canonical manifest entry-point for the matrix's row set
    (either a new `manifests/surfaces.yaml`, or a new section in
    `manifests/product-capabilities.yaml`; choice deferred to the
    plan).
  - A new schema file (or extension of an existing schema) covering
    the acceptance entry shape.
  - Renderer support that produces `build/.../SUPPORT_MATRIX.md`
    (or the chosen path) byte-equal to the committed root file's
    row content for the first cut.
  - `scripts/ci/all.sh` gate update (or new gate) that re-renders
    the matrix and lets audit-drift detect source-vs-rendered
    differences.
  - Golden fixture under `tests/golden/` for the rendered matrix.
  - Cross-link update in `SUPPORT_MATRIX.md` itself noting it is
    now generated.
  - Documentation update in the relevant section of
    `docs/source/inventory-target-architecture.md` so the rendered
    pipeline is discoverable from the architecture doc.
- Out of scope (deferred plans):
  - **Gap B**: a new `agent-runtime doctor --class support-matrix`
    (or `surface-coverage`) class that probes each manifest-listed
    surface against the live runtime home.
  - **Gap D**: running `agent-runtime doctor --live-home <sandbox>
    --product <p>` as a post-step of the existing sandbox install
    rehearsal CI gate.
  - Re-deriving `harness-shape-{codex,claude}.md` from the same
    manifest source. Out of scope; those docs remain hand-authored
    narrative.
  - Renaming or moving `SUPPORT_MATRIX.md` away from the repo root.
  - Cutting a nils-cli release. The renderer change is contained
    inside agent-runtime-kit's own CLI / library code.
  - Adding new harness primitives that the existing 17-surface set
    does not already cover.

## Non-Goals

- Replacing any existing manifest with the matrix-related new
  entries. The new manifest data is **additive**.
- Making `SUPPORT_MATRIX.md` itself a parsed input to any tool.
- Producing a Tera template just for the matrix if the renderer's
  existing approach (per-product templates plus manifest reads) can
  accommodate a cross-product output naturally.
- Changing the visible columns of the matrix in the first cut. The
  reader-facing schema is frozen from the closed plan's Sprint 1.

## Open Questions Carried Into Execution

- **Surface registry location**: should the 17-surface canonical
  list live in a new top-level `manifests/surfaces.yaml`, or as a
  new sibling section in `manifests/product-capabilities.yaml`? The
  closed plan did not need to answer this; this plan must. Trade-
  off: a new file matches the "one schema per file" pattern under
  `core/docs/schemas/`; an in-place extension keeps the manifest
  count small.
- **Cross-product render mode (already locked to option (b))**:
  the byte-equality Decision pins the rendered file's header to
  `<!-- generated by agent-runtime render --target support-matrix; do not edit -->`,
  which implicitly chose option (b) `--target support-matrix` over
  the four originally-considered options (a) `--product shared`,
  (c) separate `render-support-matrix` subcommand, (d) post-process
  inside per-product renders. The consuming plan records the
  rationale (option (b) keeps the build-tree walk one-level under
  `build/<chosen-path>/`, lets `audit-drift` reach the rendered
  file via the existing per-product entry points by treating
  `--target` as a per-product modifier, and adds the smallest CLI
  surface). **Hard constraint**: no option may read
  `SUPPORT_MATRIX.md` as input. If a fifth option (e) is proposed
  that does so, it violates Plan F4 and must be rejected without
  further analysis.
- **Build path for the rendered matrix**: `build/SUPPORT_MATRIX.md`
  (top of `build/`) is the natural cross-product home, but
  `build/` is currently flat per-product (`build/codex/`,
  `build/claude/`). A new `build/shared/` is the cleanest, but adds
  a new top-level under `build/` that audit-drift currently does
  not walk.
- **Acceptance command schema details**: minimum viable shape is
  `{kind, command|note, success?, descriptive_only?}`. Open: does
  `success` allow a regex on stdout / a JSON-path on a typed
  envelope, or only an exit-status predicate? The latter is
  cheaper; the former is what `agent-runtime doctor` already does
  internally for `version-probe` parsing.
- **Claude-side asymmetry encoding**: the matrix marks 3 codex-only
  surfaces (`$CODEX_HOME/skills` direct discovery, `config.toml`
  managed block, prompt-mode delegation policy) as
  `not-applicable` on the Claude side. The surface registry must
  encode this — either as `applicable_products: [codex]` (and the
  renderer fills `not-applicable` rows on the other side) or by
  listing per-product `state` explicitly. Both work; pick one.

## Recommended Next Artifact

- Drive `create-plan-tracking-issue` against
  `docs/plans/2026-05-23-support-matrix-rendered/support-matrix-rendered-plan.md`
  (to be authored next) with this discussion source linked under
  `Read First`.
- Keep the closed plan (`docs/plans/2026-05-23-support-matrix/`) cited as
  background context but do not reopen issue #64. The reopen
  triggers there are deliberately the "fail mode" this plan
  prevents; once Gap A lands, those triggers fire automatically via
  audit-drift.

## Read-First References

- `SUPPORT_MATRIX.md` (root) — what gets rendered.
- `docs/plans/2026-05-23-support-matrix/support-matrix-discussion-source.md` —
  origin of the F4 constraint and the reopen-trigger list.
- `docs/plans/2026-05-23-support-matrix/support-matrix-execution-state.md` —
  evidence trail for the 17/17 row counts and validation gates the
  rendered version must reproduce.
- `manifests/product-capabilities.yaml` and
  `core/docs/schemas/product-capabilities.schema.json` — candidate
  home for the surface registry / acceptance schema.
- `manifests/runtime-roots.yaml` — source of the `min_product` /
  `min_version_effective_from` columns currently appearing in the
  matrix.
- `manifests/skills.yaml`, `manifests/plugins.yaml`,
  `manifests/cli-tools.yaml` — sources of `min_nils_cli` and
  per-surface `source_manifest` pointers.
- `docs/source/harness-shape-codex.md` and
  `docs/source/harness-shape-claude.md` — primitive enumeration
  the row set must continue to cover.
- `docs/source/inventory-target-architecture.md` — architecture
  pointer to update once the renderer lands.
- `scripts/ci/all.sh` — gate sequence that must continue to pass
  after the renderer joins it.
- Issue #64 closeout comment
  (<https://github.com/graysurf/agent-runtime-kit/issues/64#issuecomment-4525489698>)
  — current statement of the reopen triggers and the deferred-gap
  split.

## Retention Intent

- Retain this discussion source under
  `docs/plans/2026-05-23-support-matrix-rendered/` until the plan it feeds
  closes. Promotion to a long-lived architecture doc is not
  expected; the architecture pointer in
  `docs/source/inventory-target-architecture.md` is the durable
  home.
