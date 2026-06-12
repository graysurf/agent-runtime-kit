# plan-issue record post --execution-state-file and --summary-file are mutually exclusive

## Status

- Status: open
- First observed: 2026-05-28
- Area: `plan-issue record post` CLI argument parser
- Severity: low

## Signal

`plan-issue record post --kind state --execution-state-file <md>
--summary-file <md>` rejects at the argument parser with:

```
error: the argument '--execution-state-file <path>' cannot be used with '--summary-file <path>'
```

Both flags are documented as additive in `record post --help`:

- `--execution-state-file <path>` — "Markdown execution-state document for
  state lifecycle comments"
- `--summary-file <path>` — "Visible Markdown commentary appended after the
  structured payload"

Nothing in the help text or in the calling skill bodies signals that the two
are mutually exclusive. Operators trying to post a state checkpoint that
both renders the canonical execution-state ledger **and** carries a short
free-form summary above/below have to pick one and inline the other into
the picked file.

## Evidence

- Raw record: not captured (manual diagnosis, 2026-05-28, while posting the
  Sprint 2 close-ready state checkpoint on
  `graysurf/agent-runtime-kit#135`).
- Concrete failure: the first attempt to post the close-ready state
  comment combined `--execution-state-file
  docs/plans/2026-05-27-plan-archive-discover/plan-archive-discover-execution-state.md`
  with `--summary-file state-summary.md`; the parser rejected with the
  message quoted above. The workaround was to drop `--summary-file` and
  rely on the execution-state markdown to carry both the ledger and the
  free-form notes.
- The state comment that ultimately landed:
  `<https://github.com/graysurf/agent-runtime-kit/issues/135#issuecomment-4560783237>`
  (followed by the close-complete state at
  `<https://github.com/graysurf/agent-runtime-kit/issues/135#issuecomment-4560849526>`).
- Upstream CLI: `sympoies/nils-cli` `plan-issue-cli` crate.
- Re-verified on plan-issue 1.0.17 (2026-06-12): the parser still rejects
  the flag combination and `--help` still gives no hint of the mutex.
- Upstream finding filed: graysurf/plan-tracking-testbed#64 (2026-06-12).

## Impact

- Lost time on every state post that conceptually wants both flags. The
  rejection happens at the parser, so the operator only learns the rule
  by trying it.
- Skill bodies (`deliver-plan-tracking-issue`,
  `execute-plan-tracking-issue`) reference both flags as if they could be
  used together, which reinforces the surprise.
- Single low-severity friction; not a correctness gap.

## Current Workaround

Pick one input shape per state post:

- For state checkpoints anchored on the canonical execution-state document
  (Task Ledger + Session Log + Validation table), use
  `--execution-state-file` alone and put any session-specific commentary
  inline in the execution-state file's `## Session Log` or `## Notes`
  section.
- For short free-form state posts (no ledger render), use `--summary-file`
  alone.

## Promotion Criteria

Promote when either:

1. `plan-issue record post --kind state` accepts both flags together
   (rendering execution-state above the summary, or vice versa) with a
   well-defined visual contract, or
2. The mutex is documented prominently in the `record post --help` text
   and in the skill bodies that drive state checkpoint posts, so operators
   discover it before the argument parser rejects.

## Prevention Rule

When two CLI flags both feed the same lifecycle comment, either compose
them into one rendered output or surface the mutex in the help text and
upstream skill bodies — the argument parser's rejection is not a
discoverable contract.

## Next Action

Track graysurf/plan-tracking-testbed#64 (filed 2026-06-12): compose the two
flags (preferred) or document the mutex in `--help` plus the affected skill
bodies under `core/skills/dispatch/*-plan-tracking-issue/`. Promote per the
promotion criteria once either lands.
