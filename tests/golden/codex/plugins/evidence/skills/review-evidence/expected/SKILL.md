---
name: review-evidence
description:
  Persist review findings, validation commands, artifacts, and verification status through the nils-cli `review-evidence` command.
---

# Review Evidence

## Contract

Prereqs:

- `review-evidence` and `agent-out` are installed from the released nils-cli package and available on `PATH`.
- The review subject and output directory are explicit.
- When no workflow-specific artifact directory already exists, allocate the
  record directory with `agent-out project --topic review-evidence --mkdir`; do
  not handwrite `/tmp` paths.
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
review_dir="$(agent-out project --topic review-evidence --mkdir)"
review-evidence init --out "$review_dir" --subject "PR #12"
review-evidence record-finding --out "$review_dir" --severity medium --path src/lib.rs --line 42 --summary "missing error path"
review-evidence record-validation --out "$review_dir" --command "cargo test" --status pass
review-evidence verify --out "$review_dir" --format json
```

After verification, `$review_dir/review-evidence.json` is the child record path
that other evidence tools may link.

## Workflow

1. Allocate the record directory through `agent-out` unless the workflow already
   owns a project-defined output path.
2. Initialize one record per review subject.
3. Record only actionable or intentionally accepted findings.
4. When importing `code-review-specialists` output, keep the specialist report
   as an evidence source; the caller still owns judgment, severity mapping, and
   whether each item blocks delivery.
5. Record validation that proves fixes or review completion.
6. Verify before another PR, issue, closeout, or `skill-usage` record links
   `$review_dir/review-evidence.json`.

## Boundary

`review-evidence` owns record structure; it and `code-review-specialists` provide evidence inputs only. Review judgment, severity assignment, and whether a finding blocks delivery remain caller responsibilities.
