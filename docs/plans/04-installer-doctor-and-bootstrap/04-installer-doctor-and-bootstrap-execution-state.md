# Phase 3 — Installer, Doctor, and Host Bootstrap Execution State

## Current State

- Status: Sprint 1 complete; Sprint 2 active
- Target scope: whole plan
- Execution window: 2026-05-21 → TBD
- Staged execution confirmation: not applicable
- Current task: Task 2.1
- Next task: Task 2.2
- Last updated: 2026-05-21
- Branch/commit: pre-work merged at `31c79e9`; Sprint 1 Task 1.1 merged at nils-cli `3309c3e`; Sprint 1 Task 1.2 PR A merged at agent-runtime-kit `f89eec1`; PR B merged at nils-cli `5d351bb`; Sprint 1 Task 1.3 merged at nils-cli `cee0903`
- Source document: docs/plans/04-installer-doctor-and-bootstrap/04-installer-doctor-and-bootstrap-plan.md
- Direct source-doc execution waiver: not applicable

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| Task 1.1 | complete | Implement managed-block helper module | [sympoies/nils-cli#414](https://github.com/sympoies/nils-cli/pull/414) merged `3309c3e` | paired-marker contract + `BodyContainsMarker` body validation; `is_trusted_surface` invariant; 19 unit + 7 integration tests; `/code-review-specialists` pass landed F-2 hardening fix |
| Task 1.2 | complete | Wire render to link to managed-block sync pipeline | PR A [graysurf/agent-runtime-kit#18](https://github.com/graysurf/agent-runtime-kit/pull/18) merged `f89eec1`; PR B [sympoies/nils-cli#416](https://github.com/sympoies/nils-cli/pull/416) merged `5d351bb` | 4 entry kinds in schema (`symlinked-file` / `plugin-manifest-copy` / `managed-block` / `backed-up-on-replace`); install pipeline ships with 13 unit + 6 integration tests; second `--apply` is byte-identical no-op; `/code-review-specialists` pass on PR B landed F-1 (HIGH path-traversal rejection) + F-3 (managed-block e2e coverage) |
| Task 1.3 | complete | Add `--live-home`, `--tag`, and overlay merge flags | [sympoies/nils-cli#418](https://github.com/sympoies/nils-cli/pull/418) merged `cee0903` | renames `--home` → `--live-home` (absolute-only); adds `--tag <name>` writing `tag-<name>` marker at backup-run root; ships `.private/link-map.overrides.yaml` overlay merge applied pre-plan-generation; `InstallOptions` + `InstallOutcome` + `OverlaySummary`; 12 install_flags + 8 overlay unit + 3 executor tag tests; `/code-review-specialists` pass landed F-1 (defense-in-depth tag validation) + F-2 (operator-visible overlay-merge notice) |
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

### 2026-05-21 — Sprint 1 Task 1.3 closed; Sprint 1 complete

- Sprint 1 Task 1.3 merged at `sympoies/nils-cli` commit `cee0903`. Two
  GPG-signed commits: feature `27607b8` + specialist-fix `e340719`.
- New surface area:
  - `--home` renamed to `--live-home` (absolute path required; Open Q1
    resolved-default shipped from day one; relative paths exit non-zero
    with a usage error naming the flag).
  - `--tag <name>` writes a `tag-<name>` marker file at
    `<state_home>/backups/<product>/<unix-seconds>/tag-<name>` whenever
    at least one backup is created during apply. ASCII-alphanumeric /
    `-` / `_` trust contract enforced at both the CLI boundary and the
    executor entry (defense in depth — see F-1 below).
  - New `.private/link-map.overrides.yaml` overlay merge runs before
    plan generation. Per-entry replace; `enabled: false` drops; new
    entries are added. Schema gated by the same
    `link-map.schema.json` contract as the tracked link-map. `--no-overlay`
    skips the merge; `--overlay-path` redirects the read.
- New Rust API: `InstallOptions { tag, overlay_enabled,
  overlay_path }` with a custom `Default` impl (overlay-on by default —
  `derive(Default)` would silently flip it off); `InstallOutcome
  { plan, changes, overlay: Option<OverlaySummary> }`;
  `OverlaySummary { dropped, replaced, added }`.
- `/code-review-specialists` pass surfaced two material findings, both
  landed pre-merge in commit `e340719`:
  - F-1 (medium, security/red-team): tag validation only happened at
    the CLI boundary. Moved `is_trusted_tag` into
    `install::executor` and re-validated at executor entry; library
    callers using `InstallOptions { tag, .. }` directly now hit
    `ApplyError::InvalidTag { value }`.
  - F-2 (medium, red-team): `.private/link-map.overrides.yaml` was
    consumed silently. Added `OverlaySummary` returned from
    `overlay::apply` and threaded through `InstallOutcome`; CLI now
    prints `agent-runtime install: overlay merged (dropped=N
    replaced=N added=N)` whenever an overlay is consumed, satisfying
    the `inventory-target-architecture.md` `### Overlay Merge
    Semantics` requirement that dry-run expose the post-merge
    effective config.
- Six advisory findings deferred (synthesis at
  `~/.local/state/claude-kit/out/task-1-3-review/SYNTHESIS.md`):
  - F-3 (api-contract low) — `tag-<name>` marker filename and
    `<entry_id>/` backup subdir share the same path namespace at the
    backup-run root. Pin in Sprint 2 Task 2.4 (`gc-backups`): test
    file-type before treating a path as a tag marker, OR reserve
    `tag-*` prefix in the link-map schema's `id` pattern.
  - F-4 (api-contract info) — `--home` → `--live-home` rename is
    breaking relative to Task 1.2's `5d351bb`. No release shipped
    `--home`; add a `### Breaking changes` line to the 0.2.0
    CHANGELOG when Sprint 4 Task 4.4 lands.
  - F-5 / F-6 (testing info) — no integration test exercises overlay
    adding a brand-new entry through `install::run` (only the
    in-memory unit test); tag-marker idempotence on a second
    `--apply` is not asserted (current behaviour is correct, just
    unpinned).
  - F-7 (maintainability info) — `InstallOptions` overrides
    `Default::default()` manually so `overlay_enabled` stays `true`.
    Consider a builder pattern when Sprint 2 grows the struct.
- Sprint 1 is now closed. Next pickup: Sprint 2 Task 2.1
  (`agent-runtime uninstall`), serial after Task 1.3.

### 2026-05-21 — Sprint 1 Task 1.2 closed across both repos

- PR A merged at agent-runtime-kit `f89eec1`: schema + initial codex/claude
  link-maps. Schema validates initial yaml and rejects 6 representative
  malformed cases (missing `schema_version`, per-kind required/forbidden
  field violations, bad `id` pattern, forbidden `recursive` on
  `managed-block`).
- PR B merged at nils-cli `5d351bb`: install pipeline body. New module
  `install::{link_map, plan, executor}` plus `commands::install`
  wrapper. Replaces the `Install` stub with `InstallArgs (--source-root
  --product --home --state-home --dry-run|--apply)`. Apply executor
  reconciles symlinks (with backup to
  `<state_home>/backups/<product>/<unix-seconds>/<entry_id>/<filename>`)
  and managed blocks (calling the Task 1.1 helper). 13 unit + 6
  integration tests; full `nils-cli-verify-required-checks` stack green.
- `/code-review-specialists` pass on PR B surfaced two material findings,
  both landed pre-merge in fix commit `c9befcf`:
  - F-1 (HIGH, security/red-team) — `home.join(destination)` and
    `source_root.join(source)` did not reject `..` traversal. Added
    `PlanError::DestinationTraversal` / `SourceTraversal` plus a
    `has_parent_dir_component` walker. 5 new plan-builder unit tests pin
    the rejection.
  - F-3 (medium, testing) — managed-block executor had no end-to-end
    test through `install::run`. Added
    `managed_block_entry_writes_block_and_is_idempotent_on_second_apply`
    driving the full pipeline against a managed-block-only link-map.
- Task 1.3 is the immediate next pickup: layer `--live-home`,
  `--tag`, and overlay merge flags on top of Task 1.2's `--home` /
  `--state-home` Rust API. Open question Q1's default (reject relative
  `--live-home`) ships from day one.

### 2026-05-21 — Sprint 1 Task 1.1 closed; Task 1.2 (schema phase) opened

- Sprint 1 Task 1.1 merged at `sympoies/nils-cli` commit `3309c3e` after a
  `/code-review-specialists` pass surfaced two material findings, both
  resolved before merge in fix commit `67edbe6`:
  - F-2 (medium, security/red-team): `write()` did not validate `body`
    against the surface's own markers; resolved by adding
    `ManagedBlockError::BodyContainsMarker` with a column-0 anchored
    rejection path covering both append (force=true) and replace flows.
  - F-1 (medium → documented invariant): surface names accepted
    arbitrary bytes; resolved by `is_trusted_surface` (ASCII
    alphanumeric / `-` / `_`) plus a `debug_assert!` in `new()` and an
    explicit module-doc contract.
  - F-3 (testing): LF-only line-ending assumption documented; CRLF
    support deferred to a later sprint.
- Final shape: 19 unit + 7 integration tests, full
  `nils-cli-verify-required-checks` stack green, GPG-signed commits.
- Sprint 1 Task 1.2 is split into two PRs to keep cross-repo scope clean:
  - **PR A (this repo)** — `core/docs/schemas/link-map.schema.json`
    (JSON Schema draft 2020-12), `targets/codex/link-map.yaml`,
    `targets/claude/link-map.yaml`. Initial entries cover the Plan 03
    reporting plugin via one `plugin-manifest-copy` (manifest under
    `targets/`) and one `recursive: true` `symlinked-file` entry for
    the rendered skills tree under `build/`. Schema validates both
    initial yaml files; rejects 6 representative malformed cases
    (missing required fields, kind / required-field mismatches, bad
    id pattern, forbidden fields per-kind).
  - **PR B (nils-cli)** — install pipeline body in
    `crates/agent-runtime-cli/src/install.rs` +
    `src/install/plan.rs`, consuming the link-map schema landed in PR
    A, with a `tests/integration/install_pipeline.rs` byte-identical
    idempotence test. Opens once PR A merges.

### 2026-05-21 — Pre-work + Sprint 1 Task 1.1 kickoff

- Validation on `main` at `ccfa7cc` confirmed clean:
  `plan-tooling validate --format text --explain` exit 0;
  `agent-runtime audit-drift` clean (0 findings);
  `agent-runtime render --product {codex,claude}` cache round-trip clean
  (rendered=0 cached=3 skipped=0); all four drift fixtures reproduce
  `expected.txt` + `expected.exit` hermetically.
- Opened housekeeping PR on `feat/plan-04-prework-ci-infra-and-doc-fixes`
  to deliver the gap resolutions above. First-ever CI run on the repo
  surfaced a hermeticity defect in the Plan 03 drift fixtures — the
  top-level `build/` gitignore pattern was masking the per-fixture
  `tests/drift/<scenario>/build/` trees, so the CI runner saw 1 finding
  instead of 3 for `agent-home-leak`. Fixed forward by carving out
  `!tests/drift/*/build/` and committing the 12 pre-rendered build files.
  PR #16 merged at SHA `31c79e9` (run `26209007414`, 26s).
- Sprint 1 Task 1.1 (managed-block helper) opened against `sympoies/nils-cli`
  on branch `feat/managed-block-helper` as draft PR #414. 15 in-crate unit
  tests + 6 file-system integration tests pass; full
  `nils-cli-verify-required-checks` gate stack green locally. Paused for
  review before continuing to Task 1.2 (install pipeline).
