# Plan: Plan Archive — nils-cli Capabilities

## Overview

Land the deterministic CLI surface in `sympoies/nils-cli` that the
plan-archive skills in `agent-runtime-kit` will call. Three subcommands
plus three schema validators plus a secret-scrub library, all delivered
under a new `plan-archive` top-level CLI binary.

This plan is one of two cross-repo deliveries that fall out of the
master design at
`docs/plans/plan-archive-system/plan-archive-system-discussion-source.md`.
Plan 3 (`plan-archive-runtime-kit`) wraps these CLI capabilities into
user-facing skills. The archive repository itself is bootstrapped as a
one-shot prerequisite (Plan 2 note in the master discussion source) and
is not tracked here.

The tracker issue for this plan is opened in `sympoies/nils-cli`. The
plan folder remains in `agent-runtime-kit` to keep the design and the
sub-plan tree co-located, following the precedent set by
`docs/plans/nils-cli-version-alignment/`.

## Read First

- Primary source: docs/plans/plan-archive-system/plan-archive-system-discussion-source.md
- Source type: discussion-to-implementation-doc
- Sibling plan: docs/plans/plan-archive-runtime-kit/plan-archive-runtime-kit-plan.md
- Open questions carried into execution:
  - [Q1] CLI binary name. Default in this plan: `plan-archive`. Confirm
    against `sympoies/nils-cli` naming conventions during execution.
  - [Q2] Secret-scrub pattern set v1 scope. Default in this plan:
    GitHub/GitLab/Bitbucket tokens, AWS access keys, generic
    `secret`/`token`/`password` key-value pairs, and PEM private-key
    headers. Finalized via fixture review.
  - [Q3] `plan-archive migrate` invocation of `semantic-commit`:
    delegate to the existing released `semantic-commit` binary, do not
    re-implement.

## Scope

- In scope:
  - New CLI binary `plan-archive` with subcommands `migrate`, `refresh`,
    and `query`.
  - Schema validators for `config/hosts.yaml`, the machine-local config
    at `$XDG_CONFIG_HOME/agent-plan-archive/config.yaml`, and the
    archived plan `metadata.yaml`.
  - Secret-scrub library used by `plan-archive refresh` before writing
    snapshot files.
  - Append-only ISO8601 snapshot writer producing
    `<ISO8601>.json` and an optional `<ISO8601>.scrub.log` sibling.
  - JSON-shaped output for every subcommand so runtime-kit skills can
    parse results without screen-scraping.
  - `--dry-run` default for `migrate` and an explicit `--apply` to
    actually move files.
  - Surface tag bump in `agent-runtime-kit`'s nils-cli pin
    (`docs/source/nils-cli-surface.md`) once released.
- Out of scope:
  - The user-facing skills (Plan 3 owns those).
  - Bootstrapping the archive repository (Plan 2 prereq note).
  - Modifying `forge-cli`'s host or auth configuration.
  - Compaction of historical `_index/` snapshots.
  - Detecting reopened provider issues to trigger refresh.
  - GUI / web UI for the archive.
  - Migrating existing pre-v1 `docs/plans/<slug>/` folders (the schema
    handles both forms; bulk migration is a separate decision).

## Assumptions

1. `forge-cli` continues to own provider authentication and host
   endpoint configuration; `plan-archive` shells out to it for issue /
   PR / MR payload fetches.
2. `semantic-commit` continues to be the supported commit entry point;
   `plan-archive migrate` invokes it rather than calling `git commit`
   directly.
3. The runtime-kit pin in `docs/source/nils-cli-surface.md` remains the
   source of truth for which `nils-cli` tag the runtime exercises.
4. JSON output schemas follow the existing `cli.<command>.<sub>.v1`
   convention used elsewhere in `nils-cli`.

## Sprint 1: Schema Validators

**Goal**: Land the three schema validators first so later subcommands
can rely on validated inputs.

**PR grouping intent**: one PR per validator family if cohesive, or one
PR for all three if the parser substrate is shared.

**Execution Profile**: serial

### Task 1.1: hosts.yaml schema and validator

- **Location**:
  - `plan-archive` CLI source tree (`sympoies/nils-cli`)
  - The master discussion source carries the working-draft schema
    (see `Read First`).
- **Description**: Add a strict schema for the archive-side
  `config/hosts.yaml` and a `plan-archive validate-hosts` subcommand
  (or equivalent) that parses, validates, and emits normalized JSON.
- **Dependencies**: none
- **Complexity**: 3
- **Acceptance criteria**:
  - The validator rejects unknown classes, missing employer label on
    `class: employer`, and unknown retention values.
  - JSON output schema is documented and stable.
  - Fixture set covers personal-only, employer-only, and mixed cases.
- **Validation**:
  - `plan-archive validate-hosts --input fixtures/hosts/<case>.yaml`

### Task 1.2: local config schema and validator

- **Location**:
  - `plan-archive` CLI source tree
- **Description**: Add a schema and validator for the machine-local
  `$XDG_CONFIG_HOME/agent-plan-archive/config.yaml`. Tolerate absence
  and emit a normalized "defaults" object when the file is missing.
- **Dependencies**: Task 1.1 (parser substrate)
- **Complexity**: 2
- **Acceptance criteria**:
  - Missing file produces a documented defaults JSON object and exit
    code 0.
  - Malformed file produces a parse-error exit and a structured error.
  - Path fields are expanded for `~` and environment variables.
- **Validation**:
  - `plan-archive validate-local --input fixtures/local/<case>.yaml`
  - `plan-archive validate-local --input /nonexistent/path`

### Task 1.3: metadata.yaml schema and validator

- **Location**:
  - `plan-archive` CLI source tree
- **Description**: Add a schema and validator for the per-plan
  `metadata.yaml`. Includes `source.host`, org / group path, repo,
  branch, archive-time commit SHA, original in-repo path, captured
  host classification (audit field), and issue / PR / MR refs.
- **Dependencies**: Task 1.1
- **Complexity**: 3
- **Acceptance criteria**:
  - Validator enforces required fields and types.
  - Validator accepts metadata that omits captured classification
    (legacy case) but flags it via a warning JSON field.
  - Fixture set covers GitHub PR, GitLab MR, and orphan-plan cases.
- **Validation**:
  - `plan-archive validate-metadata --input fixtures/metadata/<case>.yaml`

## Sprint 2: Secret Scrub Library

**Goal**: Make snapshot writes safe to extend the exposure window for
secrets that get accidentally pasted into provider comments.

**PR grouping intent**: one PR.

**Execution Profile**: serial

### Task 2.1: pattern set and redaction engine

- **Location**:
  - `plan-archive` CLI source tree (library module, not a subcommand)
- **Description**: Implement detection and in-place redaction for the
  v1 secret-pattern set ([Q2] default). Emit per-match metadata
  (pattern id, byte offset, redaction length) for downstream log
  emission.
- **Dependencies**: none
- **Complexity**: 4
- **Acceptance criteria**:
  - Each pattern has a documented id and example.
  - Fixture payloads with each pattern produce expected redactions.
  - Negative fixtures (false-positive shapes) confirm pattern
    boundaries.
- **Validation**:
  - Unit tests covering each pattern.
  - End-to-end fixture covering all patterns in one payload.

### Task 2.2: scrub log emitter

- **Location**:
  - `plan-archive` CLI source tree
- **Description**: Add the writer that produces the
  `<ISO8601>.scrub.log` sibling file when at least one redaction
  occurs. Format is line-oriented, human-readable, and stable enough
  for diff review.
- **Dependencies**: Task 2.1
- **Complexity**: 2
- **Acceptance criteria**:
  - A payload with redactions emits a scrub log with one line per
    match.
  - A payload with no redactions emits no scrub log.
  - The log records redaction pattern id and location, never the
    secret itself.
- **Validation**:
  - Fixture-driven snapshot tests.

## Sprint 3: `plan-archive migrate` Subcommand

**Goal**: Move a closed plan folder from a working repo into the
archive repo, transactionally and dry-run-first.

**PR grouping intent**: one PR.

**Execution Profile**: serial

### Task 3.1: dry-run mode

- **Location**:
  - `plan-archive` CLI source tree
- **Description**: Implement `plan-archive migrate --dry-run` (default
  when no flag is passed). Output enumerates target archive path,
  files to copy, `metadata.yaml` payload, the source repo files to
  delete on apply, and the resolved host classification from
  `config/hosts.yaml`.
- **Dependencies**: Tasks 1.1, 1.3
- **Complexity**: 4
- **Acceptance criteria**:
  - Dry-run emits structured JSON that the runtime-kit migration skill
    can render to the user.
  - Dry-run never touches the working repo, the archive clone, or any
    remote.
  - A plan folder with non-canonical files is reported correctly.
- **Validation**:
  - Fixture run against a synthetic working repo.

### Task 3.2: apply mode (transactional)

- **Location**:
  - `plan-archive` CLI source tree
- **Description**: Implement `plan-archive migrate --apply`. Writes
  the archive copy and `metadata.yaml`, commits via the existing
  released `semantic-commit` binary, pushes, and only on push success
  deletes the original folder from the working repo. Failure modes
  (push rejected, partial commit, network failure) abort deletion and
  preserve the working-repo state.
- **Dependencies**: Task 3.1
- **Complexity**: 5
- **Acceptance criteria**:
  - Successful path produces one archive commit and one source-repo
    deletion commit.
  - Push failure leaves the working repo untouched.
  - Re-running after partial failure resumes cleanly.
- **Validation**:
  - Fixture run against a synthetic archive repo and a synthetic
    working repo with simulated push failure.

## Sprint 4: `plan-archive refresh` Subcommand

**Goal**: Capture forge-cli payloads as append-only snapshots in
`_index/`, with secret scrubbing.

**PR grouping intent**: one PR.

**Execution Profile**: serial

### Task 4.1: forge-cli payload fetch

- **Location**:
  - `plan-archive` CLI source tree
- **Description**: Add `plan-archive refresh --ref <ref>` that calls
  the appropriate `forge-cli` subcommand to fetch the provider payload
  (issue, PR, MR). Resolves host via `config/hosts.yaml` for path
  derivation.
- **Dependencies**: Task 1.1
- **Complexity**: 3
- **Acceptance criteria**:
  - Fetch is delegated to `forge-cli`; no provider auth lives here.
  - Unknown hosts emit a clear error pointing at
    `config/hosts.yaml`.
  - JSON output mirrors the payload shape produced by `forge-cli`.
- **Validation**:
  - Fixture run with a stubbed `forge-cli` returning canned payloads.

### Task 4.2: snapshot write with scrub integration

- **Location**:
  - `plan-archive` CLI source tree
- **Description**: Compose Task 4.1 with the Sprint 2 scrub library:
  scrub the payload, write `<ISO8601>.json` (UTC, no colons) plus
  optional `<ISO8601>.scrub.log`, never overwrite, never delete. Emit
  the resulting paths plus the scrub summary to stdout as JSON.
- **Dependencies**: Tasks 4.1, 2.1, 2.2
- **Complexity**: 4
- **Acceptance criteria**:
  - Two consecutive refreshes produce two distinct snapshot files.
  - A redaction triggers a `.scrub.log` sibling and the JSON output
    flags the user-review requirement.
  - File contents commit cleanly through `semantic-commit`.
- **Validation**:
  - Fixture run covering clean refresh and dirty refresh.

### Task 4.3: batch refresh modes

- **Location**:
  - `plan-archive` CLI source tree
- **Description**: Add `plan-archive refresh --repo <r>` and
  `plan-archive refresh --since <date>` to drive the same per-ref
  pipeline across multiple refs.
- **Dependencies**: Task 4.2
- **Complexity**: 3
- **Acceptance criteria**:
  - Batch refresh produces one commit per ref (or one batched commit
    per documented policy; finalized during execution).
  - Failures on individual refs do not abort the batch.
- **Validation**:
  - Fixture run with a mixed-success batch.

## Sprint 5: `plan-archive query` Subcommand

**Goal**: Provide the cache-read surface that the runtime-kit query
skill wraps.

**PR grouping intent**: one PR.

**Execution Profile**: serial

### Task 5.1: single-ref cache read

- **Location**:
  - `plan-archive` CLI source tree
- **Description**: Add `plan-archive query --ref <url-or-shorthand>`
  that returns the latest snapshot plus its `fetched_at`. Latest is
  defined as the lexically last file in the ref folder.
- **Dependencies**: Task 1.3
- **Complexity**: 2
- **Acceptance criteria**:
  - Output surfaces `fetched_at` by default, not behind a verbose
    flag.
  - Missing ref returns a structured "no snapshots" response, not a
    crash.
- **Validation**:
  - Fixture run against a seeded `_index/` tree.

### Task 5.2: cross-repo and cross-host aggregate

- **Location**:
  - `plan-archive` CLI source tree
- **Description**: Add filters: by host, by org / group path, by
  repo, by date range, by label, by state. Returns a JSON array of
  matching latest snapshots.
- **Dependencies**: Task 5.1
- **Complexity**: 4
- **Acceptance criteria**:
  - A filter that matches no records returns an empty array, exit 0.
  - Cross-host queries return records from all reachable hosts in one
    pass.
- **Validation**:
  - Fixture run covering host / repo / date filters.

### Task 5.3: archive plan link traversal

- **Location**:
  - `plan-archive` CLI source tree
- **Description**: Add `plan-archive query --plan <archive-path>` and
  the inverse `plan-archive query --refs-from <metadata.yaml>` so a
  user can pivot between an archived plan and its referenced
  issue / PR / MR snapshots.
- **Dependencies**: Task 5.1
- **Complexity**: 3
- **Acceptance criteria**:
  - Plan → refs returns each ref's latest snapshot.
  - Refs → plan resolves correctly when the metadata captures the
    reference.
- **Validation**:
  - Fixture run with linked plan and snapshot fixtures.

## Issue Closeout Gate

- All Sprint 1–5 PRs are merged.
- A versioned `nils-cli` release is cut that includes the new
  `plan-archive` binary.
- `docs/source/nils-cli-surface.md` in `agent-runtime-kit` is bumped
  to the new tag in a follow-up PR.
- The fixture matrix is part of the released package so downstream
  CI gates can run it.
- The runtime-kit Plan 3 tracker is notified via comment so the
  skill-body work can start.

## Future Work (Out Of Scope For This Tracker)

- Compaction or pruning of historical `_index/` snapshots.
- Reopen-detection automation that drives refresh without user
  invocation.
- Auto-bumping `docs/source/nils-cli-surface.md` when releases happen.
- Web UI for browsing the archive.
- Bulk migration of pre-v1 `docs/plans/<slug>/` folders.
