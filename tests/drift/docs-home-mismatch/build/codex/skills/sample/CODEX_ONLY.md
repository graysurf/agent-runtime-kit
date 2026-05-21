# /sample-codex-only

This skill renders only for codex; the claude product render must not
contain this template's output.

state: agent-out path-for --domain sample --topic codex-only
required: agent-out (>=0.5.0)
script: $CODEX_HOME/skills/sample/SKILL.md.tera
