# docker/ — standalone Linux image for Codex + Claude

A single-folder Docker setup that builds a Linux image where **Codex CLI** and
**Claude Code** both run on top of the shared `agent-runtime-kit` surface
(skills, hooks, docs, and the `nils-cli` primitives).

Tracking issue: <https://github.com/graysurf/agent-runtime-kit/issues/77>

> Status: first working PoC. Scope is intentionally Linux-only and
> host-independent — macOS-only surfaces (Alfred CLIs, `macos-agent`,
> `screen-record`, `op-ssh-sign`) are out of scope.

Everything Docker-related is contained in this folder. The build context is the
repository root (the image bakes the source so the rendered `~/.claude` /
`~/.codex` symlinks resolve), but the context is trimmed by
`Dockerfile.dockerignore` (a BuildKit per-Dockerfile ignore) so nothing is
added at the repo root.

## Layout

| File | Purpose |
| --- | --- |
| `Dockerfile` | Two-stage build: fetch `nils-cli` Linux binaries, then assemble the Node-based runtime. |
| `Dockerfile.dockerignore` | BuildKit per-Dockerfile context filter (keeps Docker out of the repo root). |
| `build.sh` | Pin-aligned build entrypoint: reads `nils-cli` version from `docs/source/nils-cli-pin.yaml`. |
| `compose.yaml` | Convenience wrapper for interactive use. |
| `entrypoint.sh` | Prints a capability banner and execs the requested command. |
| `env.example` | Template for `docker/.env` (auth passthrough; gitignored). |

## Build

From the repository root. The recommended entrypoint is `docker/build.sh`,
which pins the `nils-cli` version from `docs/source/nils-cli-pin.yaml` so the
image always matches the repo's authoritative pin gate:

```bash
docker/build.sh                      # -> agent-runtime-kit:dev
docker/build.sh -t agent-runtime-kit:0.30.1   # custom tag
docker/build.sh -n                   # dry-run: print the resolved command
docker/build.sh -- --no-cache        # pass extra flags to `docker build`
```

Plain `docker build` / `compose build` also work, but fall back to the
`NILS_CLI_VERSION` default baked into the `Dockerfile` (not the pin file):

```bash
docker build -f docker/Dockerfile -t agent-runtime-kit:dev .
docker compose -f docker/compose.yaml build
```

The image targets the host architecture (`linux/amd64` or `linux/arm64`)
automatically via `TARGETARCH`.

## Run

```bash
# Interactive shell with claude / codex / agent-runtime / nils-cli on PATH
docker run --rm -it agent-runtime-kit:dev

# One-shot a CLI
docker run --rm -it agent-runtime-kit:dev claude --version
docker run --rm -it agent-runtime-kit:dev codex --version

# Operate on a host project
docker run --rm -it -v "$PWD:/work" agent-runtime-kit:dev
```

Via compose (reads `docker/.env` if present):

```bash
cp docker/env.example docker/.env   # then fill in keys
docker compose -f docker/compose.yaml run --rm agent
```

## Auth

Auth is supplied at runtime and never baked into the image:

- **Claude Code** — `ANTHROPIC_API_KEY`, or `claude login` inside the
  container, or mount a credentials file to `~/.claude/.credentials.json`.
- **Codex CLI** — `OPENAI_API_KEY`, or `codex login`, or mount
  `~/.codex/auth.json`.
- **forge-cli / gh** — `GH_TOKEN` (or `GITHUB_TOKEN`).

```bash
docker run --rm -it -e ANTHROPIC_API_KEY -e OPENAI_API_KEY agent-runtime-kit:dev
```

## What's inside

- **Base**: `node:22-bookworm-slim` (Node ≥18 for both CLIs; glibc for their
  native binaries).
- **AI CLIs**: `@anthropic-ai/claude-code` and `@openai/codex` via `npm -g`.
- **nils-cli**: prebuilt Linux release tarball (`agent-runtime`, `agent-docs`,
  `semantic-commit`, `forge-cli`, `plan-tooling`, `plan-issue`, … ~40 binaries),
  pinned to the version in `docs/source/nils-cli-pin.yaml` and verified against
  the published `.sha256`. No Linuxbrew.
- **Core CLI tools** (`cli-tools.yaml` `core` profile): `ripgrep`, `fd`, `fzf`,
  `jq`, `yq`, `gh`, `bat`.
- **Rendered runtime**: `agent-runtime render` + `install` activate the shared
  surface into `~/.claude` and `~/.codex`, plus the `AGENT_HOME.md` policy
  symlinks (`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`).

## Known gaps / review follow-ups

These are deliberate v1 simplifications, to revisit after review:

- Built and smoke-tested for the host arch only; no multi-arch manifest push.
- macOS-only skills remain rendered but inert (their CLIs are absent); not yet
  pruned from the in-container surface.
- Private skills are **not** baked in. The private-skill overlay
  (`scripts/sync-private-skills.sh`, sourced from `$AGENT_PRIVATE_SKILLS_HOME`)
  lives outside the build context and is intentionally excluded — these skills
  are personal and machine-local, so baking them into a shareable image would
  be wrong. To use them in a container, mount the private source tree and run
  the overlay at runtime (the script is a no-op when its source is absent):

  ```bash
  docker run --rm -it \
    -v "$AGENT_PRIVATE_SKILLS_HOME:/opt/private-skills:ro" \
    -e AGENT_PRIVATE_SKILLS_HOME=/opt/private-skills \
    agent-runtime-kit:dev \
    bash -lc '$AGENT_KIT_SRC/scripts/sync-private-skills.sh --apply; exec bash'
  ```

- Auth is env/login/mount only; no helper for importing host credentials.
- Not yet wired into CI; no automated image smoke gate.
