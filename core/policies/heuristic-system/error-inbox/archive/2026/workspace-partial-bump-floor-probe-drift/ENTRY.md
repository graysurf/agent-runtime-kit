# Workspace partial bump breaks downstream floor-probe assumption

## Status

- Status: promoted
- First observed: 2026-05-28
- Area: nils-cli release process; agent-runtime-kit CI floor probe
- Severity: medium

## Signal

Sprint 1 of the `2026-05-28-plan-task-ledger-durability` rollout cut a
`sympoies/nils-cli` PR (#607) that bumped only `plan-tooling` and
`plan-issue-cli` from `0.25.6` to `0.25.7`, leaving the other 31 workspace
crates (including `agent-runtime-cli`, `forge-cli`, `semantic-commit`, the
`api-*` family, the `git-*` family, and the rest) behind. A `v0.25.7` tag was
cut on top of the partial bump. The runtime-kit consumed the new
`plan-tooling ledger-update` + `plan-issue tracking close-ready
ledger-rows-pending` surface and updated `docs/source/nils-cli-surface.md` to
say `Active git describe --tags output: v0.25.7`, but
`scripts/ci/all.sh` Position 2 compared the floor to `agent-runtime --version`,
which still reported `0.25.6`. CI failed with:

```text
ci/all.sh: nils-cli surface floor check failed
  minimum in docs/source/nils-cli-surface.md : v0.25.7
  host agent-runtime    : v0.25.6
  detail: host v0.25.6 is below surface floor v0.25.7
```

The runtime-kit's floor probe had a silent assumption: every nils-cli release
tag matches every workspace crate's `Cargo.toml` version, per the convention
established by `1edf007` (`chore(release): bump cli versions to 0.25.6`).
v0.25.7 violated that convention and the probe's assumption became false in a
way that was only detected at the downstream consumer's CI.

## Evidence

- Raw record: not captured (post-mortem reconstructed from the upstream PR /
  tag / downstream-PR trail below; the CI failure was the live signal).
- nils-cli partial-bump PR: `sympoies/nils-cli#607` (squash `0c070f8`).
- nils-cli lock-step catch-up PR: `sympoies/nils-cli#608` (squash `4d0d621`,
  released as `v0.25.8`).
- runtime-kit PR #147 (`feat(skills): wire plan-tooling ledger-update + --live
  into tracking SKILLs`, squash `4371584`) — included a temporary probe flip
  from `agent-runtime --version` to `plan-tooling --version` in
  `scripts/ci/all.sh` Position 2 to unblock the rollout.
- runtime-kit PR #149 (`chore(deps): raise nils-cli floor to v0.25.8; restore
  agent-runtime probe`, squash `ad0ceab`) — reverted the temporary probe flip
  after the v0.25.8 lock-step catch-up restored the contract upstream.
- Plan bundle: `docs/plans/2026-05-28-plan-task-ledger-durability/`.

## Impact

Downstream consumers (this repo's floor probe, anything else that treats
`<release-tag> == <every-crate-version>`) silently broke during a partial
upstream release. Symptoms surfaced only at consumer CI, not at upstream
release time, because the upstream release process had no invariant guarding
against partial bumps. Recovery required (a) a follow-up upstream release
(v0.25.8) that performed the lock-step catch-up across the 31 missed crates,
(b) a Homebrew tap formula bump, and (c) a downstream PR to raise the floor
and revert the temporary probe flip. Total recovery: one extra upstream PR,
one extra release tag, one extra tap commit, one extra downstream PR.

## Current Workaround

None needed — the gap is closed. The temporary probe flip in PR #147 was the
contemporaneous workaround; it was reverted in PR #149 once v0.25.8 restored
the contract.

## Promotion Criteria

The gap is closed by two durable fixes (entry is `promoted` rather than
`open`):

1. **Upstream invariant (`sympoies/nils-cli`)**: PR `sympoies/nils-cli`
   `050976d` (`ci(release): add workspace-version-lockstep audit`) adds
   `scripts/ci/workspace-version-lockstep.sh --strict` to the required-checks
   stack. The audit fails when any `crates/*/Cargo.toml` version drifts from
   the workspace root `Cargo.toml`, or when any internal `path = "../<crate>"`
   cross-dep version pin lags behind. Wired into
   `.agents/skills/nils-cli-verify-required-checks/scripts/nils-cli-verify-required-checks.sh`
   and `DEVELOPMENT.md`. A future partial bump will now fail at the upstream
   PR's CI, before merge, before tag, before any downstream consumer can
   notice.
2. **Downstream comment (`agent-runtime-kit`)**: `scripts/ci/all.sh` Position 2
   comment block records that v0.25.7 was the exception and the lock-step
   contract is the invariant being preserved. Tells the next reader to fix
   the release rather than flip the probe if the contract breaks again.

## Next Action

None. Entry is `promoted` and retained as a curated post-mortem so future
agents working on the nils-cli release process can find the historical
rationale for the workspace-version-lockstep audit by grep instead of
spelunking through PR threads.

## Archive

- Archived: 2026-06-01
- Reason: Gap closed: v0.25.8 lock-step catch-up + upstream workspace-version-lockstep audit; downstream probe restored (PR #149)
- Durable link: `https://github.com/sympoies/nils-cli/pull/608`
