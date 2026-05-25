# Plan Issue vNext Implementation Execution State

## Current State

- Source document: `docs/plans/plan-issue-vnext-implementation/plan-issue-vnext-implementation-plan.md`
- Direct source-doc execution waiver: not applicable
- Status: not-started
- Current task: Task 1.1
- Next task: Task 1.1
- Last updated: 2026-05-26
- Execution driver: this plan bundle and the five redesign documents only
- Plan issue skills: intentionally not used to drive this implementation
- Tracking issue: not opened
- Runtime-kit branch: not recorded
- nils-cli branch: not recorded
- nils-cli released version: not recorded
- Local binary policy: use scoped local binary paths during skill development;
  do not globally replace the installed CLI
- Cross-repo target: `sympoies/nils-cli`

## Design Sources

| Source | Status | Notes |
| --- | --- | --- |
| `docs/source/plan-issue-redesign/plan-tracking-issue-comment-taxonomy-v1.md` | ready | Lifecycle role inventory, templates, visible completeness, and posting policies. |
| `docs/source/plan-issue-redesign/plan-tracking-issue-workflow-v1.md` | ready | FSM states, lifecycle diagram, and timing rules. |
| `docs/source/plan-issue-redesign/plan-tracking-issue-cli-redesign-v1.md` | ready | CLI vNext architecture and complete rewrite boundary. |
| `docs/source/plan-issue-redesign/plan-tracking-issue-run-state-controller-v1.md` | ready | Run-state schema, events, reconciliation, and controller commands. |
| `docs/source/plan-issue-redesign/plan-issue-skill-family-redesign-v1.md` | ready | Skill inventory, role boundaries, and rewrite order. |

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| Task 1.1 | pending | Add vNext module skeletons | pending | nils-cli paths and commit to be recorded during execution. |
| Task 1.2 | pending | Freeze compatibility baseline | pending | Preserve released command compatibility before vNext wiring. |
| Task 2.1 | pending | Implement lifecycle role registry | pending | Covers source, plan, state, session, validation, review, closeout. |
| Task 2.2 | pending | Implement visible completeness lint | pending | Reject Profile-only lifecycle comments. |
| Task 2.3 | pending | Extend audit with visible expectation | pending | Existing audit behavior must remain available. |
| Task 3.1 | pending | Add `record template` | pending | Non-mutating markdown and JSON skeleton preview. |
| Task 3.2 | pending | Add renderer fixture coverage for all roles | pending | Includes Task Ledger display mode coverage. |
| Task 4.1 | pending | Implement run-state schema and event journal | pending | Adds typed local execution cache and append-only events. |
| Task 4.2 | pending | Implement FSM and provider reconciliation | pending | Provider issue evidence wins over local run state. |
| Task 4.3 | pending | Add `tracking status` | pending | Non-mutating reconciliation and recommendation surface. |
| Task 5.1 | pending | Add run init and run update | pending | Initializes and updates issue-scoped run state. |
| Task 5.2 | pending | Add checkpoint dry-run rendering | pending | Renders postable comments without provider mutation. |
| Task 5.3 | pending | Add stale-state and completeness refusal tests | pending | Blocks stale or incomplete checkpoints. |
| Task 6.1 | pending | Implement live tracking checkpoint | pending | Adapter over lifecycle primitives; never closes issue. |
| Task 6.2 | pending | Implement `tracking close-ready` | pending | Non-mutating strict closeout readiness probe. |
| Task 6.3 | pending | Migrate record rendering internals to vNext | pending | Avoid duplicate lifecycle rendering engines. |
| Task 7.1 | pending | Validate local binary against design fixtures | pending | Uses scoped local binary policy. |
| Task 7.2 | pending | Update nils-cli docs and release prep | pending | Release version or blocker to be recorded. |
| Task 8.1 | pending | Rewrite lightweight tracking skills | pending | Delete or replace old skill bodies. |
| Task 8.2 | pending | Rewrite dispatch issue and lane skills | pending | Preserve profile and lane boundaries. |
| Task 8.3 | pending | Audit and rewrite related references | pending | Remove stale lifecycle mechanics. |
| Task 9.1 | pending | Refresh rendered outputs and goldens | pending | Render Codex and Claude targets. |
| Task 9.2 | pending | Add runtime smoke for visible lifecycle behavior | pending | Proves visible comment shape and stale-state refusal. |
| Task 9.3 | pending | Final released-floor validation | pending | Must pass without local debug binary. |
| Task 10.1 | pending | Run full repo validation | pending | Full runtime-kit gate after released floor. |
| Task 10.2 | pending | Final documentation and execution-state cleanup | pending | Marks final state and retained follow-ups. |

## Validation Ledger

| Command | Status | Evidence | Notes |
| --- | --- | --- | --- |
| `agent-docs resolve --context startup --strict --format checklist` | pass | current session | Required startup preflight passed. |
| `agent-docs resolve --context project-dev --strict --format checklist` | pass | current session | Required project-dev preflight passed. |
| `plan-tooling validate --file docs/plans/plan-issue-vnext-implementation/plan-issue-vnext-implementation-plan.md --format text --explain` | pass | current session | Bundle structural validation passed. |
| `git diff --check` | pass | current session | No whitespace errors after bundle creation. |

## Session Log

- 2026-05-26: Created the plan issue vNext implementation bundle to connect
  the five redesign documents into one direct execution path.
- 2026-05-26: Validated the new plan bundle with `plan-tooling validate` and
  checked whitespace with `git diff --check`.

## Notes

- `Location` entries for nils-cli tasks point at this bundle or redesign docs
  because `plan-tooling` validates paths relative to `agent-runtime-kit`.
- During execution, record exact nils-cli repo-relative paths, commits, and
  validation summaries in this file.
- Do not use the existing plan issue skill family as the implementation driver
  for this plan.
