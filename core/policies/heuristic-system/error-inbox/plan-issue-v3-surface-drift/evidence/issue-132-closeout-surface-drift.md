# Heuristic Evidence: Plan Tracking Closeout Surface Drift

## Signal

During issue #132 closeout, `plan-issue tracking close-ready --provider-repo graysurf/agent-runtime-kit --issue 132 --expect-visible` returned `ready=false`, `fsm_state=RECORD_UNOPENED`, and missing source/plan/state/session/validation/review blockers even after those lifecycle comments were present on the provider issue.

The deterministic mode using freshly fetched `body` and `comments` evidence returned `ready=true`, `fsm_state=RECORD_READY_FOR_CLOSE`, with all visible lifecycle roles passing.

## Working Path

`plan-issue record close --dry-run` against the live issue and linked PR refs passed the strict closeout gate, including merged PR checks and closeout preview. `plan-issue record close` then posted the closeout comment and closed issue #132.

## Impact

The `plan-tracking-issue-closeout` skill entrypoint still advertises the `tracking close-ready --provider-repo --issue` path, but the live controller can misclassify an otherwise close-ready issue as unopened. Agents should not patch around this by posting more progress evidence. Use `record close --dry-run` plus `record close` as the final gate until the live tracking controller reconciles provider evidence correctly.

## Evidence Pointers

- Issue: https://github.com/graysurf/agent-runtime-kit/issues/132
- Closeout comment: https://github.com/graysurf/agent-runtime-kit/issues/132#issuecomment-4556592379
- Runtime evidence: `<workspace>/out/projects/graysurf__agent-runtime-kit/20260528-000636-issue-132-delivery/`
