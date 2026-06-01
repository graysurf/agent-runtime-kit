# Runtime Hooks

`core/hooks/shared/` is the canonical source for hook logic shared by Codex and
Claude. Product-specific activation stays in `targets/<product>/hooks/` and in
the product link map.

The shared scripts accept neutral `AGENT_RUNTIME_*` environment variables. Do
not fork a hook per product unless the payload protocol or runtime harness
requires different behavior.

Install surfaces:

- Codex: `targets/codex/link-map.yaml` installs shared scripts under
  `$CODEX_HOME/hooks/` and syncs the managed hook block into
  `$CODEX_HOME/config.toml`.
- Claude: `targets/claude/link-map.yaml` installs shared scripts under
  `$HOME/.claude/hooks/`; `core/hooks/claude/settings.hooks.jsonc` is the
  source fragment for the settings `hooks` block.
