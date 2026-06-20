---
name: agent-out
description: >
  Allocate canonical project-scoped output directories and audit workflow artifacts through the nils-cli `agent-out` command.
---

# Agent Out

## Contract

Prereqs:

- `agent-out` is installed from the released nils-cli package and available on `PATH`.
- The caller has a concrete topic for temporary or evidence artifacts.
- Durable repo artifacts are used only when project policy or the user explicitly asks for them.

Inputs:

- Topic slug for a run directory.
- Optional repository path when allocating output for a repo other than the current directory.
- Optional audit request for existing output entries.

Outputs:

- Canonical run directory path, JSON, or shell env output.
- Optional audit report for output hygiene.

Failure modes:

- The topic is missing or unsafe.
- The selected repository path cannot be resolved.
- Artifact audit finds unexpected top-level or retained output entries.

## Entrypoint

Use the released CLI directly:

```bash
agent-out project --topic browser-qa --mkdir
agent-out project --repo . --topic release-notes --format json
agent-out audit --strict
```

## Workflow

1. Use `agent-out project --topic <topic> --mkdir` for temporary or workflow evidence directories when the project has no defined output path.
2. Use `--format json` or `--format env` when another command needs the allocated path.
3. Run `agent-out audit` before cleanup or before enforcing output-retention policy.
4. Do not put credentials, runtime history, or persistent project state in ad hoc output directories.

## Boundary

`agent-out` owns path construction, directory creation, and audit mechanics. The caller owns deciding whether an artifact is temporary, durable, or project-tracked.
