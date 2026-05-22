# Dispatch Issue Record Contract

Use this contract when one issue is the live runtime for plan dispatch,
subagent task lanes, PR linkage, review evidence, and final close gates.

## Authority Model

- The issue body is a mutable dashboard only.
- Dispatch ledger and state comments are runtime truth for lanes, PR links, and
  row status.
- Issue-hosted source and plan snapshots are durable restart context.
- New dispatch issues use the shared `issue-backed-plan:* profile=dispatch`
  marker family. Existing `deliver-dispatch-plan:*` or `dispatch-plan:*`
  comments remain recoverable through audit.
- Do not reuse lightweight `execute-from-tracking-issue:*` markers for dispatch
  issues.

## Markers

Standalone marker lines for new dispatch records:

- `<!-- issue-backed-plan:snapshot:v1 kind=source profile=dispatch -->`
- `<!-- issue-backed-plan:snapshot:v1 kind=plan profile=dispatch -->`
- `<!-- issue-backed-plan:state:v1 profile=dispatch -->`
- `<!-- issue-backed-plan:session:v1 profile=dispatch -->`
- `<!-- issue-backed-plan:validation:v1 profile=dispatch -->`
- `<!-- issue-backed-plan:review:v1 profile=dispatch -->`
- `<!-- issue-backed-plan:closeout:v1 profile=dispatch -->`

Ignore marker strings inside copied source snapshots, fenced code blocks,
quotes, and examples. When several valid comments share a marker, the latest
valid comment is the current checkpoint unless a gate requires a specific URL.

## Checkpoint Shape

State checkpoints should include status, current gate, target scope,
`PLAN_BRANCH`, integration PR, current lane, next action, and the current
dispatch ledger table.

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
