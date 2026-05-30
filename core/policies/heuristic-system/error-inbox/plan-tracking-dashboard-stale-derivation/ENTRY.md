# Final Dashboard renders stale target_scope/current/next_action and frozen state header

## Status

- Status: open
- First observed: 2026-05-30
- Area: plan-issue (renderer / run-state controller)
- Severity: high

## Signal

On a clean happy-path run of the plan-tracking skill series
(`create-plan-tracking-issue` → `execute-plan-tracking-issue` →
`plan-tracking-issue-closeout`) against `graysurf/plan-tracking-testbed`,
issue #54 closed with a Final Dashboard whose human-visible fields never
advanced past the pre-flight authoring, even though the hidden payload
`status` was correctly `complete` and the closeout gate passed.

User-reported: "Final Dashboard 很多地方都沒有更新" (many Final Dashboard
fields did not update).

## Evidence

- Raw record: not captured (manual diagnosis, 2026-05-30)
- Installed versions: `plan-issue 0.31.0`, `plan-tooling 0.31.0`.
- Repro issue: https://github.com/graysurf/plan-tracking-testbed/issues/54

Final Dashboard (closed issue body) actual vs expected:

| Field | Rendered | Expected |
| --- | --- | --- |
| Status | `complete` | `complete` (OK) |
| Target scope | `in-progress` | the plan scope text |
| Current task | `1.1` | `complete` (both tasks done) |
| Next action | *(blank)* | `closeout` / `none` |

`state`-role payload evolution (decoded `plan-issue-record-payload` hex):

| Source | status | target_scope | current | next_action |
| --- | --- | --- | --- | --- |
| `record open` (parses execution-state.md header) | in-progress | `Plan: …Happy Path…` | `Sprint 1 ready` | `execute Sprint 1 tasks` |
| `tracking checkpoint` (first) | in-progress | `in-progress` | `1.1` | `` |
| `tracking checkpoint` (final) | complete | `in-progress` | `1.1` | `` |

The rendered `## Execution State` comment body also froze its entire header
verbatim from the canonical `*-execution-state.md`
(`Status: ready-to-start`, `Tracking issue: tbd`,
`Source/Plan/Initial state snapshot: pending`, `Current task: none`,
`Last updated: 2026-05-28`) across every state comment; only the
`## Task Ledger` table rows advanced.

## Impact

This is systemic: every tracking-profile plan's primary human scan surface
(the issue dashboard) and every rendered Execution State comment body show
stale or wrong values after the first `tracking checkpoint`. The durable
payload and closeout gate are unaffected, so the defect is invisible to a
machine audit but misleads any human reading the issue.

Root cause is in `nils-cli` `plan-issue-cli`, not the runtime-kit skills:

1. `tracking checkpoint` derives the state payload `target_scope` from the
   run-state phase/status word (`in-progress`) instead of carrying the real
   plan scope set at `record open`.
2. `current` is set from run-state `selected_task` but is never advanced
   (stuck at the first task) and never reaches a terminal value at
   `ready-for-close`; `next_action` has no source and stays empty. The
   documented `tracking run update` surface exposes no
   `--target-scope` / `--current` / `--next-action` flag, so a skill cannot
   set these through the controller.
3. The visible `## Execution State` body is emitted verbatim from
   `*-execution-state.md`; only `## Task Ledger` rows are patched (by
   `plan-tooling ledger-update`). The header prose is never re-rendered, per
   `run-state-controller.md` Open Question #1 ("CLI does not edit the
   Markdown; require the agent to keep the file accurate"), but no skill or
   tool keeps the header accurate.

The dashboard is already auto-derived from the latest state payload, so the
fix is not "repair more often" — it is to make the renderer derive these
human-visible fields from durable evidence at render time:

- `current` = first non-terminal `## Task Ledger` row id; `complete` when all
  terminal.
- `next_action` = next pending task; `closeout` at `ready-for-close`.
- `target_scope` = carried from plan/run-state scope, never overwritten with
  a status word.
- the visible Execution State header re-rendered from these derived values
  (resolving Open Question #1 toward CLI-owned header rendering).

Affected surfaces:

- `core/skills/dispatch/plan-issue-spec/comment-taxonomy.md` (Execution State
  + Dashboard templates) and `run-state-controller.md` (Open Question #1) —
  spec updates that must follow the CLI fix.
- `core/skills/dispatch/execute-plan-tracking-issue/SKILL.md.tera` and
  `plan-tracking-issue-closeout/SKILL.md.tera` — only if the chosen fix keeps
  header maintenance agent-owned.

No direct upstream issue exists yet. Closest open upstream context:
sympoies/nils-cli#696 (provider-neutral plan-tracking rework).

## Current Workaround

None at the skill layer: the broken fields come from the controller-derived
payload and there is no CLI flag to override them. The hidden payload status
and the closeout gate are correct, so closeout still succeeds; treat the
human-visible dashboard `Target scope` / `Current task` / `Next action` and
the Execution State header as unreliable until the renderer fix lands. Do not
hand-edit closed issue bodies to paper over it.

## Promotion Criteria

Promote after the nils-cli renderer/controller fix is implemented, released,
and validated — specifically when the runtime-kit driver guards
`check_dashboard_target_scope_fresh`, `check_dashboard_current_task_fresh`,
`check_dashboard_next_action_present`, and `check_state_body_not_frozen_preflight`
in `scripts/test-plan-tracking/lib/assert.sh` go green on a fresh happy-path
run.

## Next Action

Fix the `nils-cli` `plan-issue-cli` renderer/run-state controller to derive
the dashboard and Execution State header fields (`target_scope`, `current`,
`next_action`, and the visible header) from durable evidence (`## Task Ledger`
+ plan scope + FSM phase) at render time, then update
`comment-taxonomy.md` / `run-state-controller.md` Open Question #1 to match.
The acceptance test is the set of `#54` freshness guards already added to the
plan-tracking test driver.
