# Dispatch Issue Record Contract

Use this contract when one issue is the live runtime for plan dispatch,
subagent task lanes, PR linkage, review evidence, and final close gates.

## Authority Model

- The issue body is a mutable dashboard only.
- Dispatch ledger and state comments are runtime truth for lanes, PR links, and
  row status.
- Issue-hosted source and plan snapshots are durable restart context.
- New dispatch issues use the shared `plan-issue-record:v2 profile=dispatch`
  marker family (rendered by `plan-issue record render-comment --profile
  dispatch --kind <role>` on `plan-issue >=0.17.7`). Older
  `issue-backed-plan:*:v1 profile=dispatch` and `execute-from-tracking-issue:*`
  comments remain readable but no longer round-trip; reopen any closed gate
  by rendering a fresh v2 comment.
- Do not reuse `profile=tracking` markers for dispatch issues; the audit
  filter rejects them as unsupported for the dispatch profile.

## Markers

Standalone marker lines for new dispatch records:

- `<!-- plan-issue-record:v2 role=source profile=dispatch -->`
- `<!-- plan-issue-record:v2 role=plan profile=dispatch -->`
- `<!-- plan-issue-record:v2 role=state profile=dispatch -->`
- `<!-- plan-issue-record:v2 role=session profile=dispatch -->`
- `<!-- plan-issue-record:v2 role=validation profile=dispatch -->`
- `<!-- plan-issue-record:v2 role=review profile=dispatch -->`
- `<!-- plan-issue-record:v2 role=closeout profile=dispatch -->`

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
