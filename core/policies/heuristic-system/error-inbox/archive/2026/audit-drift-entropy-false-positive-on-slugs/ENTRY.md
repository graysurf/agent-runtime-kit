# audit-drift entropy heuristic flags legitimate case-slug references; warn fails CI under set -e

## Status

- Status: promoted
- First observed: 2026-06-01
- Resolved: 2026-06-02 — criterion (a) path (1) landed. `drift-audit.allow.yaml`
  now demotes `operation-records/*/RECORD.md` and `operation-records/*/evidence/*`
  (mirroring the `error-inbox` entries), closing the last retained-record surface
  that still tripped the scorer. Verified with a throwaway probe: a `RECORD.md`
  line that scored `entropy_above_threshold` 0.4 went `unsafe/warn` (root exit 1)
  without the glob and `unsafe/suppressed` (root exit 0) with it. The inbox-entry
  and prose-policy-doc halves were already resolved (allowlist demotion and
  rewording in #251 respectively).
- Superseded upstream 2026-06-02 — nils-cli v1.0.5 (#754) reworked the unsafe
  scorer to skip path / kebab / dated identifier runs in the high-entropy
  signal, so the slug-path trigger above no longer fires: under v1.0.5 the
  `operation-records/*` records score `0.0` and need no demotion. With the host
  pinned to v1.0.5 (agent-runtime-kit #260), the `operation-records/*` allowlist
  globs were retired as redundant. The `error-inbox/*` demotions stay: those
  entries still score `0.4`, but on `keyword_prefix` (`token` / `sk-` / `secret`
  in case prose) and one genuine redaction nonce — residuals #754 did not touch
  (keyword over-match was the deferred problem (2) in sympoies/nils-cli#752,
  handled by rewording, not a scorer change).
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

- Closed gap (was: `operation-records/*/RECORD.md` not allowlisted). As of
  2026-06-02 the allowlist covers `operation-records/*/RECORD.md` and
  `operation-records/*/evidence/*`, so slug-heavy operation records are demoted
  the same way inbox entries are and no longer need hand-rewording. The three
  current records still read cleanly because the workaround was applied to them
  earlier; new records may now cross-reference siblings by slug freely.
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

None — all three retained-record surfaces (inbox entries, archived peers, and
operation records) are now exempted via `drift-audit.allow.yaml`, and the
prose-policy-doc case is handled by rewording. Archiving with status `promoted`.

The deeper upstream item is optional and out of scope here: the audit-drift
unsafe scorer still has a fixed 0.4 threshold and no allowlist flag, and Position
7 still treats a warn as a hard CI failure. If that ergonomics gap is worth
pursuing, file a fresh nils-cli issue for warn-versus-block gating rather than
reopening this entry, which tracked the repo-side allowlist coverage now closed.

## Archive

- Archived: 2026-06-02
- Reason: Promoted: operation-records allowlisted in drift-audit.allow.yaml, closing the last retained-record surface
