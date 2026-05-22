# Dispatch Issue Record Contract

Use this contract when one issue is the live runtime for plan dispatch,
subagent task lanes, sprint gates, PR linkage, and final close gates.

## Authority Model

- `## Task Decomposition` is runtime truth for lanes, PR links, and row status.
- Dispatch state comments are derived checkpoints, not a second mutable task
  ledger.
- Issue-hosted source and plan snapshots are durable restart context.
- Use `deliver-dispatch-plan:*` marker names for heavyweight dispatch issues;
  do not reuse lightweight `execute-from-tracking-issue:*` markers here.

## Markers

Standalone marker lines:

- `<!-- deliver-dispatch-plan:snapshot:v1 kind=source -->`
- `<!-- deliver-dispatch-plan:snapshot:v1 kind=plan -->`
- `<!-- deliver-dispatch-plan:state:v1 -->`
- `<!-- deliver-dispatch-plan:session:v1 -->`
- `<!-- deliver-dispatch-plan:validation:v1 -->`
- `<!-- deliver-dispatch-plan:closeout:v1 -->`

Ignore marker strings inside copied source snapshots, fenced code blocks,
quotes, and examples. When several valid comments share a marker, the latest
valid comment is the current checkpoint unless a gate requires a specific URL.

## Checkpoint Shape

State checkpoints should include status, current sprint/gate, target scope,
`PLAN_BRANCH`, integration PR, current lane, next action, and a compact task
lane table.

Validation checkpoints should include pass/fail/blocked/skipped status,
commands or gate checks, PR/check evidence, runtime artifacts, and residual or
follow-up disposition.

Closeout checkpoints should include approval basis, merged sprint PRs, merged
integration PR, validation evidence, cleanup result, and dashboard repair
status.

## Dashboard

The mutable issue body should stay compact and derived from material state:
status, current sprint/gate, next action, blockers, latest dispatch
state/session/validation links, sprint PR summary, final integration PR, and
closeout readiness.
