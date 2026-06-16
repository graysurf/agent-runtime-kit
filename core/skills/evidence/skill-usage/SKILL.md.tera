---
name: skill-usage
description:
  Record skill invocation intent, linked evidence, validation, failures, and outcomes through the nils-cli `skill-usage` command.
---

# Skill Usage

## Contract

Prereqs:

- `skill-usage` and `agent-out` are installed from the released nils-cli package and available on `PATH`.
- The skill identity, user-request summary, and output directory are explicit.
- When no workflow-specific artifact directory already exists, allocate the
  record directory with `agent-out project --topic skill-usage --mkdir`; do not
  handwrite `/tmp` paths.
- Linked child evidence records already exist and have passed their owning
  tool's verify step before they are linked.
- Writes to a given record directory are serialized by the caller.
- Raw `skill-usage` records are runtime evidence with two distinct
  dispositions: durable retention into the agent-evidence-archive via the
  `evidence-migrate` skill (queryable history; see the `evidence-archive`
  policy), and curated promotion of important unresolved or reusable follow-up
  gaps into `heuristic-inbox` cases under the shared Heuristic System root.
  These are complementary lanes, not alternatives — a record can be both
  archived and the source of a promoted case.

Inputs:

- Skill path or identity.
- User request summary and invocation intent.
- Existing linked child evidence records.
- Failure, validation, and outcome entries.

Outputs:

- Skill usage record and verification result.

Failure modes:

- The record is missing intent, outcome, or required validation.
- Linked child record paths are absent, unreadable, or not verified by their
  owning evidence tool.
- Concurrent writes corrupt or race the same output directory.

## Entrypoint

Use the released CLI directly. Set `REVIEW_EVIDENCE_RECORD` to an existing
`review-evidence.json` that has already passed `review-evidence verify`;
`skill-usage` links child records, it does not create them.

```bash
skill_dir="$(agent-out project --topic skill-usage --mkdir)"
review_record="${REVIEW_EVIDENCE_RECORD:?set to an existing verified review-evidence.json}"

skill-usage init --out "$skill_dir" --skill evidence.review-evidence --intent "record review evidence" --user-request-summary "Review PR #12"
skill-usage link-record --out "$skill_dir" --type review-evidence --path "$review_record"
skill-usage record-validation --out "$skill_dir" --command "scripts/check.sh --docs" --status pass --summary "docs passed"
skill-usage record-outcome --out "$skill_dir" --status pass --summary "skill completed"
skill-usage verify --out "$skill_dir" --format json
```

## Workflow

1. Allocate the record directory through `agent-out` unless the workflow already
   owns a project-defined output path.
2. Initialize the record before the skill performs meaningful work.
3. Link only existing child evidence records with an explicit `--type`; verify
   the child record with its owning tool before linking it.
4. Record failures when they affect outcome, repair, or future maintainability.
5. Record final outcome and verify the record before using it as durable evidence.
6. When verified evidence exposes an important unresolved or reusable
   skill-contract gap, create a curated `heuristic-inbox` case instead of
   committing the raw record.
7. For durable, queryable retention of the record itself, migrate it into the
   agent-evidence-archive with the `evidence-migrate` skill — do not commit the
   raw record into a working repo. This is orthogonal to curated promotion.

## Boundary

`skill-usage` owns the invocation record envelope. The caller owns the actual skill behavior, must serialize writes to one record directory, and decides whether a separate curated `heuristic-inbox` follow-up is warranted.
