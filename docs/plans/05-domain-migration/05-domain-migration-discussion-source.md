# Phase 4 Domain Migration Sweep Discussion Source

- Status: open, dispatch-ready planning refreshed
- Date: 2026-05-22
- Source: `docs/source/inventory-target-architecture.md` Phase 4 ordering,
  CLI Boundary Extraction Pattern, Project-Local Extensibility, GitHub
  Repositories Phase 4 archival outcome, Resolved Decision #3 (replace both
  legacy repos), and `docs/source/nils-cli-surface.md` v0.16.0 snapshot.
- Scope: final migration phase covering the remaining domains plus project /
  company / private overlays and legacy repo archival. Reporting was the Plan
  03 POC and is only re-verified here; it is not re-migrated.

## Execution

- Recommended plan: docs/plans/05-domain-migration/05-domain-migration-plan.md
- Recommended execution state: docs/plans/05-domain-migration/05-domain-migration-execution-state.md

## Purpose

After Plan 04 landed the sandbox install rehearsal harness, doctor, lifecycle,
and drift gates in the released `agent-runtime` binary, every remaining skill
domain must be rewritten so its body invokes the canonical nils-cli binary
instead of duplicating logic. This plan sweeps through the domains in the order
the architecture doc pins, then archives the two legacy source repos
(`graysurf/agent-kit`, `graysurf/claude-kit`) per Resolved Decision #3 so that
`graysurf/agent-runtime-kit` becomes the sole source of truth.

The per-skill checklist from the architecture doc drives every task:

1. Identify the nils-cli binary that owns the deterministic logic.
2. Strip embedded shell / Python / inline logic from the skill body.
3. Rewrite the body to invoke the binary with documented flags, JSON handling,
   and error recovery prose.
4. Add `required_clis` with a verified minimum semver.
5. If logic does not yet exist as a nils-cli binary, log an extraction candidate
   in `docs/source/extraction-backlog.md` rather than reinventing it inside the
   skill.

## Current Judgment

The architecture doc has already done the hard ordering work. The non-obvious
calls this plan locks in:

- `meta` is migrated in the first implementation sprint so subsequent sprints
  rewrite against the new `agent-docs` / `agent-out` / `semantic-commit` skill
  bodies, not the legacy ones.
- Shared manifest, plugin metadata, sandbox pin, golden, and extraction-backlog
  writes are isolated into integration tasks so parallel source-body lanes do
  not collide.
- `pr` and `dispatch` are the highest-risk surfaces because they touch the
  deliver lifecycle. `pr` is split into create/close and deliver-macro sprints,
  and `dispatch` follows after the delivery smoke has a scratch-target gate.
- Archival is treated as a content step (`archived=true`, root `MOVED.md`) and
  never as deletion; commit history is preserved.
- The `$HOME/.agents` symlink and any pre-existing
  `$XDG_STATE_HOME/claude-kit/` state tree are migrated only after legacy repo
  archival verifies.

## Findings

| Priority | ID | Issue | Evidence | Fix Location | Acceptance |
| --- | --- | --- | --- | --- | --- |
| high | M1 | meta-domain skills must migrate first so downstream sprints rewrite against the new bodies | inventory doc Phase 4 ordering | `core/skills/meta/`, `manifests/skills.yaml`, `manifests/plugins.yaml` | every meta skill body invokes nils-cli, `required_clis` pins a concrete released semver, render-golden snapshots update, sandbox install rehearsal still passes |
| medium | M2 | media + browser are low-risk wrappers and can land in parallel | inventory doc Phase 4 ordering | `core/skills/media/`, `core/skills/browser/` | four skills rewritten, parallel-x2 task lanes, doctor/audit reports `required_clis` ok |
| medium | M3 | evidence is broad-surface and needs split integration lanes | inventory doc Phase 4 ordering | `core/skills/evidence/` | evidence skills rewritten across capture and analysis sprints; render-golden snapshots updated |
| high | M4 | pr + dispatch touch the deliver lifecycle and must migrate only after sandbox harness is reliable | inventory doc Phase 4 ordering and high-risk note | `core/skills/pr/`, `core/skills/dispatch/`, `manifests/skills.yaml` | every pr / dispatch skill body invokes `forge-cli` / `plan-issue` / `plan-issue-local` / `plan-tooling`; deliver-lifecycle smoke test passes on a scratch fork/branch |
| medium | M5 | overlays (project / company / private) must keep merging correctly after all bodies rewrite | inventory doc Runtime Root Model and Overlay Merge Semantics table | `.private/`, `targets/`, `manifests/`, `tests/projects/` | `agent-runtime install --dry-run` post-merge output matches expected; project-local overlay smoke test passes |
| high | M6 | legacy repos must archive after migration completes per Resolved Decision #3 | inventory doc GitHub Repositories and Resolved Decisions | `graysurf/agent-kit`, `graysurf/claude-kit` (GitHub), `$HOME/.agents` (local), `$XDG_STATE_HOME/claude-kit/` (local) | both repos `archived=true` via `gh repo edit`, each carries a root `MOVED.md` pointing at `graysurf/agent-runtime-kit`, neither repo is deleted, `$HOME/.agents` symlink removed, state tree migrated to `$XDG_STATE_HOME/agent-runtime-kit/claude/` |

## Ownership Boundary

- Runtime kit (this repo): portable skill bodies under
  `core/skills/<domain>/`, product plugin metadata under
  `targets/<product>/plugins/<domain>/`, `manifests/skills.yaml`,
  `manifests/plugins.yaml`, render-golden snapshots under `tests/golden/`,
  stable overlay fixtures, `targets/<product>/link-map.yaml`, and the
  `docs/source/extraction-backlog.md` log.
- nils-cli: every capability binary the migrated bodies invoke
  (`agent-docs`, `agent-out`, `heuristic-inbox`, `semantic-commit`,
  `agent-scope-lock`, `repo-retro`, `forge-cli`, `plan-issue`,
  `plan-issue-local`, `plan-tooling`, `image-processing`, `screen-record`,
  `browser-session`, `canary-check`, `web-evidence`, `test-first-evidence`,
  `review-evidence`, `skill-usage`, `docs-impact`, `model-cross-check`).
  This plan does not modify binaries; if a body needs a flag that does not
  exist, log an extraction-backlog entry and keep the rewrite minimal.
- GitHub: archive operations on `graysurf/agent-kit` and
  `graysurf/claude-kit`.
- Local host: `$HOME/.agents` symlink removal, optional
  `$XDG_STATE_HOME/claude-kit/` to `$XDG_STATE_HOME/agent-runtime-kit/claude/`
  migration.

## Backlog / Next Fixes

1. Sprint 1 (meta foundation) — reporting regression guard plus the meta bodies
   downstream sprints depend on.
2. Sprint 2 (media + browser) — low-risk wrapper lanes, parallel-x2.
3. Sprint 3 (evidence capture) — web/test-first/review/skill-usage bodies plus
   integration.
4. Sprint 4 (evidence analysis) — docs-impact/model-cross-check plus serial
   evidence integration.
5. Sprint 5 (PR create/close) — lower-risk `forge-cli` PR/MR surfaces.
6. Sprint 6 (PR delivery macros) — delivery bodies plus scratch-target smoke.
7. Sprint 7 (dispatch) — issue lifecycle and execution orchestration skills.
8. Sprint 8 (overlays) — private and project-local overlay gates.
9. Sprint 9 (archive and cutover) — archive legacy repos, remove local symlink,
   migrate Claude state. After it lands, agent-runtime-kit is the sole source of
   truth.

## Retention Intent

- This source doc is execution coordination. Delete it via
  `dispatch:durable-artifact-cleanup` after Sprint 9 closes and the archived
  legacy repos have been verified.
- `docs/source/extraction-backlog.md` stays durable. It is the log of every
  "binary does not yet exist" finding from this sweep and feeds future nils-cli
  release planning.

## Validation Gate

- `plan-tooling validate --file docs/plans/05-domain-migration/05-domain-migration-plan.md --format text --explain`
- Per-domain render and golden refresh: `agent-runtime render --product codex`,
  `agent-runtime render --product claude`,
  `agent-runtime render --product codex --update-golden`, and
  `agent-runtime render --product claude --update-golden`
- Sandbox install rehearsal after each integration sprint:
  `bash scripts/ci/sandbox-install-rehearsal.sh`
- Drift and full gate: `agent-runtime audit-drift` and `bash scripts/ci/all.sh`
- Deliver-lifecycle smoke (Sprint 6 only): open + close one throwaway PR on a
  scratch fork/branch
- Project-local overlay smoke (Sprint 8): `agent-runtime doctor
  --check-project <repo>` against a stable sample project for overlay scripts

## Do Not Do

- Do not migrate any PR delivery or dispatch execution skill before the
  preceding lower-risk PR and smoke gates are green.
- Do not delete `graysurf/agent-kit` or `graysurf/claude-kit`; archive only.
  History preservation is a hard requirement.
- Do not change canonical skill IDs during this sweep. Renames belong in a
  follow-up plan; bodies, manifests, product metadata, and `required_clis` are
  the fields touched here.
- Do not reinvent logic inline when a binary is missing. Log an entry in
  `docs/source/extraction-backlog.md` and leave the skill body as a stub that
  exits non-zero with a clear "blocked on extraction" message.
- Do not drop `.private` overlay deep-merge semantics; the Overlay Merge
  Semantics table is the contract.

## Open Questions

- Whether `agent-kit` archival should retain the public-content split decision
  or defer it as a follow-up. **Default: defer.** This plan archives both repos
  in-place; a future plan can revisit a public split.
- Final cutover date for the `$HOME/.agents` symlink removal. **Recommended
  date: 2026-06-30**, giving in-flight sessions time to pick up the new home.
- Whether dispatch skills should keep plugin-namespaced names or simplify
  post-migration. **Default: keep**, document any future alias mapping in a
  follow-up plan.
