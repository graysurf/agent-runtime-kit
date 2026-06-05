# Issue Lifecycle Reference

This reference owns issue rules that repeat across issue-facing skills.

## Shared Rules

- Use `forge-cli issue ...` for provider reads and mutations. Direct provider
  commands are not the workflow surface for agent-owned issue records.
- Select labels from `manifests/forge-labels.yaml` when present. Ordinary
  follow-up records need one `type::`, one primary `area::`, a `state::` label,
  and `workflow::follow-up`; specialized trackers may add marker labels.
- Run `forge-cli label audit` for read-only checks and `forge-cli label ensure`
  only when label mutation is allowed. Do not use `--update-existing` unless
  drift repair was explicitly approved.
- Keep comments short and evidence-based: checked, result, decision, next.
  Link durable artifacts instead of pasting long logs.
- Keep unresolved issues open. Close only when the requested outcome is
  complete, the user explicitly abandons it, or the owning closeout workflow has
  verified the required lifecycle evidence.
- Avoid replacement issues for the same unresolved problem unless the user asks
  for a split or the scope boundary is clearly different.
