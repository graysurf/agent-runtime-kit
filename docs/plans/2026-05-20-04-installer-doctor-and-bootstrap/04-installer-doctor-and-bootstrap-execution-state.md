# Phase 3 — Installer, Doctor, and Host Bootstrap Execution State

## Current State

- Status: Sprint 2 Task 2.4 complete; Sprint 2 closed; Sprint 3 active
- Target scope: whole plan
- Execution window: 2026-05-21 → TBD
- Staged execution confirmation: not applicable
- Current task: Task 3.1
- Next task: Task 3.2
- Last updated: 2026-05-21
- Branch/commit: pre-work merged at `31c79e9`; Sprint 1 Task 1.1 merged at nils-cli `3309c3e`; Sprint 1 Task 1.2 PR A merged at agent-runtime-kit `f89eec1`; PR B merged at nils-cli `5d351bb`; Sprint 1 Task 1.3 merged at nils-cli `cee0903`; Sprint 2 Task 2.1 merged at nils-cli `6bf6102`; Sprint 2 Task 2.2 merged at nils-cli `2ae3075`; Sprint 2 Task 2.3 merged at nils-cli `4799169`; Sprint 2 Task 2.4 merged at nils-cli `4339c8d`
- Source document: docs/plans/2026-05-20-04-installer-doctor-and-bootstrap/04-installer-doctor-and-bootstrap-plan.md
- Direct source-doc execution waiver: not applicable

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| Task 1.1 | complete | Implement managed-block helper module | [sympoies/nils-cli#414](https://github.com/sympoies/nils-cli/pull/414) merged `3309c3e` | paired-marker contract + `BodyContainsMarker` body validation; `is_trusted_surface` invariant; 19 unit + 7 integration tests; `/code-review-specialists` pass landed F-2 hardening fix |
| Task 1.2 | complete | Wire render to link to managed-block sync pipeline | PR A [graysurf/agent-runtime-kit#18](https://github.com/graysurf/agent-runtime-kit/pull/18) merged `f89eec1`; PR B [sympoies/nils-cli#416](https://github.com/sympoies/nils-cli/pull/416) merged `5d351bb` | 4 entry kinds in schema (`symlinked-file` / `plugin-manifest-copy` / `managed-block` / `backed-up-on-replace`); install pipeline ships with 13 unit + 6 integration tests; second `--apply` is byte-identical no-op; `/code-review-specialists` pass on PR B landed F-1 (HIGH path-traversal rejection) + F-3 (managed-block e2e coverage) |
| Task 1.3 | complete | Add `--live-home`, `--tag`, and overlay merge flags | [sympoies/nils-cli#418](https://github.com/sympoies/nils-cli/pull/418) merged `cee0903` | renames `--home` → `--live-home` (absolute-only); adds `--tag <name>` writing `tag-<name>` marker at backup-run root; ships `.private/link-map.overrides.yaml` overlay merge applied pre-plan-generation; `InstallOptions` + `InstallOutcome` + `OverlaySummary`; 12 install_flags + 8 overlay unit + 3 executor tag tests; `/code-review-specialists` pass landed F-1 (defense-in-depth tag validation) + F-2 (operator-visible overlay-merge notice) |
| Task 2.1 | complete | Implement `agent-runtime uninstall` | [sympoies/nils-cli#419](https://github.com/sympoies/nils-cli/pull/419) merged `6bf6102` | idempotent reversal of link-map symlinks + managed-block surfaces; second uninstall on a clean home is exit-0 NoOp; foreign symlinks and regular files at install destinations are skipped (not deleted); never touches `<state_home>/backups/` or `auth*`/`history*`/`sessions*`/`cache*`/`projects*` under the runtime home; new `uninstall::{run, UninstallOptions, UninstallError, UninstallOutcome}` + `uninstall::plan` + `uninstall::executor` + `commands::uninstall`; 16 new tests (8 integration + 7 executor unit + 1 plan unit); `/code-review-specialists` pass landed F-1 (red-team medium: thread `expected_source` through `SymlinkSkippedForeign` for operator recovery context) |
| Task 2.2 | complete | Implement `agent-runtime restore-backups` | [sympoies/nils-cli#423](https://github.com/sympoies/nils-cli/pull/423) merged `2ae3075` | walks `<state_home>/backups/<product>/<ts>/` and reverses the `FileBackedUpThenSymlinked` arm of install; matches each backup file to its install destination via a regenerated InstallPlan; refuses to clobber operator-retargeted symlinks (read_link(dest) == expected_install_source check); fs::rename with EXDEV → fs::copy + set_permissions fallback; no chown; new `restore_backups::{run, RestoreOptions, RestoreError, RestoreOutcome, BackupRunSelector { Latest, Exact(u64) }}` + `restore_backups::plan` + `restore_backups::executor` + `commands::restore_backups`; 12 new tests (10 integration + 2 executor unit + 3 plan unit); `/code-review-specialists` pass landed R-1 (medium red-team: foreign-symlink protection — same F-1 shape as Task 2.1, brought into byte-for-byte parity with uninstall) |
| Task 2.3 | complete | Implement `agent-runtime purge-state` | [sympoies/nils-cli#424](https://github.com/sympoies/nils-cli/pull/424) merged `4799169` | clears writable state under `<state_home>` per required `--scope out\|backups\|all` (no default); prompts on stdin unless `--yes`; `--yes` emits one stderr audit line containing the scope BEFORE any FS mutation; symlink at the scope path refused (`Err(InvalidData)`); cleared subtree recreated as empty dir for stable shape on next install/render; no `--live-home` flag exists, so runtime homes / auth / history / sessions / cache / projects are unreachable by construction; new `purge_state::{run, Scope { Out, Backups, All }, Confirm { Yes, Prompt }, PurgeError { Io, Cancelled }, PurgeOutcome { scope, cleared }}` + `commands::purge_state`; 15 new tests (8 integration + 7 unit); `/code-review-specialists` pass landed R-1 (stdout discipline) + R-2 (prompt clarity) — both low; piggybacked a `docs(plan)` commit silencing MD013 on an inherited regression in `code-review-specialist-primitives-plan.md` so CI could pass |
| Task 2.4 | complete | Implement `agent-runtime gc-backups` | [sympoies/nils-cli#430](https://github.com/sympoies/nils-cli/pull/430) merged `4339c8d` | retention default 5 per (product, surface) bucket; `--retention <N>` overrides; `install --tag <name>` markers preserve their run regardless of retention; `--product codex\|claude` default both; `--surface <name>` filters runs containing the named entry_id subdir; `--dry-run` produces zero mutations; `--apply` performs `fs::remove_dir_all`; install never prunes silently; canonical `is_tag_marker(path)` helper (regular-file + `tag-` prefix per `symlink_metadata`) resolves Task 1.3 F-3 namespace overlap; symlinked `<state_home>/backups/<product>` refused via `symlink_metadata` guard so `remove_dir_all` cannot be redirected outside state_home; new `gc_backups::{run, Mode { DryRun, Apply }, ProductFilter { All, One }, GcOptions, GcError { Io, InvalidSurface }, GcChange { Retained, PreservedByTag, Deleted, WouldDelete }, GcOutcome { mode, retention, changes }, is_tag_marker, ALL_PRODUCTS, DEFAULT_RETENTION}` + `commands::gc_backups`; 23 new tests (12 unit + 11 integration); `/code-review-specialists` pass over 1153 diff lines (single-agent + auto red-team) landed S-1 / R-2 (defense-in-depth symlinked product_root guard) + T-4 + T-6 (stream-discipline + symlink-spoof regression pins) — 12 advisories deferred to Sprint 3 / 4 |
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
| `plan-tooling validate --file docs/plans/2026-05-20-04-installer-doctor-and-bootstrap/04-installer-doctor-and-bootstrap-plan.md --format text --explain` | pending | bundle validation gate | n/a |
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

### 2026-05-21 — Sprint 2 closed; Task 2.4 gc-backups body lands

- Sprint 2 Task 2.4 merged at `sympoies/nils-cli` commit `4339c8d`. Two
  GPG-signed commits on the feature branch: feature `7f79442` +
  specialist-fix `e5cfdf0` (S-1 / R-2 defense-in-depth symlinked
  `<state_home>/backups/<product>` guard + T-4 symlink tag-marker spoof
  regression pin + T-6 stream-discipline regression pin).
- New surface area:
  - `agent-runtime gc-backups --state-home <abs> [--product claude|codex] [--surface <entry_id>] [--retention <N>] (--dry-run | --apply)`.
  - Walks `<state_home>/backups/<product>/<unix_seconds>/`. Default
    `--product` = both `claude` + `codex`; default `--retention` = 5.
  - A run is preserved by tag iff it contains a regular FILE child whose
    basename starts with `tag-` — the canonical `is_tag_marker(path)`
    helper uses `symlink_metadata().file_type().is_file()` so an
    entry-id subdir whose name starts with `tag-` (Task 1.3 F-3 namespace
    overlap) falls through to the retention sort, and a symlink at the
    run root (even one whose target is a regular file) is NOT classified
    as a marker. This resolves Task 1.3 F-3.
  - Untagged runs sort by ts descending; first `--retention` become
    `Retained`, remainder become `Deleted` (Apply) or `WouldDelete`
    (DryRun). Tagged runs land as `PreservedByTag` regardless of
    position.
  - `--surface <name>` filters at run level: only runs containing
    `<run>/<name>/` subdir are considered for retention; runs without
    the surface are entirely skipped (never deleted). `validate_surface`
    rejects `/`, `\`, `..`, `.`, leading `.`, and empty strings.
  - Defense-in-depth: `<state_home>/backups/<product>` is gated by
    `symlink_metadata` before `enumerate_runs`, so a symlinked
    product_root is refused (otherwise `fs::remove_dir_all` could be
    redirected outside state_home).
- New Rust API: `gc_backups::{run, Mode { DryRun, Apply }, ProductFilter
  { All, One(String) }, GcOptions { product, surface, retention },
  GcError { Io, InvalidSurface }, GcChange { Retained,
  PreservedByTag { ..., marker }, Deleted, WouldDelete }, GcOutcome {
  mode, retention, changes }, is_tag_marker, ALL_PRODUCTS,
  DEFAULT_RETENTION}` + `commands::gc_backups::GcBackupsArgs`. CLI
  rejects relative `--state-home`, missing `--dry-run`/`--apply`,
  invalid `--product`, and path-traversal `--surface`.
- gc-backups deliberately uses NO link-map / NO overlay / NO
  managed-block machinery — sidesteps Task 2.1 F-2 (LinkMapPlan
  extraction), Task 2.2 R-2 (`merge_overlay` dedup), and Task 2.2 R-11
  (`ensure_parent_dir` dedup). Sprint 4 helper-duplication sweep is
  unaffected.
- `/code-review-specialists` pass surfaced 15 findings over 1153 diff
  lines (single-agent + auto red-team). Three pre-merge fixes landed in
  commit `e5cfdf0`:
  - S-1 / R-2 (security medium + red-team medium confirmation):
    `<state_home>/backups/<product>` could redirect `remove_dir_all`
    outside state_home when the product_root is a symlink. Added
    `symlink_metadata` guard before `enumerate_runs`. Regression-pinned
    by `product_root_symlink_is_refused_not_followed` unit test.
  - T-4 (testing low): pinned the positive control that
    `is_tag_marker` refuses symlink-to-file spoofs via a new
    `is_tag_marker_symlink_to_file_is_not_marker` unit test.
  - T-6 (testing low): added stream-discipline assertion to
    `seven_runs_with_default_retention_five_keeps_five_in_apply` so the
    summary + per-change report cannot leak from stderr to stdout.
- 12 advisory findings deferred (4 low + 8 info), grouped by sprint:
  - Sprint 3 doctor: orphan-symlink probe (Task 2.1 F-3 inheritance);
    list-available-surfaces probe surfacing `GcOutcome.mode/retention`
    consumer; tag-DoS observability counter (red-team R-1 by-design).
  - Sprint 4 sweep: `GcChange` accessor methods dead code; `--product`
    allowlist DRY against `ALL_PRODUCTS`; `validate_surface` allowlist
    tightening to `install::is_trusted_tag` shape; `PreservedByTag`
    type-design tightening (eliminate `RunRow.marker.expect()`); shared
    `Mode { DryRun, Apply }` extraction across install / uninstall /
    restore / gc (Task 2.2 R-10 inheritance); audit-line emission
    before destructive mutation (Task 2.3 R-3 inheritance);
    retention=0 / retention >> N test coverage; combined
    `--product` × `--surface` test coverage.
- Test count delta on `sympoies/nils-cli` agent-runtime-cli: 259/259 →
  261/261 (added 2 unit tests in the specialist-fix commit) plus 21
  new tests from the feature commit. New `gc_backups` suite: 23/23
  pass (12 unit + 11 integration). Full crate suite: 261/261.
- Sprint 2 is now CLOSED. Current task flips to Sprint 3 Task 3.1
  (`agent-runtime doctor` symlink + managed-block + runtime-roots
  probes). Task 3.1 inherits Task 2.1 F-3 (orphaned-symlink probe) and
  Task 2.4 info-2 (`GcOutcome.mode/retention` doctor consumer).

### 2026-05-21 — Sprint 2 Task 2.3 closed; purge-state body lands

- Sprint 2 Task 2.3 merged at `sympoies/nils-cli` commit `4799169`. Three
  GPG-signed commits: feature `7575b0d` + specialist-fix `088ec06`
  (R-1 stdout discipline + R-2 prompt clarity) + ride-along
  `fca11e3` (silence inherited MD013 regression in
  `code-review-specialist-primitives-plan.md` so GitHub CI's
  required-checks markdown-lint gate could pass).
- New surface area:
  - `agent-runtime purge-state --state-home <abs> --scope <out|backups|all> [--yes]`.
  - Clears writable state under `<state_home>` per the required
    `--scope`; missing or invalid `--scope` exits non-zero with the
    three valid values named in the error.
  - Prompt-on-stdin is the default; `--yes` bypasses the prompt and
    emits one stderr audit line containing the scope and state_home
    BEFORE any filesystem mutation, so the trace lands even on
    partial failure.
  - Symlink at the scope path is refused (`Err(InvalidData)`);
    `fs::remove_dir_all` is the Rust 1.58+ symlink-safe variant; the
    cleared subtree is recreated as an empty dir so subsequent
    install / render calls find a stable `<state_home>` shape.
  - No `--live-home` flag exists, so the command cannot reach a
    runtime home by construction (`auth*`, `history*`, `sessions*`,
    `cache*`, `projects*` all live under the runtime home, not
    `<state_home>`).
- New Rust API: `purge_state::{run, Scope { Out, Backups, All },
  Confirm { Yes, Prompt { reader: &mut dyn BufRead, writer: &mut dyn
  Write } }, PurgeError { Io, Cancelled }, PurgeOutcome { scope,
  cleared: Vec<PathBuf> }}`. `Confirm` is the explicit-injection
  shape so the integration tests can drive both prompt branches
  without spawning a TTY.
- `/code-review-specialists` pass surfaced two low findings, both
  landed pre-merge in commit `088ec06`:
  - R-1 (testing low): added stdout-discipline assertion to
    `scope_out_yes_removes_only_out_subtree_and_emits_audit_line` so a
    future regression that mistakenly printed the audit line to stdout
    cannot slide through.
  - R-2 (red-team low): reworded the confirmation prompt from
    `proceed? [y/N] ` to `type \`y\` or \`yes\` to confirm (anything
    else cancels): ` so the narrow accept-set is unambiguous.
- Thirteen advisory findings deferred (synthesis at
  `~/.local/state/claude-kit/out/task-2-3-review/SYNTHESIS.md`).
  **None above `low` severity** — this is the lowest-risk Plan 04
  task body shipped so far. Notable deferrals:
  - R-3 (security + red-team agreement, low) — `--yes` audit goes
    only to stderr; under cron with `2>/dev/null` no trace persists.
    Sprint 4 candidate: also append a JSON line to
    `<state_home>/audit.log` for durable record-keeping.
  - R-4 (api-contract low) — no `--dry-run` mode. Operators cannot
    preview clear plans. Spec does not require it; Sprint 3 polish.
  - R-5 (api-contract low) — `--scope` is `Option<String>` rather
    than clap's `value_enum`; custom error message covers the actual
    UX gap, but `--help` does not auto-emit the value list.
- Sprint 4 helpers refactor now also inherits from Task 2.3:
  audit-line format string + `Mode` enum absence (purge-state has
  no dry-run) + `Confirm<'a>` lifetime ergonomics. Track alongside
  the install/uninstall/restore helper duplications already on the
  refactor docket.
- Inherited-regression callout: `e642f38` on main added
  `docs/plans/code-review-specialist-primitives/code-review-specialist-primitives-plan.md`
  with 7 lines that fail the strict MD013 lint. PR #424's first CI
  run failed on that file. Resolved by inserting one
  `<!-- markdownlint-disable MD013 -->` comment near the top of
  the offending plan doc (commit `fca11e3`); the long lines are
  inline CLI command examples that fundamentally exceed 140 chars.
  Future PRs against `main` should now pass the markdown gate
  cleanly.
- Next pickup: Sprint 2 Task 2.4 (`agent-runtime gc-backups`),
  blocked-by Task 1.3 (already merged). Task 2.4 inherits Task
  1.3 F-3 (tag-* / entry_id namespace overlap), Task 2.1 F-2
  (LinkMapPlan extraction), and Task 2.2 R-2 / R-3 / R-10 / R-11
  (helper-duplication sweep) as Sprint 4 refactor candidates.

### 2026-05-21 — Sprint 2 Task 2.2 closed; restore-backups body lands

- Sprint 2 Task 2.2 merged at `sympoies/nils-cli` commit `2ae3075`. Two
  GPG-signed commits: feature `a831295` + specialist-fix `e652bdf`.
- New surface area:
  - `agent-runtime restore-backups --product <p> --live-home <abs>
    --state-home <abs> --from <unix-ts|latest> [--source-root <p>]
    [--surface <entry-id>] [--no-overlay | --overlay-path <p>]
    (--dry-run | --apply)`.
  - Walks `<state_home>/backups/<product>/<unix-seconds>/` and reverses
    only the `FileBackedUpThenSymlinked` arm of `install::executor`
    (managed-block surfaces have no per-run snapshot — `uninstall`
    owns them).
  - Each backup file at `<run>/<entry_id>/<basename>` is matched to a
    `PlanAction::Symlink` in a regenerated `InstallPlan` via
    `(entry_id, dest.file_name())`. Exactly-one match → restore;
    zero → `SkippedNoMatch`; multiple → `SkippedAmbiguous`
    (recursive-tree basename collision, since install's
    `move_to_backup` drops the relative subpath).
  - Apply path: if the post-install symlink at `dest` still points at
    the install source, remove it and `fs::rename` (or `fs::copy` +
    `set_permissions` + delete on EXDEV) the backup over it. If the
    symlink points anywhere else (operator retargeted), emit
    `SkippedSymlinkForeign` with `actual_target` + `expected_install_source` — backup preserved.
  - Missing `--from`: print the available timestamp list under
    `<state_home>/backups/<product>/` and exit non-zero.
  - `tag-*` markers at the run root are skipped (positional filter —
    inherits Task 1.3 F-3 namespace overlap; revisit when Task 2.4
    gc-backups lands a canonical helper).
- New Rust API: `restore_backups::{run, RestoreOptions { selector,
  surface, overlay_enabled, overlay_path }, RestoreError { LinkMap,
  Plan, RestorePlan, Apply, NoBackupRun }, RestoreOutcome { plan,
  changes, overlay, backup_run }, BackupRunSelector { Latest,
  Exact(u64) }, list_available_timestamps}`. `RestoreOptions::Default`
  is hand-rolled to keep `overlay_enabled = true` (same defensive
  pattern as Task 1.3's `InstallOptions` and Task 2.1's
  `UninstallOptions`).
- `/code-review-specialists` pass surfaced one material finding,
  landed pre-merge in commit `e652bdf`:
  - R-1 (medium, security + red-team consensus): the original
    executor blindly removed any symlink at `dest`, regressing the
    operator-safety contract `uninstall` already enforces. Resolved
    by threading `expected_install_source: PathBuf` from
    `PlanAction::Symlink.source` through `RestoreAction::RestoreFile`,
    adding a new `RestoredChange::SkippedSymlinkForeign { entry_id,
    dest, actual_target, expected_install_source, from_backup }`,
    and adding both an executor unit test and an integration test
    that pin the operator-retargeted symlink survives. CLI printer
    matches uninstall byte-for-byte:
    `? skip <dest> (foreign target: <actual>; expected: <source>; <entry_id>)`.
- Fourteen advisory findings deferred (synthesis at
  `~/.local/state/claude-kit/out/task-2-2-review/SYNTHESIS.md`):
  - R-2 (maintainability low) — `merge_overlay`, `Mode { DryRun,
    Apply }`, and `ensure_parent_dir` are now duplicated 3x across
    install / uninstall / restore. Roll into the Sprint 4 shared-
    helpers refactor already tracked from Task 2.1 F-2 (LinkMapPlan
    extraction).
  - R-3 (red-team low) — tag-marker filter is positional only
    (top-level files); a hypothetical link-map entry id `tag-foo`
    would be walked as a real entry dir. Inherits Task 1.3 F-3
    namespace overlap; Task 2.4 owns the canonical helper.
  - R-4 (api-contract low) — `--surface <name>` with an unknown
    entry id silently exits 0 with zero restores. UX gap; resolve
    when doctor (Sprint 3) gains a list-available-surfaces probe.
  - R-5 (api-contract low) — `list_available_timestamps` swallows
    IO errors as an empty list. Rename to make the swallow explicit,
    or surface the error; deferred.
  - R-6 (security low) — backup walk trusts arbitrary entry_id
    directory names; defense-in-depth check for `..` / `/` would
    keep malformed backup trees from injecting log path components.
  - R-7 / R-8 / R-9 (testing low/info) — no integration test for
    `SkippedNoMatch` (link-map entry removed between install and
    restore); second-`--apply` idempotence implied by the regular-
    file skip test but not pinned; `--no-overlay` flag has no
    integration coverage (cross-task gap — install / uninstall miss
    it too).
  - R-10 (maintainability info) — `Mode` enum triplicated; lift to
    `crate::common::execution::Mode` during Sprint 4 sweep.
  - R-11 (maintainability info) — `ensure_parent_dir` duplicated
    install ↔ restore; same Sprint 4 sweep.
  - R-12 (red-team info) — `copy_then_remove` partial-failure
    leaves dest restored AND backup file present; gc-backups will
    age the duplicate out. Document the recovery story; no code
    change.
  - R-13 (security info) — TOCTOU between `symlink_metadata` and
    `remove_file`; bounded threat model (single-operator, user-space
    scope), document in module header.
  - R-14 (api-contract info) — `RestorePlanError` is single-variant
    without `#[non_exhaustive]`; apply across all Plan 04 error
    enums in Sprint 4 release prep.
  - R-15 (performance info) — `walk_backup_dir` is O(M*N) candidate
    matching; M and N both <100 for current link-maps, pinned as
    bounded.
- Cross-task inheritance reminder: Task 2.4 (gc-backups) now
  inherits Task 1.3 F-3 (tag-marker / entry_id namespace overlap),
  Task 2.1 F-2 (LinkMapPlan extraction), and Task 2.2 R-2 / R-3
  / R-10 / R-11 (helper-duplication sweep). Sprint 3 Task 3.1
  doctor inherits Task 2.1 F-3 (orphaned-symlink probe).
- Next pickup: Sprint 2 Task 2.3 (`agent-runtime purge-state`),
  no upstream dependencies.

### 2026-05-21 — Sprint 2 Task 2.1 closed; uninstall body lands

- Sprint 2 Task 2.1 merged at `sympoies/nils-cli` commit `6bf6102`. Two
  GPG-signed commits: feature `41f85c1` + specialist-fix `556b841`.
- New surface area:
  - `agent-runtime uninstall --product <p> --live-home <abs> [--source-root
    <p>] [--no-overlay | --overlay-path <p>] (--dry-run | --apply)`.
  - Reverses the same link-map artifacts the installer placed: symlinks
    only when `read_link(dest) == expected_source`; managed-block
    surfaces via the Task 1.1 helper's `ManagedBlock::remove` (bytes
    outside the marker pair preserved verbatim).
  - Idempotent: second uninstall on a clean home walks every action,
    sees the destination is already absent or already free of the
    managed block, emits `NoOp` for each, exits 0 without mutating the
    filesystem.
  - Foreign symlinks (operator repointed) → `SymlinkSkippedForeign`,
    not deleted. Regular files at install destinations →
    `SymlinkSkippedRegularFile`, not deleted (restore-backups owns that
    territory).
  - Never reads or writes `<state_home>/backups/` — `uninstall::run`
    has no `state_home` parameter at all. Never touches `auth*` /
    `history*` / `sessions*` / `cache*` / `projects*` under the runtime
    home (link-map references none of those trees).
- New Rust API: `uninstall::{run, UninstallOptions { overlay_enabled,
  overlay_path }, UninstallError, UninstallOutcome { plan, changes,
  overlay }}`. `UninstallOptions::Default` is hand-rolled to keep
  `overlay_enabled = true` (same defensive pattern as Task 1.3's
  `InstallOptions` — `derive(Default)` would silently flip overlay off).
- `/code-review-specialists` pass surfaced one material finding, landed
  pre-merge in commit `556b841`:
  - F-1 (medium, red-team): `SymlinkSkippedForeign` printer lacked the
    `expected_source` the executor was comparing against, so an
    operator who rebased their kit checkout had no recovery context.
    Resolved by threading `expected_source: PathBuf` through the
    change variant + CLI printer + new integration assertion in
    `foreign_symlink_at_install_dest_is_skipped`. The printer now
    emits `? skip <dest> (foreign target: <actual>; expected: <source>; <entry_id>)`.
- Thirteen advisory findings deferred (synthesis at
  `~/.local/state/claude-kit/out/task-2-1-review/SYNTHESIS.md`):
  - F-2 (api-contract low) — `InstallPlan::build` is called with an
    empty `state_home` placeholder. Sprint 4 candidate: extract a
    `LinkMapPlan` that drops state_home so doctor and uninstall do not
    have to thread a stub.
  - F-3 (red-team low) — uninstall cannot detect orphaned link-map
    artifacts when the link-map shrinks between install and uninstall.
    Long-term home: Sprint 3 Task 3.1 doctor must walk the runtime
    home for `agent-runtime-kit`-shaped symlinks absent from the
    current link-map.
  - F-4 (security low) — managed-block uninstall follows symlinks at
    `config_file` via `fs::read_to_string`. Symmetric with install;
    optional `fs::symlink_metadata` gate in Sprint 4 if architectural
    sign-off lands.
  - F-5 (red-team low) — source_root deletion between install and
    uninstall blocks uninstall entirely (`PlanError::MissingSource`).
    Symmetric with install; Sprint 4 restore-backups may need a
    'force-uninstall-by-installed-marker' mode.
  - F-6 / F-7 / F-8 (testing info) — no integration test for
    `--no-overlay` skipping overlay-discovered entries on uninstall;
    unbalanced managed-block markers not integration-tested;
    regular-file-at-dest skip is unit-tested but not integration-tested.
  - F-9 (maintainability info) — `uninstall::executor::ApplyError`
    shares its name with `install::executor::ApplyError`. Symmetry
    intentional; revisit in Sprint 3.
  - F-10 (maintainability info) — `UninstallOptions::Default` hand-roll
    pairs with Task 1.3 F-7. Move both sites in lockstep if a future
    sprint refactors to a builder.
  - F-11 / F-12 (security info) — `overlay_path` library trust mirrors
    Task 1.3; byte-for-byte symlink target compare is the fail-safe
    direction (no canonicalisation).
  - F-13 / F-14 (api-contract info) — `UninstallError` shape parity
    with `InstallError`; CLI surface drops `--state-home` and `--tag`
    by design.
- Next pickup: Sprint 2 Task 2.2 (`agent-runtime restore-backups`),
  blocked-by Task 2.1 — now cleared.

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
