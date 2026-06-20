---
name: repo-retro
description: >
  Generate local repository retrospective data through the nils-cli `repo-retro` command.
---

# Repo Retro

## Contract

Prereqs:

- `repo-retro` is installed from the released nils-cli package and available on `PATH`.
- The target path is a local git work tree.
- Optional structured evidence inputs are explicit paths supplied by the caller.

Inputs:

- Repository path and time window.
- Optional mode such as `personal`, `team`, or `maintainer`.
- Optional JSONL inputs for timeline, validation, reviews, incidents, or decisions.
- Optional history directory with explicit write request.

Outputs:

- Markdown or JSON retrospective envelope grounded in local git history and supplied evidence.
- Optional history records only when the caller passes a history directory and write mode.

Failure modes:

- The target path is not a git repository.
- The requested window is invalid or empty.
- Optional JSONL inputs are unreadable or malformed beyond accepted warning behavior.

## Entrypoint

Use the released CLI directly:

```bash
repo-retro report --repo . --days 7 --mode team --format json
repo-retro report --repo . --from 2026-05-01 --to 2026-05-07 --mode maintainer --format markdown
repo-retro report --repo . --timeline-jsonl ./timeline.jsonl --validation-jsonl ./validation.jsonl --format json
```

## Workflow

1. Resolve the target repository and exact time window.
2. Prefer JSON when another tool or agent synthesis step will consume the result.
3. Read only explicit optional evidence paths; do not search hidden state.
4. Preserve warnings and source command metadata in user-facing synthesis.
5. Write history only when the caller explicitly requests persistence.

## Boundary

`repo-retro` owns deterministic git and evidence collection. The skill owner may synthesize themes from the returned envelope, but must mark inference separately from CLI facts.
