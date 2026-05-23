# SUPPORT_MATRIX Discussion Source

- Status: ready for plan execution
- Date: 2026-05-23
- Source: user discussion in the Claude session that landed
  `docs/source/harness-shape-{claude,codex}.md` on `main`. The
  follow-up question was whether the repo should expose a single
  human-readable inventory at the root so consumers can answer
  "what does this repo do for Codex / Claude, and at what version
  floor" without grepping five manifests.
- Intended next step: execute this plan inside agent-runtime-kit so a
  root-level `SUPPORT_MATRIX.md` lands as the human-readable view over
  the existing machine-readable manifests, without becoming a parsed
  source of truth for doctor / drift audit.

## Execution

- Recommended plan: docs/plans/support-matrix/support-matrix-plan.md
- Recommended execution state: docs/plans/support-matrix/support-matrix-execution-state.md

## Purpose

Today, answering "is Codex harness primitive X supported by
agent-runtime-kit, and at what minimum version" requires cross-reading
`manifests/product-capabilities.yaml`,
`manifests/runtime-roots.yaml`, `manifests/skills.yaml`,
`docs/source/nils-cli-surface.md`, and `DEVELOPMENT.md` simultaneously.
The recently landed `docs/source/harness-shape-claude.md` and
`docs/source/harness-shape-codex.md` are the first per-product
inventories — they pivot well per product, but the two files do not
yet share one canonical schema. A unified `SUPPORT_MATRIX.md` at the
repo root would compress the answer to a one-page lookup for new
contributors, reviewers, and external readers.

The plan deliberately scopes the artifact as a **derived
human-readable view**, not a new source of truth. The manifests stay
canonical; `SUPPORT_MATRIX.md` is regenerated from them (or, in the
first cut, hand-written but kept in lock-step with them through a
drift-audit class).

## Confirmed Facts

- [U1] User asked for a single unified table covering both Codex and
  Claude harness primitives, not two parallel docs that have to be
  cross-walked.
- [U2] User explicitly rejected making the markdown table itself the
  source of truth for doctor / test gates. Manifests remain SoT;
  `SUPPORT_MATRIX.md` is a view.
- [U3] User preferred a **long-format normalized table** (one row per
  surface × product, with `support_state`) over a wide table that
  forces N/A cells for Claude-only or Codex-only primitives.
- [U4] User instructed empirical observation of both harness shapes
  before drafting the unified schema. Both shape docs landed on `main`
  before this plan was authored.
- [U5] User authorised both dry-run artifact delivery into the repo
  **and** a live GitHub tracking issue after the PR merges; live mode
  runs only after `main` carries the plan bundle.
- [F1] `docs/source/harness-shape-claude.md` and
  `docs/source/harness-shape-codex.md` enumerate 14 + Codex-equivalent
  primitives apiece. The Claude doc closes with an explicit
  "Open Items For Schema Design" list of five column requirements.
- [F2] `manifests/product-capabilities.yaml`,
  `manifests/runtime-roots.yaml`, `manifests/skills.yaml`,
  `manifests/plugins.yaml`, `manifests/cli-tools.yaml`,
  `docs/source/nils-cli-surface.md` (snapshot `v0.17.5`), and
  `DEVELOPMENT.md` lines 157-168 collectively hold every fact the
  matrix needs. The matrix should not introduce any new fact that is
  not already in one of these sources.
- [F3] `docs/source/inventory-target-architecture.md` `### Codex
  Activation Surface (Reality Check)` (lines 533-611) and Resolved
  Decision #10 are authoritative on Codex-side asymmetry (no
  marketplace, no plugin loader at runtime, no settings.json
  equivalent); the matrix must mark these `not-applicable` rather than
  `not-shipped`.
- [F4] `DEVELOPMENT.md` lines 157-168 describe the current CI gate
  stack (positions 1-10). The matrix is not wired in as a parsed CI
  gate. If a future plan adds a `support-matrix` drift class, that
  class should read the manifests behind the matrix and not parse the
  markdown view itself.

## Open Questions Carried Into Execution

- Should the first cut be **hand-authored** (Sprint 1) and then
  promoted to **rendered from manifests** later, or rendered from
  day one through a new `agent-runtime render --target support-matrix`
  subcommand in nils-cli?
- Should `drift-audit` add a dedicated `support-matrix` class, or
  should the matrix be re-rendered fresh each invocation and diffed
  against the committed copy (cheaper, same effect)? This plan
  defers the drift-class question to a future plan; Sprint 1 ships
  a hand-authored matrix without an automated parity check, so
  silent drift between the matrix and the shape docs remains a
  known gap until that follow-up lands.
- Does the matrix belong at the repo root (`SUPPORT_MATRIX.md`) or
  under `docs/source/`? Root is more discoverable; `docs/source/`
  matches the placement policy for design artifacts.

## Non-Goals

- Replacing any existing manifest with the matrix.
- Adding new harness primitives that the shape docs did not already
  identify.
- Cutting a nils-cli release that depends on the matrix (the matrix
  must work against the current `v0.17.5` surface).
- Designing a Claude-side `--class skill-surface` doctor diagnostic
  (recorded as schema-relevant asymmetry; out of scope here).
