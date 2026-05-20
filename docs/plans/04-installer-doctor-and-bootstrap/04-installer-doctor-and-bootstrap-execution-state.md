# Phase 3 — Installer, Doctor, and Host Bootstrap Execution State

## Current State

- Status: not started
- Target scope: whole plan
- Execution window: undecided
- Staged execution confirmation: not applicable
- Current task: Task 1.1
- Next task: Task 1.1
- Last updated: 2026-05-20
- Branch/commit: not started
- Source document: docs/plans/04-installer-doctor-and-bootstrap/04-installer-doctor-and-bootstrap-plan.md
- Direct source-doc execution waiver: not applicable

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| Task 1.1 | pending | Implement managed-block helper module | n/a | paired-marker contract; refuse re-add without `--force` |
| Task 1.2 | pending | Wire render to link to managed-block sync pipeline | n/a | depends on 1.1; idempotent `--apply` |
| Task 1.3 | pending | Add `--live-home`, `--tag`, and overlay merge flags | n/a | reject relative `--live-home`; tags survive gc |
| Task 2.1 | pending | Implement `agent-runtime uninstall` | n/a | idempotent; never touch auth / history / sessions |
| Task 2.2 | pending | Implement `agent-runtime restore-backups` | n/a | `--from` required; dry-run before apply |
| Task 2.3 | pending | Implement `agent-runtime purge-state` | n/a | `--scope` required; prompts unless `--yes` |
| Task 2.4 | pending | Implement `agent-runtime gc-backups` | n/a | retention default 5; respect `--tag` markers |
| Task 3.1 | pending | Symlink + managed-block + runtime-roots probes | n/a | filesystem-level findings; exit 0 / 1 / 2 |
| Task 3.2 | pending | Version probes with 5-status output | n/a | `ok` / `recommended-only` / `warn` / `outdated` / `unparseable` |
| Task 3.3 | pending | `--suggest-upgrade`, `--check-project`, and CLI coverage probes | n/a | read-only; feeds Bump Ceremony PR |
| Task 4.1 | pending | Implement composite `unsafe` scoring | n/a | path 0.4 + keyword 0.4 + entropy 0.4 |
| Task 4.2 | pending | Implement `drift-audit.allow.yaml` allowlist | n/a | one-tier demotion; never silence outright |
| Task 4.3 | pending | Implement `intentional-difference` and `extra` finding classes | n/a | pipe through existing finding pipeline |
| Task 4.4 | pending | Cut `0.2.0` release and bump formula | n/a | tag precedes formula bump |
| Task 5.1 | pending | Fill `scripts/setup.sh` body | n/a | 7-step brew-first bootstrap |
| Task 5.2 | pending | Add `tests/sandbox/<product>/expected-skills.txt` pins | n/a | one canonical id per line, sorted |
| Task 5.3 | pending | Add CI gate position 6 sandbox install rehearsal | n/a | dry-run + skill-list diff |
| Task 5.4 | pending | Bump `required_clis` floors to `">=0.2.0"` | n/a | only skills calling new subcommands |

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `plan-tooling validate --file docs/plans/04-installer-doctor-and-bootstrap/04-installer-doctor-and-bootstrap-plan.md --format text --explain` | pending | bundle validation gate | n/a |
| `cargo test -p agent-runtime-cli` | pending | nils-cli installer + lifecycle + doctor tests | n/a |
| `cargo test -p audit-drift unsafe_score` | pending | composite scoring gate for Sprint 4 | n/a |
| `bash -n scripts/setup.sh` | pending | host bootstrap parse check | n/a |
| `bash scripts/ci/sandbox-install-rehearsal.sh` | pending | CI gate position 6 | n/a |
| `agent-runtime install --product claude --live-home /tmp/claude-sandbox --dry-run` | pending | end-to-end sandbox dry-run | n/a |

## Blockers

- Cross-plan: blocked by Plan 03 (`03-reporting-poc`). Sandbox rehearsal needs a populated `manifests/skills.yaml` with the reporting domain pinned to diff against; without it the `expected-skills.txt` would be empty.

## Session Log

(none yet)
