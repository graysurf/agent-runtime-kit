---
name: pre-pr
description:
  Dispatch pre-PR validation requests to a repository-owned
  `.agents/scripts/pre-pr.sh` implementation.
---

# Pre PR

## Contract

Prereqs:

- Run from the target repository root unless the user explicitly names another
  repository path.
- The target repository owns an executable `.agents/scripts/pre-pr.sh`.
- The consuming repository defines the validation stack that must run before a
  pull request is opened or updated.

Inputs:

- User-provided validation arguments, passed through to the project-local script.
- Optional repository path when validation should run in another checkout.

Outputs:

- The project-local script's stdout, stderr, exit code, and validation summary.
- A clear stop message when no project-local implementation exists.

Failure modes:

- `.agents/scripts/pre-pr.sh` is missing or is not executable.
- The project-local script exits non-zero.
- The requested repository path is not a directory.

## Entrypoint

Resolve the repository root, then invoke the project-local script directly:

```bash
.agents/scripts/pre-pr.sh "$@"
```

When the script is missing or not executable, report:

```text
no project-local implementation: .agents/scripts/pre-pr.sh
```

## Workflow

1. Resolve the target repository root.
2. Verify `.agents/scripts/pre-pr.sh` exists and is executable.
3. Run the script from the repository root, passing through user arguments.
4. Report the script's validation result and any failing command it prints.
5. Do not substitute a generic validation stack when the project-local script is
   absent.

## Boundary

Runtime-kit owns only the dispatch contract. Each consuming repository owns its
own pre-PR validation stack.
