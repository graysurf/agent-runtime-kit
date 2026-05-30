# syntax=docker/dockerfile:1.7
# =============================================================================
# agent-runtime-kit — standalone Linux image for Codex CLI + Claude Code.
#
# Tracking issue: https://github.com/graysurf/agent-runtime-kit/issues/77
# Scope: Linux-only / host-independent. macOS-only surfaces (Alfred CLIs,
# macos-agent, screen-record, op-ssh-sign) are intentionally out of scope.
#
# All Docker assets live under docker/. Build from the repo root:
#   docker build -f docker/Dockerfile -t agent-runtime-kit:dev .
# or:
#   docker compose -f docker/compose.yaml build
#
# The build context is the repo ROOT (the image bakes the source so the live
# ~/.claude and ~/.codex symlinks resolve). docker/Dockerfile.dockerignore
# trims the context so no repo-root .dockerignore is needed.
# =============================================================================

ARG NODE_VERSION=22
# Fallback only. The pin-aligned entrypoint `docker/build.sh` passes this from
# docs/source/nils-cli-pin.yaml so the pin gate stays the single source; keep
# this default roughly in step with that pin for plain `docker build` users.
ARG NILS_CLI_VERSION=v0.30.1
ARG CLAUDE_CODE_VERSION=latest
ARG CODEX_VERSION=latest
ARG GH_VERSION=2.65.0
ARG YQ_VERSION=v4.44.6

# -----------------------------------------------------------------------------
# Stage 1 — fetch nils-cli prebuilt Linux binaries.
#
# nils-cli ships the agent-runtime, agent-docs, semantic-commit, forge-cli,
# plan-tooling, plan-issue, plan-archive (and ~35 more) binaries as a single
# release tarball. We download the arch-matched tarball and verify it against
# the published .sha256 sidecar — no Linuxbrew required.
# -----------------------------------------------------------------------------
FROM debian:bookworm-slim AS nils
ARG NILS_CLI_VERSION
ARG TARGETARCH
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends curl ca-certificates tar; \
    rm -rf /var/lib/apt/lists/*; \
    case "$TARGETARCH" in \
      amd64) triple="x86_64-unknown-linux-gnu" ;; \
      arm64) triple="aarch64-unknown-linux-gnu" ;; \
      *) echo "unsupported TARGETARCH=$TARGETARCH" >&2; exit 1 ;; \
    esac; \
    base="https://github.com/sympoies/nils-cli/releases/download/${NILS_CLI_VERSION}"; \
    file="nils-cli-${NILS_CLI_VERSION}-${triple}.tar.gz"; \
    cd /tmp; \
    curl -fsSL -o "$file" "${base}/${file}"; \
    curl -fsSL -o "${file}.sha256" "${base}/${file}.sha256"; \
    expected="$(cut -d' ' -f1 "${file}.sha256")"; \
    echo "${expected}  ${file}" | sha256sum -c -; \
    mkdir -p /opt/nils; \
    tar -xzf "$file" -C /opt/nils --strip-components=1; \
    test -x /opt/nils/bin/agent-runtime

# -----------------------------------------------------------------------------
# Stage 2 — runtime image.
# Node base gives Node + npm for Claude Code and Codex CLI (both Node-launched,
# glibc-linked native binaries — hence Debian, not Alpine).
# -----------------------------------------------------------------------------
FROM node:${NODE_VERSION}-bookworm-slim AS runtime
ARG CLAUDE_CODE_VERSION
ARG CODEX_VERSION
ARG GH_VERSION
ARG YQ_VERSION
ENV DEBIAN_FRONTEND=noninteractive

# OCI labels. `image.source` links the published GHCR package to this repo
# (and shows it under the repo's Packages) for any build path; the CI publish
# workflow also injects revision / created via docker/metadata-action.
LABEL org.opencontainers.image.source="https://github.com/graysurf/agent-runtime-kit" \
      org.opencontainers.image.title="agent-runtime-kit" \
      org.opencontainers.image.description="Standalone Linux image for Codex CLI + Claude Code on the agent-runtime-kit surface"

# OS deps + the cli-tools.yaml "core" profile, mapped to Debian packages.
# python3 is required by the rendered hook scripts (*.py guardrails).
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates curl git tar xz-utils gnupg less bash \
      python3 \
      ripgrep fd-find fzf jq bat; \
    rm -rf /var/lib/apt/lists/*; \
    # Debian renames fd->fdfind and bat->batcat; expose the documented names.
    ln -sf "$(command -v fdfind)" /usr/local/bin/fd; \
    ln -sf "$(command -v batcat)" /usr/local/bin/bat

# gh + yq are not in Debian stable; install arch-matched release binaries.
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    curl -fsSL -o /tmp/gh.tgz \
      "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${arch}.tar.gz"; \
    tar -xzf /tmp/gh.tgz -C /tmp; \
    install -m 0755 "/tmp/gh_${GH_VERSION}_linux_${arch}/bin/gh" /usr/local/bin/gh; \
    curl -fsSL -o /usr/local/bin/yq \
      "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${arch}"; \
    chmod 0755 /usr/local/bin/yq; \
    rm -rf /tmp/gh*; \
    gh --version; yq --version

# nils-cli binaries (agent-runtime et al.) from stage 1.
COPY --from=nils /opt/nils/bin/ /usr/local/bin/
RUN agent-runtime --version

# Claude Code + Codex CLI via npm (global).
RUN set -eux; \
    npm install -g \
      "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
      "@openai/codex@${CODEX_VERSION}"; \
    npm cache clean --force; \
    claude --version; \
    codex --version

# Non-root runtime user. The node base ships a uid-1000 "node" user; replace it
# with "agent" so uid 1000 is predictable for optional host bind-mounts.
ARG AGENT_UID=1000
ARG AGENT_GID=1000
RUN set -eux; \
    userdel -r node 2>/dev/null || true; \
    groupadd -g "${AGENT_GID}" agent; \
    useradd -m -u "${AGENT_UID}" -g "${AGENT_GID}" -s /bin/bash agent; \
    mkdir -p /work; \
    chown agent:agent /work

# Stable env contract (mirrors the host AGENT_HOME.md / runtime-roots.yaml).
ENV AGENT_KIT_SRC=/opt/agent-runtime-kit \
    AGENT_DOCS_HOME=/opt/agent-runtime-kit \
    CODEX_HOME=/home/agent/.codex \
    XDG_STATE_HOME=/home/agent/.local/state \
    AGENT_HOME=/home/agent/.local/state/agent-runtime-kit \
    AGENT_RUNTIME_KIT_DOCKER=1

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0755 /usr/local/bin/entrypoint.sh

# Bake the source so the rendered live homes (symlinks into the source tree)
# resolve without any host bind-mount.
COPY --chown=agent:agent . ${AGENT_KIT_SRC}

USER agent
WORKDIR ${AGENT_KIT_SRC}

# Render the product surfaces (build/ is gitignored, so regenerate it here) and
# activate them into the container's ~/.claude and ~/.codex. Then add the
# home-scope policy symlinks the host setup uses (AGENT_HOME.md).
RUN set -eux; \
    agent-runtime render --product codex; \
    agent-runtime render --product claude; \
    mkdir -p "${AGENT_HOME}/claude" "${AGENT_HOME}/codex" \
             "${HOME}/.claude" "${CODEX_HOME}"; \
    agent-runtime install --source-root "${AGENT_KIT_SRC}" --product claude \
      --live-home "${HOME}/.claude" --state-home "${AGENT_HOME}/claude" --apply; \
    agent-runtime install --source-root "${AGENT_KIT_SRC}" --product codex \
      --live-home "${CODEX_HOME}" --state-home "${AGENT_HOME}/codex" --apply; \
    ln -sfn "${AGENT_KIT_SRC}/AGENT_HOME.md" "${HOME}/.claude/CLAUDE.md"; \
    ln -sfn "${AGENT_KIT_SRC}/AGENT_HOME.md" "${CODEX_HOME}/AGENTS.md"

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash", "-l"]
