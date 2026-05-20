# Plan 04 — Installer, Doctor, and Host Bootstrap (Source)

- Status: open, ready for implementation planning
- Date: 2026-05-20
- Source: `docs/source/inventory-target-architecture.md` (frozen inventory +
  target architecture for agent-runtime-kit), specifically the Phase 3 bullet
  list, the full `## Install And Link Strategy` section, the `## Install
  Channels` brew-first bootstrap subsection, the unsafe-scoring extension of
  drift audit, test layer 6 (sandbox install rehearsal), and Resolved
  Decision #7 (Bump Ceremony — affects `doctor --suggest-upgrade`).
- Scope: Phase 3 of the multi-repo agent runtime kit migration. Lands the
  `agent-runtime install` body, the lifecycle siblings (`uninstall`,
  `restore-backups`, `purge-state`, `gc-backups`), the read-only
  `agent-runtime doctor`, the remaining drift-audit finding classes (the
  composite `unsafe` score, `intentional-difference`, `extra`), the
  `0.2.0` nils-cli release that publishes them, and the end-to-end
  `scripts/setup.sh` body plus the sandbox install rehearsal CI gate
  (position 6) in this repo.

## Execution

- Recommended plan:
  docs/plans/04-installer-doctor-and-bootstrap/04-installer-doctor-and-bootstrap-plan.md
- Recommended execution state:
  docs/plans/04-installer-doctor-and-bootstrap/04-installer-doctor-and-bootstrap-execution-state.md

## Purpose

Phase 3 of the multi-repo agent runtime kit migration. This plan turns the
reporting POC (Plan 03) into a real installer: render output gets linked
into product runtime homes through managed symlinks and managed-block
config edits, lifecycle siblings handle uninstall / restore / state purge
without ever touching auth or sessions, `doctor` reports the host's
posture against `runtime-roots.yaml` floors, and `scripts/setup.sh` runs
the full brew tap → install nils-cli → `agent-runtime install --product
claude` and `--product codex` → `agent-runtime doctor` chain. The sandbox
install rehearsal CI gate (position 6) catches load-time errors the
render-golden gate cannot see.

The plan is cross-repo. Most Rust implementation lands in
`sympoies/nils-cli` (`crates/agent-runtime-cli/`); the `scripts/setup.sh`
body, sandbox expected-skills pins, and the new CI gate land in
`graysurf/agent-runtime-kit`. Every task carries its repo prefix in
`**Location**`.

## Current Judgment

- Sprints 1–4 are nils-cli work. The reason agent-runtime-kit owns the
  plan bundle is that the contracts (managed-block markers, overlay
  merge semantics, version-floor disposition shape, sandbox harness
  format) all originate in this repo's target architecture doc. Plan
  metadata stays with the source doc; the implementation crate lives
  elsewhere.
- Sprint 5 (host bootstrap + sandbox rehearsal) is in-repo work that
  depends on the Sprint 1–4 binary actually existing on PATH via brew.
  It is gated by the `0.2.0` formula bump in Sprint 4.
- The Bump Ceremony PR template was added in Plan 01 Sprint 1 (the
  template referenced by Resolved Decision #7). Sprint 3 here closes
  the loop with `doctor --suggest-upgrade`, which prints copy-pasteable
  `brew upgrade <formula>` commands that the ceremony PR uses as
  evidence.

## Source References

- `docs/source/inventory-target-architecture.md`
  - `## Migration Phases` → Phase 3 bullet list (around lines 1696–1718).
  - `## Install And Link Strategy` (around lines 1068–1271) — install
    plan shape, managed-block contract, uninstall behavior, restore /
    purge / gc-backups subcommands, retention, doctor checks.
  - `## Install Channels` (around lines 996–1067) — brew-first
    bootstrap end-to-end sequence and the `--skip-*` flag set.
  - `### Overlay Merge Semantics` (around lines 745–776) — what
    `--dry-run` must print as the resolved effective config.
  - `## Drift Detection` → `### Unsafe Scoring` (around lines 1362–1410)
    — composite scoring weights, thresholds, allowlist demotion.
  - `## Testing And Validation` → test layer 6 (around lines 1440–1453)
    and `### CI Gate Order` (around lines 1458–1472) — sandbox install
    rehearsal and gate position 6.
  - Resolved Decision #7 (Bump Ceremony) — what
    `doctor --suggest-upgrade` is paired with.

## Findings

| Priority | ID | Issue | Evidence | Fix Location | Acceptance |
| --- | --- | --- | --- | --- | --- |
| high | F1 | `agent-runtime install` body is stubbed (Plan 01 Sprint 3 cut a `0.12.0` no-op). Without it Phase 3 cannot ship the reporting POC into a live home. | Phase 3 bullet 1; `## Install And Link Strategy` | `nils-cli/crates/agent-runtime-cli/src/install.rs` | Dry-run prints a deterministic plan; `--apply` links approved files, syncs managed blocks, and backs up replaced originals; `--live-home` redirects to a sandbox path. |
| high | F2 | No managed-block contract is enforced in code — Codex `config.toml` and Claude `settings.json` will silently lose unmanaged edits. | `### Managed-Block Contract` | nils-cli managed-block helper module | Paired markers preserved byte-for-byte outside the range; missing-marker re-add refused without `--force`. |
| high | F3 | Lifecycle siblings (`uninstall`, `restore-backups`, `purge-state`, `gc-backups`) are absent. Without them an install mistake has no clean recovery and aged backups grow without bound. | `### Uninstall Behavior`, `### Restore-Backups Subcommand`, `### Purge-State Subcommand`, `### Backup Retention` | nils-cli `agent-runtime-cli` subcommand handlers | Uninstall is idempotent and never touches auth/history; `restore-backups --from latest` reverses an install; `purge-state` requires explicit `--scope`; `gc-backups` enforces 5-run retention. |
| high | F4 | `agent-runtime doctor` is stubbed. Bump Ceremony PRs (Decision #7) have nowhere to copy evidence from, and CI cannot exit `1` / `2` on version floor breaches. | `### Doctor Checks`; Resolved Decision #7 | nils-cli `doctor` subcommand | Doctor probes every check listed in the target doc, emits a 4-status output for product versions, supports `--suggest-upgrade` and `--check-project <path>`, and exits 0/1/2 matching `audit-drift`. |
| high | F5 | Drift audit is missing the composite `unsafe` score and the `intentional-difference` / `extra` finding classes. Without them, secret leaks and unmanaged-file detection are not enforced. | `### Unsafe Scoring`; `## Drift Detection` finding classes | nils-cli `audit-drift` source | Three new classes implemented with documented weights / thresholds; allowlist demotes by exactly one tier; `drift-audit.allow.yaml` schema enforced. |
| high | F6 | `scripts/setup.sh` only has the Plan 01 skeleton — the install / doctor invocation steps are stubbed. End-to-end host bootstrap therefore cannot be reviewed in this repo. | `### Brew-First Bootstrap` | `scripts/setup.sh` | Full 7-step sequence runs against a clean host; CI uses `--skip-*` flags to bypass irrelevant steps. |
| high | F7 | Sandbox install rehearsal harness (test layer 6) does not exist; load-time product errors (broken symlinks, `plugin.json` drift, missing hook files) cannot be caught in CI. | `## Testing And Validation` layer 6; `### CI Gate Order` position 6 | `tests/sandbox/<product>/expected-skills.txt`, CI gate script | Per-product expected-skills file pinned; CI gate position 6 runs the dry-run install + `--list-skills` diff. |
| medium | F8 | `required_clis` floors in agent-runtime-kit manifests still pin against `0.1.0`. Once `0.2.0` ships with new subcommands, skills that call them silently work locally and break on hosts running `0.1.0`. | `## Manifest Layer` `required_clis` contract | `manifests/skills.yaml` `required_clis` entries | Skills that depend on `restore-backups` / `purge-state` / `gc-backups` / new doctor flags carry `">=0.2.0"`. |

## Ownership Boundary

- agent-runtime-kit (this repo): `scripts/setup.sh` body,
  `tests/sandbox/<product>/expected-skills.txt`, CI gate position 6 in
  `scripts/ci/`, `required_clis` floor bumps in `manifests/skills.yaml`,
  `tests/install/<product>/expected.txt` re-pin against the real install
  output.
- nils-cli (`sympoies/nils-cli`): `crates/agent-runtime-cli/` install /
  uninstall / restore-backups / purge-state / gc-backups / doctor
  bodies, `audit-drift` extension for `unsafe` / `intentional-difference`
  / `extra` classes, `0.2.0` workspace version bump and release tag.
- homebrew-tap (`sympoies/homebrew-tap`): formula bump to `0.2.0`.

## Cross-Plan Context

- Blocked by Plan 03 (`03-reporting-poc`). Sandbox rehearsal needs a
  populated `manifests/skills.yaml` with the reporting domain pinned to
  diff against; without it the `expected-skills.txt` would be empty.
- Plan 05 (multi-domain migration) uses the working installer and
  doctor from this plan to land 7 more domains. Plan 05 does not
  re-implement install or doctor.
- The Bump Ceremony PR template added in Plan 01 Sprint 1 is the
  destination for `doctor --suggest-upgrade` output; Sprint 3 of this
  plan closes that loop.

## Retention Intent

- This source doc is execution coordination — delete after Plan 04
  completes and Plan 05's source doc references the same architecture
  doc directly.
- `scripts/setup.sh` and `tests/sandbox/<product>/expected-skills.txt`
  are durable repo files.
- The new nils-cli subcommand bodies are durable code.

## Open Questions

- `--live-home` path handling: should the flag accept relative paths or
  require absolute? Recommended default: absolute, reject relative
  with a usage error so accidental `--live-home foo` does not write
  into the cwd.
- Sandbox rehearsal depth: should it exercise `--apply` against a tmp
  dir or stop at dry-run + `--list-skills` diff? Recommended default:
  stop at list-skills, because full `--apply` rehearsal requires
  product CLIs (Codex CLI, Claude CLI) to accept `--home <dir>`, which
  neither does today. Revisit when either ships the flag.
- Doctor's runtime-roots probe under WSL: does the existing
  `AGENT_RUNTIME_HOST_PROFILE` env var path cover Linuxbrew-on-WSL
  detection, or is a dedicated WSL profile required? Defer to
  integration verification on a real WSL host before Sprint 3 ships.

## Do Not Do

- Do not touch auth / history / sessions / cache from any new
  subcommand. The kit is read-only against those paths.
- Do not silently prune backups inside `install`. Retention is
  enforced by the dedicated `gc-backups` subcommand.
- Do not extend `uninstall` to restore previously-replaced files; that
  is `restore-backups`'s job.
- Do not add a fourth overlay surface. `.private/` plus the
  `profile.recommended.yaml` sibling are the only overlays.
- Do not run the sandbox rehearsal against the developer's real
  `~/.claude` or `~/.codex`. `--live-home` is mandatory for the
  rehearsal harness.

## Validation Gate

- `plan-tooling validate --file docs/plans/04-installer-doctor-and-bootstrap/04-installer-doctor-and-bootstrap-plan.md --format text --explain`
- Cross-repo (nils-cli): `cargo test -p agent-runtime-cli`
- Cross-repo (nils-cli): `cargo test -p audit-drift unsafe_score`
- This repo: `bash -n scripts/setup.sh`
- This repo: `bash scripts/ci/sandbox-install-rehearsal.sh`
- End-to-end (sandbox): `agent-runtime install --product claude --live-home /tmp/claude-sandbox --dry-run`
