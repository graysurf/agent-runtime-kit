# agent-runtime-kit

Shared source of truth for agent runtime surfaces across Codex and Claude.

This repository is intended to replace the current one-way flow where
`agent-kit` is developed first and then ported into `claude-kit`. The target
model is one canonical source tree plus product adapters that render or link the
right files into `~/.codex` and `~/.claude`.

Start with:

- [Inventory And Target Architecture](docs/source/inventory-target-architecture.md)

