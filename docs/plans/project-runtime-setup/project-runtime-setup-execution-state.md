# Project Runtime Setup Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: ready for issue-backed planning
- Target scope: managed dispatcher surface cleanup plus `setup-project`
  workflow and adopted-repo `pre-pr` diagnostics.
- Execution window: Sprint 1-3
- Current task: create issue-backed tracking record.
- Next task: Task 1.1 - remove managed `bench` and `demo` skill sources after
  tracking issue creation.
- Last updated: 2026-05-26
- Branch/commit/PR: pending commit
- Source document: docs/plans/project-runtime-setup/project-runtime-setup-plan.md
- Discussion source:
  docs/plans/project-runtime-setup/project-runtime-setup-discussion-source.md
- Plan document: docs/plans/project-runtime-setup/project-runtime-setup-plan.md
- Execution state: docs/plans/project-runtime-setup/project-runtime-setup-execution-state.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: pending
- Source snapshot: pending
- Plan snapshot: pending
- Initial state snapshot: pending

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | pending | Remove managed bench and demo skill sources | n/a | Remove active managed sources and manifest/plugin entries only. |
| 1.2 | pending | Refresh render output, goldens, and expected skill lists | n/a | Expected lists should exclude removed skills and include intentional count changes. |
| 1.3 | pending | Update dispatcher docs and smoke fixtures | n/a | Retained managed dispatcher set becomes bootstrap/deploy/pre-pr/release. |
| 2.1 | pending | Define setup-project contract and adoption model | n/a | Keep setup-project separate from bootstrap and host install. |
| 2.2 | pending | Add setup-project helper and fixtures | n/a | Dry-run-first repo adoption workflow with confirmed pre-pr gate creation. |
| 2.3 | pending | Render setup-project across products | n/a | Add Codex/Claude rendered surfaces and expected skill entries. |
| 3.1 | pending | Add or consume adopted-repo doctor diagnostics | n/a | Coupled nils-cli release boundary for doctor --check-project behavior. |
| 3.2 | pending | Update pre-pr missing-script guidance | n/a | Point missing pre-pr to setup-project without adding fallback validation. |
| 3.3 | pending | Final validation and tracker closeout prep | n/a | Record focused and full validation before closeout. |

## Validation Plan

- `agent-docs resolve --context startup --strict --format checklist`
- `agent-docs resolve --context project-dev --strict --format checklist`
- `plan-tooling validate` on this plan with `--format text --explain`
- `agent-runtime render --product codex`
- `agent-runtime render --product claude`
- `agent-runtime render --target support-matrix`
- `agent-runtime audit-drift`
- `bash scripts/ci/skill-governance-audit.sh`
- `bash tests/runtime-smoke/run.sh --mode matrix`
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`
- `bash tests/projects/project-local-smoke/run.sh`
- `bash scripts/ci/all.sh`

## Session Log

- 2026-05-26: Created discussion source from user-approved direction: remove
  `bench`/`demo`, make `pre-pr` required for adopted repos, and add a
  setup-oriented project adoption workflow.
- 2026-05-26: Created initial plan and execution-state bundle for issue-backed
  tracking.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `agent-docs resolve --context startup --strict --format checklist` | passed | Required startup docs present. | n/a |
| `agent-docs resolve --context project-dev --strict --format checklist` | passed | Project development docs and docs placement policy present. | n/a |
| `plan-tooling validate --file docs/plans/project-runtime-setup/project-runtime-setup-plan.md --format json` | passed | Plan bundle validates with no errors. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-012651-project-runtime-setup/plan-tooling-validate.json` |
| `rumdl check docs/plans/project-runtime-setup/*.md` | passed | Plan bundle markdown passes. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-012651-project-runtime-setup/rumdl-check.txt` |
| `awk '/[[:blank:]]$/ ...' docs/plans/project-runtime-setup/*.md` | passed | No trailing whitespace found in the plan bundle. | n/a |

## Residual Risk

- `setup-project` may need a released nils-cli helper if dry-run/apply behavior
  becomes a stable machine-readable contract rather than a skill-local shell
  helper.
- Adopted-repo diagnostics depend on released nils-cli behavior for
  `agent-runtime doctor --check-project`; runtime-kit should not claim that
  contract is available until the corresponding release has landed.
