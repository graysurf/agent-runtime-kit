---
name: release
description:
  Dispatch release requests to a repository-owned `.agents/scripts/release.sh`
  implementation.
---

# Release

## Contract

Prereqs:

- Run from the target repository root unless the user explicitly names another
  repository path.
- The target repository owns an executable `.agents/scripts/release.sh`.
- Versioning, changelog, tags, publishing, and post-release checks are owned by
  the consuming repository.

Inputs:

- User-provided release arguments, passed through to the project-local script.
- Optional repository path when releasing from another checkout.

Outputs:

- The project-local script's stdout, stderr, exit code, release URL, and
  verification evidence.
- A clear stop message when no project-local implementation exists.

Failure modes:

- `.agents/scripts/release.sh` is missing or is not executable.
- The project-local script exits non-zero.
- The requested repository path is not a directory.

## Entrypoint

Resolve the repository root, then invoke the project-local script directly:

```bash
.agents/scripts/release.sh "$@"
```

When the script is missing or not executable, report:

```text
no project-local implementation: .agents/scripts/release.sh
```

## Workflow

1. Resolve the target repository root.
2. Verify `.agents/scripts/release.sh` exists and is executable.
3. Run the script from the repository root, passing through user arguments.
4. Report the release evidence and exit code printed by the script.
5. Do not run generic release commands when the project-local script is absent.

## Boundary

Runtime-kit owns only the dispatch contract. Each consuming repository owns its
release implementation and approval gates.
