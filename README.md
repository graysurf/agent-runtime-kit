# agent-runtime-kit

Single source of truth for the local agent runtime layer shared by **Codex CLI**
and **Claude Code**. Skills, hooks, policy docs, plugin metadata, and adapter
templates are edited here in one tree; product-specific runtime homes
(`$HOME/.codex`, `$HOME/.claude`) are regenerated from this source instead of
being hand-edited, so the two products stop drifting apart.

Per-surface ship state — which Codex and Claude harness primitives are
rendered, partial, or not shipped — is tracked in
[`SUPPORT_MATRIX.md`](SUPPORT_MATRIX.md).

## Version baseline

| component | floor | source |
|---|---|---|
| Codex CLI (`codex --version`) | `0.130.0` (effective 2026-06-03) | `manifests/runtime-roots.yaml` |
| Claude Code (`claude --version`) | `2.1.145` (effective 2026-06-03) | `manifests/runtime-roots.yaml` |
| `nils-cli` surface (`agent-runtime --version`) | `v0.17.7` | `docs/source/nils-cli-surface.md` |

Per-skill `nils-cli` floors live in `manifests/skills.yaml` `required_clis`
and are tighter than the surface-level pin.

## Layered model

The repo separates four planes: portable source, generated review output, the
actual runtime homes products read, and writable per-host state.

```
core/                     manifests/         targets/
  skills/  hooks/  docs/  *.yaml             codex/   claude/
  policies/                                  link-map.yaml + adapter files
        │                     │                      │
        └─────────────────────┴──────────────────────┘
                              │ agent-runtime render --product <codex|claude>
                              ▼
                         build/<product>/      (regenerated, golden-pinned)
                              │
                              │ agent-runtime install --apply
                              ▼
       live_home: $HOME/.codex   $HOME/.claude       (managed runtime)
       state_home: $XDG_STATE_HOME/agent-runtime-kit/{codex,claude}/
                   override via CODEX_AGENT_STATE_HOME / CLAUDE_KIT_STATE_HOME
                   (writable artifacts under <state_home>/out/ and /backups/)
```

- `core/` — product-independent source: skills, shared hook scripts, policy
  docs (`heuristic-system`, doc placement policy), helper schemas.
- `manifests/` — machine-checkable inventory (`skills.yaml`, `plugins.yaml`,
  `product-capabilities.yaml`, `runtime-roots.yaml`, `cli-tools.yaml`).
- `targets/` — Codex and Claude adapter surfaces; each declares how core
  content becomes product-native files through `link-map.yaml`.
- `build/` — generated render output, pinned by `tests/golden/`.
- `live_home` / `state_home` — managed by `agent-runtime install` and
  `agent-out`; each product has its own `state_home` (Codex and Claude do
  not share an `out/` tree). Runtime state is **never** tracked in this repo.
- `AGENT_DOCS.toml` — project-local entries the `agent-docs` preflight reads
  to gate edits, tests, and skill authoring.

## What's inside `core/skills/`

Ten skill domains, currently rendered into 44 active Codex entries and 10
Claude plugins:

`browser` · `code-review` · `conversation` · `dispatch` · `evidence` ·
`issue` · `media` · `meta` · `pr` · `reporting`

Representative skills: `pr:deliver-github-pr`,
`dispatch:deliver-plan-tracking-issue`, `evidence:test-first-evidence`,
`meta:semantic-commit`, `reporting:project-retro`, `media:screen-record`.
The authoritative list with `required_clis` floors is `manifests/skills.yaml`;
per-surface ship state with file:line citations is in
[`SUPPORT_MATRIX.md`](SUPPORT_MATRIX.md).

## CLI boundary

This repo ships **no binaries**. The `agent-runtime` command and the rest of
the runtime surface (`agent-docs`, `agent-out`, `plan-tooling`, `forge-cli`,
`heuristic-inbox`, …) live in
[`sympoies/nils-cli`](https://github.com/sympoies/nils-cli) and install via
`brew install sympoies/tap/nils-cli`.

Skills declare the binaries they need through `required_clis`. Released
contracts are pinned only after the upstream nils-cli release plus the
Homebrew tap update complete; local debug builds are validation tools, not
the default development loop.

Shell and Python helpers in this repo are glue: CI gates, fixture checks,
skill-local data helpers. Any stable parser, exit-code contract,
cross-product behavior, or shared capability belongs upstream in nils-cli.

## Home-scope policy: how the three top-level docs link up

```
AGENT_HOME.md   ← single source of global agent policy (this repo)
       ▲                 ▲
       │ symlink         │ symlink
$HOME/.codex/AGENTS.md   $HOME/.claude/CLAUDE.md

AGENTS.md       ← project-scope policy (this repo)
       ▲
       │ @AGENTS.md import (one-line file, not a symlink)
./CLAUDE.md
```

- `AGENT_HOME.md` is global policy loaded by both products. The filename is
  intentionally distinct from `AGENTS.md` / `CLAUDE.md` so neither tool
  reads the same policy twice when this repo is the active project.
- `AGENTS.md` is project-scope policy. `./CLAUDE.md` is a one-line
  `@AGENTS.md` import (Claude Code's import syntax) so Claude reads the
  same repo-local rules without a duplicate copy.
- Live Codex skill discovery reads `$HOME/.codex/skills`; live Claude
  discovery reads `$HOME/.claude/plugins/<p>/skills/`. Both are populated
  by `agent-runtime install --apply` from this repo's `build/` output.

## Quick start

1. Install the released CLI surface:
   ```bash
   brew tap sympoies/tap
   brew install sympoies/tap/nils-cli
   agent-runtime --version
   plan-tooling --version
   ```
2. Point `agent-docs` at this checkout and run the home-scope preflight
   before any repository edits:
   ```bash
   export AGENT_DOCS_HOME="$PWD"
   agent-docs resolve --context startup --strict --format checklist
   agent-docs resolve --context project-dev --strict --format checklist
   ```
3. Full development loop — render, golden refresh, drift audit, sandbox
   install rehearsal, runtime-smoke matrix, coupled nils-cli debug builds,
   and the release boundary — is in [`DEVELOPMENT.md`](DEVELOPMENT.md).

## Next reading

- [`DEVELOPMENT.md`](DEVELOPMENT.md) — setup, validation gates, release boundary.
- [`SUPPORT_MATRIX.md`](SUPPORT_MATRIX.md) — per-surface ship state, acceptance lanes, version pins.
- [`AGENT_HOME.md`](AGENT_HOME.md) — global agent policy loaded by both products.
- [`AGENTS.md`](AGENTS.md) — project-scope policy and current boundaries.
