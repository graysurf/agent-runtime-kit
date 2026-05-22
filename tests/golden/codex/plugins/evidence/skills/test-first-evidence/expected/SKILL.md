---
name: test-first-evidence
description:
  Record failing-test evidence, waivers, and final validation through the nils-cli `test-first-evidence` command.
---

# Test First Evidence

## Contract

Prereqs:

- `test-first-evidence` is installed from the released nils-cli package and available on `PATH`.
- The implementation change is classified before production behavior is edited.
- The output directory is explicit.

Inputs:

- Classification and production path.
- Failing command and exit code, or an explicit waiver reason.
- Final validation command and pass/fail status.

Outputs:

- Deterministic test-first evidence record and verification result.

Failure modes:

- Production behavior changed without failing evidence or waiver.
- Final validation is missing.
- The evidence record is incomplete or malformed.

## Entrypoint

Use the released CLI directly:

```bash
test-first-evidence init --out /tmp/evidence --classification behavior-change --production-path src/lib.rs
test-first-evidence record-failing --out /tmp/evidence --command "cargo test bug_repro" --exit-code 101 --summary "bug reproduced"
test-first-evidence record-waiver --out /tmp/evidence --reason "docs-only change"
test-first-evidence record-final --out /tmp/evidence --command "cargo test bug_repro" --status pass
test-first-evidence verify --out /tmp/evidence --format json
```

## Workflow

1. Initialize evidence before editing production behavior.
2. Record a failing test when practical.
3. Record a waiver when the change is docs-only, config-only, or otherwise not amenable to failing-test evidence.
4. Record final validation after implementation.
5. Verify the record before using it as delivery evidence.

## Boundary

`test-first-evidence` owns evidence record mechanics. The workflow owner owns the engineering judgment about whether failing-test evidence is practical and whether a waiver is acceptable.
