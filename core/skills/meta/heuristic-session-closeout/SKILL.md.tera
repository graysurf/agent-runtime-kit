---
name: heuristic-session-closeout
description:
  Use when this session's goal has been achieved and the agent needs to surface
  the session's skill-usage records, review available session evidence for
  Heuristic System updates, write curated retained records when warranted, and
  land them on `main` through the `heuristic-inbox deliver` records-branch PR
  (auto-merged).
---

# Heuristic Session Closeout

## Contract

Prereqs:

- This session's goal is achieved; no further in-session implementation,
  research, review, or delivery work is intended.
- `agent-docs` startup and project-dev preflight has passed before repository
  writes, commits, or pushes.
- `heuristic-inbox` (nils-cli >= v1.1.0, which ships default records-slug
  auto-suffixing for `heuristic-inbox deliver`) and `forge-cli` are available on
  `PATH`. `deliver` drives `git`,
  `semantic-commit`, and `forge-cli pr create` internally; the skill only adds
  the auto-merge step.
- The shared Heuristic System root can be resolved from
  `AGENT_RUNTIME_HEURISTIC_SYSTEM_ROOT` or
  `core/policies/heuristic-system/` in the active `agent-runtime-kit` checkout.

Inputs:

- Available session evidence: conversation conclusions, tool results, changed
  files, validation output, linked `skill-usage` or other runtime evidence, and
  existing Heuristic System cases.
- Current retained-record repository branch, working-tree status, and
  `origin/main` state.

Outputs:

- Updated or newly created curated records under
  `core/policies/heuristic-system/error-inbox/` or
  `core/policies/heuristic-system/operation-records/`, when retention is
  warranted.
- A surfaced inventory of the active session's `skill-usage` records (skill,
  outcome status, linked evidence) reviewed before retention, with every
  non-`pass` outcome flagged as a promotion-review candidate.
- Strict verification output for every changed retained record.
- A `heuristic-inbox deliver` run that opens a docs records-branch PR off
  `origin/main` (never a commit on the current feature branch and never a direct
  push to `main`), followed by the auto-merge that lands the records on `main`.
- A concise final summary naming what was retained, skipped, the records branch,
  and the merged PR, or the exact blocker.

Failure modes:

- The goal is not actually achieved or more task work remains.
- The Heuristic System root cannot be resolved.
- `origin/main` cannot be fetched, so the records branch cannot be based on a
  current `main`.
- Candidate evidence is unredacted, unsafe, raw runtime state, or too broad to
  commit safely.
- `heuristic-inbox verify --strict` fails, or `heuristic-inbox deliver` fails
  (`nothing-to-deliver`, `dirty-records-worktree` when changes leak outside the
  heuristic-system root, fetch / push / `forge-cli pr create` errors).
- The auto-merge step (`forge-cli pr ready` / `pr wait-checks` / `pr merge`)
  fails or required checks do not pass — leave the records PR open and report it.

## Entrypoint

Resolve the shared root and review existing cases. Author and verify the records
in the current checkout under `$root` (see Workflow) — `heuristic-inbox deliver`
owns the cwd-independent landing, so there is no manual worktree, commit, or push
here:

```bash
root="${AGENT_RUNTIME_HEURISTIC_SYSTEM_ROOT:-$PWD/core/policies/heuristic-system}"
heuristic-inbox list --inbox-dir "$root/error-inbox" --include-archived --format json
# Author / verify / archive records under $root (see Workflow). Pass an explicit
# --inbox-dir "$root/error-inbox" to every mutating heuristic-inbox call.
heuristic-inbox verify "$root/error-inbox/<slug>" --strict --format json
heuristic-inbox verify "$root/operation-records/<slug>" --strict --format json
```

Deliver the uncommitted records as a docs records-branch PR with
`heuristic-inbox deliver`. It resolves the canonical repo, fetches
`origin/<base>`, creates an isolated worktree on a `docs/<slug>` branch off
`origin/<base>`, stages only the heuristic-system root (refusing
`dirty-records-worktree` if anything else leaks in), commits via
`semantic-commit`, pushes, and opens the PR — never the current branch, never a
direct push to `main`. Always pass the fixed
`docs(heuristic): record session closeout findings` title and the
`--label workflow::heuristic-records` taxonomy label so every closeout records
PR is identifiable by title and label (not just the `docs/<slug>` branch):

```bash
deliver="$(heuristic-inbox deliver --root "$root" --kind docs \
  --title "docs(heuristic): record session closeout findings" \
  --label workflow::heuristic-records \
  --format json)"
pr_url="$(printf '%s' "$deliver" | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["pr_url"])')"
pr="${pr_url##*/}"   # trailing PR number
```

Then auto-land the records PR (the merge policy this skill owns): promote it,
wait for required checks, and squash-merge so the records reach `main`
hands-off. Once merged, discard the now-redundant uncommitted copies in the
current checkout so they never leak into an unrelated feature branch:

```bash
forge-cli pr ready "$pr"
forge-cli pr wait-checks "$pr"
forge-cli pr merge "$pr" --method squash
git checkout -- core/policies/heuristic-system   # drop the source copies now on main
```

If `deliver` or any auto-merge step blocks, stop and report the exact blocker
plus `pr_url` / branch / `worktree_path` from the `deliver` envelope; the records
remain recoverable on the pushed branch (or the open PR) and are never lost on an
abandoned feature branch.

## Workflow

1. Confirm closeout scope:
   - Treat goal achievement as the trigger.
   - Do not continue implementation, research, PR delivery, or issue lifecycle
     work from this skill.
   - If meaningful task work remains, finish or report that blocker before
     running closeout.
2. Heed the auto-loaded home policy and the hook-injected `project-dev`
   preflight before writes; `agent-docs audit --target all --strict` surfaces
   any repo-health problems.
3. Gather only available, relevant evidence:
   - Surface the active session's `skill-usage` records first, so no non-`pass`
     run is silently dropped before retention is judged. Records land under the
     `agent-out` project tree at
     `${AGENT_HOME:-$HOME/.local/state/agent-runtime-kit}/out/projects/<owner__repo>/<timestamp>-skill-usage/skill-usage.record.json`
     or under a workflow-owned run directory. Resolve the current session
     boundary before searching: prefer explicit run/evidence directories already
     produced in this session, then the current repo's project-keyed run
     directories. Do not broad-scan every `out/projects` record and treat old
     sessions or other repos as current promotion candidates.
     For each, read `skill`, `outcome.status`, `outcome.summary`, and
     `linked_records` / top-level `artifacts`, plus nested
     `failures[].artifacts`, `validation[].artifact`, and `follow_up[]`; list
     them with their outcome status and evidence pointers. Flag every non-pass
     outcome, including `fail`, `blocked`, `worked_around`,
     `accepted_risk` / `accepted-risk`, and any record with non-empty
     `failures[]` or `follow_up[]`, as a promotion-review candidate for step 4.
     This is read-only surfacing: never write to, scrub, or auto-commit the raw
     records here.
   - Review the conversation's concrete outcomes, repairs, failures, retries,
     validation results, and current diff.
   - Inspect existing active and archived Heuristic System cases before adding
     a new one.
   - Use runtime evidence paths as pointers; do not copy raw session logs,
     secrets, auth files, caches, or unredacted local paths into retained
     records.
4. Decide retention:
   - No durable artifact for transient typos, wrong cwd, immediate fixes, or
     friction without reusable future value.
   - Update an existing active entry when the session adds evidence, changes
     next action, validates promotion criteria, or clarifies the workaround.
   - Create a new `error-inbox/<slug>/ENTRY.md` only for an important,
     unresolved, repeated, skill-contract-relevant, or future-agent-reusable
     workflow gap. When a flagged session `skill-usage` record motivates the
     entry, seed it from that record with
     `heuristic-inbox new --from-skill-usage <record> --slug <slug> --out-dir "$root/error-inbox"`
     so the runtime evidence links forward to the curated case in the canonical
     inbox.
   - Use an `operation-records/<slug>/RECORD.md` only when the lesson is
     repeated, cross-skill, audit-worthy, or proves retained evidence became a
     durable fix.
   - Run a lightweight cluster-compression sweep, not only a this-session scan:
     when several `promoted` or archived entries already share a root cause or
     area, treat the cluster itself as an `operation-records/<slug>/RECORD.md`
     candidate per the Compression Rule, even if this session created none of
     them. Compress only resolved entries; reference still-open siblings as
     evidence the class recurs rather than claiming them fixed. This is the
     primary trigger that keeps the operation-records lane from going unused.
   - Archive entries only after they are `promoted` or `wontfix`, validated,
     and have no remaining next action.
5. Write curated records through the narrow mechanism:
   - Prefer `heuristic-inbox new`, `set-status`, `ingest-evidence`, and
     `archive` for case mechanics.
   - Pass an explicit `$root`-derived path (or `--inbox-dir
     "$root/error-inbox"`) to every mutating `heuristic-inbox` call — `new`,
     `set-status`, `ingest-evidence`, `archive`. Never rely on the current
     working directory, or `archive` can write a stray cwd-relative
     `./heuristic-system/` tree instead of the canonical root.
   - Keep retained prose compact: signal, evidence pointer, impact,
     workaround, promotion criteria, and next action.
   - Redact home paths to `<workspace>/...` or `$HOME/...` before retaining
     evidence.
6. Validate before commit:
   - Run `heuristic-inbox verify --strict --format json` on every changed case
     or operation record.
   - Run the smallest repo check that covers the touched surface; for
     retained-record-only edits, strict verification plus `git diff --check` is
     usually enough.
7. Deliver and auto-land through `heuristic-inbox deliver` — never the current
   branch, never a direct push to `main`:
   - Run `heuristic-inbox deliver --root "$root" --kind docs --title
     "docs(heuristic): record session closeout findings" --label
     workflow::heuristic-records` once the records are authored and
     `verify`-clean in the current checkout. The fixed title and the
     `workflow::heuristic-records` label make every closeout records PR
     identifiable by title and label, not just by the `docs/<slug>` branch. The
     command owns every mechanic the skill used to spell out in prose: it
     resolves the canonical repo, fetches `origin/<base>`, creates an isolated
     worktree on a `docs/<slug>` branch off `origin/<base>` (branch prefix
     derived from `--kind`, so it cannot mismatch `forge-cli`), stages only the
     heuristic-system root, refuses `dirty-records-worktree` if anything else
     leaks in, commits via `semantic-commit`, pushes, and opens the docs PR.
     Running closeout from inside a feature worktree therefore never commits
     records onto that feature branch.
   - Parse the `cli.heuristic-inbox.deliver.v1` envelope for `pr_url` /
     `branch` / `committed_paths` / `worktree_path`.
   - Auto-land the records PR (the merge policy this skill owns): promote it to
     ready, wait for required checks, and squash-merge —
     `forge-cli pr ready <pr>` → `forge-cli pr wait-checks <pr>` →
     `forge-cli pr merge <pr> --method squash`. The records reach `main`
     hands-off, never tangled into an unrelated feature branch and never lost if
     that branch is abandoned.
   - After the merge, discard the now-redundant uncommitted record copies in the
     current checkout (`git checkout -- core/policies/heuristic-system`) so they
     never leak into an unrelated feature branch.
   - If `deliver` or any auto-merge step blocks, stop and report the exact
     blocker plus `pr_url` / `branch` / `worktree_path`; the records stay
     recoverable on the pushed branch or the open PR.
8. Final response:
   - Name every case created, updated, promoted, archived, or skipped.
   - Include verification commands and the records branch / merged PR when
     completed.
   - If no durable record was warranted, say that explicitly and summarize the
     no-op rationale.

## Boundary

This skill owns session-level Heuristic System closeout judgment, curated
retention routing, and the merge policy for landing retained records on `main`
(auto-merge the `heuristic-inbox deliver` docs PR). It delegates the delivery
mechanics — worktree, staging guard, commit, push, PR-open — to
`heuristic-inbox deliver`, and does not re-encode them. It does not replace
`heuristic-inbox` case mechanics, `skill-usage` runtime evidence, project
implementation workflows, general PR/MR delivery, raw session-log archiving, or
memory updates.
