# plan-issue tracking_checkpoint_live tests still flake under full-parallel nextest/coverage after #793

## Status

- Status: open
- First observed: 2026-06-07
- Area: nils-plan-issue integration tests; tracking checkpoint live; cargo-nextest parallel execution; coverage runs
- Severity: medium

## Signal

During a workspace coverage run on nils-cli `main` (workspace v1.0.13, commit
c6ff996), a `nils-plan-issue` integration test failed under full-parallel
`cargo-nextest` load while passing deterministically in isolation:

- `tracking_checkpoint_live::tracking_checkpoint_live_fixture_repair_dashboard_returns_fixture_repair_result`
  failed at `crates/plan-issue/tests/integration/tracking_checkpoint_live.rs:281`
  with `assert_eq!(out.code, 0)` seeing exit code `1` and an **empty stderr**
  (diff `< 1 / > 0`). A sibling test
  `tracking_checkpoint_live::tracking_checkpoint_live_fixture_returns_posted_state_role_with_synthesized_url`
  was reported FLAKY (passed on retry) in the same run.
- The first failure aborted the run at ~test 4089/4681 (fail-fast), leaving 581
  tests unrun and producing no lcov.
- Re-running the single test in isolation
  (`cargo nextest run -p nils-plan-issue <test> --no-capture`) passes every time.

The empty-stderr exit-1 plus isolation-passes pattern points to shared mutable
state (process env, cwd, or a shared on-disk fixture/lock) racing across
concurrent plan-issue lifecycle tests rather than a logic bug in the command.

## Evidence

- Raw record: not captured as a structured artifact (manual diagnosis during a
  live coverage session, 2026-06-07). Reproduced from the local
  `cargo llvm-cov nextest --profile ci --workspace` run output.
- Repro (probabilistic): `cargo llvm-cov nextest --profile ci --workspace` or a
  full `cargo nextest run --profile ci --workspace` — fails intermittently in
  the `tracking_checkpoint_live` group under load.
- Counter-evidence (deterministic pass):
  `cargo nextest run -p nils-plan-issue tracking_checkpoint_live_fixture_repair_dashboard_returns_fixture_repair_result --no-capture`.

## Impact

Blocks clean single-shot full-workspace test and coverage runs: the flake
fail-fasts the suite, drops coverage artifacts, and forces reviewers/agents to
re-run or special-case the gate. Recurs for any workflow that runs the whole
nextest workspace (coverage maintenance, CI parity, release verification).

## Current Workaround

Run the full suite / coverage with nextest retries so the flake clears once
contention drops:

```bash
cargo llvm-cov nextest --profile ci --workspace \
  --lcov --output-path target/coverage/lcov.info --retries 5
```

(`--ignore-run-fail` is mutually exclusive with `--no-fail-fast`; `--retries`
is the clean mitigation. Coverage numbers are unaffected — the lines run either
way.)

## Related Prior Art

- Archived case: `plan-issue record post concurrency can corrupt lifecycle
  comments` (same concurrency family, production-side).
- `fix(plan-issue): serialize lifecycle mutations` (sympoies/nils-cli#793,
  merged) and the active `fix/plan-issue-lifecycle-lock` worktree — #793 did not
  fully stop the `tracking_checkpoint_live` test-side flake.

## Promotion Criteria

Promote after the durable fix lands: either the lifecycle-lock serialization is
extended to the tracking-checkpoint paths these tests exercise, or the affected
tests are given isolated state / a serial nextest test-group, validated by a
repeated full-workspace run with no flake and no `--retries`.

## Next Action

Confirm whether fix/plan-issue-lifecycle-lock (#793 follow-up) covers tracking
checkpoint paths; if not, serialize or isolate the shared mutable state these
tests touch under parallel load, or mark them as a serial nextest test group.
