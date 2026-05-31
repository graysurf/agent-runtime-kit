---
name: heuristic-session-closeout
description:
  Use when this session's goal has been achieved and the agent needs to review
  available session evidence for Heuristic System updates, write curated
  retained records when warranted, and deliver them to `main` through a
  dedicated records branch and pull request.
---

# Heuristic Session Closeout

## Contract

Prereqs:

- This session's goal is achieved; no further in-session implementation,
  research, review, or delivery work is intended.
- `agent-docs` startup and project-dev preflight has passed before repository
  writes, commits, or pushes.
- `heuristic-inbox`, `semantic-commit`, `git`, `git-cli`, and `forge-cli` are
  available on `PATH`.
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
- Strict verification output for every changed retained record.
- A dedicated records branch off `origin/main`, a semantic commit, and a docs
  pull request that lands the records on `main` — never a commit on the current
  feature branch and never a direct push to `main`.
- A concise final summary naming what was retained, skipped, the records branch,
  and the PR, or the exact blocker.

Failure modes:

- The goal is not actually achieved or more task work remains.
- The Heuristic System root cannot be resolved.
- `origin/main` cannot be fetched, so the records branch cannot be based on a
  current `main`.
- Candidate evidence is unredacted, unsafe, raw runtime state, or too broad to
  commit safely.
- `heuristic-inbox verify --strict`, `git-cli worktree`, `semantic-commit`, the
  records-branch push, or `forge-cli pr create` fails.
- Stray files leave the records worktree dirty, which blocks `forge-cli pr
  create`.

## Entrypoint

Resolve the shared root, derive the owning checkout, and refresh `origin/main`:

```bash
root="${AGENT_RUNTIME_HEURISTIC_SYSTEM_ROOT:-$PWD/core/policies/heuristic-system}"
repo="$(cd "$root/../../.." && pwd -P)"
heuristic-inbox list --inbox-dir "$root/error-inbox" --include-archived --format json
git -C "$repo" fetch origin main --prune
```

Deliver on a dedicated records branch in an isolated worktree off `origin/main`
— never on the current branch (which may be a feature branch) and never by
pushing `main` directly (the primary `main` checkout may be busy with another
session). Author, verify, and archive the records inside that worktree:

```bash
git-cli worktree add heuristic-records-<slug> --from origin/main   # resolve its path as $rw
rroot="$rw/core/policies/heuristic-system"
# Author / verify / archive records under $rroot (see Workflow). Pass an explicit
# --inbox-dir "$rroot/error-inbox" to every mutating heuristic-inbox call.
heuristic-inbox verify "$rroot/error-inbox/<slug>" --strict --format json
heuristic-inbox verify "$rroot/operation-records/<slug>" --strict --format json
git -C "$rw" add core/policies/heuristic-system
semantic-commit commit --repo "$rw" --message "docs(heuristic): record session closeout findings"
git -C "$rw" push -u origin <records-branch>
forge-cli pr create --kind docs --title "docs(heuristic): ..." --body-file <body>
```

The records reach `main` only when that PR merges, so a feature branch is never
polluted and the records are never lost if the feature branch is abandoned.

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
     workflow gap.
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
7. Deliver on a dedicated records branch — never the current branch, never a
   direct push to `main`:
   - Author, verify, and archive the records inside an isolated worktree created
     off `origin/main` with `git-cli worktree add`, so the current branch and a
     possibly-busy primary `main` checkout are never mutated. Running closeout
     from inside a feature worktree must not commit records onto that feature
     branch.
   - Stage only `core/policies/heuristic-system/...`; keep the records worktree
     free of stray files (a dirty worktree blocks `forge-cli pr create`).
   - Commit with `semantic-commit` (never `git commit` directly); push the
     records branch; open a docs PR with `forge-cli pr create --kind docs`.
   - The records land on `main` only when that PR merges, so they are never
     tangled into an unrelated feature branch and never lost if that branch is
     abandoned.
   - If verify, the push, or `forge-cli` blocks, leave the records verified in
     the worktree and report the exact blocker and the worktree path.
8. Final response:
   - Name every case created, updated, promoted, archived, or skipped.
   - Include verification commands and the records branch / PR when completed.
   - If no durable record was warranted, say that explicitly and summarize the
     no-op rationale.

## Boundary

This skill owns session-level Heuristic System closeout judgment, curated
retention routing, and the default delivery of retained records to `main`
through a dedicated records branch and PR. It does not replace `heuristic-inbox`
case mechanics, `skill-usage` runtime evidence, project implementation
workflows, general PR/MR delivery, raw session-log archiving, or memory updates.
