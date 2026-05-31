# audit-drift entropy heuristic flags legitimate case-slug references; warn fails CI under set -e

## Status

- Status: open
- First observed: 2026-06-01
- Area: audit-drift unsafe/entropy class; heuristic-system retained records; scripts/ci/all.sh Position 7
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

## Impact

- Operation records and inbox entries cannot cross-reference sibling cases or
  their archive folders by slug/path, even though that is the natural and most
  useful navigation aid. The author is forced to rewrite references as prose
  plus issue/PR numbers.
- `audit-drift --help` exposes no allowlist, baseline, or per-finding
  suppression (only `--verbose` to show suppressed findings), and the 0.4
  threshold is fixed, so a legitimate slug reference at the boundary cannot be
  whitelisted.
- Net effect: the heuristic-system is penalised for self-referencing, working
  against the cross-linking the retained records are meant to provide.

## Current Workaround

Reference sibling cases by spaced-word description plus the durable issue/PR
numbers instead of bare slug tokens, and keep any unavoidable hyphenated
identifier embedded mid-sentence rather than as the dominant token on its own
line. The existing GitHub PR required-check gating record (paths with `/`
separators) is a passing template.

## Promotion Criteria

Promote when either: (a) the audit-drift entropy class gains an allowlist,
per-path suppression, or committed baseline so legitimate retained-record slug
references can be exempted; or (b) warn-level unsafe findings stop being a hard
CI failure at Position 7 (block-only gating, with warn reported but non-fatal),
and `docs/source/nils-cli-pin.yaml` rolls forward to that release.

## Next Action

File upstream against the audit-drift entropy class (allowlist or
warn-versus-block gating) in nils-cli; the likely fix location is the
audit-drift unsafe/entropy scorer and/or the Position 7 exit handling in
`scripts/ci/all.sh`. Until then, keep the workaround above and the dogfooded
explicit-path rule added to the closeout skill in this same change.
