# Plan Archive Search Layer — Phase 1 (Catalog) Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: not started; Phase 1 ready to implement
- Target scope: Sprint 1 catalog command + derivation (nils-cli);
  Sprint 2 cross-repo discovery cue (runtime-kit)
- Execution window: Sprint 1 → Sprint 2 (serial)
- Current task: none
- Next task: Task 1.1 — define `CatalogRecord` contract and derivation module
- Last updated: 2026-05-27
- Branch/commit/PR: feat/plan-archive-search-layer; plan commit 7874ec2; PRs pending
- Source document: docs/plans/2026-05-27-plan-archive-search-layer/plan-archive-search-layer-phase1-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: pending
- Source snapshot: pending
- Plan snapshot: pending
- Initial state snapshot: pending

## Validation Plan

- `cargo test -p nils-plan-archive` (record assembly incl. missing-snapshot /
  no-refs, deterministic serialization, filter + refs-to, migrate/refresh
  integration).
- `plan-archive catalog --write` on the live clone, then re-run and confirm
  `git diff` is empty (determinism evidence).
- `agent-docs resolve --context project-dev --strict --format checklist` from
  this repo and from one unrelated repo (inherited pointer `status=present`).
- `rumdl check docs/source/plan-archive-query-pointer-v1.md AGENT_DOCS.toml`
  (markdown doc only).
- `cargo fmt --all -- --check` and `cargo clippy` clean before commit.
- Repo skill governance / `sync-runtime-skills` build stays in sync for the
  query-skill cue.

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | pending | Define `CatalogRecord` contract and shared derivation module | — | `sympoies/nils-cli` (`crates/plan-archive`). Deterministic serde; single derivation point reused unchanged by Phase 2. |
| 1.2 | pending | Add the `plan-archive catalog` command | — | `sympoies/nils-cli`. `--write` / print / `--grep` / `--area` / `--refs-to`. Depends on 1.1. |
| 1.3 | pending | Regenerate catalog on migrate and refresh | — | `sympoies/nils-cli`. Same signed commit on `migrate --apply`; no change to refresh no-auto-commit or `_index/` append-only. Depends on 1.1, 1.2. |
| 2.1 | pending | Add the global-scope query pointer doc and register it | — | `graysurf/agent-runtime-kit`. New `docs/source/plan-archive-query-pointer-v1.md` + `AGENT_DOCS.toml` (`project-dev` / `global` / `required` / `always`). Depends on 1.2. |
| 2.2 | pending | Mirror the cue in the query skill description | — | `graysurf/agent-runtime-kit`. Narrow when-to-use cue in the plan-archive query skill; keep rendered Codex/Claude surfaces in sync. Depends on 2.1. |

## Session Log

- 2026-05-27: Authored this Phase 1 execution-state to complete the plan
  bundle — the `7874ec2` commit shipped only the plan and the shared
  discussion-source. Plan was already validated (`plan-tooling validate` →
  `ok:true`). No implementation started; this state is prepared so
  `create-plan-tracking-issue` can open the tracker with a populated task
  ledger. Because the phase plan/state use a `phase1` infix while the
  discussion-source is the shared Phase 1/2 master, `record open` is invoked
  with explicit `--source-file` / `--plan-file` / `--execution-state-file`
  overrides rather than `<slug>-...` auto-derivation.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `agent-docs resolve --context startup --strict --format checklist` | pass | 2/2 required docs present. | n/a |
| `agent-docs resolve --context project-dev --strict --format checklist` | pass | 2/2 required docs present. | n/a |
| `plan-tooling validate --file docs/plans/2026-05-27-plan-archive-search-layer/plan-archive-search-layer-phase1-plan.md --format json` | pass | `{"ok":true,"errors":[]}` (exit 0). | n/a |
| `rumdl check docs/plans/2026-05-27-plan-archive-search-layer/plan-archive-search-layer-phase1-execution-state.md` | pass | No issues found. | n/a |

## Notes

- The plan's `Location` entries for Sprint 1 point at `crates/plan-archive`
  paths in `sympoies/nils-cli`; `plan-tooling` validates paths relative to
  `agent-runtime-kit`, so nils-cli file existence is not enforced by the
  bundle validator here. The `nils-plan-archive` crate is the implementation
  target for Tasks 1.1–1.3.
- Sprint 2 (Tasks 2.1–2.2) lands in `graysurf/agent-runtime-kit`; this is also
  where the tracking issue and this plan bundle live.
- Phase 2 (SQLite + FTS5 search, indexed `query --text` / `query --refs-to`)
  opens its own tracker from the same discussion-source and is explicitly not
  required for this tracker to close. Phase 3 (optional `files[]` from PR
  changed-files) is also out of scope.
