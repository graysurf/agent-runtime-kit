# heuristic-inbox new requires a skill-usage record; no path for mid-session findings

## Status

- Status: open
- First observed: 2026-05-27
- Area: heuristic-inbox CLI; Heuristic System retention policy
- Severity: low

## Signal

`heuristic-inbox new` requires `--from-skill-usage <PATH>` and can only
scaffold a curated `error-inbox` entry from a `skill-usage.record.v1` envelope.
Findings diagnosed mid-session that do not originate from a single named-skill
invocation have no scaffolding path: they must be hand-authored, which then
trips the non-obvious `verify --strict` `missing raw evidence pointer` check.
The CLI requirement is **narrower than the policy** — the Promotion Ladder in
`HEURISTIC_SYSTEM.md` treats "important unresolved workflow gap -> curated
error-inbox entry" without requiring a skill-usage envelope; skill-usage is
only the preferred path when friction happens inside an active named-skill
workflow.

## Evidence

- Raw record: not captured (live in-session diagnosis, 2026-05-27).
- Concrete instance: while retaining the worktree-signing case
  (`worktree-unsigned-commit-config-drift`), there was no skill-usage record,
  so `new` could not be used; the entry was hand-authored and first failed
  `heuristic-inbox verify --strict` with `missing raw evidence pointer` until a
  `Raw record:` line was added by hand.
- `ingest-evidence` already provides a non-skill-usage evidence path
  (`--from <file>`), so decoupling `new` from skill-usage is consistent with
  the existing design surface.
- Upstream issue: sympoies/nils-cli#585.

## Impact

- Two creation paths exist but only one is scaffolded: `new` helps the
  evidence-anchored (skill-usage) path; the equally policy-sanctioned
  "workflow gap" path is unsupported and must be hand-authored.
- Authors must memorize the schema, including the undocumented `Raw record:`
  pointer that `verify --strict` demands, or they hit a confusing failure.

## Current Workaround

Hand-author `error-inbox/<slug>/ENTRY.md` following an existing entry's shape,
include a `Raw record:` pointer (e.g. `not captured (live diagnosis, <date>)`)
so `verify --strict` passes, then run
`heuristic-inbox verify <folder> --strict`. Use `ingest-evidence --from` to
attach any redacted artifacts.

## Promotion Criteria

Promote when sympoies/nils-cli#585 lands any one of:

- (a) `heuristic-inbox new --from-evidence <path>` scaffolds from an arbitrary
  redacted evidence file (preferred; keeps the evidence-anchoring invariant); or
- (b) a guarded `--manual` mode scaffolds from `--title/--area/--severity/
  --next-action` and auto-fills a `Raw record: not captured` pointer, with the
  descriptive flags required and strict body/redaction checks retained; or
- (c) the `heuristic-inbox` SKILL/docs document the hand-authored path,
  including the `Raw record:` pointer requirement, so the gap is at least no
  longer silent.

## Next Action

Track sympoies/nils-cli#585. No blocking work — the hand-authored workaround is
sufficient for now; this entry exists so the friction is visible and the CLI
fix is anchored to a concrete case.
