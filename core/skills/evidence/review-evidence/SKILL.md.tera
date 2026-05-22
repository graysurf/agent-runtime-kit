---
name: review-evidence
description:
  Persist review findings, validation commands, artifacts, and verification status through the nils-cli `review-evidence` command.
---

# Review Evidence

## Contract

Prereqs:

- `review-evidence` is installed from the released nils-cli package and available on `PATH`.
- The review subject and output directory are explicit.
- Findings are concrete, source-grounded, and scoped to the reviewed change.

Inputs:

- Review subject.
- Finding severity, path, optional line, and summary.
- Validation command, status, and optional artifact paths.
- Optional specialist review report from `code-review-specialists`, mapped into
  this tool's severity and finding fields when retained evidence is needed.

Outputs:

- Review evidence record, finding entries, validation entries, and verification result.

Failure modes:

- Required subject or finding fields are missing.
- Validation evidence is absent for delivery.
- Referenced artifacts or paths cannot be resolved.
- Caller treats a specialist review report as an automatic merge, close, or
  follow-up decision instead of evidence that still needs review judgment.

## Entrypoint

Use the released CLI directly:

```bash
review-evidence init --out /tmp/review --subject "PR #12"
review-evidence record-finding --out /tmp/review --severity medium --path src/lib.rs --line 42 --summary "missing error path"
review-evidence record-validation --out /tmp/review --command "cargo test" --status pass
review-evidence verify --out /tmp/review --format json
```

## Workflow

1. Initialize one record per review subject.
2. Record only actionable or intentionally accepted findings.
3. When importing `code-review-specialists` output, keep the specialist report
   as an evidence source; the caller still owns judgment, severity mapping, and
   whether each item blocks delivery.
4. Record validation that proves fixes or review completion.
5. Verify before linking the review record from PR, issue, or closeout evidence.

## Boundary

`review-evidence` owns record structure. Review judgment, severity assignment, and whether a finding blocks delivery remain caller responsibilities.
Do not use `review-evidence` or `code-review-specialists` as a substitute for
review judgment; both provide evidence inputs.
