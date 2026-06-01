# semantic-commit body bullet uppercase rule undocumented

## Status

- Status: promoted
- First observed: 2026-05-25
- Promoted: 2026-06-02 — criterion (b) satisfied. The runtime-facing surfaces
  now teach the body-line rule: `meta/semantic-commit` SKILL.md (Contract →
  Failure modes, plus the structured-fields workflow step) and
  `core/policies/git-delivery.md` "Commits" (the relocated home of the former
  `AGENT_HOME.md` Commit Rules — `AGENT_HOME.md` was made concise and delegates
  commit mechanics there). The README portion was already covered by
  sympoies/nils-cli#576.
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
- Recurrence (2026-05-27): hit again during sympoies/nils-cli#589 delivery. A
  body bullet starting with `- --now stays the deterministic override …` was
  rejected with `commit body line 5 must start with '- ' followed by uppercase
  letter`. New trigger class — a leading double-dash flag (`--now`), common when
  a bullet describes a CLI flag; `--auto-fix` did not rescue it (it cannot
  capitalize a flag). Confirms the gap recurs across session families (now also
  PR-delivery commits).
- Partial upstream documentation fix (2026-05-27): sympoies/nils-cli#576
  (merged) added the body-format rule to `crates/semantic-commit/README.md` —
  body bullets must start with `- ` plus an uppercase ASCII letter, or use a
  two-space continuation line. This satisfied the README portion of criterion
  (b).
- Runtime-facing documentation fix (2026-06-02): `meta/semantic-commit`
  SKILL.md and `core/policies/git-delivery.md` "Commits" now teach the rule, and
  the v1.0.3 error string was re-confirmed to also name the trailer and
  two-space continuation escapes. `--auto-fix` capitalizes a lowercase first
  word but cannot rescue a leading `--flag` or backticked identifier (re-verified
  on v1.0.3). Both runtime surfaces of criterion (b) are now covered.

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
or rephrase as above. Leading CLI flags (e.g. `- --now …`) are rejected too;
lead with a capitalized verb instead, e.g. `- Keep \`--now\` as the override`.

## Promotion Criteria

Promote when **either** (a) the validator is relaxed to accept backticked
identifiers / common lowercase tokens, **or** (b) the rule is documented in:

- `crates/semantic-commit/README.md` body-format section,
- `meta/semantic-commit` SKILL.md "Acceptance criteria",
- `AGENT_HOME.md` "Commit Rules" section.

Closing this entry requires linking the upstream nils-cli issue / PR that
implements (a) or the doc change that implements (b).

## Next Action

None — resolved via criterion (b). The runtime-facing surfaces
(`meta/semantic-commit` SKILL.md and `core/policies/git-delivery.md` "Commits")
now teach the body-line rule, and the README portion was covered by
sympoies/nils-cli#576. Archiving with status `promoted`. A future validator
relaxation (criterion (a)) would be tracked as a fresh nils-cli issue, not by
reopening this entry.

## Archive

- Archived: 2026-06-02
- Reason: Promoted: criterion (b) doc surfaces (SKILL.md + git-delivery.md) now teach the rule
