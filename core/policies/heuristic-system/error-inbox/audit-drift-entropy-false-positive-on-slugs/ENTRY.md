# audit-drift entropy heuristic flags legitimate case-slug references; warn fails CI under set -e

## Status

- Status: open
- First observed: 2026-06-01
- Area: audit-drift unsafe class (entropy + keyword_prefix); heuristic-system retained records; scripts/ci/all.sh Position 7
- Severity: medium

## Signal

While authoring two operation records under `operation-records/`,
`agent-runtime audit-drift` raised `unsafe/warn` findings on the record bodies
(signal `entropy_above_threshold`, score 0.4). The trigger was any line whose
dominant token was a long hyphenated case-slug path — roughly 35 to 52
characters, i.e. an archived inbox case folder name written inside a backtick
path reference. Those lines are exactly how a record cross-references its
sibling cases and source folders.

## Evidence

- Raw record: not captured (manual diagnosis during a live session, 2026-06-01).
- Per affected record, audit-drift reported `score=0.4
  signals=entropy_above_threshold(line N); thresholds: >=0.8 block, >=0.4 warn,
  <0.4 suppressed`.
- The detector scores per line and reports one finding per file: clearing the
  flagged line surfaced the next slug-dominated line, so every slug line had to
  be reworded before the file passed.
- Paths split by `/` into short segments (as in the existing GitHub PR
  required-check gating record) stay under 0.4; a single long hyphen-joined slug
  segment does not, even when wrapped at the repo's line width.
- `scripts/ci/all.sh` Position 7 runs `agent-runtime audit-drift` bare under
  `set -euo pipefail`, so a warn (audit-drift exit 1) fails the entire gate.
  Warn is not advisory in CI here.
- Related trigger class (2026-06-02, agent-runtime-kit#251): the `keyword_prefix`
  signal (distinct from `entropy_above_threshold`) fired at score 0.4 on a plain
  prose policy doc, `core/policies/git-delivery.md`, after a bullet describing
  commit-body rules introduced flag-shaped tokens. Unlike a retained-record slug
  reference, a prose policy doc that only describes CLI flags is best fixed by
  rewording to drop the flagged tokens (the precise flag examples can live in the
  owning SKILL.md), NOT by adding the doc to the command-pattern allowlist — that
  allowlist is reserved for files whose purpose is to carry command- or
  credential-shaped content as evidence. Resolved by rewording in #251.

## Impact

- Remaining gap (2026-06-02): `operation-records/*/RECORD.md` is NOT in the
  allowlist, so a slug-heavy operation record still trips the scorer and must be
  reworded by hand (the three current records under `operation-records/` pass
  only because the workaround below was applied). Inbox entries no longer hit
  this — they are allowlisted — so operation records are the last retained-record
  surface forced to rewrite slug references as prose plus issue/PR numbers.
- Correction (2026-06-02): a committed per-path allowlist DOES exist —
  `drift-audit.allow.yaml` at the repo root, read automatically by `audit-drift`,
  which demotes a matched finding by one tier (block to warn, warn to suppressed)
  with a documented reason. It already exempts `error-inbox/*/ENTRY.md`, the
  `error-inbox/*/evidence/*` files, and the `archive/` peers. What the CLI lacks
  is an allowlist FLAG; the 0.4 threshold and the per-line scorer are still fixed,
  and a one-tier demotion of a block-level (score >= 0.8) line only reaches warn,
  which still fails CI.
- Net effect: the heuristic-system is penalised for self-referencing, working
  against the cross-linking the retained records are meant to provide.

## Current Workaround

Reference sibling cases by spaced-word description plus the durable issue/PR
numbers instead of bare slug tokens, and keep any unavoidable hyphenated
identifier embedded mid-sentence rather than as the dominant token on its own
line. The existing GitHub PR required-check gating record (paths with `/`
separators) is a passing template.

## Promotion Criteria

The committed-allowlist half of the original criterion is already met for inbox
entries (see Correction above), so the bar is now narrower. Promote when either:
(a) `operation-records/*/RECORD.md` (and `operation-records/*/evidence/*`) gain
the same `drift-audit.allow.yaml` per-path demotion the `error-inbox` paths
already have — closing the last retained-record surface that still trips the
scorer — or the upstream scorer stops flagging legitimate slug references; or
(b) warn-level unsafe findings stop being a hard CI failure at Position 7
(block-only gating, with warn reported but non-fatal), and
`docs/source/nils-cli-pin.yaml` rolls forward to that release.

## Next Action

Two concrete paths, smallest first: (1) add `operation-records/*/RECORD.md` and
`operation-records/*/evidence/*` globs to `drift-audit.allow.yaml`, mirroring the
existing `error-inbox` entries and their rationale, to exempt the last
retained-record surface; and/or (2) file upstream against the audit-drift unsafe
scorer (fixed 0.4 threshold, no allowlist flag) and the Position 7 exit handling
in `scripts/ci/all.sh` (warn-versus-block gating). The inbox-entry and
prose-policy-doc halves are already resolved — allowlist demotion and rewording
respectively — so keep the workaround for operation records only until (1) lands.
