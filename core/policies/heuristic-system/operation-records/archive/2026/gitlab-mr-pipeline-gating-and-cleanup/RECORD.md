# GitLab MR Pipeline Gating And Cleanup Operation Record

## Status

- Date: 2026-05-18
- Status: superseded
- Cluster: delivery-check-gating
- Superseded-by: `forge-cli pr wait-checks` — skipped-source / non-required
  pipeline gating is now owned by the released CLI; the legacy
  `skills/workflows/pr` scripts were retired.
- Archived: 2026-06-15
- System area: GitLab MR delivery workflows
- Migrated from: legacy agent-kit retained inbox archive
- Source: the archived legacy agent-kit inbox case for skipped GitLab MR
  pipeline gating and close cleanup (delivery PR graysurf/agent-kit#254). The
  GitHub side of the same delivery-gate class is recorded in the GitHub PR
  required-check gating operation record (the `delivery-check-gating` cluster).

## Signal

A real `deliver-gitlab-mr` delivery for `gim/backend/livekit-agents!103`
completed only after manual judgment and cleanup. The source-branch pipeline
was skipped by the repo's CI rules while GitLab MR merge checks reported the MR
mergeable once it left draft. The delivery workflow still blocked on
source-branch pipeline gating, and after a successful merge the close script
failed its local cleanup.

This is the GitLab MR mirror of the GitHub PR required-check gating operation
record: in both cases a delivery script treated a non-required / skipped CI
signal as a hard failure when the provider's own merge checks were already
sufficient.

## Evidence

Retained local evidence:

- `<workspace>/out/.../skill-usage.record.json`

Durable provider evidence:

- MR: `gim/backend/livekit-agents!103`
- Source-branch pipeline: `308909`; post-merge `test` pipeline: `308915`
- Agent-kit delivery PR: `graysurf/agent-kit#254`
- Live acceptance MR: `gim/backend/livekit-agents!104`;
  live acceptance source pipeline: `308998`

Relevant evidence summary:

- `deliver-gitlab-mr.sh --kind feature wait-pipeline --mr 103` failed with
  `failed to parse pipeline status` and printed an empty status even though
  `glab ci status --branch <feature> --output json` carried
  `pipeline.status=skipped`.
- GitLab MR metadata showed the MR mergeable except for draft status.
- The target repo only ran meaningful build/deploy work on target branches, so
  a skipped feature source pipeline was expected, not a fault.
- `deliver-gitlab-mr.sh --kind feature close --mr 103 --skip-pipeline` marked
  the MR ready and merged it, then exited during local cleanup with a git pull
  configuration error.
- Manual cleanup succeeded with an explicit fetch plus fast-forward.

## Diagnosis

Two coupled defects in the GitLab MR delivery and close scripts:

1. Pipeline status parsing did not read the nested `pipeline.status` field from
   GitLab JSON, so a valid `skipped` status surfaced as a parse failure rather
   than a recognized non-blocking state.
2. Delivery policy assumed the source-branch pipeline must be green, which does
   not fit target-branch CI repos where the meaningful pipeline starts only
   after merge. The close workflow then merged but failed local cleanup under
   the repo's git config.

The same parse-and-gate logic spanned both the delivery and close scripts, so a
partial fix in one path would still leave delivery blocked or cleanup broken.

## Promotion Decision

Promoted as a Heuristic System operation record because it was:

- observed during a real high-impact delivery workflow;
- reproducible with stubbed nested-pipeline payloads and focused tests;
- narrow enough to fix safely;
- the direct GitLab counterpart to an existing operation record, so leaving it
  as an archived inbox entry only left the delivery-gate class half-documented.

Not every promoted inbox entry needs an operation record. This one qualifies
because the retained signal affected a broad delivery workflow, produced shared
script behavior, and is audit evidence that the Heuristic System loop operated
symmetrically across GitHub and GitLab delivery.

## Durable Fix

- GitLab MR source-branch `skipped`, `manual`, `blocked`, and
  `action_required` pipeline states are parsed from nested
  `pipeline.status` and remain blocked by default.
- For repos whose meaningful CI runs on target branches, `--skip-pipeline` is
  an explicit, user-confirmed merge control rather than a default.
- Close cleanup uses deterministic explicit fetch plus fast-forward.
- Stubbed tests cover nested pipeline payloads, skipped/manual status policy,
  and the close-cleanup pull/fast-forward failure mode.
- GitLab MR workflow docs explain target-branch CI versus skipped source-branch
  CI handling.

## Validation

- Focused GitLab MR delivery and close tests: pass.
- Full agent-kit repo validation: pass.
- Agent-kit delivery PR `graysurf/agent-kit#254`: merged.
- Live acceptance MR `gim/backend/livekit-agents!104` validated skipped source
  pipeline parsing, explicit `--skip-pipeline`, ready transition, merge, and
  local cleanup.

## Retention

- Raw skill usage records remain in `out/` and are not committed as normal repo
  artifacts.
- The source inbox case stays archived in the error inbox under the 2026
  archive, and this record is its compressed durable proof; treat it as the
  entry point for the GitLab MR delivery-gate class.
- This operation record remains as durable proof that the Heuristic System loop
  operated on a real GitLab MR delivery failure, mirroring the GitHub PR case.
