# Runtime Smoke Harness

This directory contains the Plan 06 acceptance foundation for migrated runtime
skills. The harness is intentionally offline and credential-free by default.
It must never mutate real `$HOME/.codex`, `$HOME/.claude`, auth, sessions,
history, logs, caches, or product state.

## Modes

- `matrix`: validates the acceptance matrix contract and checks that its
  `skill_id` set exactly matches the committed sandbox skill pins for both
  products.
- `install`: creates temporary `live_home` and `state_home` roots for Codex and
  Claude, renders current product surfaces, runs `agent-runtime install
  --apply`, verifies installed `SKILL.md` surfaces against
  `tests/sandbox/<product>/expected-skills.txt`, and runs `agent-runtime
  doctor`.
- `deterministic`: runs committed command-level probes for available domains.
  Sprint 2 currently includes `meta`, `media`, `browser`, `evidence`, and
  `reporting` domains.
- `product`: runs quarantined product CLI isolation probes. Sprint 3 Task 3.1
  supports `--probe-only` to verify temp-home invocation contracts without
  depending on real auth, provider state, sessions, or user product homes.

`doctor` warnings are allowed in install mode because host tool freshness can
vary. Blocking findings are not allowed; the runner parses the `block=<n>`
summary and fails when it is nonzero or missing.

## Commands

```bash
bash tests/runtime-smoke/run.sh --mode matrix
bash tests/runtime-smoke/run.sh --mode install
bash tests/runtime-smoke/run.sh --mode install --format json
bash tests/runtime-smoke/run.sh --mode deterministic
bash tests/runtime-smoke/run.sh --mode deterministic --domain meta
bash tests/runtime-smoke/run.sh --mode deterministic --domain media
bash tests/runtime-smoke/run.sh --mode deterministic --domain browser
bash tests/runtime-smoke/run.sh --mode deterministic --domain evidence
bash tests/runtime-smoke/run.sh --mode deterministic --domain reporting
bash tests/runtime-smoke/run.sh --mode product --product codex --probe-only
bash tests/runtime-smoke/run.sh --mode product --product claude --probe-only
```

Use `--product codex` or `--product claude` to narrow install mode. Use
`--keep-artifacts` for manual debugging; the command prints the temporary root
to stderr. Use `--artifacts-dir <path>` when a caller needs persistent logs
without keeping the temporary runtime homes.

Product mode is intentionally outside default CI. A probe passes when the
product CLI can run with only temporary runtime homes and either completes the
prompt path or fails for a known missing isolated provider/auth reason. Product
prompt cases become required only after they can run without touching real
`$HOME/.codex`, `$HOME/.claude`, auth, sessions, history, logs, or caches.

## Matrix Contract

`acceptance-matrix.yaml` is a constrained YAML subset so it can be validated
with portable shell tools. Each case must include:

- `id`
- `product`
- `domain`
- `skill_id`
- `mode`
- `fixture_workspace`
- `setup`
- `invocation`
- `expected_exit_code`
- `expected_artifacts`
- `cleanup`
- `expected_disposition`
- `skip_policy`

Allowed result dispositions are `pass`, `fail`, `skip-host-capability`, and
`blocked-design`.

## Artifact Policy

Committed expected outputs stay small and deterministic under `expected/`.
Runtime logs, observed skill lists, diffs, and future case artifacts are written
to the temporary run root or to the caller-provided artifacts directory.
