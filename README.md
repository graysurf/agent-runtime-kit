# agent-runtime-kit

`agent-runtime-kit` is the source repository for the local agent runtime layer
shared by **Codex CLI** and **Claude Code**. Skills, hooks, policy docs, plugin
metadata, manifests, and adapter templates are edited here, then rendered into
product-specific runtime homes such as `$HOME/.codex` and `$HOME/.claude`.

Per-surface ship state is tracked in [`SUPPORT_MATRIX.md`](SUPPORT_MATRIX.md).

## What this repo owns

- Portable runtime source under `core/`: skills, hooks, policies, schemas, and
  product-independent helper content.
- Product adapters under `targets/`: Codex and Claude link maps, templates, and
  activation surfaces.
- Machine-readable inventory under `manifests/`: skills, plugins, product
  capabilities, runtime roots, CLI floors, and labels.
- Generated review output under `build/`, pinned by `tests/golden/`.
- Repository docs, plans, fixtures, and validation scripts.

This repo does **not** ship binaries and does not track host runtime state,
auth, sessions, logs, caches, generated backups, or secrets.

## Version baseline

| component | floor | source |
|---|---|---|
| Codex CLI (`codex --version`) | `0.130.0` (effective 2026-06-03) | `manifests/runtime-roots.yaml` |
| Claude Code (`claude --version`) | `2.1.145` (effective 2026-06-03) | `manifests/runtime-roots.yaml` |
| `nils-cli` surface (`agent-runtime --version`) | `v0.22.3` | `docs/source/nils-cli-surface.md` |

Per-skill `nils-cli` floors live in `manifests/skills.yaml` `required_clis`
and are tighter than the surface-level pin.

## Runtime model

The repo separates source, rendered output, installed runtime homes, and
writable per-host state.

```text
core/                     manifests/         targets/
  skills/  hooks/  docs/  *.yaml             codex/   claude/
  policies/                                  link-map.yaml + adapter files
        |                     |                      |
        +---------------------+----------------------+
                              |
                              | agent-runtime render --product <codex|claude>
                              v
                         build/<product>/      (regenerated, golden-pinned)
                              |
                              | agent-runtime install --apply
                              v
       live_home: $HOME/.codex   $HOME/.claude       (managed runtime)
       state_home: $XDG_STATE_HOME/agent-runtime-kit/{codex,claude}/
                   override via CODEX_AGENT_STATE_HOME / CLAUDE_KIT_STATE_HOME
                   (writable artifacts under <state_home>/out/ and /backups/)
```

Live Codex skill discovery reads `$HOME/.codex/skills`; live Claude discovery
reads `$HOME/.claude/plugins/<p>/skills/`. Both are populated from this repo's
rendered `build/` output by `agent-runtime install --apply`.

## CLI boundary

The `agent-runtime` command and the rest of the runtime surface
(`agent-docs`, `agent-out`, `plan-tooling`, `forge-cli`,
`heuristic-inbox`, and related tools) live in
[`sympoies/nils-cli`](https://github.com/sympoies/nils-cli) and install via
Homebrew.

```bash
brew tap sympoies/tap
brew install sympoies/tap/nils-cli
agent-runtime --version
plan-tooling --version
```

Skills declare the binaries they need through `required_clis`. Released
contracts are pinned only after the upstream nils-cli release and Homebrew tap
update complete. Local debug builds are validation tools, not the default
development loop.

Shell and Python helpers in this repo are glue: CI gates, fixture checks, and
skill-local data helpers. Stable parsers, exit-code contracts, cross-product
behavior, and shared capabilities belong upstream in nils-cli.

## Local setup

Clone or enter your local checkout, then point `agent-docs` at that checkout:

```bash
cd /path/to/agent-runtime-kit
export AGENT_DOCS_HOME="$PWD"
agent-docs resolve --context startup --strict --format checklist
agent-docs resolve --context project-dev --strict --format checklist
```

For persistent local shells, add a host-local path to `~/.zshenv`:

```zsh
# Replace this with your local checkout path.
export AGENT_DOCS_HOME="/path/to/agent-runtime-kit"
```

Do not commit a personal absolute path to this repo. Do not point
`AGENT_DOCS_HOME` at `$AGENT_HOME`, `$HOME/.agents`, `$HOME/.codex`, or
`$HOME/.claude`; it should point at the checked-out `agent-runtime-kit` docs
catalog. `$AGENT_HOME` is reserved for writable `agent-out` state.

## Development workflow

Before implementation, tests, commits, delivery, or documentation edits, run
the required `agent-docs` preflight from the repository root:

```bash
agent-docs resolve --context startup --strict --format checklist
agent-docs resolve --context project-dev --strict --format checklist
```

Documentation changes also follow
[`docs/source/docs-placement-retention-policy-v1.md`](docs/source/docs-placement-retention-policy-v1.md),
which is registered in `AGENT_DOCS.toml` as required `project-dev` context.

The full local validation gate is:

```bash
bash scripts/ci/all.sh
```

See [`DEVELOPMENT.md`](DEVELOPMENT.md) for setup details, render and golden
refresh commands, drift audit, sandbox install rehearsal, runtime-smoke checks,
and coupled nils-cli debug-build guidance.

## Repository map

```text
.
├── AGENT_HOME.md        # shared home-scope policy for Codex and Claude
├── AGENTS.md            # repo-local policy for this checkout
├── CLAUDE.md            # Claude import wrapper for AGENTS.md
├── AGENT_DOCS.toml      # project-local agent-docs dispatch entries
├── core/
│   ├── docs/            # schemas and shared source docs
│   ├── hooks/           # shared and product-specific hook sources
│   ├── policies/        # portable runtime policies and retained records
│   └── skills/          # portable skill source by domain
├── targets/             # Codex and Claude adapter surfaces
├── manifests/           # machine-checkable runtime inventory
├── docs/
│   ├── source/          # architecture, policies, specs, and references
│   └── plans/           # plan bundles and retained execution records
├── build/               # generated render output
├── tests/
│   ├── golden/          # render-golden snapshots
│   ├── drift/           # drift-audit fixtures
│   ├── runtime-smoke/   # runtime skill acceptance harness
│   └── projects/        # project-local overlay smoke fixtures
└── scripts/             # setup, sync, CI, and validation glue
```

## Skills

Ten skill domains are currently rendered into Codex entries and Claude plugins:

`browser` · `code-review` · `conversation` · `dispatch` · `evidence` ·
`issue` · `media` · `meta` · `pr` · `reporting`

Representative skills include `pr:deliver-github-pr`,
`dispatch:deliver-plan-tracking-issue`, `evidence:test-first-evidence`,
`issue:issue-triage`, `meta:semantic-commit`, `reporting:project-retro`, and
`media:screen-record`.

The authoritative skill list and CLI floors live in `manifests/skills.yaml`.
The skill catalog is summarized in [`core/skills/README.md`](core/skills/README.md).

## Policy wiring

```text
AGENT_HOME.md   <- single source of global agent policy
       ^                 ^
       | symlink         | symlink
$HOME/.codex/AGENTS.md   $HOME/.claude/CLAUDE.md

AGENTS.md       <- project-scope policy for this repo
       ^
       | @AGENTS.md import
./CLAUDE.md
```

`AGENT_HOME.md` intentionally has a different name from `AGENTS.md` and
`CLAUDE.md`, so neither product reads the same policy twice when this source
repo is the active project.

## Next reading

- [`DEVELOPMENT.md`](DEVELOPMENT.md): setup, validation gates, and release boundary.
- [`SUPPORT_MATRIX.md`](SUPPORT_MATRIX.md): per-surface ship state and acceptance lanes.
- [`core/skills/README.md`](core/skills/README.md): skill catalog by category and series.
- [`AGENT_HOME.md`](AGENT_HOME.md): global agent policy loaded by both products.
- [`AGENTS.md`](AGENTS.md): project-scope policy and current boundaries.
