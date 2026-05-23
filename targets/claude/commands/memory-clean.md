---
name: memory-clean
description: >
  Run consolidate-memory with user-safe defaults — merge duplicates,
  fix stale facts, prune the MEMORY.md index. Skips destructive
  operations unless `--force` is passed.
allowed-tools: Skill, Read, Write, Edit, Bash, Glob, Grep
argument-hint: "[--force] [--dry-run]"
---

# /memory-clean

Wraps `anthropic-skills:consolidate-memory` with safe defaults.

## Behaviour

1. Invoke `Skill consolidate-memory`.
2. Default mode: `--dry-run` — report changes without writing.
3. With `--force`: actually apply (merge duplicates, rewrite stale entries,
   drop unrelated notes).

## Examples

```text
/memory-clean
/memory-clean --force
/memory-clean --dry-run
```

## Boundaries

- Never touches `~/.claude/projects/*/sessions/`, `history.jsonl`, or
  `auth-context.json`.
- Memory typing follows Claude Code defaults (`user` / `feedback` /
  `project` / `reference`); `consolidate-memory` keeps the existing
  frontmatter unless a duplicate or stale entry warrants rewriting.

## References

- `anthropic-skills:consolidate-memory` SKILL.md
