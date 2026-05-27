# Plan Archive Discover Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: not started; tracking issue opened
- Target scope: read-only `plan-archive discover` CLI in `nils-cli`, plus thin
  `plan-archive-discover` skill wrapper in `agent-runtime-kit`
- Execution window: Sprint 1 CLI, then Sprint 2 skill wrapper
- Current task: none
- Next task: Task 1.1 — define candidate model and shared discovery inputs
- Last updated: 2026-05-27
- Branch/commit/PR: feat/plan-archive-discover; plan commit a5c6ea6; PR pending
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
| 1.1 | pending | Define candidate model and shared discovery inputs | — | `sympoies/nils-cli`; share migrate source identity, host classification, and archive target derivation. |
| 1.2 | pending | Add `plan-archive discover` | — | `sympoies/nils-cli`; read-only JSON/text subcommand with eligible/blocked/unknown classifications. |
| 1.3 | pending | Document CLI behavior and examples | — | `sympoies/nils-cli`; make discover a preselection helper, not a bulk apply path. |
| 2.1 | pending | Add skill source and manifest entries | — | `graysurf/agent-runtime-kit`; thin wrapper that delegates selected folders to `plan-archive-migrate`. |
| 2.2 | pending | Update runtime floor and generated surfaces | — | `graysurf/agent-runtime-kit`; only after released CLI surface includes discover. |

## Session Log

- 2026-05-27: Created a dedicated worktree/branch for this plan so concurrent
  plan-archive work in other checkouts does not conflict. Authored the source,
  plan, and execution-state bundle for Option B: CLI-owned discovery plus a thin
  runtime skill wrapper. No implementation has started.
- 2026-05-27: Opened tracking issue #135 with source, plan, and initial state
  snapshots from plan commit a5c6ea6. Initialized run state for issue #135 and
  confirmed `record audit --expect-visible` passes.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `agent-docs resolve --context startup --strict --format checklist` | pass | 2/2 required docs present. | n/a |
| `agent-docs resolve --context project-dev --strict --format checklist` | pass | 2/2 required docs present. | n/a |
| `plan-tooling validate --file docs/plans/2026-05-27-plan-archive-discover/plan-archive-discover-plan.md --format json` | pass | `{"ok":true,"errors":[]}` (exit 0). | n/a |
| `rumdl check docs/plans/2026-05-27-plan-archive-discover/*.md` | pass | No issues found. | n/a |
| `plan-issue --repo graysurf/agent-runtime-kit --format json record open --profile tracking ...` | pass | Opened issue #135 and posted source, plan, and state snapshots. | n/a |
| `plan-issue --format json tracking run init --provider-repo graysurf/agent-runtime-kit --issue 135 ...` | pass | Initialized run `00000000000000-issue-135`. | n/a |
| `plan-issue --format json record audit --profile tracking --expect-visible ...` | pass | Visible audit passed for source, plan, and state roles. | `agent-out` run dir |

## Notes

- The tracking issue should be opened in `graysurf/agent-runtime-kit` because
  runtime-kit owns the skill surface and coordination bundle. The first
  implementation lane still lands in `sympoies/nils-cli`.
- Use `area::cli` for the initial tracking label because the CLI surface is the
  durable behavior owner; the runtime skill remains a wrapper.
