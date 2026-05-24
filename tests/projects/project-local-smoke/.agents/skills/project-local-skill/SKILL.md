---
name: project-local-skill
description:
  Fixture project-local skill used by runtime-kit project-local smoke checks.
---

# Project Local Skill

## Contract

Prereqs:

- `PROJECT_LOCAL_SMOKE_OUT` is set.

Inputs:

- Any arguments passed through by the smoke harness.

Outputs:

- A deterministic invocation marker.

Failure modes:

- `PROJECT_LOCAL_SMOKE_OUT` is missing.

## Scripts

- `.agents/skills/project-local-skill/scripts/project-local-skill.sh`

## Workflow

1. Run the script from the fixture project root.
2. Verify the marker under `PROJECT_LOCAL_SMOKE_OUT`.
