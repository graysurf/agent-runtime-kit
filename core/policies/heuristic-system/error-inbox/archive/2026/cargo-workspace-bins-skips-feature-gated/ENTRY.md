# `cargo build --workspace --bins` silently skips feature-gated binary targets

## Status

- Status: promoted
- First observed: 2026-05-26
- Area: Rust Cargo `--workspace --bins` × `[[bin]] required-features` × CI
  completion / coverage audits
- Severity: medium

## Signal

A `[[bin]]` target declared with `required-features = ["foo"]` is silently
skipped by `cargo build --workspace --bins` when feature `foo` is not in
the default-active feature set. The build still exits 0 and reports
"Compiling ... Finished" for the rest of the workspace, so any
post-build audit that walks `target/debug/<bin-name>` and expects every
declared binary to be present fails with a misleading
"missing binaries after build" error rather than a feature-resolution
diagnostic.

Reproduced on sympoies/nils-cli@a608586 (PR #553, Sprint 3 of the
Markdown Render Template Layer plan):

- `crates/nils-markdown/Cargo.toml` declares
  `[[bin]] name = "md-render", required-features = ["bin-cli"]` and
  `bin-cli` is *not* in the default feature set (it pulls in `clap`,
  `clap_complete`, and `anyhow` as optional deps).
- `scripts/ci/completion-flag-parity-audit.sh` then ran
  `cargo build --workspace --bins`, walked the workspace binary list,
  and failed with `missing binaries after build: target/debug/md-render`.
- The fix was to add `--all-features` to the audit's build step so
  feature-gated bins are materialised.

## Evidence

- Raw record: PR #553 CI run trail (`completion-flag-parity-audit`
  failure followed by green after the `--all-features` fix).
- Repro shape:

  ```sh
  # Silently skips md-render — exits 0 with no warning
  cargo build --workspace --bins
  ls target/debug/md-render  # → No such file or directory

  # Materialises every feature-gated bin
  cargo build --workspace --bins --all-features
  ls target/debug/md-render  # → present
  ```

- The audit fix is a one-line change in
  `scripts/ci/completion-flag-parity-audit.sh`:

  ```diff
  - cargo build --workspace --bins
  + cargo build --workspace --bins --all-features
  ```

## Impact

Any workspace audit that assumes "`cargo build --workspace --bins` builds
every declared binary" is broken in the presence of feature-gated bins.
On sympoies/nils-cli this pattern is currently used by at least one CI
gate (`completion-flag-parity-audit.sh`); the same trap likely applies to
similar coverage / completion / packaging audits whenever a new
feature-gated binary lands. Agents typically iterate two or three rounds
("the bin is declared, why is the audit complaining?") before
discovering that `--all-features` (or `--features <feat>` per bin) is
required.

A related symptom: binary integration tests that hard-code
`target/debug/<bin>` paths break under coverage runs because
`cargo-llvm-cov` redirects to `target/llvm-cov-target/`. The accepted
pattern is to resolve via
`nils_test_support::bin::resolve("<bin-name>")` instead.

## Current Workaround

For workspace audits / coverage gates that walk the binary list:

- Build with `cargo build --workspace --bins --all-features`, or
- Build with `--features <feature>` for each feature-gated bin
  individually if a narrower scope is required.

For binary integration tests, prefer
`nils_test_support::bin::resolve("<name>")` over hand-built
`target/debug/<name>` paths so coverage runs work.

## Promotion Criteria

Promote when **either**:

- (a) the lesson is captured in a workspace contract — candidates:
  `docs/runbooks/new-cli-crate-development-standard.md`,
  `docs/runbooks/cli-completion-development-standard.md`,
  `docs/specs/completion-coverage-matrix-v1.md` — so that future
  feature-gated bins land with the right audit invocation, OR
- (b) the relevant CI audits in `scripts/ci/` are reviewed and any that
  walk `target/debug/<bin>` are updated to use `--all-features` (or an
  equivalent feature-aware build step) by default.

Closing this entry requires linking the upstream runbook / spec edit or
the audit-script audit PR.

## Next Action

None. Resolved by sympoies/nils-cli#553: completion audit now builds workspace bins with `--all-features` before checking `target/debug` binaries.

Lifecycle link: `https://github.com/sympoies/nils-cli/pull/553`

## Archive

- Archived: 2026-05-30
- Reason: Resolved by feature-aware completion audit build (nils-cli#553).
- Durable link: `https://github.com/sympoies/nils-cli/pull/553`
