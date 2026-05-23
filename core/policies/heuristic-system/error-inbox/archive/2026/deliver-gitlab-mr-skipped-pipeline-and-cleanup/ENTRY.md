# Deliver GitLab MR Skipped Pipeline And Cleanup Gaps

## Status

- Status: promoted
- First observed: 2026-05-18
- Area: GitLab MR delivery skills
- Severity: high
- GitLab MR workflow status: complete
- Migrated from: legacy agent-kit retained inbox archive

## Signal

A real `deliver-gitlab-mr` delivery for `gim/backend/livekit-agents!103`
succeeded only after manual judgment and cleanup. The source branch pipeline
was skipped by repo CI rules, while GitLab MR merge checks showed the MR was
mergeable after leaving draft state. The delivery workflow still blocked on
source-branch pipeline gating, then the close script merged successfully but
failed local cleanup.

This entry covers the GitLab MR skill bugs exposed by retained delivery
evidence. The defects are now fixed and validated.

## Evidence

- Raw record: `<workspace>/out/.../skill-usage.record.json`
- MR: `gim/backend/livekit-agents!103`
- Source-branch pipeline: `308909`
- Post-merge `test` pipeline: `308915`
- Agent-kit delivery PR: `graysurf/agent-kit#254`
- Live acceptance MR: `gim/backend/livekit-agents!104`
- Live acceptance source pipeline: `308998`

Relevant evidence summary:

- `deliver-gitlab-mr.sh --kind feature wait-pipeline --mr 103` failed with
  `failed to parse pipeline status` and printed an empty pipeline status even
  though `glab ci status --branch feat/reservation-graph-router-resilience --output json`
  contained `pipeline.status=skipped`.
- GitLab MR metadata showed the MR was mergeable except for draft status.
- The target repo's CI model only ran meaningful build/deploy work on target
  branches, so the feature source pipeline being skipped was expected.
- `deliver-gitlab-mr.sh --kind feature close --mr 103 --skip-pipeline` marked
  the MR ready and merged it, then exited during local cleanup with a git pull
  configuration error.
- Manual cleanup succeeded with an explicit fetch plus fast-forward workflow.
- Live acceptance MR `!104` validated skipped source pipeline parsing,
  explicit `--skip-pipeline`, ready transition, merge, and local cleanup.

## Impact

Future GitLab MR deliveries can be blocked or reported incorrectly when a repo
uses target-branch CI rather than source-branch CI. This matters for deployment
branches where meaningful build/deploy pipelines start only after merge.

The cleanup failure also makes a successful merge look like a failed delivery
unless the agent verifies MR state and repairs the local checkout. Without a
durable inbox entry, this failure would remain only in local `out/` evidence
and could be lost during cleanup.

The GitLab MR delivery impact is resolved in agent-kit.

## Current Workaround

No GitLab MR workaround remains after PR #254 and live MR !104 validation.
Continue using explicit `--skip-pipeline` only for user-confirmed
target-branch CI models.

## Verified Behavior

- GitLab MR source-branch `skipped`, `manual`, `blocked`, and
  `action_required` pipeline states remain blocked by default.
- For repos whose meaningful CI runs on target branches, `--skip-pipeline` is
  still an explicit user-confirmed merge control, not a default.
- Close cleanup uses explicit fetch plus fast-forward.

## Findings

| Priority | Issue | Evidence | Likely fix location | Acceptance |
| --- | --- | --- | --- | --- |
| P1 | `deliver-gitlab-mr` did not parse nested `pipeline.status` from GitLab JSON. | `pipeline.status=skipped` existed, but the script reported a parse failure. | GitLab MR delivery and close workflow scripts. | Stubbed tests cover nested pipeline payloads and skipped/manual status policy. |
| P1 | GitLab delivery policy assumed source-branch pipeline must be green, which did not fit target-branch CI repos. | Feature branch only had manual/allow-failure work; post-merge target branch started the meaningful pipeline. | GitLab MR delivery and close workflow docs/scripts. | Workflow distinguishes source CI gaps from GitLab mergeability and supports explicit target-branch CI handling. |
| P2 | Close workflow merged the MR but failed local cleanup under repo git config. | Close output showed merge success followed by git cleanup failure; manual fetch plus fast-forward succeeded. | GitLab MR close workflow script. | Cleanup uses deterministic fetch plus fast-forward and has regression coverage. |

GitLab MR findings are fixed and accepted by focused tests, full repo
validation, PR #254, and live acceptance MR !104.

## Promotion Criteria

The GitLab MR portion of this inbox entry is complete when all of these are
true:

- GitLab MR pipeline status parsing has focused tests and script fixes.
- Close cleanup has a regression test for the local pull/fast-forward failure
  mode.
- Skill docs explain target-branch CI and skipped source-branch CI handling.
- The relevant docs, markdown, focused tests, and full repo checks pass.
- A live GitLab MR validates skipped source pipeline parsing, explicit
  `--skip-pipeline`, ready transition, merge, and local cleanup.

## Next Action

None. The GitLab MR workflow gap is resolved by PR #254 and live MR !104
validation. Durable outcome links are recorded in Evidence.

## Archive

- Archived: 2026-05-18
- Reason: Resolved by PR #254 and archived out of the active error inbox.
- Durable link: `graysurf/agent-kit#254`
