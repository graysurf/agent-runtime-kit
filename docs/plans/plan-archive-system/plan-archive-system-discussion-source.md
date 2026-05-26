# Plan Archive System Implementation Handoff

- Status: ready for plan generation
- Date: 2026-05-26
- Source: user-driven design discussion on managing `docs/plans/` lifecycle
  across repositories, capturing work history outside individual repos, and
  letting future agents trace cross-repo work context.
- Intended next step: feed this document into `create-plan-tracking-issue`
  before implementation. This is a source artifact, not an implementation plan.

## Execution

- Recommended plan: docs/plans/plan-archive-system/plan-archive-system-plan.md
- Recommended execution state: docs/plans/plan-archive-system/plan-archive-system-execution-state.md

## Purpose

`docs/plans/` material currently accumulates in every working repository.
The pain points the user reported:

- Plans stay forever in source repos, inflating `rg` noise during debug and
  development.
- Each repo carries its own plan history with no cross-repo or cross-host view.
- Plan issues already retain commit hashes that let a contributor recover a
  specific plan version, but the recovery flow is manual and undiscoverable.
- Future debug or design work would benefit from being able to trace prior
  decisions across repos and provider hosts (GitHub + multiple GitLab hosts).

The proposal is a dedicated GitHub private archive repository plus two new
skills:

1. A user-invoked plan migration skill that moves closed plans out of working
   repos into the archive repo.
2. A work-history query skill that builds and consults a local index of
   issues / PRs / MRs (single-repo or cross-repo) and links archived plans
   for review.

## Confirmed Facts

- [U1] User wants to add a `YYYY-MM-DD-<slug>` date prefix to plan folders
  for chronological ordering at a glance.
- [U2] User does not want to keep all historical plans inside each source
  repository because `rg` and `grep` searches become noisy and repos grow.
- [U3] Plan issues already preserve work records and contain commit hashes
  for later file recovery, so deletion from the source repo is acceptable
  when archive preservation is in place.
- [U4] User wants a single archive repository that accepts plans from all
  source repos across GitHub and multiple GitLab hosts.
- [U5] User explicitly wants archive cross-repo querying capability so that
  future agents can trace prior development context and pull related old
  plan files for review when needed.
- [U6] Migration skill must be user-invoked (not auto-triggered) and must
  provide a dry-run safeguard.
- [U7] Local issue/PR/MR cache may also live in the archive repository as
  append-only snapshots, never overwritten, never deleted.
- [U8] User accepts (for v1) that company-internal GitLab plan content
  will be placed into a personal GitHub private repository. User
  acknowledges this can be revisited later and the schema must keep that
  migration cheap.
- [F1] `docs/source/docs-placement-retention-policy-v1.md` classifies
  `docs/plans/<slug>/` as coordination material that is cleanup-eligible
  after execution unless promoted, which is consistent with the proposed
  archive-then-delete flow.
- [F2] Existing plan folders under
  `docs/plans/` use a plain slug (no date prefix) such as
  `skill-lifecycle-management/` and `issue-backed-plan-lifecycle/`. The new
  rule only governs newly created plan folders; backfill is out of scope
  for v1.

## Decisions

### Naming and layout

- Archive repository layout uses a four-level mirror of provider URLs to
  prevent collisions across hosts, orgs, groups, and repos:

  ```text
  agent-plan-archive/
  ├── plans/
  │   └── <host>/<org-or-group-path>/<repo>/<YYYY-MM-DD>-<slug>/
  │       ├── PLAN.md
  │       ├── (other files copied verbatim from the original plan folder)
  │       └── metadata.yaml
  └── _index/
      └── <host>/<org-or-group-path>/<repo>/
          ├── issues/<number>/<ISO8601>.json
          └── pulls/<number>/<ISO8601>.json
  ```

  GitLab merge requests use `merge_requests/<number>/` instead of
  `pulls/<number>/`.
- `<host>` uses the provider FQDN with dots preserved
  (`github.com`, `gitlab.com`, `gitlab.example.com`).
- `<org-or-group-path>` preserves nested GitLab groups verbatim
  (`acme/platform/backend`).
- `<repo>` uses the canonical repo slug.
- `<YYYY-MM-DD>` records the archive date (plan completion date), not the
  plan creation date.
- `<slug>` keeps the original plan slug, kebab-case, three to six words.
- Newly created plan folders in working repos adopt the
  `<YYYY-MM-DD>-<slug>` form so the working-repo name already matches the
  archive name. Existing pre-v1 plan folders keep their current names.

### Source plan provenance

- Every archived plan carries a `metadata.yaml` capturing source host,
  org / group path, repo, branch, the archive-time commit SHA, and the
  original in-repo path, plus references to the issue and PR / MR that
  drove the plan. The exact field shape is illustrative and finalized in
  the plan-skill design.

### Archive repository

- Provider: GitHub.
- Visibility: private.
- Default repo name: `agent-plan-archive` (final name can be confirmed
  during plan execution).
- Default local clone path: `~/Project/graysurf/agent-plan-archive`,
  matching the existing `~/Project/<org>/<repo>` convention.
- All writes go through a commit using the standard
  `semantic-commit` family (no direct `git commit`), with a
  message such as
  `archive(plan): <host>/<org>/<repo> <YYYY-MM-DD>-<slug>`.

### Retention of employer-sourced material

- The archive repository must publish, in its `README.md` or an
  equivalent top-level notice, a formal statement to the effect that
  any material originating from an employer-operated GitHub or GitLab
  instance is retained solely for the maintainer's use during the
  active employment relationship with that organization, and that all
  such material will be removed from the archive upon termination of
  the relevant employment relationship.
- The canonical wording for the notice is finalized during plan
  execution. A working draft is:

  > Materials in this repository that originate from an
  > employer-operated GitHub or GitLab instance are retained solely
  > for the maintainer's use during the active employment
  > relationship with the respective organization. Upon termination
  > of any such employment relationship, all materials originating
  > from that organization, including archived plan folders and
  > index snapshots, will be deleted from this repository.

- The notice must reference the `source.host` field in
  `metadata.yaml` and the matching `_index/<host>/...` paths so that
  the deletion criterion is mechanically identifiable.

### Migration skill

- Trigger: user invocation only. The skill is not chained from any
  closeout workflow automatically.
- Default behaviour is dry-run. A `--apply` flag (or equivalent) is
  required to actually move files.
- Move is transactional: the skill pushes the new archive commit
  successfully before deleting the original `docs/plans/<slug>/` folder
  in the working repo.
- The skill records source provenance into `metadata.yaml` before
  writing the archive commit.
- The skill does not chain to commit / PR for the source-repo deletion
  step beyond standard project rules (`semantic-commit` and the active
  delivery skill remain authoritative).

### Index / cache

- Cache lives inside the same `agent-plan-archive` repository under
  `_index/`, not in a separate cache directory.
- Snapshot rule: every `refresh` writes a new
  `<ISO8601>.json` file. Existing snapshots are never overwritten and
  never deleted.
- Snapshot filename uses UTC ISO8601 without colons
  (`2026-06-26T143200Z.json`) so lexical sort equals chronological order.
- Snapshot content is the provider API payload as captured at refresh
  time (issue body, comments, state, labels, timestamps, and similar
  fields). Exact payload trimming is finalized in the implementation
  plan.
- "Latest" snapshot is the lexically last file in the ref folder; no
  symlink, no pointer file.
- Query behaviour reads cache by default and surfaces the latest
  snapshot's `fetched_at`. Refresh is explicit: single-ref, single-repo
  sweep, or `--since <date>` batch.
- No background sync, no reopen detection. Staleness is communicated
  through the visible `fetched_at`; the caller decides when to refresh.
- Compaction of historical snapshots is explicitly deferred and is not
  part of v1.

### Query skill

- Provided as a new skill that wraps the local archive index.
- Capability tiers:
  - Single-repo issue / PR / MR lookup against the cached snapshots.
  - Cross-repo / cross-host aggregate queries over the same cache.
  - Link traversal from archived plans (`metadata.yaml.refs.*`) back to
    the matching `_index/` snapshots, and vice versa.
- Default read path is local cache. Explicit refresh is available per
  ref, per repo, or by date window.
- The skill does not own provider API authentication; it delegates to
  `forge-cli` for the actual fetches.

## Scope

- Define the archive repository layout and `metadata.yaml` contract.
- Define the date-prefixed plan folder naming rule for new plans.
- Define rules for the local index / cache that lives inside the archive
  repository as append-only snapshots.
- Author two new skills:
  - Plan migration skill (user-invoked, dry-run-first, transactional).
  - Work-history query skill (read cache, explicit refresh, single-repo
    and cross-repo modes, archived-plan link traversal).
- Decide and document `agent-runtime-kit`'s discoverability story for
  these skills (`Read First` references, domain placement, manifest
  entries).
- Update `docs/source/docs-placement-retention-policy-v1.md` if needed
  so the policy reflects the new lifecycle.

## Non-Scope

- Backfilling `<YYYY-MM-DD>-` date prefixes onto existing plan folders.
- Migrating any plan folder that currently lives in any source repo;
  v1 migration is on-demand by the user.
- Splitting company-internal GitLab plan content into a separate
  archive repository. The schema must support such a split later, but
  v1 uses one personal-GitHub private archive.
- Detecting reopened provider issues automatically and refreshing their
  snapshots. The user explicitly accepted manual refresh as the model.
- Compacting or pruning historical `_index/` snapshots. v1 is pure
  append.
- Background sync, webhooks, or daemonized polling.
- A web UI for browsing the archive. Local CLI + filesystem inspection
  are sufficient.

## Implementation Boundaries

- Source authoring belongs in `agent-runtime-kit`. Deterministic
  filesystem mutation, JSON parsing, and provider lookups belong in
  `sympoies/nils-cli` (matching the existing `agent-runtime-kit` /
  `nils-cli` boundary called out in
  `docs/source/inventory-target-architecture.md`).
- Provider API access must go through `forge-cli` so authentication and
  host configuration follow existing conventions.
- The migration skill should call existing `semantic-commit` and active
  delivery skills rather than running raw `git commit`.
- New skills must register through `manifests/skills.yaml` and the
  appropriate plugin entry under `manifests/plugins.yaml`.

## Requirements

1. The new plan folder name format `<YYYY-MM-DD>-<slug>` is adopted for
   all new plans created after this work lands.
2. A GitHub private repository (default name `agent-plan-archive`)
   exists and is reachable from the user's primary GitHub identity.
3. The migration skill defaults to dry-run, requires explicit
   confirmation to apply, and only deletes source-repo files after the
   archive commit pushes successfully.
4. `metadata.yaml` captures host, org / group path, repo, branch,
   archive-time commit SHA, original in-repo path, and references to
   the issue and PR / MR that drove the plan.
5. The local index lives inside the archive repository at `_index/...`
   and follows the append-only ISO8601 snapshot rule.
6. The query skill reads cache by default, surfaces `fetched_at`, and
   provides explicit refresh by ref, by repo, or by date window.
7. Skills are discoverable through `manifests/skills.yaml` and
   appropriate plugin entries.
8. Validation includes manifest schema checks, render-golden updates if
   new skill bodies are added, and the standard runtime-smoke pass.
9. The archive repository's `README.md` (or an equivalent top-level
   notice) publishes a formal employer-sourced retention statement
   committing to deletion of all employer-originated material upon
   termination of the corresponding employment relationship, with the
   mechanical identification anchored on the `source.host` field.

## Acceptance Criteria

- A user can take a closed plan in any working repo and run the
  migration skill in dry-run, see exactly which files would move and to
  what archive path, then apply the move and observe both the archive
  commit on GitHub and the deletion in the working repo.
- After migration, a user can call the query skill with no arguments
  beyond an issue / PR / MR reference and receive the cached snapshot
  plus its `fetched_at`.
- A user can call the query skill across hosts and orgs and receive
  matching cached records.
- A user can ask the query skill to refresh a specific reference,
  observe a new `<ISO8601>.json` snapshot appear in the archive repo,
  and confirm older snapshots remain in place.
- A reopened-then-closed provider issue, refreshed by the user, shows
  multiple snapshots in chronological order under
  `_index/<host>/<org>/<repo>/<kind>/<number>/`.
- The standard repo validation (`scripts/ci/all.sh` or its successor)
  passes after the new skills land.
- The archive repository's `README.md` (or equivalent top-level notice)
  contains the employer-sourced retention statement and the wording is
  reviewed and accepted by the maintainer before any company-sourced
  plan or snapshot is written.

## Validation Plan

- Run `agent-docs resolve --context startup --strict --format checklist`
  and `agent-docs resolve --context project-dev --strict --format checklist`
  before edits during execution.
- Validate manifest changes with the existing manifest schema check.
- Refresh affected render-goldens if the new skills add or modify
  product render output.
- Run the project's standard runtime smoke when new skill bodies are
  added.
- Apply `code-review-quick-pass` for the docs and manifest changes,
  escalating to a focused lens (`security`, `data-migration`) only if
  the plan introduces unexpected file deletion paths or cross-host
  data movement code.

## Risks And Guardrails

- **Cross-organisation data placement (high).** Company-internal
  GitLab plan content placed into a personal GitHub private repository
  may conflict with employment or data-handling agreements. v1
  proceeds with explicit user acceptance ([U8]) and is bounded by the
  employer-sourced retention statement decided above (see
  `Retention of employer-sourced material`). The schema records
  `source.host` in every `metadata.yaml` so the archive can be split
  later by host with a deterministic filter and so the
  end-of-employment deletion criterion is mechanically identifiable.
- **Accidental source-repo deletion.** The migration skill defaults to
  dry-run and only deletes after a successful archive push. The plan
  must specify the exact failure modes (push rejected, partial commit,
  network failure) that abort deletion.
- **Archive repo size growth.** Append-only `_index/` snapshots grow
  monotonically. v1 accepts this and explicitly defers compaction.
  Plan execution should size-check after the first month of usage and
  open a follow-up if growth is concerning.
- **Stale cache mistaken for current state.** Cache reads surface
  `fetched_at` so the caller can judge staleness. Implementation must
  make `fetched_at` visible by default, not behind a verbose flag.
- **Forge-cli host coverage.** Cross-host queries require
  `forge-cli` authentication for every targeted host. The plan should
  enumerate which hosts must be configured up front and what error
  message the query skill shows when a host is unauthenticated.

## Retention Intent

- This document is plan-source material. It is cleanup-eligible after
  the plan executes, unless the team chooses to promote it to a
  domain-local runbook describing the plan archive workflow.
- The downstream plan and execution-state files under
  `docs/plans/plan-archive-system/` follow the standard cleanup-after-
  execution rule unless promoted.

## Read First References

- `docs/source/docs-placement-retention-policy-v1.md` (placement rules
  for `docs/plans/` and lifecycle classes).
- `docs/source/inventory-target-architecture.md` (boundary between
  `agent-runtime-kit` and `sympoies/nils-cli`).
- `docs/plans/skill-lifecycle-management/skill-lifecycle-management-discussion-source.md`
  (precedent for skill authoring discussion source).
- `AGENT_HOME.md` and `AGENTS.md` (preflight, commit, and forge-cli
  policy).

## Recommended Next Artifact

A `create-plan-tracking-issue` invocation that uses this document as
`Read First` source material and proposes phased tasks for:

1. Naming convention and policy update (date prefix, placement policy
   touch-up).
2. Archive repository bootstrap and `metadata.yaml` contract.
3. Migration skill (dry-run-first, transactional).
4. `_index/` snapshot contract and refresh semantics.
5. Query skill (single-repo, cross-repo, archive linkage).
6. Manifest / plugin registration and validation pass.
