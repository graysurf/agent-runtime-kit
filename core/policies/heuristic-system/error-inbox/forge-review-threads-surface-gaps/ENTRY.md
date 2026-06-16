# forge-cli pr review-threads surface gaps (dry-run not dry; list first-comment-only)

## Status

- Status: open
- First observed: 2026-06-16
- Area: forge-cli
- Severity: medium

## Signal

`forge-cli` v1.9.1 `pr review-threads` (the surface the shared
`review-thread-cleanup` skill drives) has two gaps a thread-sweep agent hits:

1. `pr review-threads list --dry-run` is NOT dry — it issues a live `gh`
   PR-view call before the dry-run plan branch, so it depends on network /
   `gh` auth / a live PR. Sibling `pr` subcommands (`checks` / `create` /
   `resolve` / `reply`) plan offline under `--dry-run`.
2. The `pr review-threads list` JSON carries only each thread's first comment
   (author / body / url) — not later replies or the diff hunk — so triage that
   depends on a reply or the hunk needs a separate fetch.

## Evidence

- Raw record: not captured (manual diagnosis, 2026-06-16).
- Evidence: `evidence/review-threads-dryrun-repro.md` (dry-run live-call repro).
- Version: `forge-cli` v1.9.1.
- Repro (gap 1): `forge-cli --provider github --repo graysurf/agent-runtime-kit
  --dry-run --format json pr review-threads list 9999999` returns a live
  GraphQL error ("Could not resolve to a PullRequest 9999999"), while
  `pr checks 9999999 --dry-run` and `pr review-threads resolve/reply --dry-run`
  return offline `plan` envelopes.
- Upstream: sympoies/nils-cli#887 (dry-run live call) and sympoies/nils-cli#888
  (umbrella: first-comment-only payload + host-aware writes, text-id,
  PR-id validation, JSON error contract from #883 review).
- In-repo fixes/workarounds landed: agent-runtime-kit#416 (smoke dropped the
  `list` dry-run probe; skill documents normalized `resolved`/`outdated` fields
  + full-context fetch) and #417 (surface-snapshot signatures, `deliver-pr` /
  `close-pr` floors to `>=1.9.1`, convergence-policy wiring, acceptance-matrix).

## Impact

A "deterministic" runtime-smoke probe over `list --dry-run` fails closed on a
host without network / `gh` auth / a live PR; and an agent triaging threads off
the `list` payload alone can disposition on incomplete evidence (missing replies
or diff hunks).

## Current Workaround

- Do not dry-run-probe `list`; probe only `resolve` / `reply` (which plan
  offline) plus the documented-surface assertions (agent-runtime-kit
  runtime-smoke does this).
- Before dispositioning a thread whose finding depends on a reply or the diff,
  fetch full context (open the thread `url`, or `gh api` the thread comments /
  PR diff).
- Filter on the normalized `resolved` / `outdated` envelope fields, not the raw
  GraphQL `isResolved` / `isOutdated`.

## Promotion Criteria

Promote/close when nils-cli#887 (dry-run honored for `list`) and #888 (incl.
replies/hunks in the `list` payload) land in a `forge-cli` release and the
agent-runtime-kit nils-cli pin is bumped.

## Next Action

Track upstream via #887 / #888. On the next `forge-cli` release: bump the
agent-runtime-kit nils-cli pin, restore the dropped `list` dry-run smoke probe,
and re-add the read-surface coverage claim in `acceptance-matrix.yaml`.
