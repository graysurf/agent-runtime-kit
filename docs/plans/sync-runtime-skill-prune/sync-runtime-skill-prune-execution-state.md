# sync-runtime-skill-prune Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: pending implementation
- Target scope: Add stale managed-skill pruning to nils-cli and consume it from
  runtime-kit sync.
- Execution window: Sprint 1
- Current task: Task 1.1 — add nils-cli prune-stale planner and executor
- Next task: Task 1.2 — expose `agent-runtime prune-stale` CLI
- Last updated: 2026-05-26
- Branch/commit/PR: feat/sync-runtime-skill-prune (plan bundle);
  implementation branches pending
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
- live audit: `agent-runtime audit-drift --source-root /Users/terry/Project/graysurf/agent-runtime-kit`

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | pending | Add nils-cli prune-stale planner and executor | pending | Detect and classify stale live surfaces under install-map-owned roots. |
| 1.2 | pending | Expose `agent-runtime prune-stale` CLI | pending | Add dry-run/apply flags and stable text/JSON output. |
| 1.3 | pending | Regression-check install, uninstall, and audit behavior | pending | Prove prune does not weaken existing reconciliation contracts. |
| 1.4 | pending | Release and install the nils-cli primitive | pending | Runtime-kit must consume a released local command, not an unreleased checkout. |
| 2.1 | pending | Update `scripts/sync-runtime-skills.sh` | pending | Insert prune after install and before verification; add `--no-prune`. |
| 2.2 | pending | Update skill docs, manifest floor, and rendered outputs | pending | Raise `agent-runtime` floor after release. |
| 2.3 | pending | Add removed-skill sync fixture coverage | pending | Prove stale skill cleanup without real live-home mutation. |
| 2.4 | pending | Full validation and live sync proof | pending | Run full gate plus durable-checkout live smoke. |

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

## Notes

- The plan is intentionally nils-cli-first. Runtime-kit must not consume
  `agent-runtime prune-stale` until the command is released and installed.
- The live issue should use labels `type::chore`, `area::skills`,
  `state::needs-triage`, `workflow::plan`, `workflow::tracking`, and `plan`.
