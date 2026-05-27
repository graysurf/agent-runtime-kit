# Execution State: Project Skill Create Unification

<!-- execute-from-tracking-issue:state:v1 -->
## Execution State

- Status: implementation complete; full repository validation passed
- Target scope: unify project-local skill creation under
  `meta:create-project-skill`, remove the Claude-only create surface, and prove
  default-both / Codex-only / bridge-only behavior with fixtures.
- Current task: delivery PR and issue closeout.
- Next task: open delivery PR, run review gate, and close tracking issue when
  gates pass.
- Last updated: 2026-05-25
- Branch: feat/project-skill-create-unification
- Source document:
  docs/plans/2026-05-25-project-skill-create-unification/project-skill-create-unification-plan.md
- Plan document:
  docs/plans/2026-05-25-project-skill-create-unification/project-skill-create-unification-plan.md
- Discussion source:
  docs/plans/2026-05-25-project-skill-create-unification/project-skill-create-unification-discussion-source.md
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
| 1.1 | done | Update create-project-skill contract | `core/skills/meta/create-project-skill/SKILL.md.tera` | Documents default both, Codex-only, bridge-only, removed Claude-only flags, and explicit pre-pr opt-in. |
| 1.2 | done | Add shared helper entrypoint | `core/skills/meta/create-project-skill/scripts/create-project-skill.sh` | Helper owns deterministic creation, bridge, wrapper, dry-run, and removed-flag rejection behavior. |
| 1.3 | done | Render shared products | `agent-runtime render --product codex --update-golden`; `agent-runtime render --product claude --update-golden`; `agent-runtime render --target support-matrix --update-golden` | Codex/Claude goldens and shared support matrix refreshed. |
| 2.1 | done | Delete Claude-only command and script | `targets/claude/commands/create-claude-project-skill.md`; `targets/claude/scripts/create-claude-project-skill.sh` | Removed without alias or compatibility window. |
| 2.2 | done | Update docs, manifests, and support matrix references | `manifests/surfaces.yaml`; `SUPPORT_MATRIX.md`; plan bundle | Active surfaces stop advertising the removed Claude-only command/script. |
| 3.1 | done | Extend create-project fixture matrix | `scripts/ci/skill-governance-audit.sh`; `tests/runtime-smoke/fixtures/skill-lifecycle/create-project-skill/` | Fixture now includes `.claude/skills`, `.gitignore`, and default no `pre-pr.sh`. |
| 3.2 | done | Extend runtime-smoke coverage | `tests/runtime-smoke/cases/meta/run.sh`; `tests/runtime-smoke/acceptance-matrix.yaml` | Runtime-smoke covers default both, Codex-only, bridge-only, and removed flag rejection. |
| 3.3 | done | Run full validation and record follow-up | `bash scripts/ci/all.sh` | Doctor bridge validation remains non-blocking; no separate follow-up evidence warranted. |

## Validation

| Command | Status | Summary |
| --- | --- | --- |
| `agent-docs resolve --context startup --strict --format checklist` | pass | Required startup docs present. |
| `agent-docs resolve --context project-dev --strict --format checklist` | pass | Project development docs and docs placement policy present. |
| `bash -n core/skills/meta/create-project-skill/scripts/create-project-skill.sh` | pass | Helper shell syntax valid. |
| `bash -n tests/runtime-smoke/cases/meta/run.sh` | pass | Runtime-smoke meta case shell syntax valid. |
| `bash -n scripts/ci/skill-governance-audit.sh` | pass | Governance audit shell syntax valid. |
| `bash scripts/ci/skill-governance-audit.sh --fixture create-project` | pass | Project-skill fixture shape and helper executable checks passed. |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta` | pass | Meta deterministic runtime-smoke passed with unified helper probes. |
| `agent-runtime audit-drift` | pass | Drift audit clean; only intentional-difference info findings. |
| `rumdl check docs/plans/2026-05-25-project-skill-create-unification/project-skill-create-unification-discussion-source.md docs/plans/2026-05-25-project-skill-create-unification/project-skill-create-unification-plan.md docs/plans/2026-05-25-project-skill-create-unification/project-skill-create-unification-execution-state.md` | pass | Plan bundle markdown passes. |
| `plan-tooling validate --file docs/plans/2026-05-25-project-skill-create-unification/project-skill-create-unification-plan.md --format json` | pass | Plan bundle validates. |
| `rg -n "create-claude-project-skill|--link-only" manifests targets SUPPORT_MATRIX.md docs/source` | pass | No active manifest/target/support/source-doc references remain. |
| `bash scripts/ci/all.sh` | pass | Positions 1-13 passed after implementation commit with clean golden baseline. |

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
