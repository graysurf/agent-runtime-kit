# Plan-Issue Contract Drift On Silent Host Bumps Operation Record

## Status

- Date: 2026-05-24
- Status: implemented and validated (guardrail), class still open upstream
- System area: plan-issue record contract; dispatch + pr tracking skills;
  runtime-smoke probes; nils-cli surface pinning
- Compresses three resolved cases that are archived in the error inbox, all the
  same contract-drift class: the v2 marker collapse case (tracking issue #79),
  the record payload fence leak case (tracking issue #84, delivery #85), and the
  v3 surface drift case (issue #93, resolved by the plan-issue.* v1.0.0 migration
  in #233).

## Signal

A repeated, cross-skill failure class: a silent `brew upgrade
sympoies/tap/nils-cli` advanced the host `agent-runtime` / `plan-issue` binary
past the surface pin in `docs/source/nils-cli-surface.md`, and each
`plan-issue record` contract change then broke the dispatch / pr tracking
skills, their runtime-smoke probes, or the live tracking-issue render — with no
gate comparing host version against the pin.

Three concrete, now-resolved instances:

1. **v2 marker collapse (nils-cli v0.17.7).** The `--marker-family` flag was
   removed, the record envelope bumped `v1 → v2`, and the marker token format
   collapsed to a single `plan-issue-record:v2` token keyed by `role` /
   `profile`. Six dispatch and one pr runtime-smoke probe failed, the
   `create-plan-tracking-issue` skill body's `--marker-family compat` step could
   not complete, and `scripts/ci/all.sh` failed for every push from a v0.17.7
   host regardless of the change.
2. **Payload fence leak (nils-cli v0.17.7).** `plan-issue record open` rendered
   a visible `plan-issue-record-payload` JSON code-fence in every source / plan
   / state comment and collapsed the state comment's inlined markdown body. The
   user flagged the broken render on a live tracking issue; three comments had
   to be hand-patched via `gh api -X PATCH` to restore the prior shape.
3. **v3 surface drift (kit-side, issue #93).** The same class recurred when the
   kit's dispatch / pr skills still referenced retired plan-issue helpers after
   a later contract bump; it was resolved by migrating the kit to the
   plan-issue.* v1.0.0 contract (PR #233), leaving zero retired-helper
   references.

These breaks shared one root cause — a host binary ahead of the pinned, tested
surface — but surfaced differently (flag/schema rejection, render regression,
then stale helper references), so each escaped the prior migration's tests.

## Evidence

- v2 marker collapse: tracking issue `graysurf/agent-runtime-kit#79`;
  consumer-migration PR `#76`; surface-pin alignment gate PR `#78`. Reproduced
  via `agent-runtime --version` = `0.17.7` against pinned `v0.17.6`, and
  `plan-issue record render-comment ... --marker-family compat` →
  `error: unexpected argument '--marker-family' found` (exit 2).
- Payload fence leak: user report on `graysurf/agent-runtime-kit#83`; upstream
  `sympoies/nils-cli#463` (fixed by `#464`, shipped in `v0.18.0`); local pin +
  lifecycle delivery in `#85` against tracker `#84`. Cross-issue check found the
  visible payload fence on `#83` (count 3) and on no prior tracker.
- Both source cases retain full reproduction detail and durable links in their
  archived `ENTRY.md` files.

## Diagnosis

The repo pinned the nils-cli surface in docs but ran every downstream gate
(runtime-smoke probes, skill bodies, goldens) against whatever binary `brew`
had installed. Nothing failed closed when the host drifted ahead of the pin, so
a breaking `plan-issue record` change could land between a pin snapshot and a
host upgrade and only surface as confusing downstream probe failures — or, for
the render regression, as a visibly broken live tracking issue. The prevention
rule first written as "dry-run affected subcommands before bumping the pin" was
correct but manual, and the second instance proved a manual rule is not enough.

## Promotion Decision

Promoted to a single operation record because the signal is **repeated and
cross-skill** (two distinct nils-cli releases, multiple dispatch + pr skills and
probes) and because it is the clearest case of the Compression Rule: several
local exceptions collapsed into one mechanical guardrail. It is audit-worthy as
proof that retained inbox evidence drove a durable CI gate rather than only
per-incident patches.

## Durable Fix

- **Mechanical guardrail (the durable outcome):** `scripts/ci/all.sh`
  Position 2 runs `agent-runtime doctor --class version-alignment --pin
  docs/source/nils-cli-pin.yaml` and blocks on any host deviation from
  `pinned_tag` — ahead OR behind — plus any `required_clis[]` floor miss. A
  silent `brew upgrade` past the pin now fails closed; bumping the host is a
  conscious pin bump through the `meta:nils-cli-bump` skill. This started as PR
  `#78` and, as of nils-cli v0.28.0 (`sympoies/nils-cli#636`), delegates to the
  released `version-alignment` doctor class.
- **Consumer migrations:** the dispatch / pr skill bodies, runtime-smoke
  fixtures, and golden snapshots were migrated to the v2 marker contract (PR
  `#76`); the payload-fence regression was resolved upstream in nils-cli
  v0.18.0 with the local pin + lifecycle delivery in PR `#85`. The kit later
  migrated to the `plan-issue.*` contract and pinned v1.0.0 (PR `#233`).
- **Prevention rule (retained in both source cases):** before merging a
  nils-cli surface-pin bump that touches `plan-issue record open|post`,
  dry-run the affected subcommands and visually inspect the rendered source /
  plan / state comments against the most recent tracker; block the bump on a
  same-PR migration if anything diverges. Position 2 now enforces the
  version-drift half of this rule mechanically.

## Validation

- v2 migration: all previously-failing dispatch + pr runtime-smoke probes
  return `pass / skill_count=1` on a v0.17.7 host; `agent-runtime render`
  regenerates clean output; goldens refreshed.
- Payload fence: verified on nils-cli v0.18.0 — live tracker `#84` source /
  plan / state comments return `visible_fence=false`, `hidden_payload=true`,
  and `plan-issue record audit --profile tracking` returns
  `missing_required:[]`, `recognized_count` 3–4.
- Guardrail: `scripts/ci/all.sh` Position 2 blocks on any host/pin deviation
  and is part of the current full local gate.

## Retention

- All three source inbox cases remain archived in the error inbox; this record
  is the compressed durable proof and should be the entry point for future
  plan-issue contract-drift triage.
- Two adjacent plan-issue contract entries remain active in the inbox and are
  NOT part of this version-drift class or this record's "validated" claim. Both
  are separate record-post defects: one on concurrent record posts corrupting
  lifecycle comments, and one on the execution-state and summary file flags
  being mutually exclusive. Treat each on its own lifecycle.
