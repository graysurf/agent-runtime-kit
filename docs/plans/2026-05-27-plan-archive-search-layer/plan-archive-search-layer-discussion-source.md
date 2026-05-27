# Plan Archive Search Layer Implementation Handoff

- Status: ready for plan generation
- Date: 2026-05-27
- Source: user-driven design discussion on extending the `plan-archive` system
  with a discoverability + search layer (catalog + future SQLite index),
  evaluating where SQLite is suitable and how to stage delivery.
- Intended next step: split this document into two phase plans (see
  `Two-Plan Split`), then feed Phase 1 into `create-plan-tracking-issue`.
  This is a source artifact, not an implementation plan.

## Execution

This document feeds **two** sequential plans. Both lines are recorded so plan
generation and tracking can resolve each phase independently.

- Recommended plan (Phase 1): docs/plans/2026-05-27-plan-archive-search-layer/plan-archive-search-layer-phase1-plan.md
- Recommended execution state (Phase 1): docs/plans/2026-05-27-plan-archive-search-layer/plan-archive-search-layer-phase1-execution-state.md
- Recommended plan (Phase 2): docs/plans/2026-05-27-plan-archive-search-layer/plan-archive-search-layer-phase2-plan.md
- Recommended execution state (Phase 2): docs/plans/2026-05-27-plan-archive-search-layer/plan-archive-search-layer-phase2-execution-state.md
- Status: Phase 1 is ready to implement immediately; Phase 2 is designed now but
  deferred until query/scale demand justifies it.
- Next-task source: this document.

## Purpose

The `plan-archive` storage layers are built and in use: `plans/**/metadata.yaml`
and append-only `_index/**/<ISO8601>.json` snapshots, with a read-only `query`
that resolves a known ref / plan / repo into its latest cached snapshot. What is
missing is the layer that lets an agent **find the right record when it does not
already know the ref number**, and traverse links **bidirectionally**.

Two gaps were confirmed against the current code and the master design:

- There is **no catalog**: `_index/` is a content cache keyed by ref number, not
  a by-topic / by-title index. `query` aggregate mode returns only
  `ref + snapshot path + fetched_at` — no title, slug, or summary — so an agent
  cannot tell what each cached ref is about without opening every JSON file.
- There is **no search / no bidirectional traversal beyond plan → refs**: no
  keyword/full-text search over snapshot bodies, and no `ref → which plans
  reference it` direction.

This layer closes those gaps in two phases:

1. **Phase 1 (now): a derived, deterministic, text catalog** committed at the
   archive root, giving any clone a single cheap-to-grep discovery surface and a
   stable record shape.
2. **Phase 2 (later): a derived, local, rebuildable SQLite index** built from
   the *same* records, adding ranked full-text search (FTS5) and fast relational
   bidirectional queries — without refactoring Phase 1.

The Phase 1 record shape is deliberately the Phase 2 row shape, so Phase 2 adds
a consumer, not a rewrite.

## Confirmed Facts

- [U1] The current `_index/` cache serves fast CLI responses for *known* refs;
  the user wants a search layer on top for discovery and future extensibility.
- [U2] The user wants **bidirectional** lookup (find data in both directions),
  not only the existing plan → refs traversal.
- [U3] The user wants this written as a design document now, then split into
  **two** plans executed by phase. Phase 1 is implemented immediately and must
  pre-design the structures Phase 2 needs so Phase 2 requires **no refactor**.
- [F1] Master design fixes the source-of-truth and append-only contract: the
  cache lives in `_index/`, every refresh writes a new `<ISO8601>.json`,
  existing snapshots are never overwritten or deleted, and "the local index
  lives inside the archive repository at `_index/`"
  (`docs/plans/2026-05-26-plan-archive-system/plan-archive-system-discussion-source.md`,
  Index/cache section and design tenets).
- [F2] The archive repo's integrity model is git-tracked, GPG-signed commits,
  a scrub-log review gate before snapshot commit, and a file-level deletion
  criterion — all of which assume **diffable, human-reviewable text**.
- [F3] `metadata.yaml` already records `source.{host,org_or_group_path,repo,
  branch,archive_commit}`, `original_path`, and `refs.{issue,pr,mr}`
  (verified on `plans/github.com/sympoies/nils-cli/2026-05-23-forge-cli-inbox-latency/metadata.yaml`).
- [F4] `query` aggregate mode returns `SnapshotRecord { ref, host, org, repo,
  kind, number, latest_snapshot, fetched_at }` only — no title/summary/slug
  (`crates/plan-archive/src/query/mod.rs`).
- [F5] `rusqlite` 0.39 with the `bundled` feature is already a proven workspace
  dependency in `crates/memo-cli/Cargo.toml`, so Phase 2 carries no new
  toolchain or cross-platform packaging risk.
- [F6] `plan-archive` snapshot filenames use colon-free UTC ISO8601 so lexical
  sort equals chronological order; "latest" is the lexically last file.

## Decisions

### D1 — JSON / metadata stays the only source of truth

`_index/**/*.json` and `plans/**/metadata.yaml` remain authoritative. The
catalog (Phase 1) and the SQLite index (Phase 2) are **derived projections**:
fully rebuildable, never read as truth, and safe to delete and regenerate. This
preserves the append-only, signed, reviewable contract from [F1]/[F2].

### D2 — Derived TEXT index MAY be committed; derived BINARY index MUST stay local

This is the rule that decides "where does it live":

- The **catalog is deterministic JSON text** → diffable, signed, reviewable, and
  consistent with the archive's integrity model. It is committed at the archive
  root so any fresh clone has a zero-setup discovery surface.
- A **SQLite database is binary and mutable** → it would break diff/review,
  conflict on merge, and add non-deterministic churn under signed commits.
  **SQLite is never committed into the archive repo.** It is a machine-local,
  gitignored, rebuildable cache.

### D3 — Catalog placement and determinism

- Path: `<archive-root>/catalog.json` (committed). An optional human-readable
  `<archive-root>/CATALOG.md` may be rendered from the same records.
- Determinism is mandatory: entries sorted by `(host, org, repo, date, slug)`,
  object keys emitted in a fixed order, stable formatting — so regeneration
  produces minimal, reviewable diffs and merges resolve by re-running the
  generator.
- The catalog is regenerated by the CLI and re-committed as part of `migrate`
  and after `refresh` review, not hand-edited.
- A local-only / gitignored catalog was considered and **rejected**: it would
  re-create the "manual and undiscoverable" problem (every clone/machine must
  bootstrap before anything is queryable), defeating Phase 1's zero-setup
  discovery goal. A committed deterministic text file is small, diffable, and
  signed-safe, so the cost is acceptable.

### D4 — One canonical record shape shared by both phases (the no-refactor bridge)

A single `CatalogRecord` type is defined in Phase 1 and is **simultaneously** the
catalog JSON entry and the Phase 2 SQLite row source. The derivation logic
(scan `plans/**/metadata.yaml`, join the latest `_index/` snapshot per ref, pull
`data.title`/`data.state`) is written once in Phase 1 in a shared `catalog`
module. Phase 2 adds a SQLite writer that consumes the same in-memory
`CatalogRecord`s; it does not re-derive or reshape anything. See
`Data Contract`.

### D5 — Phase 2 uses SQLite as a derived local index, with FTS5

- Location: `${XDG_CACHE_HOME:-$HOME/.cache}/agent-plan-archive/index.sqlite`
  (machine-local; aligns with the existing machine-local config at
  `$XDG_CONFIG_HOME/agent-plan-archive/config.yaml`). Never inside the repo.
- Built/refreshed by `plan-archive index rebuild` from the authoritative JSON +
  `catalog.json`. Incremental updates key off snapshot ISO8601 filenames [F6].
- Relational tables answer bidirectional queries cheaply; an FTS5 virtual table
  provides ranked full-text search over snapshot title/body/comments.
- Dependency: reuse `rusqlite = { version = "0.39", features = ["bundled"] }`
  per [F5].

### D6 — Search surfaces by phase

- Phase 1 (no DB): `plan-archive catalog` generates/prints the catalog;
  discovery is "grep `catalog.json`" plus a thin built-in filter
  (`catalog --grep <substr>` / `--area <x>`) reading the catalog in memory.
  Bidirectional `ref → plans` is already answerable in Phase 1 because each
  catalog entry lists its refs (linear scan over a small file).
- Phase 2 (DB): `query --text <term>` (FTS5, ranked), `query --refs-to <ref>`
  (indexed reverse traversal), and faceted aggregate filters, all backed by the
  SQLite index; JSON remains the rebuild source and fallback.

### D7 — Discoverability trigger is a narrow, home-scope policy line

The "when should an agent consult the archive" gap (master design open item) is
closed in Phase 1 by a **narrow, global-scope** `agent-docs` entry, so it is
inherited by every repo's `project-dev` preflight (the bug-diagnosis scenario
can happen in any repo, and the user's primary mode is development):

- Mechanism: register a short pointer doc in this checkout's `AGENT_DOCS.toml`
  as `context = "project-dev"`, `scope = "global"`, `required = true`. Global
  entries resolve from `AGENT_DOCS_HOME` and are inherited by unrelated project
  repos, which is exactly the cross-repo discovery path this layer needs.
- Pointer doc: `docs/source/plan-archive-query-pointer-v1.md`, intentionally
  short (~12 lines) — it only needs to tell the agent the archive is queryable
  and how (grep `catalog.json`; `plan-archive query --ref/--plan/--repo`).
- Secondary: mirror the same cue in the query skill's "when to use" description
  (the routing layer).
- Wording stays narrow on purpose: consult **only** before opening a new plan,
  or when diagnosing a suspected recurring / previously resolved problem —
  **not** on every task, to avoid the noise the system is designed to remove.

`project-dev` was chosen over `startup` so the cue fires on development
preflight, not in every unrelated session. Skill-only placement was rejected:
the skill description fires only once an agent is already routing toward
plan-archive, so it would not prompt consultation during general debugging. The
pointer doc references `catalog.json` and `query`, so it ships **with** Phase 1
(not before the catalog exists). No background sync, no auto-trigger; staleness
stays visible via `fetched_at` and the caller decides when to `refresh`/`rebuild`
(consistent with the master design's manual-refresh model).

### D8 — issue → source-file mapping is not a bespoke index

The authoritative source-file → history path already exists (`git blame`/`git
log` → commit → PR/issue → `query --ref`). The archive's added value is the
reverse and enriched view: `original_path` (plan doc location, already in
`metadata.yaml`) and the discussion context in snapshots. An optional
`files[]` per-ref field (PR changed-files captured at refresh time) is reserved
in the record shape for a possible Phase 3, but is **not** built in Phase 1 or 2.

## Scope

- Phase 1: shared `catalog` derivation module + `CatalogRecord` contract;
  `plan-archive catalog` command (generate/write/print/filter); deterministic
  committed `catalog.json`; regeneration wired into `migrate`/`refresh`;
  `ref → plans` answerable from the catalog; the D7 trigger policy line.
- Phase 2: `plan-archive index rebuild` building a local SQLite projection from
  the same records; relational schema + FTS5; `query --text` and
  `query --refs-to`; staleness surfaced via `fetched_at`.
- The `CatalogRecord` data contract that bridges both phases.

## Non-Scope

- Compaction/pruning of historical `_index/` snapshots (v1 stays append-only).
- Committing any binary (SQLite) artifact into the archive repo (D2).
- Background sync, reopen detection, or auto-refresh (manual model preserved).
- A bespoke issue → source-file index (D8); `files[]` is a reserved field only.
- Backfilling date prefixes or migrating new source repos (owned by the master
  plan-archive plans, not this layer).
- Changing the provider fetch path (`forge-cli` integration is unchanged).

## Implementation Boundaries

- Both phases land in the `nils-cli` `plan-archive` crate
  (`crates/plan-archive/`); this document and its phase plans live in
  `agent-runtime-kit` per repo convention.
- The catalog generator reads only the archive clone (no provider calls).
- Phase 2 must not change the `CatalogRecord` shape, the catalog file format, or
  the derivation module's public surface — it only adds a SQLite consumer and
  new `query` sub-modes. Any change to the shared shape is a Phase 1 change.
- SQLite path resolution honors `XDG_CACHE_HOME` and an explicit override flag
  / env var for tests, mirroring the existing `PLAN_ARCHIVE_LOCAL_CONFIG`
  pattern.

## Requirements

### Phase 1 (implement now)

- R1.1 Define `CatalogRecord` (and nested `CatalogRef`) per `Data Contract`, with
  serde serialization producing deterministic key order.
- R1.2 Implement a shared `catalog` module that scans `plans/**/metadata.yaml`,
  resolves each ref's latest `_index/` snapshot, and assembles `CatalogRecord`s.
  This module is the single derivation point reused by Phase 2.
- R1.3 `plan-archive catalog --write` writes deterministic `<archive>/catalog.json`
  (sorted, fixed key order). `catalog` (no `--write`) prints to stdout honoring
  `--format json|text`.
- R1.4 `plan-archive catalog --grep <substr>` / `--area <x>` filters records in
  memory and prints matches (the Phase 1 discovery surface alongside raw grep).
- R1.5 `ref → plans` is answerable in Phase 1: a record lists its refs, so a
  scan over the catalog resolves which plans reference a given ref. Expose this
  as `catalog --refs-to <ref-url>` (linear scan; Phase 2 makes it indexed).
- R1.6 `migrate --apply` regenerates and stages/commits `catalog.json` as part of
  the same transaction; the post-`refresh` review flow regenerates it too.
- R1.7 Create `docs/source/plan-archive-query-pointer-v1.md` (short) and
  register it in `AGENT_DOCS.toml` as `context = "project-dev"`,
  `scope = "global"`, `required = true`; mirror the cue in the query skill's
  "when to use" description. Verify with
  `agent-docs resolve --context project-dev --strict` from an unrelated repo
  (the pointer appears as an inherited global doc).

### Phase 2 (designed now, deferred)

- R2.1 `plan-archive index rebuild` builds the local SQLite projection at the
  D5 path from the authoritative JSON + `catalog.json`, consuming the same
  `CatalogRecord`s with no reshape (incremental via snapshot ISO8601 keys).
- R2.2 Relational schema (see `Data Contract`) supports `plan → refs`,
  `ref → plans`, and faceted filters in indexed time.
- R2.3 FTS5 virtual table over snapshot `title`/`body`/`comments`; rebuilt after
  each `refresh`.
- R2.4 `query --text <term>` returns ranked matches; `query --refs-to <ref>`
  returns referencing plans from the index. JSON remains the rebuild source and
  the fallback when the DB is absent/stale.
- R2.5 Staleness is surfaced via each record's `fetched_at`; no auto-refresh.

## Data Contract (the bridge between phases)

`CatalogRecord` — one per archived plan; the catalog JSON entry **and** the
Phase 2 row source. Fields present from Phase 1 even when only Phase 2 indexes
them, so Phase 2 needs no schema change:

```jsonc
{
  "slug": "2026-05-23-forge-cli-inbox-latency",
  "host": "github.com",
  "org": "sympoies",
  "repo": "nils-cli",
  "date": "2026-05-23",
  "original_path": "docs/plans/2026-05-23-forge-cli-inbox-latency/",
  "archive_commit": "d4200098...",
  "title": "...",                 // from plan / first ref snapshot
  "summary": "...",               // one line; derived, may be empty in v1
  "area": ["forge-cli"],          // optional labels/area, may be empty
  "refs": [
    {
      "url": "https://github.com/sympoies/nils-cli/pull/444",
      "kind": "pull",             // issue | pull | merge_request
      "number": 444,
      "state": "merged",          // from snapshot when available
      "title": "...",             // from snapshot data.title
      "latest_snapshot": "_index/.../pulls/444/<ISO8601>.json",
      "fetched_at": "2026-05-27T05:25:04Z"
    }
  ],
  "files": []                     // reserved for Phase 3; unused in v1/v2
}
```

Phase 2 SQLite schema is a direct projection of the above (no derived field is
recomputed differently):

```sql
CREATE TABLE plans (
  id INTEGER PRIMARY KEY,
  slug TEXT, host TEXT, org TEXT, repo TEXT, date TEXT,
  original_path TEXT, archive_commit TEXT, title TEXT, summary TEXT, area TEXT
);
CREATE TABLE refs (
  id INTEGER PRIMARY KEY,
  url TEXT UNIQUE, host TEXT, org TEXT, repo TEXT,
  kind TEXT, number INTEGER, state TEXT, title TEXT,
  latest_snapshot TEXT, fetched_at TEXT
);
CREATE TABLE plan_refs (plan_id INTEGER, ref_id INTEGER);   -- bidirectional edges
CREATE TABLE ref_files (ref_id INTEGER, path TEXT);         -- reserved (Phase 3)
CREATE VIRTUAL TABLE snapshots_fts USING fts5(ref_url, title, body, comments);
```

## Acceptance Criteria

### Phase 1

- A1.1 `plan-archive catalog --write` produces `catalog.json` whose entries match
  every archived plan and its refs; re-running with no archive change yields a
  byte-identical file (determinism).
- A1.2 `catalog --grep <term>` and `--refs-to <ref-url>` return the correct
  records over the current archive content.
- A1.3 `migrate --apply` leaves `catalog.json` regenerated and committed in the
  same signed commit as the migrated plan.
- A1.4 `agent-docs resolve --context project-dev --strict` run from an
  unrelated repo lists the global pointer doc (`status=present`); the doc points
  at `catalog.json` with the narrow wording, mirrored in the query skill.
- A1.5 Unit tests cover record assembly (incl. missing snapshot / no-refs plans),
  deterministic serialization, and the grep/refs-to filters.

### Phase 2

- A2.1 `index rebuild` reconstructs the SQLite index from the same records with
  no change to `CatalogRecord` or the catalog format (verified by reusing the
  Phase 1 derivation module unmodified).
- A2.2 `query --text <term>` returns ranked FTS matches; `query --refs-to <ref>`
  matches the Phase 1 linear-scan result on the same data.
- A2.3 Deleting the SQLite file and rebuilding reproduces identical query
  results (rebuildable projection).
- A2.4 Tests cover schema build, incremental update by ISO8601 key, FTS ranking
  on fixtures, and bidirectional traversal.

## Validation Plan

- `cargo test -p nils-plan-archive` (unit + integration for both phases).
- `cargo fmt --all -- --check` and `cargo clippy` before each commit (a prior
  release failed CI on skipped `fmt`).
- `plan-archive catalog --write` dry-run on the live archive clone; confirm
  deterministic re-run and a clean `git diff` on the second run.
- Phase 2: build the index on the live clone, delete + rebuild, diff query
  outputs.
- Markdown lint for this document and the two phase plans.

## Risks and Guardrails

- **Committed derived state can drift / conflict.** Guardrail: determinism (D3)
  with regeneration on `migrate`/`refresh`; conflicts resolve by re-running the
  generator, never hand-merging `catalog.json`.
- **Over-engineering at current scale (~39 records).** Guardrail: Phase 2 is
  explicitly deferred; grep over `catalog.json` is sufficient until query
  complexity or record count grows. Phase 1 alone closes the discovery gap.
- **Two derivation code paths drifting apart.** Guardrail: D4 mandates a single
  shared module; Phase 2 must not fork it (enforced by A2.1).
- **Binary in git.** Guardrail: D2 forbids committing SQLite; the DB path is
  machine-local and gitignored.
- **Scrub contract.** The catalog is derived from already-scrubbed snapshots and
  public metadata; it must not reintroduce un-scrubbed content. Guardrail: only
  read committed `_index/` snapshots (post-scrub), never raw provider payloads.

## Two-Plan Split (explicit)

This design is delivered as **two separate plans**, executed in order:

- **Plan 1 — Catalog (Phase 1), implemented immediately.**
  - Slug: `2026-05-27-plan-archive-search-layer` (Phase 1 plan file:
    `plan-archive-search-layer-phase1-plan.md`).
  - Delivers: `CatalogRecord` contract, shared `catalog` derivation module,
    `plan-archive catalog` command, deterministic committed `catalog.json`,
    regeneration hooks, `ref → plans` via catalog, D7 trigger line.
  - Goal: close the discovery + bidirectional-link gap with zero new heavy
    dependencies, and lock the record shape Phase 2 consumes.

- **Plan 2 — SQLite index + search (Phase 2), deferred.**
  - Slug shares the folder (Phase 2 plan file:
    `plan-archive-search-layer-phase2-plan.md`).
  - Delivers: `plan-archive index rebuild`, relational + FTS5 schema,
    `query --text`, `query --refs-to`, faceted filters; all consuming the
    Phase 1 records unchanged.
  - Goal: ranked full-text search and fast bidirectional/faceted queries when
    scale or query complexity justifies it — **no refactor of Plan 1**.

The no-refactor guarantee rests on D4 + the `Data Contract`: Plan 1 ships the
final record shape and the single derivation module; Plan 2 only adds a consumer
and new read surfaces.

## Retention Intent

Plan-source document for execution coordination. Cleanup-eligible after both
phases are delivered and archived, per
`docs/source/docs-placement-retention-policy-v1.md`. Promote to a durable
runbook only if the catalog/index contract becomes broadly referenced.

## Read First References

- Master design: `docs/plans/2026-05-26-plan-archive-system/plan-archive-system-discussion-source.md`
  (Source type: discussion-to-implementation-doc).
- Current implementation: `nils-cli` `crates/plan-archive/src/{query,refresh,migrate}/`,
  `crates/plan-archive/src/cli.rs`.
- Dependency precedent: `nils-cli` `crates/memo-cli/Cargo.toml` (`rusqlite` bundled).
- Retention policy: `docs/source/docs-placement-retention-policy-v1.md`.

## Recommended Next Artifact

Generate `plan-archive-search-layer-phase1-plan.md` first (immediate
implementation), with `plan-archive-search-layer-phase2-plan.md` authored from
this same source when Phase 1 lands. Then open the Phase 1 tracker via
`create-plan-tracking-issue`.
