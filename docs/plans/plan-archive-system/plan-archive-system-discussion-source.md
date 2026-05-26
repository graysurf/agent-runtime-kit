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
  ├── README.md                       (or LEGAL.md; carries the retention notice)
  ├── config/
  │   └── hosts.yaml                  (host classification, retention anchor)
  ├── plans/
  │   └── <host>/<org-or-group-path>/<repo>/<YYYY-MM-DD>-<slug>/
  │       ├── PLAN.md
  │       ├── (other files copied verbatim from the original plan folder)
  │       └── metadata.yaml
  └── _index/
      └── <host>/<org-or-group-path>/<repo>/
          ├── issues/<number>/<ISO8601>.json
          ├── issues/<number>/<ISO8601>.scrub.log   (when scrubbing redacted content)
          └── pulls/<number>/<ISO8601>.json
  ```

  GitLab merge requests use `merge_requests/<number>/` instead of
  `pulls/<number>/`.
- `<host>` uses the provider FQDN with dots preserved
  (`github.com`, `gitlab.com`, `gitlab.example.com`).
- `<org-or-group-path>` preserves nested GitLab groups verbatim
  (`acme/platform/backend`).
- `<repo>` uses the canonical repo slug.
- `<YYYY-MM-DD>` records the date the plan folder was first created in
  its working repository. The same prefix is preserved verbatim through
  archive so the working-repo folder name and the archive path always
  match, and migration never has to rename or recompute the date.
- `<slug>` keeps the original plan slug, kebab-case, three to six words.
- Newly created plan folders in working repos adopt the
  `<YYYY-MM-DD>-<slug>` form. Existing pre-v1 plan folders keep their
  current slug-only names and are archived under their existing name.

### Source plan provenance

- Every archived plan carries a `metadata.yaml` capturing source host,
  org / group path, repo, branch, the archive-time commit SHA, the
  original in-repo path, the host classification resolved against
  `config/hosts.yaml` at archive time (and the employer label when
  applicable), and references to the issue and PR / MR that drove the
  plan. The captured classification is recorded as audit evidence;
  it is not the authoritative input for the retention deletion query
  (see `Retention of employer-sourced material`). The exact field
  shape is illustrative and finalized in the plan-skill design.

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

### Configuration layering

Configuration that the archive system needs is split into three layers
so that each piece of state lives at the narrowest correct owner:

- **Layer A — provider authentication and host endpoints.** Owned by
  the existing `forge-cli` configuration. The archive system does not
  duplicate authentication, tokens, API base URLs, or default
  namespaces. All provider API access is delegated to `forge-cli`.
- **Layer B — host classification.** Owned by a committed file inside
  the archive repository at `config/hosts.yaml`. Each provider FQDN
  is classified as `personal` or `employer`. Employer entries name
  the employer and carry the retention policy. This file is the
  authoritative source for the retention deletion criterion and must
  be reviewable through the archive's git history.
- **Layer C — machine-local state.** Owned by a local config file at
  `$XDG_CONFIG_HOME/agent-plan-archive/config.yaml`. Carries the
  per-machine archive clone path, the working-repo scan roots used by
  the migration skill, and any performance tuning knobs. Never
  contains tokens, never contains host classification, and is not
  required for the archive's authoritative behaviour to be
  reproducible.

A working draft of `config/hosts.yaml` is:

```yaml
version: 1
hosts:
  github.com:
    class: personal
    primary_identity: graysurf
  gitlab.com:
    class: personal
  gitlab.example.com:
    class: employer
    employer: ExampleCorp
    retention: delete-on-termination
```

A working draft of the local config is:

```yaml
version: 1
archive_clone_path: ~/Project/graysurf/agent-plan-archive
working_repo_roots:
  - ~/Project
performance:
  refresh_batch_size: 50
```

Both schemas are illustrative for v1 and finalized during plan
execution.

### Retention of employer-sourced material

- The archive repository must publish, in `README.md` or `LEGAL.md`,
  a formal statement to the effect that any material originating from
  an employer-operated GitHub or GitLab instance is retained solely
  for the maintainer's use during the active employment relationship
  with that organization, and that the archive repository as a whole
  will be destroyed on termination of any such employment
  relationship.
- Honouring the statement requires deleting the entire archive
  repository (including its full git history) rather than performing
  in-tree file deletion, because file-level deletion would leave a
  reachable copy in git history. After destruction, any personally
  originated content the maintainer wishes to preserve is
  reconstructed into a freshly initialized archive.
- The current state of `config/hosts.yaml` is the authoritative
  classification input. The retention deletion criterion ("is this
  archive subject to destruction") is determined by querying the
  present-day `config/hosts.yaml`, not by reading historical
  `metadata.yaml` snapshots. Re-classifying a host from `personal` to
  `employer` is therefore sufficient to bring all existing plans and
  snapshots from that host under the deletion clause without editing
  any existing `metadata.yaml`.
- The canonical wording for the notice is finalized during plan
  execution. A working draft is:

  > Materials in this repository that originate from an
  > employer-operated GitHub or GitLab instance, as classified by
  > `config/hosts.yaml`, are retained solely for the maintainer's
  > use during the active employment relationship with the
  > respective organization. Upon termination of any such employment
  > relationship, the archive repository as a whole, including its
  > git history, will be destroyed in order to remove all such
  > materials. Any personally originated content the maintainer
  > wishes to preserve is reconstructed into a freshly initialized
  > archive afterwards.

- The notice must explicitly cite `config/hosts.yaml` as the
  authoritative source of the employer-host list, and reference the
  `source.host` field in `metadata.yaml` together with the matching
  `_index/<host>/...` paths so that the deletion criterion is
  mechanically identifiable and reproducible from the archive alone.

### Migration skill

- Trigger: user invocation only. The skill is not chained from any
  closeout workflow automatically.
- Default behaviour is dry-run. A `--apply` flag (or equivalent) is
  required to actually move files.
- Move is transactional: the skill pushes the new archive commit
  successfully before deleting the original plan folder in the working
  repo (`docs/plans/<YYYY-MM-DD>-<slug>/` for v1 plans, or
  `docs/plans/<slug>/` for pre-v1 legacy plans).
- The skill records source provenance into `metadata.yaml` before
  writing the archive commit, and resolves `source.host` against
  `config/hosts.yaml` so the resulting `metadata.yaml` carries the
  host classification (and employer label, when applicable) that was
  in force at archive time. This captured classification is audit
  evidence; the authoritative classification for retention deletion
  is always the current `config/hosts.yaml` (see `Retention of
  employer-sourced material`).
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
- Before a snapshot is committed, the refresh step scans the payload
  for common secret patterns (tokens, API keys, passwords, private
  key headers, AWS-style access IDs, and similar). Matches are
  redacted in place, a sibling `<ISO8601>.scrub.log` file lists each
  redaction by location, and the user is required to review the log
  before the snapshot commit is created. Snapshots that contain no
  redactions do not emit a scrub log.
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
- Define the `config/hosts.yaml` schema inside the archive repository
  and the machine-local config schema at
  `$XDG_CONFIG_HOME/agent-plan-archive/config.yaml`.
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
- Provider authentication and host endpoint configuration remain
  owned by `forge-cli`. The archive system reads only the
  classification layer (`config/hosts.yaml`) and does not modify or
  duplicate `forge-cli` config.
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
9. The archive repository's `README.md` or `LEGAL.md` publishes a
   formal employer-sourced retention statement committing to
   destruction of the entire archive repository (working tree plus
   git history) upon termination of any corresponding employment
   relationship, with the mechanical identification anchored on the
   current `config/hosts.yaml`. The statement also describes the
   freshly-initialized-archive reconstruction step for personally
   originated content.
10. The archive repository commits a `config/hosts.yaml` file that
    classifies every provider host the archive references as
    `personal` or `employer`, names the employer for employer-class
    entries, and carries the retention policy. Migration writes the
    resolved classification into each new `metadata.yaml`.
11. A machine-local config at
    `$XDG_CONFIG_HOME/agent-plan-archive/config.yaml` carries the
    archive clone path, working-repo scan roots, and performance
    tuning knobs. Skills tolerate its absence by falling back to
    documented defaults, and never store tokens or host
    classification there.
12. `forge-cli` configuration is not modified or duplicated by the
    archive system; the archive system delegates all provider API
    access to `forge-cli`.
13. Snapshot writes pass through a secret-scrubbing step that redacts
    common token / key / password patterns before commit, emits a
    `<ISO8601>.scrub.log` sibling when any redaction occurs, and
    requires user review of the scrub log before the snapshot commit
    is created.

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
- Adding a new employer host to `config/hosts.yaml` and re-running
  the migration skill for a plan from that host results in a
  `metadata.yaml` whose host classification fields reflect the new
  entry without any other code or config change.
- Running the migration or query skill on a machine that has no
  local config under `$XDG_CONFIG_HOME/agent-plan-archive/` succeeds
  using documented defaults and reports the defaults it used.
- Re-classifying a host from `personal` to `employer` in
  `config/hosts.yaml` is sufficient to bring every existing plan
  folder and `_index/` snapshot from that host under the retention
  deletion clause, with no edits to any historical `metadata.yaml`.
- Refreshing a provider issue whose payload contains a deliberately
  planted secret pattern produces a redacted snapshot plus a
  `<ISO8601>.scrub.log` enumerating the redaction, and the snapshot
  commit is held until the user acknowledges the scrub log.

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
  `Retention of employer-sourced material`). Deletion is implemented
  by destroying the entire archive repository (working tree plus git
  history) so file-only deletion of `_index/` or `plans/` paths is
  explicitly insufficient and never substituted. The schema records
  `source.host` in every `metadata.yaml` and the authoritative
  classification lives in `config/hosts.yaml` so the deletion
  criterion is mechanically identifiable and is responsive to later
  re-classification without rewriting historical metadata.
- **Secret leakage through snapshots (medium).** Provider issues and
  PRs sometimes contain accidentally pasted tokens or keys. Storing
  the raw payload in the archive extends the exposure window. The
  refresh step therefore redacts common patterns before commit and
  emits a per-snapshot `.scrub.log` for user review. Detection is
  pattern-based and not exhaustive; novel secret shapes remain a
  residual risk and the plan must enumerate the patterns covered.
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
6. Configuration layering: `config/hosts.yaml` schema + seeded
   entries, machine-local config schema + defaults, integration
   points with `forge-cli`.
7. Manifest / plugin registration and validation pass.
