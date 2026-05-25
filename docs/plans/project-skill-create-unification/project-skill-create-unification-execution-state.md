# Execution State: Project Skill Create Unification

<!-- execute-from-tracking-issue:state:v1 -->
## Execution State

- Status: tracking issue opened; implementation pending
- Target scope: unify project-local skill creation under
  `meta:create-project-skill`, remove the Claude-only create surface, and prove
  default-both / Codex-only / bridge-only behavior with fixtures.
- Current task: issue-backed tracking record created.
- Next task: implement Sprint 1.
- Last updated: 2026-05-25
- Branch: feat/project-skill-create-unification
- Source document:
  docs/plans/project-skill-create-unification/project-skill-create-unification-plan.md
- Plan document:
  docs/plans/project-skill-create-unification/project-skill-create-unification-plan.md
- Discussion source:
  docs/plans/project-skill-create-unification/project-skill-create-unification-discussion-source.md
- Live tracking issue:
  <https://github.com/graysurf/agent-runtime-kit/issues/112>
  - Source comment:
    <https://github.com/graysurf/agent-runtime-kit/issues/112#issuecomment-4534683810>
  - Plan comment:
    <https://github.com/graysurf/agent-runtime-kit/issues/112#issuecomment-4534683944>
  - Initial state comment:
    <https://github.com/graysurf/agent-runtime-kit/issues/112#issuecomment-4534684065>

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | pending | Update create-project-skill contract | n/a | Shared skill body should document default both, Codex-only, bridge-only, and removed Claude-only modes. |
| 1.2 | pending | Add shared helper entrypoint | n/a | Helper should own deterministic file operations for supported modes. |
| 1.3 | pending | Render shared products | n/a | Codex/Claude rendered outputs and goldens need update after source changes. |
| 2.1 | pending | Delete Claude-only command and script | n/a | Remove old command/script without alias. |
| 2.2 | pending | Update docs, manifests, and support matrix references | n/a | Active docs should stop advertising the old Claude-only surface. |
| 3.1 | pending | Extend create-project fixture matrix | n/a | Fixture should cover default both, Codex-only, bridge-only, rejected removed flags, and opt-in pre-pr. |
| 3.2 | pending | Extend runtime-smoke coverage | n/a | Runtime-smoke should prove unified behavior and old helper absence. |
| 3.3 | pending | Run full validation and record follow-up | n/a | Doctor bridge validation remains non-blocking unless evidence warrants a follow-up. |

## Validation

| Command | Status | Summary |
| --- | --- | --- |
| `agent-docs resolve --context startup --strict --format checklist` | pass | Required startup docs present. |
| `agent-docs resolve --context project-dev --strict --format checklist` | pass | Project development docs and docs placement policy present. |

## Closeout Gate

- Close condition: every task is done or explicitly deferred, focused
  governance/runtime-smoke/render/audit validation passes, full repository
  validation is recorded, and the old Claude-only create surface has no active
  references.
- Reopen triggers:
  - `create-claude-project-skill` reappears as an active command/script surface.
  - `--target claude`, `--claude-only`, or `--link-only` is documented or
    accepted as a supported creation mode.
  - Default `create-project-skill` creation no longer sets up the Claude bridge.
  - `.agents/scripts/pre-pr.sh` is created without explicit opt-in.
