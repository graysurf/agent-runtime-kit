# Codex Code Review Delegation

Codex sessions may use subagent reviewers by default for code-review requests
when the active Codex host exposes subagent tools.

- Prefer `reviewer-quick` for small routine diffs and focused
  `reviewer-<lens>` agents for broad or risky diffs.
- The parent agent owns base-ref selection, lens selection, synthesis,
  validation, follow-up code, and PR action.
- Reviewer subagents inspect read-only and report findings.
- If subagent dispatch is unavailable or blocked by the active Codex runtime,
  run the same review inline and state that fallback.
