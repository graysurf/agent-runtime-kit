# Sync Runtime Skill Prune Implementation Handoff

- Status: ready for plan generation
- Date: 2026-05-26
- Source: user review of `sync-runtime-skills` add-only behavior, follow-up
  request to include the `nils-cli` implementation boundary, local inspection
  of `agent-runtime-kit`, and local inspection of `sympoies/nils-cli`.
- Intended next step: feed this document into a focused implementation plan
  that first adds a stale-surface prune primitive in `nils-cli`, releases it,
  then teaches `agent-runtime-kit`'s sync workflow to consume it.
- Source type: discussion-to-implementation-doc

## Execution

- Recommended plan: docs/plans/sync-runtime-skill-prune/sync-runtime-skill-prune-plan.md
- Recommended execution state: docs/plans/sync-runtime-skill-prune/sync-runtime-skill-prune-execution-state.md
- Recommended first implementation task: add the `agent-runtime` stale-surface
  prune primitive in `sympoies/nils-cli`, with dry-run/apply behavior and
  focused integration fixtures for removed skills.

## Purpose

`scripts/sync-runtime-skills.sh` now covers the daily "make newly merged skills
visible" path by pulling the source checkout, rendering product builds,
installing runtime homes, and running verification. That handles additions and
updates. It does not remove stale live skill surfaces after a managed skill is
removed from `manifests/skills.yaml`, product link maps, or rendered
`build/<product>/`.

The missing behavior should be owned by `nils-cli`'s `agent-runtime` layer, not
by ad hoc shell cleanup in `sync-runtime-skills.sh`. The shell wrapper should
compose released primitives; the Rust CLI owns link-map interpretation, product
runtime-home safety, symlink ownership checks, dry-run/apply semantics, and
future tests.

## Confirmed Facts

- [U1] The user asked whether `sync-runtime-skills` can add new skills but does
  not delete removed skills, and whether delete/prune should be added.
- [U2] The user explicitly asked to include the `nils-cli` portion in this
  implementation-readiness document.
- [F1] `docs/plans/<slug>/` is the default location for coordination plan
  source documents. See `docs/source/docs-placement-retention-policy-v1.md`.
- [F2] `scripts/sync-runtime-skills.sh` currently runs `git pull`, source-count
  audit, `agent-runtime render`, `agent-runtime install`, `agent-runtime doctor
  --class skill-surface`, and optional `codex debug prompt-input`. It has no
  prune, delete, uninstall, or `audit-drift` step. See
  `scripts/sync-runtime-skills.sh:320-511`.
- [F3] Codex exposes active skills through explicit per-skill directory
  symlinks under `skills/<domain>/<skill>` and also installs recursive plugin
  skill trees. See `targets/codex/link-map.yaml:7-12` and
  `targets/codex/link-map.yaml:22-157`.
- [F4] Claude installs plugin skill trees through recursive link-map entries
  such as `plugins/<domain>/skills`. See `targets/claude/link-map.yaml:7-24`
  and `targets/claude/link-map.yaml:31-123`.
- [F5] `remove-skill` removes source, manifest, plugin containment, product
  render metadata, golden snapshots, sandbox expected skill pins,
  runtime-smoke cases, hook/reminder metadata, and maintained docs references.
  It does not own live runtime-home cleanup. See
  `core/skills/meta/remove-skill/SKILL.md.tera:27-79`.
- [F6] `agent-runtime install` in nils-cli walks the current install plan and
  reconciles only the plan's actions. It creates, replaces, backs up, or no-ops
  current destinations; there is no pass that scans plan-owned roots for
  destinations no longer in the plan. See
  `sympoies/nils-cli:crates/agent-runtime-cli/src/install/executor.rs:96-248`.
- [F7] The installed `agent-runtime 0.22.3` `install --help` output exposes
  `--dry-run` and `--apply`, but no prune/delete flag.
- [F8] `agent-runtime uninstall` exists and removes current link-map-owned
  symlinks and managed blocks. Because its uninstall plan is derived from the
  current install plan, it cannot remove a skill destination that has already
  been deleted from the current link map. See
  `sympoies/nils-cli:crates/agent-runtime-cli/src/uninstall/plan.rs:1-6`.
- [F9] `audit-drift` already has an `extra` class that compares live runtime
  homes against install-map expected paths under install-map-owned scan roots.
  It reports extra live files but does not repair them. See
  `sympoies/nils-cli:crates/agent-runtime-cli/src/audit_drift/classes/extra.rs:1-62`.
- [F10] `doctor --class skill-surface` is shape-only and deliberately does not
  stat the live runtime home or reproduce Codex Desktop discovery. See
  `sympoies/nils-cli:crates/agent-runtime-cli/src/doctor/skill_surface.rs:1-5`.
- [A1] On 2026-05-26, the installed runtime was `agent-runtime 0.22.3`.
- [A2] On 2026-05-26, `agent-runtime list-skills --product codex` and
  `--product claude` each reported `59` skills for this checkout.
- [A3] On 2026-05-26, `agent-runtime audit-drift --source-root "$PWD"`
  against the runtime-kit checkout exited 0 and reported
  `audit-drift: clean (20 findings)`, where all findings were documented
  intentional plugin manifest differences.

## Inferences

- [I1] A managed-skill removal can leave stale live surfaces after the next
  sync: Codex can retain an old `skills/<domain>/<skill>` symlink, and Claude
  can retain old plugin skill files under `plugins/<domain>/skills/<skill>/`.
- [I2] `audit-drift` can already detect a subset of this class as extra live
  surfaces, but `sync-runtime-skills` does not call it and `audit-drift` is
  read-only.
- [I3] `uninstall` is not the right primitive for normal refresh pruning. It is
  an all-current-link-map uninstall path, not a "remove only stale entries"
  reconciler.
- [I4] The safe implementation belongs first in nils-cli because only
  `agent-runtime` has the stable parser and test surface for link maps,
  recursive expansion, managed blocks, runtime homes, backup semantics, and
  foreign-symlink skips.
- [I5] Shell-level deletion in `sync-runtime-skills.sh` would duplicate
  link-map semantics, miss overlay behavior, and increase the risk of deleting
  user-owned runtime state.

## Recommended Decisions

- [D1] Add a nils-cli primitive named `agent-runtime prune-stale` rather than
  implementing deletion directly in `scripts/sync-runtime-skills.sh`.
- [D2] Make `prune-stale` dry-run-first with `--dry-run` and `--apply`, matching
  the existing install/uninstall operator model.
- [D3] Reuse or factor the existing `audit-drift extra` expected-path and
  scan-root logic so detection and repair classify stale surfaces the same way.
- [D4] Remove only live paths that are provably runtime-kit-owned:
  symlinks whose lexical target is under the selected source root's managed
  source/build/target roots, managed-block markers owned by runtime-kit, and
  empty directories under owned recursive install roots after their stale
  symlinks are removed.
- [D5] Skip and warn on regular files, non-empty directories, foreign symlinks,
  and any path outside install-map-owned roots.
- [D6] After the nils-cli primitive is released, update
  `scripts/sync-runtime-skills.sh --apply` to run stale pruning by default
  after install and before final verification. Add `--no-prune` for emergency
  bypass.
- [D7] Keep `--no-verify` scoped to doctor/prompt verification. Do not let it
  implicitly skip source-count checks or prune safety classification.
- [D8] Add `agent-runtime audit-drift` or the new `prune-stale --dry-run`
  summary to the sync verification tail so stale live surfaces fail visibly
  even when `--no-prune` is used.

## Scope

### nils-cli

- Add `agent-runtime prune-stale` under
  `sympoies/nils-cli:crates/agent-runtime-cli`.
- Build expected live paths from the current product link map after overlay
  merge, including recursive entries.
- Scan only install-map-owned live roots.
- Classify stale candidates as removable symlink, removable empty directory,
  skipped foreign symlink, skipped regular file, skipped non-empty directory, or
  no-op.
- Support `--source-root`, `--product`, `--live-home`, `--dry-run`,
  `--apply`, `--no-overlay`, and `--overlay-path`.
- Provide focused integration tests for Codex active skill symlinks, Codex
  plugin tree files, Claude plugin tree files, overlay entries, foreign
  symlinks, regular files, non-empty directories, and idempotent second apply.

### agent-runtime-kit

- Update `scripts/sync-runtime-skills.sh` to call the released prune primitive
  after install when `--apply` is active.
- In dry-run mode, print the planned prune command alongside render/install
  commands.
- Add `--no-prune` to the wrapper and document when it is acceptable.
- Update `core/skills/meta/sync-runtime-skills/SKILL.md.tera`, rendered
  Codex/Claude goldens, and any tests that assert the skill contract.
- Raise the `meta.sync-runtime-skills` required `agent-runtime` floor in
  `manifests/skills.yaml` after the nils-cli release containing `prune-stale`
  is available.
- Add runtime-kit fixture coverage that simulates a removed managed skill and
  proves sync cleanup removes the stale live surface without touching
  user-owned runtime files.

## Non-Scope

- Do not delete arbitrary files under `$CODEX_HOME`, `$HOME/.claude`, auth,
  history, sessions, logs, caches, projects, or plugin install artifacts.
- Do not make `remove-skill` mutate live runtime homes directly. `remove-skill`
  remains source/manifest/test cleanup; live runtime reconciliation belongs to
  sync/prune.
- Do not repurpose `agent-runtime uninstall` as normal refresh pruning.
- Do not require a first-time host bootstrap or Homebrew reinstall for this
  feature.
- Do not treat historical `docs/plans/**` records as stale live runtime
  surfaces.

## Requirements

- A removed managed skill does not remain visible in live Codex or Claude homes
  after `sync-runtime-skills.sh --apply` completes with pruning enabled.
- The prune primitive must be idempotent: a second apply after successful prune
  exits 0 and reports no removals.
- Dry-run must report every candidate and classification without mutating the
  runtime home.
- Apply must remove only owned stale symlinks and empty directories under owned
  roots.
- Foreign symlinks and regular files must survive byte-for-byte and be reported
  clearly.
- Overlay-added link-map entries must be included unless `--no-overlay` or an
  explicit alternate overlay path is used.
- `sync-runtime-skills.sh --no-prune` must leave stale candidates in place but
  surface an audit/prune warning so the operator knows the live surface is not
  fully reconciled.
- Current additions and updates must continue to work exactly as they do now.

## Acceptance Criteria

- `agent-runtime prune-stale --dry-run` against a sandbox home with a removed
  Codex active skill reports the stale `skills/<domain>/<skill>` symlink as
  removable and does not mutate the sandbox.
- `agent-runtime prune-stale --apply` removes that stale Codex symlink and a
  second apply is a clean no-op.
- A sandbox Claude home with stale
  `plugins/<domain>/skills/<skill>/SKILL.md` symlinks is pruned, and empty
  skill directories created only for stale recursive entries are removed.
- Foreign symlink, regular file, and non-empty directory fixtures are skipped
  with actionable messages and survive unchanged.
- `agent-runtime audit-drift` is clean after render, install, and prune in a
  removed-skill fixture.
- `scripts/sync-runtime-skills.sh --apply --no-pull` runs render, install,
  prune, doctor, and Codex prompt-input sequencing in that order.
- `scripts/sync-runtime-skills.sh --dry-run` prints planned prune commands and
  performs no runtime-home mutation.
- The `sync-runtime-skills` skill body, rendered outputs, and golden snapshots
  describe prune behavior and `--no-prune` consistently.

## Validation Plan

- `agent-docs resolve --context startup --strict --format checklist`
- `agent-docs resolve --context project-dev --strict --format checklist`
- nils-cli focused tests:
  `cargo test -p agent-runtime-cli --test integration prune_stale`
- nils-cli regression tests:
  `cargo test -p agent-runtime-cli --test integration install_pipeline`
- nils-cli regression tests:
  `cargo test -p agent-runtime-cli --test integration uninstall`
- nils-cli regression tests:
  `cargo test -p agent-runtime-cli --test integration audit_drift_extra_intentional`
- nils-cli full relevant gate per repository convention before release.
- Release/install the nils-cli version containing `agent-runtime prune-stale`.
- Runtime-kit focused checks:
  `agent-runtime render --product codex --update-golden`
- Runtime-kit focused checks:
  `agent-runtime render --product claude --update-golden`
- Runtime-kit sandbox check:
  `bash scripts/ci/sandbox-install-rehearsal.sh`
- Runtime-kit sync fixture check for removed-skill pruning.
- Runtime-kit full gate:
  `bash scripts/ci/all.sh`
- Live post-release smoke from the durable primary checkout:
  `bash scripts/sync-runtime-skills.sh --apply --no-pull`
- Final live verification:
  `agent-runtime audit-drift --source-root "$PWD"`

## Risks And Guardrails

- Deleting runtime-home content is higher risk than creating symlinks. The
  implementation must fail closed and skip anything not proven owned.
- Broken stale symlinks may point at removed build paths. Ownership checks must
  not rely only on canonicalizing existing targets; lexical source-root
  containment is needed for broken managed symlinks.
- Recursive plugin-tree cleanup can leave empty directories. Remove only empty
  directories under owned scan roots and never remove a directory containing
  unclassified content.
- `audit-drift` and `prune-stale` should share classification rules or a common
  helper to avoid "audit says extra, prune says unknown" drift.
- Runtime-kit must not consume the new primitive until the nils-cli release is
  installed and the skill manifest floor is updated.

## Retention Intent

This is coordination material. Keep it under `docs/plans/` while the nils-cli
and runtime-kit implementation plan is active. After completion, either delete
the plan bundle during cleanup or promote only the durable prune contract into
the relevant runtime architecture docs.

## Read-First References

- `scripts/sync-runtime-skills.sh`
- `targets/codex/link-map.yaml`
- `targets/claude/link-map.yaml`
- `core/skills/meta/remove-skill/SKILL.md.tera`
- `sympoies/nils-cli:crates/agent-runtime-cli/src/install/executor.rs`
- `sympoies/nils-cli:crates/agent-runtime-cli/src/uninstall/plan.rs`
- `sympoies/nils-cli:crates/agent-runtime-cli/src/audit_drift/classes/extra.rs`

## Recommended Next Artifact

Create `docs/plans/sync-runtime-skill-prune/sync-runtime-skill-prune-plan.md`
from this source document, with a nils-cli-first sprint followed by an
agent-runtime-kit consumption sprint.
