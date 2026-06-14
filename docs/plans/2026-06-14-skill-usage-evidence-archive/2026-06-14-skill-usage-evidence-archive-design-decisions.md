# Skill Usage Evidence Durability And Query - Design Decisions

- Status: accepted on 2026-06-14; execution has entered Sprint 1.2. This is the
  Sprint 1 Task 1.2 deliverable and gates Sprints 3, 4, and 5.
- Source: docs/plans/2026-06-14-skill-usage-evidence-archive/2026-06-14-skill-usage-evidence-archive-discussion-source.md
- Plan: docs/plans/2026-06-14-skill-usage-evidence-archive/2026-06-14-skill-usage-evidence-archive-plan.md

This document freezes the decisions that gate Sprint 3, 4, and 5. Each decision
records the chosen option, the rationale, and the rejected alternatives.

## Decision 1: Durable grain

- **Decision**: rollup-per-run. The archive stores one normalized index record
  per skill-run, not the raw envelope. Raw detail stays in typed child evidence,
  referenced from the index record after scrubbing.
- **Rationale**: keeps archive volume and redaction burden bounded while still
  supporting the queries operators actually need (by skill, outcome, repo, time).
  Mirrors the `agent-plan-archive` `_index/` snapshot model, so the query CLI can
  reuse the same shape.
- **Rejected**:
  - Raw audit log (archive every envelope): unbounded volume, heavy per-record
    redaction, and most records are never read.
  - Curated-only (archive just promoted records): that is already what
    `heuristic-inbox` does; it would not surface the unpromoted majority the user
    wants to look back on.

## Decision 2: Archival trigger and writer

- **Decision**: a single explicit writer. An `evidence migrate` flow (dry-run
  first, apply on confirmation) is the only path that writes to the archive,
  mirroring `plan-archive migrate`. `heuristic-session-closeout` (Sprint 2) only
  surfaces and suggests the session's records; it never writes to the archive.
- **Rationale**: keeps the Sprint 2 (surface) and Sprint 4 (archive) boundaries
  clean, preserves the existing rule that raw records are never auto-committed,
  and keeps every archive write a reviewed, intentional action.
- **Rejected**:
  - Closeout auto-archives: blurs the surface/store boundary and risks silent,
    unreviewed writes.
  - Two writers (closeout and migrate): duplicate redaction and dedup logic.

## Decision 3: Storage target and clone-path resolution

- **Decision**: a new sibling archive repo `agent-evidence-archive`, mirroring
  `agent-plan-archive`. Two-level config/data split. Clone path resolves:
  `--archive` flag > `$AGENT_EVIDENCE_ARCHIVE_HOME` env > machine-local config
  `archive_clone_path` (config at
  `$XDG_CONFIG_HOME/agent-evidence-archive/config.yaml`) > documented default
  `${XDG_DATA_HOME:-$HOME/.local/share}/agent-evidence-archive`.
- **Rationale**: gives nils-cli a fixed, zero-config default entry point while
  keeping the override chain. The config pointer lives in XDG config; the git
  data repo defaults to XDG data, which is the XDG-correct home for growing,
  pushable data and matches the existing state/config separation
  (`AGENT_HOME` already lives under XDG state).
- **Rejected**:
  - Git data repo under `$XDG_CONFIG_HOME`: config-as-data, bloats dotfile
    sync/backup, and diverges from `agent-plan-archive` whose clone lives under a
    normal project checkout.
  - Extending `agent-plan-archive`: mixes plan history and evidence in one store.
  - A heuristic-system section: the gatekeeper rejects raw records from that root
    by design.
- **Improvement over `agent-plan-archive`**: a documented zero-config default
  location, rather than requiring a manual clone placement plus hand-written
  config.

## Decision 4: Producer version field

- **Decision**: add an additive `producer` block to the `skill-usage.record.v1`
  envelope carrying the tool name and the producing nils-cli version. The schema
  version is not bumped because the field is purely additive and backward
  compatible.
- **Rationale**: archived records span time and hosts, so each must carry its
  producing version for unambiguous cross-version queries; the kit version-pin
  fixes the version per host but not across the archive.
- **Rejected**: a separate sidecar version file (splits provenance from the
  record); bumping the schema version for an additive change (forces needless
  reader churn).

## Decision 5: Query shapes

- **Decision**: minimum query surface filters by skill, outcome, repo, and time,
  plus full-text search over intent and outcome summary. Mirror the
  `plan-archive` `catalog` (filtered) and `search` (full-text) split.
- **Rationale**: these are the dimensions a "look back at a critical moment"
  query needs; they map directly onto the rollup index record fields.
- **Rejected**: an open-ended query DSL (overbuilt before real query patterns are
  known).

## Decision 6: Cross-version query handling

- **Decision**: the query layer declares the schema-version range it can read and
  runs queries against a normalized derived catalog, not against heterogeneous
  raw records. Records that fall outside the readable range are reported, not
  silently skipped.
- **Rationale**: lets a mixed-version archive stay queryable as the record schema
  evolves, echoing the kit's existing `version-alignment` discipline.
- **Rejected**: querying raw records directly (breaks when the schema changes);
  silently ignoring unreadable records (hides coverage gaps).

## Decision 7: Redaction

- **Decision**: reuse the existing redaction discipline. The migrate flow scrubs
  before writing and produces a reviewable scrub log, following
  `plan-archive refresh` scrub-log review and `heuristic-inbox ingest-evidence`
  redaction. Raw `skill-usage.record.json` is never committed.
- **Rationale**: records contain command transcripts and local paths; committing
  them unscrubbed would leak local context into a durable repo.
- **Rejected**: committing raw records (leak risk); building a new redaction
  engine (the existing surfaces already do this).

## Decision 8: Cross-repo coordination

- **Decision**: the nils-cli changes (the `producer` field in Sprint 3.1 and the
  evidence query primitives in Sprint 3.2) land as their own upstream nils-cli
  PRs, are referenced from this tracker, and are consumed in the kit through the
  `nils-cli-bump` version-pin flow after release. The `agent-evidence-archive`
  repo is created independently and referenced. The kit-side deliverables
  (closeout surfacing, migrate skill, policy, version-pin bumps) are the in-repo
  PRs.
- **Rationale**: the kit pins nils-cli to an exact tag and is the natural place to
  coordinate "kit needs these nils-cli primitives"; this keeps each repo's PRs
  scoped while the tracker stays the coordination spine.
- **Rejected**: vendoring the nils-cli changes into the kit (breaks the
  single-source nils-cli model).

## Draft rollup index record shape

The rollup index record per skill-run (field names indicative, finalized in
Sprint 4.1):

- `id`: stable slug for the run (timestamp + skill + short digest).
- `archived_at`: archive write time.
- `skill`: skill path or id.
- `intent`, `trigger`: from the source envelope.
- `repo`, `cwd`: scrubbed to a repo slug or `$HOME`-relative path.
- `started_at`, `ended_at`.
- `outcome`: `{ status, summary }`.
- `producer`: `{ tool, nils_cli_version }`.
- `counts`: `{ validation, failures }`.
- `linked_evidence`: scrubbed references to typed child records.
- `source_digest`: hash of the raw envelope for provenance and dedup; the raw
  record itself is not stored.
- `promotion`: optional `{ heuristic_inbox_case }` when the run was promoted.

This shape is queryable by Decision 5's dimensions and links forward to
heuristic-inbox promotion without duplicating raw content.
