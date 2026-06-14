---
name: skill-usage
description:
  Record skill invocation intent, linked evidence, validation, failures, and outcomes through the nils-cli `skill-usage` command.
---

# Skill Usage

## Contract

Prereqs:

- `skill-usage` is installed from the released nils-cli package and available on `PATH`.
- The skill identity, user-request summary, and output directory are explicit.
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
- Linked child evidence records.
- Failure, validation, and outcome entries.

Outputs:

- Skill usage record and verification result.

Failure modes:

- The record is missing intent, outcome, or required validation.
- Linked child records are absent or unreadable.
- Concurrent writes corrupt or race the same output directory.

## Entrypoint

Use the released CLI directly:

```bash
skill-usage init --out /tmp/skill --skill skills/tools/devex/review-evidence --intent "record review evidence" --user-request-summary "Review PR #12"
skill-usage link-record --out /tmp/skill --path /tmp/review/review-evidence.record.json
skill-usage record-validation --out /tmp/skill --command "scripts/check.sh --docs" --status pass --summary "docs passed"
skill-usage record-outcome --out /tmp/skill --status pass --summary "skill completed"
skill-usage verify --out /tmp/skill --format json
```

## Workflow

1. Initialize the record before the skill performs meaningful work.
2. Link child evidence records instead of duplicating their content.
3. Record failures when they affect outcome, repair, or future maintainability.
4. Record final outcome and verify the record before using it as durable evidence.
5. When verified evidence exposes an important unresolved or reusable
   skill-contract gap, create a curated `heuristic-inbox` case instead of
   committing the raw record.
6. For durable, queryable retention of the record itself, migrate it into the
   agent-evidence-archive with the `evidence-migrate` skill — do not commit the
   raw record into a working repo. This is orthogonal to step 5.

## Boundary

`skill-usage` owns the invocation record envelope. The caller owns the actual skill behavior, must serialize writes to one record directory, and decides whether a separate curated `heuristic-inbox` follow-up is warranted.
