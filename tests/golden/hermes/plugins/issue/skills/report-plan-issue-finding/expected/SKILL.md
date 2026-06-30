---
name: report-plan-issue-finding
description: >
  File a plan-issue / plan-tracking family finding (skill, CLI, driver, or
  catalog drift) as a labeled issue in the canonical tracker via forge-cli,
  and close it when the upstream fix lands. Files and tracks only — never
  fixes.
---

# Report Plan Issue Finding

Natural-language entrypoint for turning a problem discovered while running the
`plan-issue` / `plan-tracking` skill family (or its CLIs `plan-issue`,
`plan-tooling`, `forge-cli`) into one durable, labeled GitHub issue in the
canonical tracker. Use it from any repository the moment a finding appears —
the tracker is centralized, so the finding does not have to be filed from the
tracker repo itself.

Fixes are NOT made by this skill. The finding's fix lands upstream in
`agent-runtime-kit` (skill bodies, manifests, render output) or `nils-cli`
(the `plan-issue` / `plan-tooling` / `forge-cli` CLIs). This skill owns only
the finding's issue record: open, dedup, comment, and close.

## Contract

Prereqs:

- `forge-cli >=1.11.2` is installed from the released nils-cli package and on
  `PATH`. All issue mutation goes through it, never raw `gh issue create`.
- `jq` is available for parsing `forge-cli ... --format json` output.
- Provider authentication is available for non-dry-run issue reads/writes.
- The canonical tracker repository and its label catalog are known. Default
  tracker: `graysurf/plan-tracking-testbed`. The `plan-issue-finding` marker
  label plus the shared `type::` / `area::` / `severity::` / `state::` taxonomy
  exist there (mirrored from `manifests/forge-labels.yaml`).
- Shared issue label/comment/close rules in
  `../issue-follow-up/references/issue-lifecycle.md` are satisfied.

Inputs:

- Required:
  - `title` — concise, surface-first, ≤70 chars (forge-cli `title_length`
    rule). Example: `deliver skill: --phase ready_for_close rejected by CLI`.
  - `severity` — `s1` flow-breaking / wrong user-facing output; `s2`
    recoverable with a workaround; `s3` cosmetic / doc / naming drift.
  - `surface` — who owns the fix: `skill` (a SKILL body), `cli`
    (`plan-issue` / `plan-tooling`), `provider` (`forge-cli`), `driver`
    (the `test-plan-tracking` harness), or `catalog` (labels).
  - `description`, `repro`, and a `fix candidate`.
- Optional:
  - `where surfaced` — the skill + phase or the exact command, plus the CLI
    versions in play (`plan-issue`, `plan-tooling`).
  - `source location` — `repo path:line` of the likely fix site upstream.
  - `tracker repo` — override the default tracker when filing elsewhere.

Outputs:

- A new GitHub issue in the tracker labeled `plan-issue-finding` plus the mapped
  taxonomy, or a comment on an existing matching finding. The issue URL is
  returned.
- On fix: a closing comment citing the fixing PR / commit and a closed issue.

Failure modes:

- `title` exceeds 70 chars — forge-cli rejects with `title_length`; shorten
  before creating.
- A matching open finding already exists — comment on it instead of opening a
  duplicate.
- Attempting to implement the fix in the tracker repo — out of scope; the fix
  is an upstream `agent-runtime-kit` / `nils-cli` change.
- Provider auth, permission, or network failure on a non-dry-run mutation.
- `local_path_present`: rewrite useful evidence paths in provider-visible
  finding bodies/comments to `$HOME/...` and omit remote-useless local artifact
  paths before retrying.

## Label mapping

Always apply `plan-issue-finding` + `state::needs-triage`, plus one value from
each dimension:

- **type** — `type::bug` (CLI / behavior), `type::docs` (skill / doc drift),
  `type::test` (driver / test-scope gap), `type::improvement` (capability gap).
- **area** — `area::skills`, `area::cli`, `area::provider`, `area::ci`
  (driver), `area::docs`, `area::infra` (catalog).
- **severity** — `severity::s1`, `severity::s2`, `severity::s3`.

When the tracker carries the shared catalog, follow the shared issue lifecycle
reference for `label audit` versus `label ensure`. The live ensure form is:

```bash
forge-cli label ensure \
  --catalog manifests/forge-labels.yaml \
  --repo "$TRACKER_REPO" \
  --format json
```

## Workflow

`TRACKER_REPO` defaults to `graysurf/plan-tracking-testbed`.

1. **Dedup** — scan open findings for the same surface before filing:

   ```bash
   forge-cli issue list --repo "$TRACKER_REPO" \
     --label plan-issue-finding --state open --format json \
     | jq -r '.data.items[]?.title'
   ```

   If a clear match exists, comment on it instead of opening a duplicate:
   `forge-cli issue comment <ID> --repo "$TRACKER_REPO" --body-file <note>`.

2. **Compose** — write the body to a file using the template below. Keep it
   evidence-based: name the exact skill + phase or command, the CLI versions,
   and a verifiable repro. When the finding comes from a `test-plan-tracking`
   run, paste that run's provenance block (`<driver>/.state/provenance.md` —
   `agent-runtime-kit` checkout SHA + each CLI's version and install source)
   verbatim into the `## Provenance` section so the finding pins the exact
   upstream build it was produced against.

3. **Create** — open the issue with the marker plus mapped labels:

   ```bash
   forge-cli issue create --repo "$TRACKER_REPO" \
     --title "<≤70-char surface-first title>" \
     --body-file "<body.md>" \
     --label plan-issue-finding --label state::needs-triage \
     --label type::bug --label area::skills --label severity::s2 \
     --format json
   ```

   Replace the sample `type::` / `area::` / `severity::` with the mapped values.

4. **Report** — return the issue URL to the user.

5. **Close on fix** — when the upstream fix merges, comment with the fixing
   PR / commit, then close (never close silently):

   ```bash
   forge-cli issue comment <ID> --repo "$TRACKER_REPO" \
     --body "Fixed by <owner-repo>#<PR> (<merge-sha>). Verified by <re-run / test>."
   forge-cli issue close <ID> --repo "$TRACKER_REPO"
   ```

## Body template

```markdown
## Finding

<one-paragraph description of the drift / bug>

## Surfaced by

- Skill / command: <e.g. deliver-plan-tracking-issue step 5 / `forge-cli pr deliver`>
- CLI versions: plan-issue <x.y.z>, plan-tooling <x.y.z>
- Run / evidence: <issue / PR / comment URL or driver assert output>

## Provenance

<!-- For findings from a `test-plan-tracking` run, paste the driver's
     .state/provenance.md block verbatim so the finding pins the exact build.
     Otherwise fill in best-available identity. -->

- Run: fixture `<name>` at <UTC timestamp>
- agent-runtime-kit: `<short-sha>(+dirty)` (checkout SHA — skills carry no semver)
- plan-issue: `<x.y.z>` — <brew release (formula <ver>) | local checkout <sha>(+dirty)>
- plan-tooling: `<x.y.z>` — <source>
- forge-cli: `<x.y.z>` — <source>
- Declared skill floors: `plan-issue >=<x.y.z>`, `plan-tooling >=<x.y.z>`

## Repro

1. <step>
2. <step>

## Expected vs actual

- Expected: <…>
- Actual: <…>

## Fix candidate

- Owner: <agent-runtime-kit | nils-cli>
- Location: <repo path:line>
- Change: <what to change>
```

## Boundary

This skill owns the finding's issue record in the tracker (open / dedup /
comment / close) and its labels. It does not implement the fix (that is an
`agent-runtime-kit` skill or `nils-cli` CLI change), run the plan-tracking e2e
flow (that is the `test-plan-tracking` driver plus the dispatch plan-tracking
skills), or mutate runtime-kit manifests, rendered output, or global runtime
homes. For general (non-plan-issue) issue work use `issue-follow-up`; for
work-selection across an inbox use `issue-triage`; for plan-bundle tracking
issues use `create-plan-tracking-issue`.
