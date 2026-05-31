# forge-cli inbox_tcp_vpn_probe port-reuse race (flaky test)

## Status

- Status: open
- First observed: 2026-05-31
- Area: forge-cli
- Severity: medium

## Signal

Pre-existing flaky test in `nils-cli` surfaced while delivering tracking issue
sympoies/nils-cli#716 (forge-cli search surface). Not introduced by that work;
it flakes on `main` independently.

- Version: nils-cli 0.31.7 (also reproduces on 0.31.6 / `main`).
- Test: `ops::inbox::tests::inbox_tcp_vpn_probe_connects_and_reports_refused_ports`
  (`crates/forge-cli/src/ops/inbox.rs`).
- Observed rate: ~1/3 of full-suite runs on `main`; higher (~2/3) once extra
  tests increase parallel pressure.

## Evidence

- Raw record: not captured (manual diagnosis, 2026-05-31).
- Repro: `cargo test -p nils-forge-cli --lib` run a few times; fails
  intermittently, passes in isolation
  (`cargo test -p nils-forge-cli --lib inbox_tcp_vpn_probe_connects_and_reports_refused_ports`).

## Impact

CI `test` / `test_macos` jobs and the local-fast gate can fail spuriously on
unrelated PRs, costing re-runs and eroding trust in a red suite.

## Root Cause

The test binds a `TcpListener` to `127.0.0.1:0`, records the OS-assigned
ephemeral port, asserts a connect succeeds, then `drop`s the listener and
asserts the *same* port is now connection-refused. Between the drop and the
second probe, another concurrently-running test can bind the just-freed
ephemeral port, so the probe connects instead of being refused and the
`expect_err("closed listener should fail readiness")` panics.

## Current Workaround

Re-run the suite; the test passes in isolation and usually on retry. No code
change shipped for this (kept out of the #716 search PRs as out-of-scope).

## Suggested Fix

Make the "refused" assertion robust to port reuse — e.g. serialize the
port-binding inbox tests behind a shared mutex, or assert
`vpn_unavailable` against a port that cannot be reused mid-test (reserve it for
the duration) rather than relying on the OS not re-binding a freed ephemeral
port.

## Related

A sibling pre-existing race in `crates/forge-cli/src/backend.rs` tests (two
`ProcessRunner` tests both mutating the process-global `ENV_GH_BIN`) was the
*same class* of bug and was fixed in sympoies/nils-cli#722 by serializing those
two tests behind a shared `Mutex` — the same remedy likely applies here.

## Promotion Criteria

Promote after the durable fix (or an accepted-risk decision) is implemented,
validated, and linked from this entry. No upstream issue filed yet.

## Next Action

Open a focused `nils-cli` fix (or GitHub issue) for the port-reuse race in
`inbox_tcp_vpn_probe_connects_and_reports_refused_ports`; link it here and set
status `promoted` when the fix lands.
