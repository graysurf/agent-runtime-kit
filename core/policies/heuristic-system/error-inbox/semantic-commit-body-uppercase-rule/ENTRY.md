# semantic-commit body bullet uppercase rule undocumented

## Status

- Status: open
- First observed: 2026-05-25
- Area: nils-cli semantic-commit body validator
- Severity: medium

## Signal

`semantic-commit commit` rejects commit-message body bullets whose first
character after `- ` is not uppercase. Lowercase tool / function / identifier
openings (e.g. `- forge-cli label ensure …`, `- dispatch lane …`,
`` - `forge-cli` rejects … ``) trip the validator with
`commit body line N must start with '- ' followed by uppercase letter`.
The rule is not documented in `semantic-commit --help`, `SKILL.md` for
`meta/semantic-commit`, or `AGENT_HOME.md` (which only mentions the 1–2 bullets
limit). Agents iterate two or three times before discovering the workaround
(capitalize the first word, or rephrase to lead with a non-identifier word).

## Evidence

- Raw record: not captured at first occurrence; reproduce with any
  `- forge-cli …` bullet.
- Repro:

  ```sh
  printf 'docs(plans): test\n\n- forge-cli rejects --opened on glab 1.99.\n' \
    | semantic-commit commit --dry-run
  # → error: commit body line N must start with '- ' followed by uppercase
  #   letter
  ```

- Minimal failing bullet: `- forge-cli rejects --opened on glab 1.99.`
- Source: sympoies/nils-cli#506 P1-2 (F-5); originally surfaced in
  `terrylin/agent-runtime-testing:docs/plans/gitlab-skill-validation/
  gitlab-skill-validation-discussion-source.md` Findings table F-5.

## Impact

Every agent writing a commit that names a lowercase CLI / function / module hits
the validator and either:

- silently rephrases the bullet (loses precision — "Fix forge-cli" → "Update CLI"),
- discovers the rule by trial and error (2–3 wasted iterations per commit), or
- uses `--no-verify`-style escapes, which home `AGENT_HOME.md` prohibits.

Cumulative cost across the runtime-kit + nils-cli + sandbox session families is
non-trivial; the lesson is not learnable from any doc surface today.

## Current Workaround

Capitalize the first word of every body bullet, or rewrite so the bullet starts
with a regular verb / noun:

- Before: `- forge-cli list rejects empty repos.`
- After:  `- Fixes \`forge-cli list\` rejection on empty repos.`

Backticked identifiers as the first token after `- ` are also rejected; quote
or rephrase as above.

## Promotion Criteria

Promote when **either** (a) the validator is relaxed to accept backticked
identifiers / common lowercase tokens, **or** (b) the rule is documented in:

- `crates/semantic-commit/README.md` body-format section,
- `meta/semantic-commit` SKILL.md "Acceptance criteria",
- `AGENT_HOME.md` "Commit Rules" section.

Closing this entry requires linking the upstream nils-cli issue / PR that
implements (a) or the doc change that implements (b).

## Next Action

Open an upstream nils-cli issue requesting either (a) relaxation of the rule
for backtick / common-identifier openings, or (b) explicit documentation of the
rule + recommended rewording pattern. Reference this entry from the issue.
