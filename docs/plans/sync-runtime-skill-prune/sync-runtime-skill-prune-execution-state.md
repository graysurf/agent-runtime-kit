# sync-runtime-skill-prune Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: implementation in progress
- Target scope: Add stale managed-skill pruning to nils-cli and consume it from
  runtime-kit sync.
- Execution window: Sprint 2 closeout
- Current task: Task 2.4 — full validation and live sync proof
- Next task: Open, review, merge, and close the runtime-kit PR; then run live
  sync from the durable primary checkout.
- Last updated: 2026-05-26
- Branch/commit/PR: feat/sync-runtime-skill-prune (plan bundle);
  nils-cli PR #536 merged; runtime-kit PR pending
- Source document: docs/plans/sync-runtime-skill-prune/sync-runtime-skill-prune-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: <https://github.com/graysurf/agent-runtime-kit/issues/119>
- Source snapshot:
  <https://github.com/graysurf/agent-runtime-kit/issues/119#issuecomment-4536315998>
- Plan snapshot:
  <https://github.com/graysurf/agent-runtime-kit/issues/119#issuecomment-4536316092>
- Initial state snapshot:
  <https://github.com/graysurf/agent-runtime-kit/issues/119#issuecomment-4536316162>

## Validation Plan

- Plan bundle validation:
  `plan-tooling validate --file <plan> --format text --explain`
- Markdown lint:
  `rumdl check <discussion-source> <plan> <execution-state>`
- `git diff --check -- docs/plans/sync-runtime-skill-prune/`
- nils-cli: `cargo test -p agent-runtime-cli --test integration prune_stale`
- nils-cli: `cargo test -p agent-runtime-cli --test integration install_pipeline`
- nils-cli: `cargo test -p agent-runtime-cli --test integration uninstall`
- nils-cli: `cargo test -p agent-runtime-cli --test integration audit_drift_extra_intentional`
- runtime-kit: `agent-runtime render --product codex --update-golden`
- runtime-kit: `agent-runtime render --product claude --update-golden`
- runtime-kit: `bash scripts/ci/sandbox-install-rehearsal.sh`
- runtime-kit: `bash scripts/ci/all.sh`
- live smoke: `bash scripts/sync-runtime-skills.sh --apply --no-pull`
- live audit: `agent-runtime audit-drift --source-root "$PWD"`

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | done | Add nils-cli prune-stale planner and executor | sympoies/nils-cli#536 | Added reusable live-surface classification and apply-mode removal for owned stale symlinks and empty directories. |
| 1.2 | done | Expose `agent-runtime prune-stale` CLI | sympoies/nils-cli#536 | Added `--source-root`, `--product`, `--live-home`, `--dry-run`, `--apply`, overlay flags, text output, and JSON output. |
| 1.3 | done | Regression-check install, uninstall, and audit behavior | nils-cli local and CI validation passed | Install, uninstall, audit extra, CLI, fmt, clippy, and local-fast checks passed before merge. |
| 1.4 | done | Release and install the nils-cli primitive | nils-cli v0.22.4 | PR #536 merged, release PR #538 merged, `v0.22.4` published, tap updated, and local `agent-runtime prune-stale --help` exposes the command. |
| 2.1 | done | Update `scripts/sync-runtime-skills.sh` | runtime-kit branch `feat/sync-runtime-skill-prune` | Default dry-run prints prune, apply mode runs prune after install, and `--no-prune` logs the skipped reconciliation boundary. |
| 2.2 | done | Update skill docs, manifest floor, and rendered outputs | runtime-kit branch `feat/sync-runtime-skill-prune` | Skill docs and manifest require released `agent-runtime >=0.22.4`; Codex and Claude goldens rerendered. |
| 2.3 | done | Add removed-skill sync fixture coverage | runtime smoke meta fixture | Added no-prune and removed-skill prune fixture coverage without mutating real live homes. |
| 2.4 | in progress | Full validation and live sync proof | local runtime-kit validation passed; PR/live proof pending | Focused, matrix, sandbox, lint, render, and audit gates passed. Full CI must be rerun after committing the intended golden diffs, followed by PR merge and durable-checkout live sync. |

## Session Log

- 2026-05-26: Created source document after confirming the current
  `sync-runtime-skills` path is add/update-only and that nils-cli lacks a
  stale-surface prune primitive. User requested the nils-cli portion be
  included before opening a plan tracker.
- 2026-05-26: Created plan and initial execution-state files in a fresh
  sibling worktree `feat/sync-runtime-skill-prune` for issue-backed tracking.
- 2026-05-26: Opened tracking issue #119 through `plan-issue record open` and
  verified the source, plan, and state lifecycle comments through live readback
  audit.
- 2026-05-26: Delivered nils-cli PR #536, adding
  `agent-runtime prune-stale`; merged it, released nils-cli v0.22.4, updated
  the Homebrew tap, and verified the installed command exposes
  `prune-stale`.
- 2026-05-26: Updated runtime-kit sync to run released prune by default, added
  a `--no-prune` escape hatch, raised the skill manifest floor to
  `agent-runtime >=0.22.4`, rerendered Codex and Claude skill goldens, and
  added removed-skill prune fixture coverage.
- 2026-05-26: Runtime-kit focused validation passed. Full CI was run before
  commit and correctly stopped on intended uncommitted golden diffs; rerun is
  required after committing.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `agent-docs resolve --context startup --strict --format checklist` | passed | Required startup docs present. | n/a |
| `agent-docs resolve --context project-dev --strict --format checklist` | passed | Required project-dev docs present. | n/a |
| `plan-tooling validate --file docs/plans/sync-runtime-skill-prune/sync-runtime-skill-prune-plan.md --format text --explain` | passed | Plan bundle validation passed; `--explain` printed canonical examples. | n/a |
| `rumdl check docs/plans/sync-runtime-skill-prune/*.md` | passed | Markdown lint passed for source, plan, and execution state. | n/a |
| `git diff --check -- docs/plans/sync-runtime-skill-prune/` | passed | No whitespace errors. | n/a |
| `forge-cli label ensure --catalog manifests/forge-labels.yaml --repo graysurf/agent-runtime-kit --format json` | passed | Label catalog was already reconciled; no actions required. | n/a |
| `plan-issue --repo graysurf/agent-runtime-kit --format json --dry-run record open ...` | passed | Dry-run rendered source, plan, and visible state comments from commit `944d9e0`. | n/a |
| `plan-issue --repo graysurf/agent-runtime-kit --format json record open ...` | passed | Created issue #119 with source, plan, and initial state lifecycle comments. | `20260526-021908-sync-runtime-skill-prune/plan-issue-record-open-live.json` |
| `plan-issue --format json record audit --profile tracking --body-file <issue-body> --comments-json <issue-json>` | passed | Live audit recognized source, plan, and state markers. | `20260526-021908-sync-runtime-skill-prune/issue-119-record-audit.json` |
| `rg -n "## Execution State\|## Task Ledger\|plan-issue-record-payload" <state-comment>` | passed | State comment visibly contains execution state, folded task ledger, and payload carrier. | `20260526-021908-sync-runtime-skill-prune/issue-119-state-comment.md` |
| nils-cli failing probe: `agent-runtime prune-stale --help` before implementation | expected failure | Confirmed the released `v0.22.3` CLI did not expose `prune-stale` before Sprint 1 implementation. | skill-usage evidence |
| `cargo test -p agent-runtime-cli --test integration prune_stale` | passed | New prune-stale planner, executor, CLI, idempotence, and safety coverage passed. | nils-cli PR #536 |
| `cargo test -p agent-runtime-cli --test integration install_pipeline` | passed | Existing install pipeline contracts still passed. | nils-cli PR #536 |
| `cargo test -p agent-runtime-cli --test integration uninstall` | passed | Existing uninstall contracts still passed. | nils-cli PR #536 |
| `cargo test -p agent-runtime-cli --test integration audit_drift_extra_intentional` | passed | Audit extra behavior remained aligned with prune classification. | nils-cli PR #536 |
| `cargo test -p agent-runtime-cli --test integration cli` | passed | CLI surface regression checks passed. | nils-cli PR #536 |
| `cargo fmt --all -- --check` | passed | nils-cli formatting passed. | nils-cli PR #536 |
| `cargo clippy -p agent-runtime-cli --all-targets --all-features -- -D warnings` | passed | nils-cli lint passed. | nils-cli PR #536 |
| `bash scripts/ci/nils-cli-checks-entrypoint.sh --local-fast` | passed | nils-cli local-fast gate passed before merge. | nils-cli PR #536 |
| nils-cli release gate for `v0.22.4` | passed | Release PR #538 merged, `v0.22.4` published, tap updated, and local install upgraded. | <https://github.com/sympoies/nils-cli/releases/tag/v0.22.4> |
| `agent-runtime --version` | passed | Installed CLI reports `agent-runtime 0.22.4`. | skill-usage evidence |
| `agent-runtime prune-stale --help` | passed | Installed CLI exposes the released prune-stale command and flags. | skill-usage evidence |
| `bash scripts/sync-runtime-skills.sh --source-root "$PWD" --product codex --no-pull` | passed | Dry-run includes render, install, prune, doctor, Codex prompt-input, and `prune=planned`. | skill-usage evidence |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta --format text` | passed | Meta runtime smoke passed, including no-prune and removed-skill prune fixtures. | skill-usage evidence |
| `agent-runtime render --product codex --update-golden` | passed | Codex rendered output and golden updated. | n/a |
| `agent-runtime render --product claude --update-golden` | passed | Claude rendered output and golden updated. | n/a |
| `agent-runtime render --target support-matrix --update-golden` | passed | Support matrix render remained current. | n/a |
| `bash tests/runtime-smoke/run.sh --mode matrix --format text` | passed | Runtime smoke matrix passed for 72 skills. | skill-usage evidence |
| `bash scripts/ci/sandbox-install-rehearsal.sh` | passed | Sandbox install rehearsal passed with prune-capable sync surface. | skill-usage evidence |
| `git diff --check` | passed | No whitespace errors in the runtime-kit diff. | n/a |
| `bash -n scripts/sync-runtime-skills.sh tests/runtime-smoke/cases/meta/run.sh` | passed | Shell syntax passed. | n/a |
| `shellcheck scripts/sync-runtime-skills.sh tests/runtime-smoke/cases/meta/run.sh` | passed | Shell lint passed. | n/a |
| `rumdl check docs/source/nils-cli-surface.md core/skills/meta/sync-runtime-skills/SKILL.md.tera tests/golden/codex/plugins/meta/skills/sync-runtime-skills/expected/SKILL.md tests/golden/claude/plugins/meta/skills/sync-runtime-skills/expected/SKILL.md docs/plans/sync-runtime-skill-prune/*.md` | passed | Markdown lint passed for changed docs, templates, goldens, and plan files. | n/a |
| `agent-runtime audit-drift` | passed | Audit reported clean, with only documented intentional differences. | skill-usage evidence |
| `bash scripts/ci/all.sh` before commit | expected failure | Full CI reached the golden diff check and stopped because intended golden updates were still uncommitted. Rerun after commit is required. | skill-usage evidence |

## Notes

- The plan is intentionally nils-cli-first. Runtime-kit must not consume
  `agent-runtime prune-stale` until the command is released and installed.
- The live issue should use labels `type::chore`, `area::skills`,
  `state::needs-triage`, `workflow::plan`, `workflow::tracking`, and `plan`.
