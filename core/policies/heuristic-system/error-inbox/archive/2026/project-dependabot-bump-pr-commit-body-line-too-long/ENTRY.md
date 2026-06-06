# project-deliver-dependabot-bump-pr emits an overlong semantic-commit body line

## Status

- Status: promoted
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

None. Resolved by the project skill emitting a shorter semantic-commit body
bullet and by smoke coverage that rejects the former long
`scripts/generate-third-party-artifacts.sh --write after` wording.

## Promotion Criteria

Promote after the project skill script is changed to emit body bullets within
the gate and a smoke test covers the commit-message construction path.

## Next Action

None. Fixed in
`https://github.com/sympoies/nils-cli/commit/5ada8e990ae346fee4da328b7112c8ae5a2e40fc`.

Lifecycle link: `https://github.com/sympoies/nils-cli/commit/5ada8e990ae346fee4da328b7112c8ae5a2e40fc`

## Archive

- Archived: 2026-06-06
- Reason: Completed entry archived out of the active error inbox.
- Durable link: `https://github.com/sympoies/nils-cli/commit/5ada8e990ae346fee4da328b7112c8ae5a2e40fc`
