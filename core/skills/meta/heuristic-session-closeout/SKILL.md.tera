---
name: heuristic-session-closeout
description:
  Use when this session's goal has been achieved and the agent needs to review
  available session evidence for Heuristic System updates, write curated
  retained records when warranted, and preserve them on `main`.
---

# Heuristic Session Closeout

## Contract

Prereqs:

- This session's goal is achieved; no further in-session implementation,
  research, review, or delivery work is intended.
- `agent-docs` startup and project-dev preflight has passed before repository
  writes, commits, or pushes.
- `heuristic-inbox`, `semantic-commit`, and `git` are available on `PATH`.
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
- A semantic commit and push to `origin main` when the retained-record diff is
  eligible.
- A concise final summary naming what was retained, skipped, committed, pushed,
  or blocked.

Failure modes:

- The goal is not actually achieved or more task work remains.
- The Heuristic System root cannot be resolved.
- Existing dirty or staged changes make the retained-record commit boundary
  ambiguous.
- Candidate evidence is unredacted, unsafe, raw runtime state, or too broad to
  commit safely.
- `heuristic-inbox verify --strict`, `semantic-commit`, or `git push` fails.
- The branch is not `main`, `main` is not fast-forwardable to `origin/main`, or
  pushing would require force or merge conflict resolution.

## Entrypoint

Resolve the shared root, derive the owning checkout, and inspect the
retained-record state:

```bash
root="${AGENT_RUNTIME_HEURISTIC_SYSTEM_ROOT:-$PWD/core/policies/heuristic-system}"
repo="$(cd "$root/../../.." && pwd -P)"
heuristic-inbox list --inbox-dir "$root/error-inbox" --include-archived --format json
git -C "$repo" status --short --branch
git -C "$repo" fetch origin main --prune
```

Verify each changed retained record before staging it:

```bash
heuristic-inbox verify "$root/error-inbox/<slug>" --strict --format json
heuristic-inbox verify "$root/operation-records/<slug>" --strict --format json
```

Commit and push only the eligible retained-record diff:

```bash
git -C "$repo" add core/policies/heuristic-system
semantic-commit commit --repo "$repo" --message "docs(heuristic): record session closeout findings"
git -C "$repo" push origin main
```

## Workflow

1. Confirm closeout scope:
   - Treat goal achievement as the trigger.
   - Do not continue implementation, research, PR delivery, or issue lifecycle
     work from this skill.
   - If meaningful task work remains, finish or report that blocker before
     running closeout.
2. Run required preflight before writes:
   - `agent-docs resolve --context startup --strict --format checklist`
   - `agent-docs resolve --context project-dev --strict --format checklist`
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
   - Archive entries only after they are `promoted` or `wontfix`, validated,
     and have no remaining next action.
5. Write curated records through the narrow mechanism:
   - Prefer `heuristic-inbox new`, `set-status`, `ingest-evidence`, and
     `archive` for case mechanics.
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
7. Commit and push by default when eligible:
   - Stage only `core/policies/heuristic-system/...` changes in the owning
     `agent-runtime-kit` checkout and only when they are owned by this closeout.
   - Do not include unrelated staged or unstaged changes.
   - Commit only from `main` when it is cleanly based on `origin/main`; never
     force-push.
   - Use `semantic-commit`; do not call `git commit` directly.
   - Push to `origin main` after commit so the retained record is not lost.
   - If any gate blocks the commit or push, leave the record verified locally
     and report the exact blocker.
8. Final response:
   - Name every case created, updated, promoted, archived, or skipped.
   - Include verification commands and commit/push SHA when completed.
   - If no durable record was warranted, say that explicitly and summarize the
     no-op rationale.

## Boundary

This skill owns session-level Heuristic System closeout judgment, curated
retention routing, and the default commit/push attempt for retained records. It
does not replace `heuristic-inbox` case mechanics, `skill-usage` runtime
evidence, project implementation workflows, PR/MR delivery, raw session-log
archiving, or memory updates.
