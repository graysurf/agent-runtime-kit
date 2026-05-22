# Phase 4 Domain Migration Sweep Execution State

## Current State

- Status: not started
- Target scope: whole plan
- Execution window: undecided
- Staged execution confirmation: not applicable
- Current task: Task 1.1
- Next task: Task 1.1
- Last updated: 2026-05-22
- Branch/commit: not started
- Source document: docs/plans/05-domain-migration/05-domain-migration-plan.md
- Direct source-doc execution waiver: not applicable

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| Task 1.1 | pending | Re-verify Plan 03 reporting POC | n/a | Regression guard before meta edits |
| Task 1.2 | pending | Migrate policy and state meta skills | n/a | `agent-docs`, `agent-out`, `agent-scope-lock` |
| Task 1.3 | pending | Migrate workflow meta skills | n/a | `heuristic-inbox`, `repo-retro`, `semantic-commit` |
| Task 1.4 | pending | Wire meta manifests, adapters, and golden snapshots | n/a | Owns shared manifest/golden/sandbox files |
| Task 2.1 | pending | Migrate media skill sources | n/a | `image-processing`, `screen-record` |
| Task 2.2 | pending | Migrate browser skill sources | n/a | `browser-session`, `canary-check` |
| Task 2.3 | pending | Wire media/browser manifests, adapters, and golden snapshots | n/a | Owns shared files |
| Task 3.1 | pending | Migrate web and test-first evidence sources | n/a | Capture lane A |
| Task 3.2 | pending | Migrate review and skill-usage evidence sources | n/a | Capture lane B |
| Task 3.3 | pending | Wire evidence capture manifests, adapters, and golden snapshots | n/a | Owns shared files |
| Task 4.1 | pending | Migrate docs-impact source | n/a | Serial to avoid shared-file conflicts |
| Task 4.2 | pending | Migrate model-cross-check source | n/a | Depends on Task 4.1 |
| Task 4.3 | pending | Finalize evidence domain integration | n/a | Complete evidence domain gate |
| Task 5.1 | pending | Migrate PR/MR create skills | n/a | `forge-cli` create surfaces |
| Task 5.2 | pending | Migrate PR/MR close skills and wire create/close integration | n/a | Shared PR files |
| Task 6.1 | pending | Migrate delivery skill sources | n/a | `forge-cli` delivery macros |
| Task 6.2 | pending | Add delivery lifecycle smoke harness | n/a | Scratch fork/branch only |
| Task 6.3 | pending | Wire delivery manifests, golden snapshots, and PR domain gate | n/a | Full PR-domain integration |
| Task 7.1 | pending | Migrate issue lifecycle dispatch sources | n/a | `plan-issue`, `plan-issue-local`, `plan-tooling` |
| Task 7.2 | pending | Migrate execution and dispatch orchestration sources | n/a | Execution/review handoff lane |
| Task 7.3 | pending | Wire dispatch manifests, adapters, and golden snapshots | n/a | Full dispatch-domain integration |
| Task 8.1 | pending | Audit private overlay effective config | n/a | `.private` values remain untracked |
| Task 8.2 | pending | Verify project-local overlay smoke gate | n/a | Adds stable fixture only |
| Task 9.1 | pending | Prepare legacy repository archive markers | n/a | Root `MOVED.md` in legacy repos |
| Task 9.2 | pending | Archive legacy repositories on GitHub | n/a | Archive, do not delete |
| Task 9.3 | pending | Remove local legacy pointers and migrate Claude state | n/a | Recommended cutover 2026-06-30 |

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `plan-tooling validate --file docs/plans/05-domain-migration/05-domain-migration-plan.md --format text --explain` | pending | Plan bundle validation before dispatch | n/a |
| `for n in 1 2 3 4 5 6 7 8 9; do plan-tooling batches --file docs/plans/05-domain-migration/05-domain-migration-plan.md --sprint "$n" --format json; done` | pending | Sprint DAG/sizing check for every sprint | n/a |
| `plan-tooling split-prs --file docs/plans/05-domain-migration/05-domain-migration-plan.md --scope sprint --sprint 1 --strategy deterministic --pr-grouping group --pr-group 'Task 1.1=s1-reporting-guard' --pr-group 'Task 1.2=s1-meta-policy-state' --pr-group 'Task 1.3=s1-meta-workflow' --pr-group 'Task 1.4=s1-meta-integration' --format json` | pending | Sprint 1 dependency-layer PR split | n/a |
| `plan-tooling split-prs --file docs/plans/05-domain-migration/05-domain-migration-plan.md --scope sprint --sprint 2 --strategy deterministic --pr-grouping group --pr-group 'Task 2.1=s2-media-source' --pr-group 'Task 2.2=s2-browser-source' --pr-group 'Task 2.3=s2-media-browser-integration' --format json` | pending | Sprint 2 dependency-layer PR split | n/a |
| `plan-tooling split-prs --file docs/plans/05-domain-migration/05-domain-migration-plan.md --scope sprint --sprint 3 --strategy deterministic --pr-grouping group --pr-group 'Task 3.1=s3-web-test-evidence' --pr-group 'Task 3.2=s3-review-usage-evidence' --pr-group 'Task 3.3=s3-evidence-capture-integration' --format json` | pending | Sprint 3 dependency-layer PR split | n/a |
| `plan-tooling split-prs --file docs/plans/05-domain-migration/05-domain-migration-plan.md --scope sprint --sprint 7 --strategy deterministic --pr-grouping group --pr-group 'Task 7.1=s7-issue-lifecycle' --pr-group 'Task 7.2=s7-execution-orchestration' --pr-group 'Task 7.3=s7-dispatch-integration' --format json` | pending | Sprint 7 dependency-layer PR split | n/a |
| `for n in 4 5 6 8 9; do plan-tooling split-prs --file docs/plans/05-domain-migration/05-domain-migration-plan.md --scope sprint --sprint "$n" --strategy deterministic --pr-grouping per-sprint --format json; done` | pending | Serial sprint PR split where metadata uses `per-sprint` | n/a |
| `agent-runtime render --product codex` | pending | Render Codex target | n/a |
| `agent-runtime render --product claude` | pending | Render Claude target | n/a |
| `agent-runtime render --product codex --update-golden` | pending | Refresh Codex golden snapshots | n/a |
| `agent-runtime render --product claude --update-golden` | pending | Refresh Claude golden snapshots | n/a |
| `bash scripts/ci/sandbox-install-rehearsal.sh` | pending | Dry-run install skill-list diff | n/a |
| `agent-runtime audit-drift` | pending | Root drift audit | n/a |
| `bash scripts/ci/all.sh` | pending | Full local gate stack | n/a |
| `bash tests/smoke/deliver-lifecycle.sh --scratch-fork graysurf/agent-runtime-kit-smoke --scratch-branch agent-runtime-kit-delivery-smoke` | pending | Sprint 6 scratch delivery smoke | n/a |
| `agent-runtime install --product claude --dry-run` | pending | Sprint 8 effective config check | n/a |
| `agent-runtime install --product codex --dry-run` | pending | Sprint 8 effective config check | n/a |
| `bash tests/projects/project-local-smoke/run.sh` | pending | Sprint 8 project-local overlay smoke | n/a |
| `agent-runtime doctor --check-project tests/projects/project-local-smoke` | pending | Sprint 8 project-local doctor check | n/a |
| `gh repo view graysurf/agent-kit --json isArchived,name` | pending | Sprint 9 archive verification | n/a |
| `gh repo view graysurf/claude-kit --json isArchived,name` | pending | Sprint 9 archive verification | n/a |
| `test ! -L "$HOME/.agents"` | pending | Sprint 9 symlink removal check | n/a |
| `state_root="${XDG_STATE_HOME:-$HOME/.local/state}"; if [ -d "$state_root/agent-runtime-kit/claude" ]; then test ! -d "$state_root/claude-kit"; else rg -q 'claude-kit state migration no-op' docs/plans/05-domain-migration/05-domain-migration-execution-state.md; fi` | pending | Sprint 9 conditional state-home check | n/a |

## Blockers

- Any missing nils-cli binary or required flag blocks the affected skill body
  and must be logged in `docs/source/extraction-backlog.md`.
- Sprint 6 delivery smoke requires a scratch fork/branch and must not target
  `graysurf/agent-runtime-kit` `main`.
- Sprint 9 requires GitHub admin permission on `graysurf/agent-kit` and
  `graysurf/claude-kit`.
- Local cutover should use the recommended 2026-06-30 date unless the execution
  owner records a different decision.

## Session Log

(none yet)
