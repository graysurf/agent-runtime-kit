# project-deliver-dependabot-bump-pr emits an overlong semantic-commit body line

## Status

- Status: open
- First observed: 2026-06-04
- Area: project-deliver-dependabot-bump-pr skill; semantic-commit body gate
- Severity: medium

## Signal

`project-deliver-dependabot-bump-pr.sh` repaired the dependency branch and
regenerated third-party artifacts, then failed at the commit step because its
generated semantic-commit body bullet exceeded the 100-character body-line
limit.

## Evidence

- Raw record: not captured (manual diagnosis, 2026-06-04)
- Observed while delivering Dependabot PRs sympoies/nils-cli#773, #775, and
  #774.
- The script-generated bullet was:
  `Regenerate THIRD_PARTY_LICENSES.md and THIRD_PARTY_NOTICES.md via scripts/generate-third-party-artifacts.sh --write after the dependency bump.`
- `semantic-commit` rejected it with:
  `error: commit body line 3 exceeds 100 characters (max 100)`.
- Manual commits with shorter bullets unblocked all three PRs.

## Impact

The workflow can complete the expensive branch repair and artifact regeneration
steps, then stop at the final commit. Future agents are likely to repeat manual
semantic-commit recovery on every Dependabot artifact-refresh PR until the
script emits commit bodies that satisfy the shared gate.

## Current Workaround

Run the regeneration step, then commit manually through `semantic-commit` with a
shorter body bullet such as:
`Regenerate third-party artifacts after the chrono bump`.

## Promotion Criteria

Promote after the project skill script is changed to emit body bullets within
the gate and a smoke test covers the commit-message construction path.

## Next Action

Shorten the generated semantic-commit body bullets in the
project-deliver-dependabot-bump-pr script and add a smoke test that exercises
the commit path.
