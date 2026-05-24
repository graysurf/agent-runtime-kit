# Forge Label Taxonomy

`manifests/forge-labels.yaml` is the machine-readable catalog for GitHub
issues / PRs and GitLab issues / MRs. `forge-cli label audit|ensure` consumes
that catalog; this policy defines how agents choose and apply the labels.
`manifests/forge-label-classification-rules.yaml` records the first shared
agent classification heuristics for consistent triage and review.

## Required Selection

- Issues: choose one `type::` label, one primary `area::` label, and a
  `state::` label. Use `state::needs-triage` unless a more specific state is
  known. When re-labeling historical closed records, use `state::closed` unless
  a more specific reopened workflow state is being recorded.
- Bug, incident, or security issues: add one `severity::` label when impact is
  known. Severity describes impact, not scheduling order.
- Triaged issues: add one `priority::` label when scheduling order is known.
  Priority owns ordering; do not add an `urgency::` group in the first rollout.
- PRs and MRs: choose one `type::`, one primary `area::`, and one `size::`
  label before provider mutation.
- Risky PRs and MRs: add one `risk::` label and strengthen the review /
  rollback notes accordingly.
- Provider workflow work: add `provider::github`, `provider::gitlab`,
  `provider::both`, or `provider::neutral` when provider behavior is part of
  the scope.
- Agent-owned durable workflow records: add the matching `workflow::` label
  (`workflow::plan`, `workflow::tracking`, `workflow::dispatch`, or
  `workflow::follow-up`).

## Provider Operations

- Before the first live issue, PR, or MR mutation in a repository, run:

  ```bash
  forge-cli label ensure --catalog manifests/forge-labels.yaml --repo "$OWNER_REPO" --format json
  ```

- Use `forge-cli label audit --catalog ...` when mutation is not allowed or
  when checking drift after setup.
- `forge-cli label ensure` may create missing labels. It must not delete or
  rename labels during rollout.
- Do not pass `--update-existing` unless the user or issue plan explicitly
  approves color / description drift repair.
- For PR/MR creation and delivery, pass selected labels with repeatable
  `--label` flags. When the catalog is available, add `--label-catalog
  manifests/forge-labels.yaml --strict-labels` so invalid or conflicting
  labels fail before provider mutation.

## Rollout Compatibility

- Keep existing `plan` and `issue` labels during rollout. They remain
  compatibility labels for older issues and scripts.
- New plan-tracking and follow-up workflows should apply `workflow::*` labels
  in addition to compatibility labels where the older workflow still expects
  them.
- Repo-local `area::` extensions are allowed when a repository needs a primary
  area outside the shared catalog. Shared automation should still prefer the
  cataloged core areas when one fits.

## Agent Classification Rules

- Use the classification rules manifest as the default routing aid when
  re-labeling existing provider records.
- Treat rule output as an agent recommendation, not an override of explicit
  issue text or user direction.
- Remove stale labels from exclusive taxonomy groups before applying the new
  selected label for that group. Keep compatibility labels such as `plan` and
  `issue` during rollout.
- If a record matches multiple areas, pick the primary area that owns the next
  implementation or review action; mention secondary concerns in the issue or
  PR comment instead of stacking exclusive `area::` labels.
