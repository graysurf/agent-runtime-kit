---
name: sync-runtime-skills
description:
  Refresh the active agent-runtime-kit skill surfaces into local Codex and
  Claude runtime homes by running `scripts/sync-runtime-skills.sh`. Use when the
  user asks to sync, update, refresh, or make newly merged runtime-kit skills
  visible to live agent sessions.
---

# Sync Runtime Skills

## Contract

Prereqs:

- `agent-runtime-kit` is available as a local checkout with
  `scripts/sync-runtime-skills.sh`.
- First-time host bootstrap has already been handled by `scripts/setup.sh`.
- `git` is available. `agent-runtime` is required for `--apply` refreshes.
- The source checkout passes
  `bash scripts/ci/skill-governance-audit.sh --check-counts`; sync checks
  count freshness but never runs update mode.

Inputs:

- User intent: preview-only, apply refresh, product-limited refresh, no-pull
  refresh, or verification-skipped refresh.
- Optional product: `codex`, `claude`, or `both`.
- Optional source checkout path when the active directory is not the desired
  `agent-runtime-kit` checkout.

Outputs:

- The script's stdout/stderr and exit code.
- A concise summary of whether pull, render, install, doctor, and Codex
  prompt-input verification were planned, skipped, or completed.
- A read-only source count check before any render/install step.

Failure modes:

- The source checkout cannot be resolved or lacks the refresh script.
- `git pull --ff-only` fails before render/install.
- Active skill-count references drift from `manifests/skills.yaml`.
- `agent-runtime render`, `install`, or `doctor --class skill-surface` fails.
- Codex prompt-input verification fails when Codex is selected and available.

## Entrypoint

Resolve the `agent-runtime-kit` checkout, then run the script from that root:

```bash
bash scripts/sync-runtime-skills.sh "$@"
```

Common invocations:

```bash
# Preview only; no runtime mutation.
bash scripts/sync-runtime-skills.sh

# Update both Codex and Claude runtime homes.
bash scripts/sync-runtime-skills.sh --apply

# Update one product.
bash scripts/sync-runtime-skills.sh --apply --product codex
bash scripts/sync-runtime-skills.sh --apply --product claude

# Refresh the current checkout state without pulling.
bash scripts/sync-runtime-skills.sh --apply --no-pull
```

## Workflow

1. Resolve the intended `agent-runtime-kit` checkout:
   - If the current repository root contains `scripts/sync-runtime-skills.sh`,
     use it.
   - Otherwise, use an explicit user-provided path, `AGENT_DOCS_HOME`, or the
     known active checkout path only when it contains the script.
   - Stop and ask for the checkout path if no candidate contains the script.
2. Interpret user intent:
   - If the user asks to "sync", "update", "refresh", "install", or "make the
     skill visible", run with `--apply`.
   - If the user asks to preview, inspect, check, or show what would happen, run
     without `--apply`.
3. Pass through product and safety flags exactly:
   - `--product codex|claude|both`
   - `--no-pull`
   - `--no-verify`
   - `--source-root <path>`
4. Let the script run its read-only
   `bash scripts/ci/skill-governance-audit.sh --check-counts` source readiness
   gate after checkout resolution/pull and before render/install. `--no-verify`
   does not skip this gate because it only controls post-install verification.
5. Before an `--apply` run, state that the command may mutate the selected
   local runtime homes (`$CODEX_HOME`/`$HOME/.codex`, `$HOME/.claude`, and
   runtime-kit state homes).
6. Run the script from the checkout root and let it own pull, render, install,
   doctor, and Codex prompt-input sequencing.
7. Report the final summary line and the first failing command if the script
   exits non-zero.

## Boundary

This skill is a thin agent-facing wrapper for
`scripts/sync-runtime-skills.sh`. It must not reimplement render/install/doctor
logic, mutate runtime homes outside the script, or replace `scripts/setup.sh`
for first-time host setup.
