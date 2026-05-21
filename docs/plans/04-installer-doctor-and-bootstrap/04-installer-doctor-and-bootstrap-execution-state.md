# Phase 3 — Installer, Doctor, and Host Bootstrap Execution State

## Current State

- Status: pre-work complete; Sprint 1 active
- Target scope: whole plan
- Execution window: 2026-05-21 → TBD
- Staged execution confirmation: not applicable
- Current task: Task 1.1
- Next task: Task 1.2
- Last updated: 2026-05-21
- Branch/commit: pre-work on `feat/plan-04-prework-ci-infra-and-doc-fixes`; Sprint 1 Task 1.1 on nils-cli `feat/managed-block-helper`
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

- Cross-plan: cleared on 2026-05-21. Plan 03 merged (PRs #14, #15) with the
  reporting domain populated in `manifests/skills.yaml`. Sprint 5 Task 5.2 now
  has real fodder to pin against.

## Session Log

### 2026-05-21 — Pre-work decisions resolved at defaults

Four plan-doc gaps surfaced before Sprint 1 could start. Each was resolved at
its suggested default — no design dialogue, no rework. Captured here so the
next session does not re-debate them.

- **Gap #1 — `targets/<product>/link-map.yaml` absent.** Resolved: design
  the schema + initial files inside Sprint 1 Task 1.2 PR. Schema must cover
  symlinked-file entries, managed-block entries, backed-up-on-replace
  entries, and plugin manifest copy entries (since
  `.<product>-plugin/plugin.json` lives under `targets/` not `build/`).
- **Gap #2 — `audit-drift` is not a standalone crate.** Resolved: keep it
  as the `audit_drift` module of `agent-runtime-cli`. Sprint 4 task
  locations and validation commands rewritten to point at
  `crates/agent-runtime-cli/src/audit_drift/{unsafe_score,allowlist,classes/*}.rs`
  and `cargo test -p agent-runtime-cli audit_drift::<name>`.
- **Gap #3 — nils-cli `CHANGELOG.md` does not exist.** Resolved: create
  the file in Sprint 4 Task 4.4 with only the `0.2.0` entry. Earlier
  releases point to GitHub Releases as a single line — no retro-fill.
- **Gap #4 — agent-runtime-kit lacks CI.** Resolved in this pre-work PR
  (`feat/plan-04-prework-ci-infra-and-doc-fixes`): `scripts/ci/all.sh`
  encodes the five existing local gates (`plan-tooling validate`, render
  codex, render claude, golden diff, audit-drift root + four fixtures);
  `.github/workflows/ci.yml` wraps it on `pull_request` + `push:main`;
  `.gitignore` gains `.claude/` and `backup-*.zip`. Sprint 5 Task 5.3 only
  needs to add position 6 (sandbox rehearsal).

Three open questions from the plan source were also resolved at their
suggested defaults:

- **Open Q1 — `--live-home` relative paths.** Reject relative; require
  absolute. Implemented in Sprint 1 Task 1.3 from day one, not as a
  follow-up.
- **Open Q2 — sandbox rehearsal depth.** Stop at dry-run +
  `--list-skills` diff until Codex / Claude CLIs accept `--home <dir>`.
  Sprint 5 Task 5.3 does not exercise `--apply` against tmp.
- **Open Q3 — WSL `AGENT_RUNTIME_HOST_PROFILE`.** Deferred to Sprint 3
  entry. Not actionable in Sprint 1 or Sprint 2.

### 2026-05-21 — Pre-work + Sprint 1 Task 1.1 kickoff

- Validation on `main` at `ccfa7cc` confirmed clean:
  `plan-tooling validate --format text --explain` exit 0;
  `agent-runtime audit-drift` clean (0 findings);
  `agent-runtime render --product {codex,claude}` cache round-trip clean
  (rendered=0 cached=3 skipped=0); all four drift fixtures reproduce
  `expected.txt` + `expected.exit` hermetically.
- Opened housekeeping PR on `feat/plan-04-prework-ci-infra-and-doc-fixes`
  to deliver the gap resolutions above. Plan 04 Sprint 1 Task 1.1 (managed
  block helper) starts on `sympoies/nils-cli` once the housekeeping PR
  merges.
