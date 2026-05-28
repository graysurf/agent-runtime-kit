# Plan Archive Discover Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: close-ready (Sprint 1 + Sprint 2 delivered and merged)
- Target scope: read-only `plan-archive discover` CLI in `nils-cli`, plus thin
  `plan-archive-discover` skill wrapper in `agent-runtime-kit`
- Execution window: Sprint 1 CLI, then Sprint 2 skill wrapper — both done
- Current task: none
- Next task: run `/plan-tracking-issue-closeout` to close issue #135
- Last updated: 2026-05-28
- Branch/commit/PR: feat/plan-archive-discover (Sprint 1); feat/plan-archive-discover-skill (Sprint 2); plan commit `a5c6ea6`; merged PRs `sympoies/nils-cli#593`, `sympoies/nils-cli#597`, and `graysurf/agent-runtime-kit#141`
- Source document: docs/plans/2026-05-27-plan-archive-discover/plan-archive-discover-discussion-source.md
- Tracking issue: <https://github.com/graysurf/agent-runtime-kit/issues/135>
- Source snapshot:
  <https://github.com/graysurf/agent-runtime-kit/issues/135#issuecomment-4556244805>
- Plan snapshot:
  <https://github.com/graysurf/agent-runtime-kit/issues/135#issuecomment-4556244987>
- Initial state snapshot:
  <https://github.com/graysurf/agent-runtime-kit/issues/135#issuecomment-4556245331>

## Validation Plan

- `plan-tooling validate --file
  docs/plans/2026-05-27-plan-archive-discover/plan-archive-discover-plan.md
  --format text --explain`
- `rumdl check docs/plans/2026-05-27-plan-archive-discover/*.md`
- `cargo test -p nils-plan-archive discover`
- `cargo test -p nils-plan-archive migrate`
- `agent-runtime render --product codex`
- `agent-runtime render --product claude`
- `bash scripts/ci/skill-governance-audit.sh`
- `bash scripts/ci/all.sh` before final runtime-kit PR delivery when practical

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | done | Define candidate model and shared discovery inputs | sympoies/nils-cli#593 | Shared source identity, host classification, and archive target derivation between discover and migrate. |
| 1.2 | done | Add `plan-archive discover` | sympoies/nils-cli#593 | Read-only `cli.plan-archive.discover.v1` JSON/text subcommand with eligible/blocked/unknown classifications. |
| 1.3 | done | Document CLI behavior and examples | sympoies/nils-cli#593 | README + crate docs updated; release shipped in v0.25.5 via sympoies/nils-cli#597. |
| 2.1 | done | Add skill source and manifest entries | graysurf/agent-runtime-kit#141 | `core/skills/meta/plan-archive-discover/SKILL.md.tera`; manifests, link-map, reminder catalog, sandbox lists, golden renders, runtime-smoke probe. |
| 2.2 | done | Update runtime floor and generated surfaces | graysurf/agent-runtime-kit#141 | `docs/source/nils-cli-surface.md` pinned to v0.25.5 (head `1b8d2dd`); goldens regenerated; skill counts bumped 61→62. |

## Session Log

- 2026-05-27: Created a dedicated worktree/branch for this plan so concurrent
  plan-archive work in other checkouts does not conflict. Authored the source,
  plan, and execution-state bundle for Option B: CLI-owned discovery plus a thin
  runtime skill wrapper. No implementation has started.
- 2026-05-27: Opened tracking issue #135 with source, plan, and initial state
  snapshots from plan commit a5c6ea6. Initialized run state for issue #135 and
  confirmed `record audit --expect-visible` passes.
- 2026-05-28: Sprint 1 delivered via `sympoies/nils-cli#593` (squash merge
  `94cf119`, 2026-05-28T03:12:14Z); release cut as `sympoies/nils-cli#597`
  (merge `1b8d2dd`, 2026-05-28T03:28:37Z); tag `v0.25.5` published
  2026-05-28T03:39:57Z and Homebrew tap formula bumped.
- 2026-05-28: Sprint 2 delivered via `graysurf/agent-runtime-kit#141` (squash
  merge `b0b267f`). Added the `meta:plan-archive-discover` skill source +
  manifests + link-map + reminder catalog + sandbox entries, bumped the
  documented nils-cli surface floor to v0.25.5, regenerated codex/claude/
  shared goldens, refreshed maintained skill counts (61→62), and added a
  deterministic `plan-archive discover` runtime-smoke probe. Resolved the two
  plan open questions (combined `suggested_migrate_command` per eligible
  folder; CLI owns the closeout verdict).

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `agent-docs resolve --context startup --strict --format checklist` | pass | 4/4 required docs present (Sprint 2 session). | n/a |
| `agent-docs resolve --context project-dev --strict --format checklist` | pass | 2/2 required docs present. | n/a |
| `plan-tooling validate --file docs/plans/2026-05-27-plan-archive-discover/plan-archive-discover-plan.md --format json` | pass | `{"ok":true,"errors":[]}` (exit 0). | n/a |
| `rumdl check docs/plans/2026-05-27-plan-archive-discover/*.md` | pass | No issues found. | n/a |
| `plan-issue --repo graysurf/agent-runtime-kit --format json record open --profile tracking ...` | pass | Opened issue #135 and posted source, plan, and state snapshots. | n/a |
| `plan-issue --format json tracking run init --provider-repo graysurf/agent-runtime-kit --issue 135 ...` | pass | Initialized run `00000000000000-issue-135`. | n/a |
| `plan-issue --format json record audit --profile tracking --expect-visible ...` | pass | Visible audit passed for source, plan, and state roles. | `agent-out` run dir |
| `plan-archive --version`; `plan-archive discover --help` | pass | Host installed at `0.25.5`; discover subcommand surfaces documented flags. | n/a |
| `agent-runtime render --product codex` / `--product claude` | pass | Both report `rendered=62`. | `build/codex/`, `build/claude/` |
| `bash scripts/ci/skill-governance-audit.sh` | pass | `repo OK skills=62 plugins=10 lifecycle=4 count_targets=6 active_count=62`. | n/a |
| `bash scripts/ci/all.sh` | pass | Positions 1–13 OK (governance + fixtures, surface-floor alignment, codex/claude renders, golden diff after `--update-golden`, audit-drift root + 4 fixtures, surfaces manifest + acceptance, skill-surface shape `checks=ok=82`, sandbox install rehearsal, deterministic runtime smoke incl. new `meta.plan-archive-discover` probe, project-local overlay smoke, shared hook tests). | n/a |
| `forge-cli pr deliver --kind feature ...` | pass | Opened, readied, and squash-merged `graysurf/agent-runtime-kit#141` at `b0b267f`; labels `type::feature, area::skills, size::s, risk::low, workflow::tracking` applied. | PR #141 |

## Notes

- The tracking issue should be opened in `graysurf/agent-runtime-kit` because
  runtime-kit owns the skill surface and coordination bundle. The first
  implementation lane still lands in `sympoies/nils-cli`.
- Use `area::cli` for the initial tracking label because the CLI surface is the
  durable behavior owner; the runtime skill remains a wrapper.

## Resolved Open Questions

- Migrate command shape (plan §Open questions): the released CLI
  (`plan-archive` v0.25.5) emits a single combined `suggested_migrate_command`
  per eligible folder, preferring self-referential `--issue` / `--pr` / `--mr`
  refs (`crates/plan-archive/src/discover/mod.rs::build_migrate_command`). The
  runtime-kit skill follows that contract verbatim and does not synthesize
  per-ref commands.
- Closeout markers (plan §Open questions): the CLI owns the verdict via
  `DiscoverStatus`; the skill never promotes `unknown` to `eligible` based on
  agent-side heuristics. The skill body codifies that boundary so future agent
  reviewers do not regress it.
