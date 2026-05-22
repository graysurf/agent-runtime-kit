---
name: model-cross-check
description:
  Record primary and checker model observations through the nils-cli `model-cross-check` command without owning provider calls.
---

# Model Cross Check

## Contract

Prereqs:

- `model-cross-check` is installed from the released nils-cli package and available on `PATH`.
- Primary and checker observations are obtained outside this primitive.
- The output directory, prompt summary, and model names are explicit.

Inputs:

- Prompt or review subject summary.
- Primary model name and checker model name.
- Observation role, model, verdict, summary, and optional artifact links.

Outputs:

- Model cross-check record and verification result.

Failure modes:

- Either primary or checker observation is missing.
- A provider call is attempted inside the primitive instead of being supplied as observation text.
- The record lacks verdicts or summaries needed for verification.

## Entrypoint

Use the released CLI directly:

```bash
model-cross-check init --out /tmp/model-check --prompt "review this patch" --primary-model gpt-5.5 --checker-model gemini-2.5-pro
model-cross-check record-observation --out /tmp/model-check --role primary --model gpt-5.5 --verdict pass --summary "implementation is coherent"
model-cross-check record-observation --out /tmp/model-check --role checker --model gemini-2.5-pro --verdict pass --summary "no blocker found"
model-cross-check verify --out /tmp/model-check --format json
```

## Workflow

1. Initialize the record with the prompt or review subject before recording observations.
2. Run any provider calls through the appropriate model tooling outside this skill.
3. Record the primary and checker observations with concise verdicts and source artifacts when available.
4. Verify before linking the record as review or validation evidence.

## Boundary

`model-cross-check` owns deterministic record handling only. Provider selection, prompt execution, model access, and review judgment remain caller responsibilities.
