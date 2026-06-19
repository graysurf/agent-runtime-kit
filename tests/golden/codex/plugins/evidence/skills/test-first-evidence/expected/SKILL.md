---
name: test-first-evidence
description:
  Govern an implementation change with failing-test discipline — failing test
  or waiver before production edits, then final validation — through the
  nils-cli `test-first-evidence` command; the record the forge-cli test-first
  gate verifies.
---

# Test First Evidence

## Contract

Prereqs:

- `test-first-evidence` is installed from the released nils-cli package and available on `PATH`.
- The implementation change is classified before production behavior is edited.
- The output directory is explicit.

Inputs:

- Implementation task, target behavior or bug, done criteria, relevant files, known test command, and constraints when available.
- Classification and production path.
- Failing command and exit code, or an explicit waiver reason.
- Final validation command and pass/fail status.

Outputs:

- Change classification.
- A deterministic test-first evidence record: failing-test evidence before production edits, or an explicit waiver with substitute validation, plus a passing final validation.
- A verification result usable as delivery evidence for the `forge-cli` test-first gate.

Failure modes:

- Production behavior changed without failing evidence or waiver.
- Final validation is missing.
- The evidence record is incomplete or malformed.
- No usable test harness exists and a waiver is not acceptable for the change.

## Discipline

The engineering judgment behind the record — follow it whether or not the
`forge-cli` gate is enabled:

1. **Classify before editing production code.** Decide whether the request changes testable production behavior. Treat bug fixes, parser logic, state machines, API contracts, workflow logic, user-visible behavior, and new features as testable by default. Docs-only, generated-only, formatting-only, visual-only, exploratory spikes, emergency hotfixes, or repos with no usable test harness may use a waiver.
2. **Failing test first.** For a testable behavior change, add or identify a focused regression / unit / integration / acceptance test and capture failing evidence (command, exit code, failing test name, concise failure summary) before editing production code. Do not weaken, skip, or overfit the test to the planned implementation.
3. **Waiver when test-first does not apply.** State the waiver before editing: the reason, why a failing test is not practical now, and the substitute validation you will run.
4. **Implement after evidence.** Only edit production code after recording failing evidence or a waiver. Keep the change scoped to making the failing test pass; add broader tests only when blast radius or a shared contract justifies it.
5. **Final validation.** Re-run the failing test and the smallest meaningful related validation; record command, result, and any skipped checks.

## Entrypoint

Use the released CLI directly (point `--out` at an explicit evidence directory
resolved through `agent-out`, not a hand-written `/tmp` path):

```bash
test-first-evidence init --out "$evidence_dir" --classification behavior-change --production-path src/lib.rs
test-first-evidence record-failing --out "$evidence_dir" --command "cargo test bug_repro" --exit-code 101 --summary "bug reproduced"
test-first-evidence record-waiver --out "$evidence_dir" --reason "docs-only change"
test-first-evidence record-final --out "$evidence_dir" --command "cargo test bug_repro" --status pass
test-first-evidence verify --out "$evidence_dir" --format json
```

## Workflow

1. Classify the change, then initialize evidence before editing production behavior.
2. Record a failing test when practical (rule 2 above).
3. Record a waiver when the change is docs-only, config-only, or otherwise not amenable to failing-test evidence (rule 3).
4. Implement scoped to the failing test, then record final validation.
5. Verify the record before using it as delivery evidence — a record is complete only with a failing test or waiver **and** a passing final validation.

## Delivery gate

When `[test_first].require` resolves true — from a repo `.forge-cli.toml` or
the user-global `${XDG_CONFIG_HOME:-~/.config}/forge-cli/config.toml` layer —
`forge-cli pr create` / `pr deliver` require `--test-first-evidence <dir>` for
`--kind feature` / `bug` PRs, pointing at a directory whose record this skill
produced and `verify` accepts. `docs` / `chore` / `ci` / `refactor` kinds are
exempt. A missing, incomplete, or unreadable record fails the PR with
`test_first_evidence_required` / `_incomplete` / `_unreadable`. The gate is the
release-surface enforcement point; this skill is how you satisfy it. See
`core/policies/git-delivery.md` for the delivery-side contract.

## Boundary

`test-first-evidence` owns the evidence record mechanics **and** the engineering
judgment about classification, when a failing test is practical, and whether a
waiver is acceptable. The release-surface enforcement (the config-gated
requirement on `forge-cli pr create` / `pr deliver`) lives in nils-cli, not in
skill prose; this skill produces the record that gate verifies.
