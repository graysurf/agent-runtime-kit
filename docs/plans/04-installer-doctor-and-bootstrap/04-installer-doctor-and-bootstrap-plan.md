# Plan: Phase 3 — Installer, Doctor, and Host Bootstrap

## Overview

Phase 3 turns the reporting POC (Plan 03) into a real installer. Sprint 1
lands the `agent-runtime install` body in nils-cli (render → link →
managed-block sync → backup) with `--dry-run` / `--apply` / `--live-home`
/ `--tag` flags. Sprint 2 lands the lifecycle siblings (`uninstall`,
`restore-backups`, `purge-state`, `gc-backups`). Sprint 3 lands the
read-only `agent-runtime doctor` (symlink + managed-block integrity,
runtime-roots resolution, 5-status version probes, `--suggest-upgrade`,
`--check-project`). Sprint 4 extends `audit-drift` with the composite
`unsafe` score plus `intentional-difference` and `extra` finding classes
and cuts the `0.2.0` release across nils-cli and homebrew-tap. Sprint 5
returns to agent-runtime-kit to fill `scripts/setup.sh`, add the sandbox
install rehearsal harness, and wire CI gate position 6.

## Read First

- Primary source: docs/plans/04-installer-doctor-and-bootstrap/04-installer-doctor-and-bootstrap-discussion-source.md
- Source type: discussion-to-implementation-doc
- Open questions carried into execution:
  - `--live-home` path handling: should the flag accept relative paths or require absolute? Recommended default: absolute, reject relative with a usage error.
  - Sandbox rehearsal depth: should it exercise `--apply` against a tmp dir or stop at dry-run + `--list-skills` diff? Recommended default: stop at list-skills until product CLIs accept `--home <dir>`.
  - Doctor's runtime-roots probe under WSL: does `AGENT_RUNTIME_HOST_PROFILE` already cover Linuxbrew-on-WSL detection, or is a dedicated WSL profile required? Defer to integration verification on a real WSL host before Sprint 3 ships.

## Scope

- In scope:
  - `agent-runtime install` body in nils-cli (`crates/agent-runtime-cli/src/install.rs`) with the render → link → managed-block sync → backup pipeline.
  - Managed-block helper module enforcing paired markers and `--force` re-add semantics.
  - Lifecycle siblings: `uninstall`, `restore-backups`, `purge-state`, `gc-backups` subcommands in nils-cli.
  - `agent-runtime doctor` body with the 5-status version probe (`ok` / `recommended-only` / `warn` / `outdated` / `unparseable`), `--suggest-upgrade`, `--check-project`.
  - `audit-drift` extension: composite `unsafe` score (path 0.4 + keyword 0.4 + entropy 0.4) plus `intentional-difference` and `extra` finding classes, `drift-audit.allow.yaml` allowlist schema.
  - `0.2.0` workspace bump in nils-cli, release tag, formula bump in `sympoies/homebrew-tap`.
  - `scripts/setup.sh` body in agent-runtime-kit (7-step brew-first bootstrap with `--skip-*` flags).
  - `tests/sandbox/<product>/expected-skills.txt` pins for codex and claude, plus the CI gate at position 6.
  - `required_clis` floor bumps to `">=0.2.0"` for skills calling the new subcommands.
- Out of scope:
  - Migrating additional domains beyond the Plan 03 pilot — deferred to Plan 05.
  - `--apply`-against-tmp sandbox rehearsal — blocked on product CLIs accepting `--home <dir>`.
  - Adding a fourth overlay surface beyond `.private/` and `profile.recommended.yaml`.
  - Mutating auth / history / session / cache paths from any new subcommand.

## Assumptions

1. Plan 03 (`03-reporting-poc`) is merged and `manifests/skills.yaml` carries at least one populated domain (`reporting`) the sandbox rehearsal can diff against.
2. The Bump Ceremony PR template added in Plan 01 Sprint 1 is the destination for `doctor --suggest-upgrade` output; format compatibility is verified during Sprint 3 implementation.
3. The `agent-runtime` binary skeleton from Plan 01 Sprint 3 is already on PATH via brew (the existing `0.1.0` formula); this plan replaces its stubbed bodies, not the binary itself.
4. `audit-drift` already emits `missing` and `stale` findings from Plan 03's drift work; Sprint 4 adds the three remaining classes without rewriting the existing classifier.
5. Backup retention is enforced exclusively by the dedicated `gc-backups` subcommand — `install` never prunes silently.
6. The render pipeline shipped in Plan 02 produces byte-identical `build/` output for the same manifest commit (Resolved Decision #9); the installer can trust render output without re-validating determinism.

## Sprint 1: `agent-runtime install` body

**Goal**: Land the render → link → managed-block sync → backup install pipeline in nils-cli with `--dry-run` / `--apply` / `--live-home` / `--tag` flags and overlay merge support.

**Demo/Validation**:

- Command(s):
  - `cargo test -p agent-runtime-cli install`
  - `agent-runtime install --product claude --live-home /tmp/claude-sandbox --dry-run`
  - `agent-runtime install --product codex --live-home /tmp/codex-sandbox --dry-run`
- Verify:
  - Dry-run prints a deterministic plan including the resolved post-overlay-merge effective config.
  - `--apply` links approved files, syncs managed blocks, and backs up replaced originals to `<state_home>/backups/<product>/<timestamp>-<surface>/`.
  - `--live-home /tmp/...` redirects all writes to the sandbox path; the developer's real `~/.claude` / `~/.codex` are not touched.
  - Re-running `--apply` is a no-op (idempotent).

**PR grouping intent**: `group`
**Execution Profile**: `serial`

### Task 1.1: Implement managed-block helper module

- **Location**:
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/src/managed_block.rs
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/tests/integration/managed_block.rs
- **Description**: Implement a helper module that owns the paired-marker contract (`# >>> agent-runtime-kit:<surface> >>>` and `# <<< agent-runtime-kit:<surface> <<<`). The module exposes `read_block`, `write_block`, and `remove_block` operations. Outside the marker pair, the file is preserved byte-for-byte. Detect missing or unbalanced markers and refuse to re-add a managed block without `--force`. Cover both Codex `config.toml` (TOML-comment markers) and Claude `settings.json` (JSON-comment-safe wrapper) surfaces. Include round-trip property tests verifying that idempotent re-writes do not perturb unmanaged bytes.
- **Dependencies**:
  - none
- **Complexity**: 6
- **Acceptance criteria**:
  - Reading a file with a complete marker pair returns the inner content.
  - Writing a block into a file that has the markers replaces only the inner content; bytes outside the markers compare byte-for-byte against the input.
  - Writing into a file without markers refuses without `--force` and returns a typed error naming the surface.
  - Detecting an unbalanced marker pair (one side present, the other missing) refuses and returns a typed error.
  - Property test: random unmanaged payload + random managed payload → write + write again is identical to write once.
- **Validation**:
  - `cargo test -p agent-runtime-cli managed_block`

### Task 1.2: Wire render → link → managed-block sync pipeline

- **Location**:
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/src/install.rs
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/src/install/plan.rs
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/tests/integration/install_pipeline.rs
- **Description**: Replace the Plan 01 `0.12.0` stub. Build the install plan by reading `manifests/runtime-roots.yaml` and the product's `targets/<product>/link-map.yaml`, applying overlay merge (deep-merge for runtime-roots, per-entry replace for link-map, profile-level for cli-tools), then enumerating the surfaces: symlinked files, managed-block edits, and backed-up originals. Emit the plan as a deterministic struct that both the dry-run printer and the apply executor consume. `--apply` walks the plan, writes symlinks, calls the Task 1.1 helper for managed blocks, and copies replaced originals to `<state_home>/backups/<product>/<timestamp>-<surface>/`. `--apply` is idempotent — a second run produces no changes.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 8
- **Acceptance criteria**:
  - `--dry-run` prints the resolved effective config (post overlay merge) plus the planned symlink, managed-block, and backup actions.
  - `--apply` writes symlinks for every entry in the link map and backs up any pre-existing non-symlink target.
  - Re-running `--apply` against a clean install produces zero file mutations.
  - Existing files at a target path are copied to the timestamped backup directory before the symlink replaces them.
  - Integration test asserts byte-identical idempotence on the second `--apply`.
- **Validation**:
  - `cargo test -p agent-runtime-cli install_pipeline`

### Task 1.3: Add `--live-home`, `--tag`, and overlay merge flags

- **Location**:
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/src/cli.rs
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/src/install.rs
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/tests/integration/install_flags.rs
- **Description**: Add `--live-home <path>` (absolute path required; reject relative with a usage error pointing to the open-question default), `--tag <name>` (tags the backup directory so `gc-backups` skips it), and ensure overlay merge runs before plan generation. `--live-home` redirects every write (symlink targets, managed-block files, backup paths) to the sandbox; nothing under the developer's real `~/.claude` / `~/.codex` is touched. `--tag` adds a `tag-<name>` marker file inside the backup directory.
- **Dependencies**:
  - Task 1.2
- **Complexity**: 5
- **Acceptance criteria**:
  - `--live-home ./relative-path` exits non-zero with a usage error naming the flag.
  - `--live-home /tmp/claude-sandbox --apply` writes only under `/tmp/claude-sandbox` and the configured `state_home` (verified by file-tree assertion).
  - `--tag pre-bump` writes a tag marker into the backup directory; `gc-backups` (Task 2.4) is documented to honor it.
  - Integration test covers all three flags and the relative-path rejection.
- **Validation**:
  - `cargo test -p agent-runtime-cli install_flags`

## Sprint 2: Lifecycle siblings

**Goal**: Ship the four lifecycle siblings (`uninstall`, `restore-backups`, `purge-state`, `gc-backups`) so install mistakes have clean, scoped recovery without ever touching auth / history / sessions.

**Demo/Validation**:

- Command(s):
  - `cargo test -p agent-runtime-cli lifecycle`
  - `agent-runtime uninstall --product claude --live-home /tmp/claude-sandbox --dry-run`
  - `agent-runtime restore-backups --product claude --from latest --live-home /tmp/claude-sandbox --dry-run`
  - `agent-runtime purge-state --scope out --dry-run`
  - `agent-runtime gc-backups --product claude --dry-run`
- Verify:
  - Uninstall is idempotent and never reaches outside the install map.
  - `restore-backups --from latest` reverses the most recent install for the named product.
  - `purge-state` requires `--scope` and prompts unless `--yes` is set.
  - `gc-backups` enforces the 5-run retention default and respects `--tag`-marked directories.

**PR grouping intent**: `group`
**Execution Profile**: `serial`

### Task 2.1: Implement `agent-runtime uninstall`

- **Location**:
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/src/uninstall.rs
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/tests/integration/uninstall.rs
- **Description**: Remove only the symlinks and managed blocks the current install map owns. Backups, runtime state, secrets, auth, history, and sessions are never touched. Uninstall is idempotent — running it twice on a clean home is a no-op, not an error. Restoring previously-replaced files is delegated to `restore-backups`; do not invoke restore from uninstall.
- **Dependencies**:
  - Task 1.2
- **Complexity**: 5
- **Acceptance criteria**:
  - After `install --apply` then `uninstall --apply`, every symlink owned by the link map is gone and every managed block has been removed via the Task 1.1 helper.
  - Backup directories remain untouched after uninstall.
  - Running uninstall against a home that has no install present exits 0 with no mutations.
  - Integration test asserts uninstall does not touch any path under `auth*`, `history*`, `sessions*`, `cache*`, or `projects*` under the sandbox home.
- **Validation**:
  - `cargo test -p agent-runtime-cli uninstall`

### Task 2.2: Implement `agent-runtime restore-backups`

- **Location**:
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/src/restore_backups.rs
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/tests/integration/restore_backups.rs
- **Description**: Restore the named backup of any pre-existing file the installer replaced. `--from <timestamp>|latest` is required; running without it exits non-zero with a list of available timestamps. Supports `--product codex|claude` and `--surface <name>` (both default to "all owned by the install map"). `--dry-run` prints planned restores; `--apply` performs them. Re-applies the original file mode and ownership where possible.
- **Dependencies**:
  - Task 2.1
- **Complexity**: 6
- **Acceptance criteria**:
  - Calling without `--from` exits non-zero and prints the available timestamp list.
  - `--from latest --apply` restores the most recent backup's files into their original install-target paths.
  - `--surface <name>` restricts restore to that surface only; other surfaces remain at their post-install state.
  - `--dry-run` produces zero file mutations.
  - Integration test exercises a write → install → re-install → restore round trip.
- **Validation**:
  - `cargo test -p agent-runtime-cli restore_backups`

### Task 2.3: Implement `agent-runtime purge-state`

- **Location**:
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/src/purge_state.rs
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/tests/integration/purge_state.rs
- **Description**: Remove writable state under `<state_home>`. `--scope out|backups|all` is required and never defaults. Always prompts for confirmation unless `--yes` is set; `--yes` is reserved for CI / scripted contexts and is logged to stderr. Does not touch product runtime homes, auth, history, or sessions. `out` clears runtime artifacts only; `backups` clears backup directories only; `all` does both.
- **Dependencies**:
  - none
- **Complexity**: 4
- **Acceptance criteria**:
  - Calling without `--scope` exits non-zero with a usage error naming the three valid scope values.
  - `--scope out --yes` removes everything under `<state_home>/out/` and nothing else.
  - `--scope backups --yes` removes everything under `<state_home>/backups/` and nothing else.
  - `--yes` use is recorded to stderr in a single audit line containing the scope value.
  - Confirmation prompt is exercised in a non-TTY-disabled mode in the integration test.
- **Validation**:
  - `cargo test -p agent-runtime-cli purge_state`

### Task 2.4: Implement `agent-runtime gc-backups`

- **Location**:
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/src/gc_backups.rs
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/tests/integration/gc_backups.rs
- **Description**: Prune aged backups beyond the retention default of 5 install runs per surface. `--retention <N>` overrides the default. `--tag`-marked directories are preserved regardless of retention. Supports `--product codex|claude` (default both) and `--surface <name>` (default all). `--dry-run` prints planned deletions; `--apply` performs them. `install` never prunes silently — gc-backups is the only retention enforcer.
- **Dependencies**:
  - Task 1.3
- **Complexity**: 4
- **Acceptance criteria**:
  - After 7 install runs against a single surface, `gc-backups --apply` retains exactly 5 directories (the 5 most recent timestamps).
  - A backup directory created with `install --tag pre-bump` is preserved even when it falls outside the retention window.
  - `--retention 3 --apply` retains exactly 3 directories per surface.
  - `--dry-run` produces zero file mutations.
- **Validation**:
  - `cargo test -p agent-runtime-cli gc_backups`

## Sprint 3: `agent-runtime doctor`

**Goal**: Land the read-only `agent-runtime doctor` body: symlink + managed-block integrity, runtime-roots resolution, 5-status version probes, `--suggest-upgrade`, nils-cli + cli-tools coverage, `--check-project` overlay inspection.

**Demo/Validation**:

- Command(s):
  - `cargo test -p agent-runtime-cli doctor`
  - `agent-runtime doctor --product claude --live-home /tmp/claude-sandbox`
  - `agent-runtime doctor --suggest-upgrade --product claude --live-home /tmp/claude-sandbox`
  - `agent-runtime doctor --check-project ~/Project/graysurf/agent-runtime-kit`
- Verify:
  - Doctor reports each check listed in `## Install And Link Strategy` `### Doctor Checks`.
  - Exit codes match the contract: `0` clean, `1` warnings only, `2` blocking issues.
  - `--suggest-upgrade` prints copy-pasteable `brew upgrade <formula>` lines for every probed binary.
  - Doctor never mutates any file.

**PR grouping intent**: `group`
**Execution Profile**: `serial`

### Task 3.1: Symlink + managed-block + runtime-roots probes

- **Location**:
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/src/doctor.rs
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/src/doctor/probes.rs
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/tests/integration/doctor_filesystem.rs
- **Description**: Implement the filesystem-level probes: every link map entry exists and points to a tracked source file; managed-block markers in product config files are paired (unbalanced markers report as blocking); runtime-roots paths exist and are readable. Each probe emits a typed finding with severity (`ok` / `warn` / `block`). The aggregator counts severities and computes the exit code (`0` / `1` / `2`).
- **Dependencies**:
  - Task 1.2
  - Task 2.1
- **Complexity**: 6
- **Acceptance criteria**:
  - Breaking a tracked symlink in a sandbox home produces a blocking finding and exit `2`.
  - Removing one half of a managed-block marker pair produces a blocking finding and exit `2`.
  - A missing `state_home` directory produces a warn finding and exit `1`.
  - A clean install on a sandbox home produces zero findings and exit `0`.
- **Validation**:
  - `cargo test -p agent-runtime-cli doctor_filesystem`

### Task 3.2: Version probes with 5-status output

- **Location**:
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/src/doctor/version.rs
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/tests/integration/doctor_version.rs
- **Description**: Implement the product version probe. Run each product's `version_probe` command from `runtime-roots.yaml`, parse the output with a permissive semver matcher that tolerates product-specific prefixes (e.g. `codex 0.18.2 (build abc1234)`). Compare the parsed version against `min_version`, `recommended_version`, and `min_version_effective_from`. Emit one of five status values per product: `ok`, `recommended-only`, `warn`, `outdated`, `unparseable`. Only `outdated` (when `min_version_effective_from` has passed) is blocking. `unparseable` is fail-open with a loud warning, never a silent pass.
- **Dependencies**:
  - Task 3.1
- **Complexity**: 7
- **Acceptance criteria**:
  - A version above `recommended_version` reports `ok`.
  - A version at or above `min_version` but below `recommended_version` reports `recommended-only`.
  - A version below `min_version` before `min_version_effective_from` reports `warn` and exits `1`.
  - A version below `min_version` on or after `min_version_effective_from` reports `outdated` and exits `2`.
  - Version output that fails to parse reports `unparseable` and exits `1` with the raw output captured in the finding.
- **Validation**:
  - `cargo test -p agent-runtime-cli doctor_version`

### Task 3.3: `--suggest-upgrade`, `--check-project`, and CLI coverage probes

- **Location**:
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/src/doctor/upgrade.rs
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/src/doctor/project.rs
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/src/doctor/coverage.rs
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/tests/integration/doctor_upgrade.rs
- **Description**: Implement `--suggest-upgrade` (read-only — never executes the upgrade) printing `brew upgrade <formula>` commands for product CLIs, every `required_clis` nils-cli binary, and every cli-tools catalog entry that is below its declared `recommended_version` / latest formula. Implement `--check-project <path>` to inspect a consuming repo's `.agents/scripts/` overlay coverage. Add coverage probes for nils-cli binaries (every `required_clis` entry across tracked skills) and `manifests/cli-tools.yaml` formulas (filtered by active profile).
- **Dependencies**:
  - Task 3.2
- **Complexity**: 6
- **Acceptance criteria**:
  - `--suggest-upgrade` emits copy-pasteable `brew upgrade <formula>` lines and never mutates state.
  - `--check-project <path>` reads the target repo's `.agents/scripts/` directory and reports missing-overlay findings.
  - A missing `required_clis` binary reports `missing` and exits `2`; an outdated one reports `outdated` and exits `1`.
  - Integration test confirms `--suggest-upgrade` output matches the Bump Ceremony PR template fields (one `brew upgrade <formula>` line per formula on its own line).
- **Validation**:
  - `cargo test -p agent-runtime-cli doctor_upgrade`

## Sprint 4: Audit-drift remaining classes + `0.2.0` release

**Goal**: Extend `audit-drift` with the composite `unsafe` score plus `intentional-difference` and `extra` classes, ship the allowlist schema, tag the `0.2.0` nils-cli release, and bump the homebrew-tap formula.

**Demo/Validation**:

- Command(s):
  - `cargo test -p agent-runtime-cli audit_drift::unsafe_score`
  - `cargo test -p agent-runtime-cli audit_drift::classes`
  - `cargo test --workspace` (nils-cli)
  - `git tag v0.2.0 && git push origin v0.2.0` (nils-cli; performed by the release task)
  - `brew install --build-from-source sympoies/tap/nils-cli` (post formula bump)
- Verify:
  - Composite score 0.8 → block, 0.4..0.8 → warn, <0.4 → suppressed.
  - Allowlist entries demote by exactly one tier.
  - `intentional-difference` and `extra` classes round-trip through fixture tests.
  - `0.2.0` release tag is reachable via brew tap.

**PR grouping intent**: `group`
**Execution Profile**: `serial`

### Task 4.1: Implement composite `unsafe` scoring

- **Location**:
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/src/audit_drift/unsafe_score.rs
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/tests/integration/audit_drift_unsafe_score.rs
- **Description**: Implement the three signals (path_match, keyword_prefix, entropy_above_threshold) with weights 0.4 each as a new module inside the existing `audit_drift` module tree (audit-drift is not a standalone crate; it lives at `crates/agent-runtime-cli/src/audit_drift/`). Sum signals per finding and apply thresholds: `>= 0.8` → block, `0.4..0.8` → warn, `< 0.4` → suppressed (visible only with `--verbose`). Path patterns include `**/auth.json`, `**/.credentials*`, `**/sessions/**`. Keywords include `token`, `api_key`, `password`, `bearer`, `secret`, `private_key` (case-insensitive). Entropy uses Shannon entropy ≥ 4.0 bits/byte over a contiguous ≥ 24-char run on the same line.
- **Dependencies**:
  - none
- **Complexity**: 7
- **Acceptance criteria**:
  - A `**/auth.json` path with a `token: <high-entropy>` line scores 1.2 and reports `block`.
  - A path-only match scores 0.4 and reports `warn`.
  - An entropy-only match in a non-sensitive path scores 0.4 and reports `warn`.
  - A keyword without a value-shaped token nearby scores < 0.4 and reports `suppressed`.
  - Fixture tests cover all three signal combinations and the three disposition tiers.
- **Validation**:
  - `cargo test -p agent-runtime-cli audit_drift::unsafe_score`

### Task 4.2: Implement `drift-audit.allow.yaml` allowlist

- **Location**:
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/src/audit_drift/allowlist.rs
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/tests/integration/audit_drift_allowlist.rs
- **Description**: Read `drift-audit.allow.yaml` (top-level) for the schema `{ schema_version: 1, unsafe_allow: [{ path: <glob>, reason: <text> }, ...] }` as a new sibling module under `audit_drift/`. Each entry requires both `path` and `reason`; missing `reason` is a schema error. Allowlist matches demote a finding by exactly one tier (`block` → `warn`, `warn` → `suppressed`). Allowlist never silences a finding outright. Putting `unsafe` allowances in `.private/` is intentionally not supported and rejected at config-load time.
- **Dependencies**:
  - Task 4.1
- **Complexity**: 5
- **Acceptance criteria**:
  - A `block` finding under `tests/drift/fixtures/**` with an allowlist entry is reported as `warn`.
  - A `warn` finding with an allowlist entry is reported as `suppressed`.
  - An allowlist entry without `reason` exits non-zero at audit start with a schema error.
  - An allowlist file under `.private/` is rejected at config-load time.
- **Validation**:
  - `cargo test -p agent-runtime-cli audit_drift::allowlist`

### Task 4.3: Implement `intentional-difference` and `extra` finding classes

- **Location**:
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/src/audit_drift/classes/intentional.rs
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/src/audit_drift/classes/extra.rs
  - ~/Project/sympoies/nils-cli/crates/agent-runtime-cli/tests/integration/audit_drift_extra_intentional.rs
- **Description**: `intentional-difference` reads documented divergences from `manifests/product-capabilities.yaml` and reports the differing surface as informational (exit 0). `extra` reports a live surface that exists in the runtime home but is not tracked in the install map (default: `warn`). Both classes flow through the same finding pipeline as `missing` / `stale` / `unsafe` and respect the allowlist. Both ship as new `classes/` submodules under the existing `audit_drift` module tree.
- **Dependencies**:
  - Task 4.2
- **Complexity**: 5
- **Acceptance criteria**:
  - A surface present in `product-capabilities.yaml` divergence list reports `intentional-difference` and does not affect the exit code.
  - An untracked file in `~/.claude` outside the install map reports `extra` and exits `1`.
  - Fixture tests pin both classes' text reports and exit codes.
- **Validation**:
  - `cargo test -p agent-runtime-cli audit_drift::classes`

### Task 4.4: Cut `0.2.0` release and bump formula

- **Location**:
  - ~/Project/sympoies/nils-cli/Cargo.toml
  - ~/Project/sympoies/nils-cli/CHANGELOG.md
  - ~/Project/sympoies/homebrew-tap/Formula/nils-cli.rb
- **Description**: Bump the nils-cli workspace version to `0.2.0`, create `CHANGELOG.md` (the file does not exist yet — add only the `0.2.0` entry covering install / uninstall / restore-backups / purge-state / gc-backups / doctor / audit-drift; do not retro-fill earlier releases, point to "Earlier releases: see GitHub Releases" as a single line), push the annotated tag `v0.2.0`, wait for the release pipeline, then bump the homebrew-tap formula's `url` / `sha256` to the new release artifact. Follow the Bump Ceremony PR template from Plan 01 Sprint 1.
- **Dependencies**:
  - Task 4.3
- **Complexity**: 4
- **Acceptance criteria**:
  - `cargo metadata --format-version 1` reports the workspace at `0.2.0`.
  - `git tag --list v0.2.0` returns the tag and it is reachable from `main`.
  - `brew install sympoies/tap/nils-cli` resolves to the new release artifact and installs cleanly on a fresh host.
  - The Bump Ceremony PR contains the `doctor --suggest-upgrade` output for the version bump.
- **Validation**:
  - `cargo test --workspace`
  - `brew install --build-from-source sympoies/tap/nils-cli`

## Sprint 5: Host bootstrap + sandbox rehearsal

**Goal**: Fill `scripts/setup.sh` body in agent-runtime-kit, pin per-product `expected-skills.txt`, wire CI gate position 6, and bump `required_clis` floors to `">=0.2.0"` for skills that use the new subcommands.

**Demo/Validation**:

- Command(s):
  - `bash -n scripts/setup.sh`
  - `bash scripts/ci/sandbox-install-rehearsal.sh`
  - `bash scripts/ci/all.sh`
- Verify:
  - `setup.sh` runs the full 7-step brew-first bootstrap end-to-end against a clean host; `--skip-*` flags short-circuit CI-irrelevant steps.
  - Sandbox rehearsal performs `install --dry-run --live-home /tmp/<product>-sandbox` and diffs `--list-skills` output against the pinned `expected-skills.txt`.
  - CI gate position 6 runs the sandbox rehearsal after `audit-drift` (position 5).

**PR grouping intent**: `group`
**Execution Profile**: `serial`

### Task 5.1: Fill `scripts/setup.sh` body

- **Location**:
  - scripts/setup.sh
- **Description**: Replace the Plan 01 skeleton with the full 7-step sequence: (1) install Homebrew if missing (`--skip-homebrew-install` bypasses), (2) `brew tap sympoies/tap`, (3) `brew install nils-cli` or `brew upgrade nils-cli`, (4) read `manifests/cli-tools.yaml` filtered by `--profile core|recommended|full` and install third-party CLIs (`--skip-cli-tools` bypasses), (5) clone agent-runtime-kit into `$HOME/.config/agent-runtime-kit` if missing, (6) `agent-runtime install --product claude` and `--product codex`, (7) `agent-runtime doctor` and print a one-screen summary. Detect brew prefix via `brew --prefix` so the same script works on macOS and Linuxbrew. Print missing-tool list and exit non-zero rather than guessing when a tool is unavailable.
- **Dependencies**:
  - Task 4.4
- **Complexity**: 6
- **Acceptance criteria**:
  - `bash -n scripts/setup.sh` parses cleanly.
  - Running with `--skip-homebrew-install --skip-cli-tools --dry-run` walks every other step without making changes.
  - Running against a clean macOS host taps, installs, clones, installs both products, and runs doctor; final exit code matches `doctor`'s exit code.
  - `brew --prefix` is the only prefix source — no hard-coded `/opt/homebrew` or `/home/linuxbrew/.linuxbrew`.
- **Validation**:
  - `bash -n scripts/setup.sh`
  - `bash scripts/setup.sh --skip-homebrew-install --skip-cli-tools --dry-run`

### Task 5.2: Add `tests/sandbox/<product>/expected-skills.txt` pins

- **Location**:
  - tests/sandbox/claude/expected-skills.txt
  - tests/sandbox/codex/expected-skills.txt
- **Description**: Generate the pinned `expected-skills.txt` for both products by running `agent-runtime install --product <p> --live-home /tmp/<p>-sandbox --dry-run` against the Plan 03 reporting domain plus any other populated domain in `manifests/skills.yaml`, then committing the resulting skill list (one canonical id per line, sorted). The file is updated explicitly on every domain migration — never auto-generated in CI.
- **Dependencies**:
  - Task 4.4
- **Complexity**: 3
- **Acceptance criteria**:
  - `tests/sandbox/claude/expected-skills.txt` exists and contains one canonical skill id per line, sorted.
  - `tests/sandbox/codex/expected-skills.txt` exists with the same shape.
  - The pinned content matches the Plan 03 reporting domain's skill set exactly.
  - No empty lines, no blank trailing line beyond the single terminating newline.
- **Validation**:
  - `test -s tests/sandbox/claude/expected-skills.txt`
  - `test -s tests/sandbox/codex/expected-skills.txt`

### Task 5.3: Add CI gate position 6 sandbox install rehearsal

- **Location**:
  - scripts/ci/sandbox-install-rehearsal.sh
  - scripts/ci/all.sh
- **Description**: Add the sandbox rehearsal script: for each product, run `agent-runtime install --product <p> --live-home /tmp/<p>-sandbox --dry-run`, capture the skill list (until product CLIs accept `--home <dir>`, this is the dry-run `--list-skills` path per the open question), and `diff` against `tests/sandbox/<p>/expected-skills.txt`. Add the script to `scripts/ci/all.sh` at position 6 (after position 5 `audit-drift`). Document the position in a comment.
- **Dependencies**:
  - Task 5.2
- **Complexity**: 4
- **Acceptance criteria**:
  - `bash scripts/ci/sandbox-install-rehearsal.sh` exits 0 when the pinned expected-skills match the dry-run output for both products.
  - A modified `expected-skills.txt` that no longer matches the dry-run output causes the script to exit non-zero with a diff.
  - `scripts/ci/all.sh` invokes the new script at position 6 and propagates its exit code.
- **Validation**:
  - `bash scripts/ci/sandbox-install-rehearsal.sh`
  - `bash scripts/ci/all.sh`

### Task 5.4: Bump `required_clis` floors to `">=0.2.0"`

- **Location**:
  - manifests/skills.yaml
- **Description**: For every skill in `manifests/skills.yaml` that calls `restore-backups`, `purge-state`, `gc-backups`, or any new doctor flag added in Sprint 3, set its `required_clis` floor for `agent-runtime` (or the nils-cli binary that exposes the subcommand) to `">=0.2.0"`. Leave unaffected skills at their existing floors. Audit the change with a `git grep "required_clis" manifests/` review pass.
- **Dependencies**:
  - Task 4.4
- **Complexity**: 2
- **Acceptance criteria**:
  - Every skill that names one of the new subcommands carries `">=0.2.0"` for the relevant binary in `required_clis`.
  - Skills that do not name new subcommands keep their existing floors.
  - A schema validation run accepts the updated manifest.
- **Validation**:
  - `git grep -nE "(restore-backups|purge-state|gc-backups)" manifests/skills.yaml`
  - `bash scripts/ci/all.sh`

## Testing Strategy

- Unit: in-tree tests for managed-block helper, install plan struct, overlay merge, version-probe parser, and audit-drift scoring signals.
- Integration: per-task `tests/integration/` files in nils-cli for install pipeline, uninstall, restore-backups, purge-state, gc-backups, each doctor probe family, and the three new audit-drift classes.
- Cross-repo: `cargo test --workspace` in nils-cli after each sprint; `cargo test -p agent-runtime-cli audit_drift::unsafe_score` is the focused gate for Sprint 4.
- In-repo: `bash -n scripts/setup.sh`, `bash scripts/ci/sandbox-install-rehearsal.sh`, and the full `bash scripts/ci/all.sh` gate stack after Sprint 5.
- Sandbox: end-to-end `agent-runtime install --product <p> --live-home /tmp/<p>-sandbox --dry-run` round trip plus `doctor` on the sandbox home.

## Risks & gotchas

- `--live-home` accepting relative paths would silently write into the cwd. The open-question default is "reject relative" — implementation must enforce it from day one, not as a follow-up.
- Sandbox rehearsal cannot exercise `--apply` until Codex CLI and Claude CLI accept `--home <dir>`. Stop at dry-run + skill-list diff; revisit when either ships the flag.
- Doctor's runtime-roots probe under WSL is unverified. The `AGENT_RUNTIME_HOST_PROFILE` env var may already cover Linuxbrew-on-WSL, or a dedicated profile may be required. Verify on a real WSL host before Sprint 3 ships.
- The `0.2.0` release tag must precede the formula bump in homebrew-tap — bumping the formula before the tag is reachable breaks every host running `setup.sh` between the two commits. Sprint 4 Task 4.4 enforces the ordering.
- Backup retention is exclusively `gc-backups`'s job. Adding silent retention to `install` would re-introduce the foot-gun the discussion-source explicitly forbids.
- Cross-repo serial sprints (1–4) ship in nils-cli before Sprint 5 can start in agent-runtime-kit; the dependency is enforced via the `0.2.0` formula bump in Task 4.4.

## Rollback plan

- Sprint 1 rollback: revert install body to the `0.12.0` stub; reinstall the prior nils-cli release. No state damage because `--apply` writes are reversible via `restore-backups` once Sprint 2 ships, or via manual restore of backup directories created during testing.
- Sprint 2 rollback (per task): each subcommand is its own PR; reverting one leaves the others intact. `uninstall` and `restore-backups` are independent — neither depends on the other at the file-system level.
- Sprint 3 rollback: doctor is read-only, so reverting its body only affects reporting. Drop the new Sprint 3 binary, fall back to the Plan 01 stub.
- Sprint 4 rollback: if the `0.2.0` release has issues, yank the formula commit in homebrew-tap (back to the previous SHA), tag `v0.2.1` with the fix, and re-publish. Do not retag `v0.2.0`.
- Sprint 5 rollback: revert `scripts/setup.sh`, `scripts/ci/sandbox-install-rehearsal.sh`, and `tests/sandbox/<product>/expected-skills.txt`. The `required_clis` bump can stay because lower floors still validate against `0.2.0` hosts.
