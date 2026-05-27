# Plan Archive Query Pointer

The agent-plan-archive stores past plans, issues, PRs, and MRs for recurring
implementation context.

Consult it only before opening a new plan, or when diagnosing a suspected
recurring or previously resolved problem.

Use `grep` over `<archive-root>/catalog.json` for discovery when the exact ref
is unknown. Use `plan-archive query --ref`, `--plan`, or `--repo` to fetch the
latest cached context once a candidate is known.

Check each result's `fetched_at` before relying on it. Refresh on demand; do not
turn archive lookup into a background or every-task step.
