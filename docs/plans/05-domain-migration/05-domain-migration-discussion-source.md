# Phase 4 — Domain Migration Sweep Discussion Source

- Status: open, ready for implementation planning
- Date: 2026-05-20
- Source: `docs/source/inventory-target-architecture.md` Phase 4 ordering
  (lines 1719-1753), CLI Boundary Extraction Pattern (lines 981-994),
  Project-Local Extensibility (lines 725-743), GitHub Repositories Phase 4
  archival outcome (lines 260-289), Resolved Decision #3 (replace both legacy
  repos).
- Scope: final migration phase covering seven remaining domains plus
  project / company / private overlays and legacy repo archival. Reporting
  was the Plan 03 POC and is only re-verified here; it is not re-migrated.

## Execution

- Recommended plan: docs/plans/05-domain-migration/05-domain-migration-plan.md
- Recommended execution state: docs/plans/05-domain-migration/05-domain-migration-execution-state.md

## Purpose

After Plan 04 lands the sandbox install rehearsal harness and a reliable
doctor, every remaining skill domain must be rewritten so its body invokes
the canonical nils-cli binary instead of duplicating logic. This plan
sweeps through the domains in the order the architecture doc pins, then
archives the two legacy source repos (`graysurf/agent-kit`,
`graysurf/claude-kit`) per Resolved Decision #3 so that
`graysurf/agent-runtime-kit` becomes the sole source of truth.

The per-skill checklist (from the architecture doc) drives every task:

1. Identify the nils-cli binary that owns the deterministic logic.
2. Strip embedded shell / Python / inline logic from the skill body.
3. Rewrite the body to invoke the binary with documented flags, JSON
   handling, and error recovery prose.
4. Add `required_clis` with a verified minimum semver.
5. If logic does not yet exist as a nils-cli binary, log an extraction
   candidate in `docs/source/extraction-backlog.md` rather than reinventing
   it inside the skill.

## Current Judgment

The architecture doc has already done the hard ordering work. The
non-obvious calls this plan locks in:

- `meta` is migrated first (Sprint 1) so subsequent sprints rewrite against
  the new `agent-docs` / `agent-out` / `semantic-commit` skill bodies, not
  the legacy ones.
- `pr` and `dispatch` are the highest-risk surfaces because they touch the
  deliver lifecycle; they are batched into a single sprint with a
  deliver-lifecycle smoke test on a throwaway sandbox branch.
- Archival is treated as a content step (set `archived=true`, add a
  `MOVED.md`) rather than a deletion; commit history is preserved.
- The `$HOME/.agents` symlink (legacy pointer at `agent-kit`) and any
  pre-existing `$XDG_STATE_HOME/claude-kit/` state tree are migrated in
  Sprint 5 alongside the archival step.

## Findings

| Priority | ID | Issue | Evidence | Fix Location | Acceptance |
| --- | --- | --- | --- | --- | --- |
| high | M1 | meta-domain skills must migrate first so downstream sprints rewrite against the new bodies | inventory doc Phase 4 ordering (lines 1725-1731) | `skills/meta/` and `manifests/skills.yaml` | every meta skill body invokes nils-cli, `required_clis` ≥0.2.0, render-golden snapshot updated, sandbox install rehearsal still passes |
| medium | M2 | media + browser are low-risk wrappers and can land in parallel | inventory doc Phase 4 ordering (lines 1732-1733) | `skills/media/`, `skills/browser/` | 4 skills rewritten, parallel-x2 task lanes, doctor reports `required_clis` ok |
| medium | M3 | evidence is broad-surface (6 skills) and needs per-skill PR scoping | inventory doc Phase 4 ordering (lines 1734-1735) | `skills/evidence/` | each of 6 skills rewritten as its own task; render-golden snapshots updated |
| high | M4 | pr + dispatch touch the deliver lifecycle and must migrate only after sandbox harness is reliable | inventory doc lines 1736-1738, 1752-1753 | `skills/pr/`, `skills/dispatch/`, `manifests/skills.yaml` | every pr / dispatch skill body invokes `forge-cli` / `plan-issue` / `plan-issue-local` / `plan-tooling`; deliver-lifecycle smoke test passes on a throwaway sandbox branch |
| medium | M5 | overlays (project / company / private) must keep merging correctly after all bodies rewrite | inventory doc lines 725-743 + Overlay Merge Semantics table | `.private/`, `targets/`, `manifests/` | `agent-runtime install --dry-run` post-merge "effective config" matches expected; project-local overlay smoke test (CI gate 8) passes |
| high | M6 | legacy repos must archive after migration completes — Resolved Decision #3 | inventory doc lines 260-289 | `graysurf/agent-kit`, `graysurf/claude-kit` (GitHub), `$HOME/.agents` (local), `$XDG_STATE_HOME/claude-kit/` (local) | both repos `archived=true` via `gh repo edit`, each carries a root `MOVED.md` pointing at `graysurf/agent-runtime-kit`, neither repo is deleted, `$HOME/.agents` symlink removed, state tree migrated to `$XDG_STATE_HOME/agent-runtime-kit/claude/` |

## Ownership Boundary

- Runtime kit (this repo): skill bodies under `skills/<domain>/`, plugin
  bundles under `plugins/<domain>/`, `manifests/skills.yaml`, render-golden
  snapshots under `tests/golden/`, `.private/` overlay files,
  `targets/<product>/link-map.yaml`, and the `docs/source/extraction-backlog.md`
  log.
- nils-cli: every capability binary the migrated bodies invoke
  (`agent-docs`, `agent-out`, `heuristic-inbox`, `semantic-commit`,
  `agent-scope-lock`, `repo-retro`, `forge-cli`, `plan-issue`,
  `plan-issue-local`, `plan-tooling`, `image-processing`, `screen-record`,
  `browser-session`, `canary-check`, `web-evidence`,
  `test-first-evidence`, `review-evidence`, `skill-usage`, `docs-impact`,
  `model-cross-check`). This plan does not modify binaries; if a body needs
  a flag that does not exist, log an extraction-backlog entry and keep the
  rewrite minimal.
- GitHub: archive operations on `graysurf/agent-kit` and
  `graysurf/claude-kit`.
- Local host: `$HOME/.agents` symlink removal, optional
  `$XDG_STATE_HOME/claude-kit/` → `$XDG_STATE_HOME/agent-runtime-kit/claude/`
  migration.

## Backlog / Next Fixes

1. Sprint 1 (meta) — promoted ahead of media/browser/etc. because every
   downstream sprint depends on the new bodies.
2. Sprint 2 (media + browser) — low risk, parallel-x2.
3. Sprint 3 (evidence) — six per-skill tasks for PR scoping.
4. Sprint 4 (pr + dispatch) — highest risk; gated on Plan 04's sandbox
   harness and on `forge-cli` semver bump from Plan 04.
5. Sprint 5 (overlays + archival) — terminal step. After it lands,
   agent-runtime-kit is the sole source of truth.

## Retention Intent

- This source doc is execution coordination — delete via
  `dispatch:durable-artifact-cleanup` after Sprint 5 closes and the
  archived legacy repos have been verified.
- `docs/source/extraction-backlog.md` stays durable — it is the log of
  every "binary does not yet exist" finding from this sweep and feeds
  future nils-cli release planning.

## Validation Gate

- `plan-tooling validate --file docs/plans/05-domain-migration/05-domain-migration-plan.md --format text --explain`
- Per-domain render-golden refresh: `cargo test -p agent-runtime-cli render_golden_<domain>`
- Sandbox install rehearsal after each sprint: `bash tests/sandbox/claude/run.sh` and `bash tests/sandbox/codex/run.sh`
- Doctor regression gate: `agent-runtime doctor --product claude` and `--product codex` report all `required_clis` as `ok`
- Deliver-lifecycle smoke (Sprint 4 only): open + close one throwaway PR on a sandbox branch in a scratch fork
- Project-local overlay smoke (Sprint 5): `agent-runtime doctor --check-project <repo>` against one consumer repo per overlay script (`bench`, `demo`, `deploy`, `pre-pr`, `release`, `bootstrap`)

## Do Not Do

- Do not migrate any pr / dispatch skill before Plan 04's sandbox harness
  is green and the `forge-cli` semver bump is published.
- Do not delete `graysurf/agent-kit` or `graysurf/claude-kit`; archive
  only. History preservation is a hard requirement.
- Do not change skill manifest IDs (`pr:create-feature-pr`,
  `dispatch:dispatch-implementation`, etc.) during this sweep. Renames
  belong in a follow-up plan; bodies and `required_clis` are the only
  fields touched here.
- Do not reinvent logic inline when a binary is missing — log an entry in
  `docs/source/extraction-backlog.md` and leave the skill body as a stub
  that exits non-zero with a clear "blocked on extraction" message.
- Do not drop the `.private/` overlay's deep-merge semantics; the
  Overlay Merge Semantics table is the contract.

## Open Questions

- Whether `agent-kit` archival should retain the public-content split
  decision (the inventory doc's Open Question about a future public face)
  or defer it as a follow-up. **Default: defer.** This plan archives both
  repos in-place; a future plan can revisit a public split.
- Final cutover date for the `$HOME/.agents` symlink removal — Sprint 5
  task. **Recommended date: 2026-06-30** (six weeks after Plan 04 lands,
  giving in-flight sessions time to pick up the new home).
- Whether dispatch:* skills should keep their plugin-namespaced names
  (`dispatch:dispatch-implementation`) or simplify post-migration.
  **Default: keep**, document any future alias mapping in a follow-up plan.
