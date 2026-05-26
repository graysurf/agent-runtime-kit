# Workspace feature unification silently activates `serde_json/preserve_order` per-crate green / workspace green divergence

## Status

- Status: open
- First observed: 2026-05-26
- Area: Rust Cargo workspace features × `serde_json` JSON envelope key order
- Severity: medium

## Signal

A crate that uses `serde_json::Value` for JSON envelope assertions can pass
`cargo test -p <crate>` (per-crate) but fail under
`cargo nextest run --workspace`, or vice-versa, with the same code, because
Cargo's workspace-wide feature unification activates
`serde_json/preserve_order` (an `IndexMap`-backed object map) only when at
least one other crate in the build graph requests that feature. Without
unification, `serde_json::Value` uses `BTreeMap`, which sorts object keys
alphabetically — so JSON envelopes whose payloads encode logical key order
(e.g. `state.prs[]` ordering, `data.steps[]` order, golden snapshots)
serialize differently between the two runs.

Reproduced on sympoies/nils-cli@b30db6c (PR #548, Task 2.5b of the Markdown
Render Template Layer plan): per-crate `cargo test -p plan-issue-cli`
passed; `cargo nextest run --workspace` (the actual CI gate) failed three
`lifecycle_record_post_comment_*` fixtures because the workspace pulled in
`serde_json/preserve_order` via `forge-cli` / `git-cli` downstream
activation.

## Evidence

- Raw record: PR #548 CI rerun trail (`CI / coverage (pull_request)
  Failing`).
- Repro shape (no minimal repro saved at first occurrence):

  ```sh
  # Per-crate: BTreeMap path → keys alphabetised
  cargo test -p plan-issue-cli lifecycle_record_post_comment

  # Workspace: IndexMap path → insertion-order preserved
  cargo nextest run --workspace -E 'test(lifecycle_record_post_comment)'
  ```

- The crate manifest before the fix had no `serde_json` line; after the fix:

  ```toml
  [dependencies]
  serde_json = { workspace = true, features = ["preserve_order"] }
  ```

- Fix commit: sympoies/nils-cli@b30db6c.

## Impact

Any crate that assembles JSON envelopes or asserts JSON byte-equality
golden fixtures and does *not* explicitly pin the `preserve_order` feature
risks per-crate-vs-workspace divergence. The failure mode is silent on
`cargo test -p <crate>` (which agents often run first as the fast loop),
then surfaces only after pushing to a CI gate that runs the full
workspace, costing one full CI round-trip (typically 3–5 minutes on
sympoies/nils-cli) per occurrence. Agents who do not know the rule may
re-bless fixtures from a workspace build to "fix" CI without
understanding the cause, embedding `preserve_order` byte order into
fixtures while the per-crate test path remains broken — a latent trap
for the next developer who runs `cargo test -p <crate>` after the
fixtures land.

## Current Workaround

Any crate whose tests rely on JSON object key order — golden fixtures,
envelope assertions that index by position, snapshot tests — must
explicitly pin `serde_json` with the `preserve_order` feature in its own
`Cargo.toml`, even when only `serde_json = { workspace = true }` appears
to suffice:

```toml
[dependencies]
serde_json = { workspace = true, features = ["preserve_order"] }
```

This makes the feature activation independent of which downstream crates
the build graph happens to include.

## Promotion Criteria

Promote when **either**:

- (a) a workspace-wide lint / audit (e.g. an extension to
  `scripts/ci/cli-output-contract-lint.sh` or a new
  `serde-json-preserve-order-audit.sh`) flags crates with
  `serde_json::Value` use that do not pin the feature, OR
- (b) the lesson is documented in a workspace contract — candidates:
  `docs/specs/cli-service-json-contract-guideline-v1.md`,
  `docs/runbooks/new-cli-crate-development-standard.md`,
  `docs/runbooks/markdown-template-development-standard.md`.

Closing this entry requires linking the upstream lint commit or the
contract / runbook update that documents the rule.

## Next Action

Open a sympoies/nils-cli issue proposing a `serde-json-preserve-order`
crate audit (the simplest implementation: parse each crate's
`Cargo.toml`, grep `serde_json::Value` usage under `src/`, fail when
both are present and the crate does not pin the feature). Reference
this entry from the issue. Optionally pair the audit with a one-paragraph
note in
`docs/runbooks/new-cli-crate-development-standard.md` so new crates land
with the feature pinned by default.
