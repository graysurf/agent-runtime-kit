# completion parity audit misses stale committed completion content

## Status

- Status: promoted
- First observed: 2026-06-12
- Area: nils-cli CI completion audits
- Severity: low

## Signal

A committed completion asset that encodes a **removed** clap constraint (or
stale flag descriptions) passes every nils-cli gate. In sympoies/nils-cli#824
the `conflicts_with` between `--execution-state-file` and `--summary-file`
was removed from `plan-issue record post`; `completions/zsh/_plan-issue` was
regenerated, but the sibling `completions/zsh/_plan-issue-local` — generated
from the same clap surface via the `plan-issue-local` bin — was missed. The
stale asset still carried `'(--summary-file)--execution-state-file=[...]'`,
so zsh would suppress `--summary-file` after `--execution-state-file` even
though the binary accepts both. Local-fast and full CI stayed green; only the
pre-merge review gate caught it (fixed in the same PR before merge).

## Evidence

- Raw record: `$HOME/.local/state/agent-runtime-kit/out/projects/sympoies__nils-cli/20260612-235014-skill-usage/skill-usage.record.json`
  (linked `skill-usage.record.v1` envelope for the #824 delivery).
- `scripts/ci/completion-flag-parity-audit.sh` checks flag presence and
  non-empty descriptions only; exclusion groups and description text are
  never compared against the clap surface.
- `scripts/ci/completion-asset-audit.sh` checks asset presence per the
  coverage matrix, not content.
- Upstream improvement filed: sympoies/nils-cli#827 (2026-06-12), with the
  byte-diff fix candidate.

## Impact

- Stale committed completions ship silently whenever a clap flag definition
  changes and not every bin's assets are regenerated; users get wrong shell
  behavior (suppressed flags, stale descriptions) with green CI.
- Multi-bin crates (`plan-issue` + `plan-issue-local`) are the trap: one
  clap surface, several committed assets, no gate tying them together.

## Current Workaround

When changing any clap definition (flags, conflicts, value enums, help
text), regenerate completions for **every** bin of the affected crate — list
them via the crate's `[[bin]]` targets or the existing
`completions/zsh/_<bin>` files — then run `zsh -n` / `bash -n` and diff
against the committed assets before committing.

## Promotion Criteria

Promote when nils-cli CI regenerates completions for every
completion-required bin and fails on any byte diff against the committed
assets (sympoies/nils-cli#827), or an equivalent content-parity gate lands.

## Prevention Rule

Deterministically generated, committed artifacts need a content-diff gate,
not just presence/coverage checks — presence audits cannot see staleness.

## Next Action

None. Resolved by sympoies/nils-cli#831 and ready to archive after strict verification.

Lifecycle link: `https://github.com/sympoies/nils-cli/pull/831`

## Archive

- Archived: 2026-06-12
- Reason: Content-freshness gate delivered and verified in sympoies/nils-cli#831.
- Durable link: `https://github.com/sympoies/nils-cli/pull/831`
