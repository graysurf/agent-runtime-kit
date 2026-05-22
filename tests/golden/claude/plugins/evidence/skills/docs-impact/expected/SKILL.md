---
name: docs-impact
description:
  Scan Git changes for documentation impact through the nils-cli `docs-impact` command.
---

# Docs Impact

## Contract

Prereqs:

- `docs-impact` is installed from the released nils-cli package and available on `PATH`.
- The target repository and diff base are known.
- The caller has already decided which changed files are in scope.

Inputs:

- Repository path.
- Diff base or include-untracked mode.
- Optional JSON output format.

Outputs:

- Documentation-impact classification with changed-file evidence and escalation hints.

Failure modes:

- The repository cannot be resolved.
- The diff base is missing or ambiguous.
- Git status or diff commands fail.

## Entrypoint

Use the released CLI directly:

```bash
docs-impact scan --include-untracked
docs-impact scan --repo . --base origin/main --format json
```

## Workflow

1. Run after implementation changes are present and before final delivery claims.
2. Use `--base <ref>` for PR-style review and `--include-untracked` for local draft scans.
3. Treat the CLI result as deterministic input to docs judgment, not as an automatic docs-edit requirement.
4. If docs are needed, update the relevant source docs or record why no docs change is required.

## Boundary

`docs-impact` owns changed-file scanning and impact classification. The caller owns documentation judgment, escalation, and any follow-up issue or task disposition.
