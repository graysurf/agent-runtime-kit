# Phase 4 — Domain Migration Sweep Execution State

## Current State

- Status: not started
- Target scope: whole plan
- Execution window: undecided
- Staged execution confirmation: not applicable
- Current task: Task 1.0
- Next task: Task 1.0
- Last updated: 2026-05-20
- Branch/commit: not started
- Source document: docs/plans/05-domain-migration/05-domain-migration-plan.md
- Direct source-doc execution waiver: not applicable

## Task Ledger

| ID       | Status  | Task                                                                                  | Evidence | Notes                                                                |
| -------- | ------- | ------------------------------------------------------------------------------------- | -------- | -------------------------------------------------------------------- |
| Task 1.0 | pending | Re-verify Plan 03 reporting POC                                                       | n/a      | Plan 03 regression gate before meta-domain rewrites begin            |
| Task 1.1 | pending | Migrate `agent-docs` skill body                                                       | n/a      | downstream sprints rely on the new body                              |
| Task 1.2 | pending | Migrate `agent-scope-lock` skill body                                                 | n/a      |                                                                      |
| Task 1.3 | pending | Migrate `agent-out` skill body                                                        | n/a      | state-tree allocation contract from CLAUDE.md preflight              |
| Task 1.4 | pending | Migrate `heuristic-inbox` skill body                                                  | n/a      | legacy id is `heuristic-error-inbox`                                 |
| Task 1.5 | pending | Migrate `repo-retro` skill body                                                       | n/a      | may need extraction-backlog entry if binary not yet shipped          |
| Task 1.6 | pending | Migrate `semantic-commit` skill body                                                  | n/a      | preserve 1-2 bullets body gate; downstream sprints rely on it        |
| Task 2.1 | pending | Migrate `image-processing` skill body                                                 | n/a      |                                                                      |
| Task 2.2 | pending | Migrate `screen-record` skill body                                                    | n/a      | macOS-only guard documented in prose                                 |
| Task 2.3 | pending | Migrate `browser-session` skill body                                                  | n/a      |                                                                      |
| Task 2.4 | pending | Migrate `canary-check` skill body                                                     | n/a      |                                                                      |
| Task 3.1 | pending | Migrate `web-evidence` skill body                                                     | n/a      |                                                                      |
| Task 3.2 | pending | Migrate `test-first-evidence` skill body                                              | n/a      |                                                                      |
| Task 3.3 | pending | Migrate `review-evidence` skill body                                                  | n/a      |                                                                      |
| Task 3.4 | pending | Migrate `skill-usage` skill body                                                      | n/a      |                                                                      |
| Task 3.5 | pending | Migrate `docs-impact` skill body                                                      | n/a      |                                                                      |
| Task 3.6 | pending | Migrate `model-cross-check` skill body                                                | n/a      |                                                                      |
| Task 4.1 | pending | Migrate pr-domain create skills onto `forge-cli`                                      | n/a      | feature, bug, gitlab-mr variants                                     |
| Task 4.2 | pending | Migrate pr-domain close skills onto `forge-cli`                                       | n/a      |                                                                      |
| Task 4.3 | pending | Migrate pr-domain deliver skills onto `forge-cli`                                     | n/a      | deliver-lifecycle smoke test required                                |
| Task 4.4 | pending | Migrate dispatch-domain skills onto `plan-issue` / `plan-issue-local` / `plan-tooling`| n/a      | implementation, orchestrator, review, monitor                        |
| Task 5.1 | pending | Audit `.private/` shadow overlay merges                                               | n/a      | post-merge "effective config" gate                                   |
| Task 5.2 | pending | Verify project-local overlay smoke test (CI gate 8)                                   | n/a      | bench / demo / deploy / pre-pr / release / bootstrap                 |
| Task 5.3 | pending | Archive `graysurf/agent-kit` and `graysurf/claude-kit`                                | n/a      | per Resolved Decision #3; archive, do not delete; add MOVED.md       |
| Task 5.4 | pending | Remove `$HOME/.agents` symlink                                                        | n/a      | recommended cutover 2026-06-30                                       |
| Task 5.5 | pending | Migrate `$XDG_STATE_HOME/claude-kit/` to `$XDG_STATE_HOME/agent-runtime-kit/claude/`  | n/a      | rsync -a; verify with diff -r                                        |

## Validation

| Command                                                                                                       | Status  | Summary                                       | Artifact |
| ------------------------------------------------------------------------------------------------------------- | ------- | --------------------------------------------- | -------- |
| `plan-tooling validate --file docs/plans/05-domain-migration/05-domain-migration-plan.md --strict`            | pending | run before first commit on each sprint branch | n/a      |
| `cargo test -p agent-runtime-cli render_golden_reporting`                                                     | pending | Task 1.0 regression gate                      | n/a      |
| `cargo test -p agent-runtime-cli render_golden_meta`                                                          | pending | per Sprint 1                                  | n/a      |
| `cargo test -p agent-runtime-cli render_golden_media`                                                         | pending | per Sprint 2                                  | n/a      |
| `cargo test -p agent-runtime-cli render_golden_browser`                                                       | pending | per Sprint 2                                  | n/a      |
| `cargo test -p agent-runtime-cli render_golden_evidence`                                                      | pending | per Sprint 3                                  | n/a      |
| `cargo test -p agent-runtime-cli render_golden_pr`                                                            | pending | per Sprint 4                                  | n/a      |
| `cargo test -p agent-runtime-cli render_golden_dispatch`                                                      | pending | per Sprint 4                                  | n/a      |
| `bash tests/sandbox/claude/run.sh`                                                                            | pending | end of every sprint                           | n/a      |
| `bash tests/sandbox/codex/run.sh`                                                                             | pending | end of every sprint                           | n/a      |
| `agent-runtime doctor --product claude`                                                                       | pending | end of every sprint                           | n/a      |
| `agent-runtime doctor --product codex`                                                                        | pending | end of every sprint                           | n/a      |
| `bash tests/smoke/deliver-lifecycle.sh --scratch-fork`                                                        | pending | Sprint 4 only                                 | n/a      |
| `agent-runtime install --product claude --dry-run --print-effective-config`                                   | pending | Task 5.1                                      | n/a      |
| `agent-runtime install --product codex --dry-run --print-effective-config`                                    | pending | Task 5.1                                      | n/a      |
| `bash tests/sandbox/project-local/run.sh`                                                                     | pending | Task 5.2                                      | n/a      |
| `agent-runtime doctor --product claude --check-project /Users/terry/Project/graysurf/agent-runtime-kit`       | pending | Task 5.2                                      | n/a      |
| `gh repo view graysurf/agent-kit --json isArchived,name`                                                      | pending | Task 5.3                                      | n/a      |
| `gh repo view graysurf/claude-kit --json isArchived,name`                                                     | pending | Task 5.3                                      | n/a      |
| `test ! -L "$HOME/.agents"`                                                                                   | pending | Task 5.4                                      | n/a      |
| `test -d "${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit/claude"`                                    | pending | Task 5.5                                      | n/a      |

## Blockers

- Plan 04 must land before Sprint 4 begins (sandbox install rehearsal harness + doctor gate + published `forge-cli` semver).
- Plan 03 must remain green for Task 1.0 to clear; any reporting regression blocks Sprint 1.

## Session Log

(none yet)
