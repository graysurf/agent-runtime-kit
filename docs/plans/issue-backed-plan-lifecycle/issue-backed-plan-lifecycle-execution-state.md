# Issue-Backed Plan Lifecycle Execution State

## Current State

- Source document: `docs/plans/issue-backed-plan-lifecycle/issue-backed-plan-lifecycle-plan.md`
- Status: not-started
- Current task: Task 1.1
- Next task: Task 1.1
- Branch: `feat/issue-backed-plan-lifecycle`
- Tracking issue: pending

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| Task 1.1 | todo | Define lifecycle contract fixtures | pending | Cross-repo nils-cli fixture work. |
| Task 1.2 | todo | Preserve plan-tooling boundary | pending | Keep provider UI out of plan-tooling. |
| Task 1.3 | todo | Choose CLI surface and compatibility policy | pending | Decide command shape after code inspection. |
| Task 2.1 | todo | Implement shared dashboard and comment renderer | pending | nils-cli implementation. |
| Task 2.2 | todo | Implement marker audit and dashboard repair | pending | nils-cli implementation. |
| Task 2.3 | todo | Implement dispatch ledger and gate support | pending | nils-cli implementation. |
| Task 2.4 | todo | Build and expose debug binaries for integration | pending | Debug binary path only for scoped validation. |
| Task 3.1 | todo | Update tracking-plan skill bodies | pending | agent-runtime-kit integration. |
| Task 3.2 | todo | Update dispatch-plan skill bodies | pending | agent-runtime-kit integration. |
| Task 3.3 | todo | Update smoke coverage and manifests | pending | agent-runtime-kit integration. |
| Task 4.1 | todo | Run cross-repo validation | pending | nils-cli and agent-runtime-kit gates. |
| Task 4.2 | todo | Run specialist review and fix findings | pending | code-review-specialists required before final delivery. |
| Task 4.3 | todo | Decide release/floor and close plan | pending | Final closeout. |

## Validation Ledger

| Command | Status | Evidence | Notes |
| --- | --- | --- | --- |
| `agent-docs --docs-home "$HOME/.config/agent-kit" resolve --context startup --strict --format checklist` | pass | current session | agent-runtime-kit preflight. |
| `agent-docs --docs-home "$HOME/.config/agent-kit" resolve --context project-dev --strict --format checklist` | pass | current session | agent-runtime-kit preflight. |
| `agent-docs --docs-home "$HOME/.config/agent-kit" resolve --context skill-dev --strict --format checklist` | pass | current session | skill lifecycle preflight. |
| `plan-tooling validate --file docs/plans/issue-backed-plan-lifecycle/issue-backed-plan-lifecycle-plan.md --format text --explain` | pass | current session | Plan validates after replacing placeholder review commands. |
| `for n in 1 2 3 4; do plan-tooling batches --file docs/plans/issue-backed-plan-lifecycle/issue-backed-plan-lifecycle-plan.md --sprint "$n" --format json; done` | pass | current session | Sprints 1-4 batch analysis passed. |
| `plan-tooling split-prs ...` for Sprints 1-4 | pass | current session | Sprints 1-3 use auto group; Sprint 4 uses per-sprint deterministic. |
| `/Users/terry/.config/agent-kit/skills/workflows/plan/plan-tracking-issue/scripts/plan-tracking-issue.sh --plan docs/plans/issue-backed-plan-lifecycle/issue-backed-plan-lifecycle-plan.md --provider github --repo graysurf/agent-runtime-kit --dry-run --label plan` | pass | current session | Dry-run rendered lightweight issue body at `/tmp/issue-backed-plan-lifecycle-issue-body.md`. |

## Notes

- This plan intentionally spans `agent-runtime-kit` and
  `/Users/terry/Project/sympoies/nils-cli`.
- `Location` entries for nils-cli implementation tasks point at this execution
  state or the discussion source because `plan-tooling` validates locations
  relative to the current `agent-runtime-kit` repository.
- Actual nils-cli code changes must be recorded here with exact paths, commits,
  commands, and debug-binary integration evidence as execution proceeds.
