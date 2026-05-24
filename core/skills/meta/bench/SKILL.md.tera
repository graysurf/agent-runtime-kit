---
name: bench
description:
  Dispatch benchmark requests to a repository-owned `.agents/scripts/bench.sh`
  implementation.
---

# Bench

## Contract

Prereqs:

- Run from the target repository root unless the user explicitly names another
  repository path.
- `agent-run` is installed from nils-cli 0.20.0 or newer and available on
  `PATH`.
- The target repository owns an executable `.agents/scripts/bench.sh`.
- The project-local script is allowed to choose its benchmark framework,
  fixtures, output format, and performance thresholds.

Inputs:

- User-provided benchmark arguments, passed through to the project-local script.
- Optional repository path when the benchmark should run somewhere other than
  the current working directory.

Outputs:

- The project-local script's stdout, stderr, exit code, and artifacts.
- A clear stop message when no project-local implementation exists.

Failure modes:

- `.agents/scripts/bench.sh` is missing or is not executable.
- `agent-run` is unavailable or reports a blocked required project
  environment.
- The project-local script exits non-zero.
- The requested repository path is not a directory.

## Entrypoint

Resolve the repository root, then invoke the project-local script through
`agent-run` so repository `.envrc` / `.env` decisions are explicit:

```bash
agent-run exec --cwd "$repo_root" -- ./.agents/scripts/bench.sh "$@"
```

When the script is missing or not executable, report:

```text
no project-local implementation: .agents/scripts/bench.sh
```

## Workflow

1. Resolve the target repository root.
2. Verify `.agents/scripts/bench.sh` exists and is executable.
3. Run the script through `agent-run exec --cwd "$repo_root" --`, passing
   through user arguments.
4. Report the script's exit code and the artifact paths it prints.
5. Do not invent generic benchmark commands in runtime-kit.

## Boundary

Runtime-kit owns only the dispatch contract. Each consuming repository owns the
actual benchmark behavior.
