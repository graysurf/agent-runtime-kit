# /sample-determinism

state: agent-out path-for --domain sample --topic determinism
required: agent-out (>=0.5.0)
script: $CODEX_HOME/skills/sample/SKILL.md.tera

run --docs-home "$HOME/.claude" --foo
