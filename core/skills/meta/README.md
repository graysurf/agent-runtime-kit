# Meta Skills

The `meta` domain contains runtime-kit maintenance and repository operation
skills. These skills manage the agent runtime itself, project adoption, skill
catalog lifecycle, retained workflow records, and delivery support primitives.
They are not application-domain implementation skills.

`manifests/skills.yaml` is the machine-checkable inventory. This README is the
human routing index for choosing the right meta skill without scanning every
`SKILL.md`.

## Summary

| Series | Skills | Use when |
| --- | ---: | --- |
| Runtime primitives | 4 | Resolving required docs, output paths, edit scope, or installed runtime skill surfaces |
| Repo operation dispatchers | 5 | Running repo-owned bootstrap, deploy, pre-PR, release, or adoption workflows |
| Skill lifecycle | 4 | Creating or removing managed runtime-kit skills or consuming-repo project skills |
| Plan archive | 3 | Querying, discovering, or migrating completed plan bundles |
| Evidence archive | 1 | Migrating durable, scrubbed skill-usage evidence into the agent-evidence-archive |
| Heuristic system | 2 | Recording unresolved workflow gaps or session closeout lessons |
| Delivery and repo maintenance | 4 | Committing, worktree triage, CLI pin bumps, or local retrospectives |

## Runtime Primitives

| Skill | Purpose |
| --- | --- |
| [agent-docs](./agent-docs/) | Resolves, scaffolds, and validates required agent documentation for home and project scopes. |
| [agent-out](./agent-out/) | Allocates canonical project-scoped output directories and audits workflow artifacts. |
| [agent-scope-lock](./agent-scope-lock/) | Creates, reads, validates, and clears edit-scope locks through `agent-scope-lock`. |
| [sync-runtime-surfaces](./sync-runtime-surfaces/) | Refreshes active runtime-kit managed surfaces into local Codex and Claude runtime homes. |

## Repo Operation Dispatchers

| Skill | Purpose |
| --- | --- |
| [bootstrap](./bootstrap/) | Dispatches project bootstrap requests to a repository-owned `.agents/scripts/bootstrap.sh` implementation. |
| [deploy](./deploy/) | Dispatches deploy requests to a repository-owned `.agents/scripts/deploy.sh` implementation. |
| [pre-pr](./pre-pr/) | Dispatches pre-PR validation requests to a repository-owned `.agents/scripts/pre-pr.sh` implementation. |
| [release](./release/) | Dispatches release requests to a repository-owned `.agents/scripts/release.sh` implementation. |
| [setup-project](./setup-project/) | Guides a repository into the `.agents/` conventions used by retained dispatcher skills. |

## Skill Lifecycle

| Skill | Purpose |
| --- | --- |
| [create-skill](./create-skill/) | Adds a repo-owned runtime-kit skill with source, manifests, product render surfaces, acceptance coverage, and governance validation. |
| [remove-skill](./remove-skill/) | Removes a repo-owned runtime-kit skill with dry-run-first reference audit and retained historical records. |
| [create-project-skill](./create-project-skill/) | Scaffolds a consuming-repo project-local skill under `.agents/skills` without mutating runtime-kit manifests. |
| [remove-project-skill](./remove-project-skill/) | Removes a consuming-repo project-local skill with dry-run-first inventory and explicit approval for cleanup. |

## Plan Archive

| Skill | Purpose |
| --- | --- |
| [plan-archive-query](./plan-archive-query/) | Reads and refreshes the agent-plan-archive work-history cache before opening new work or diagnosing recurring problems. |
| [plan-archive-discover](./plan-archive-discover/) | Performs a read-only scan of plan folders for archive candidates before migration. |
| [plan-archive-migrate](./plan-archive-migrate/) | Migrates a closed plan folder into the agent-plan-archive repository, dry-run first and apply only on explicit confirmation. |

## Evidence Archive

| Skill | Purpose |
| --- | --- |
| [evidence-migrate](./evidence-migrate/) | Migrates skill-usage evidence out of the ephemeral agent-out tree into the agent-evidence-archive, dry-run first and apply only on explicit confirmation; the read surfaces (`evidence discover` / `query` / `search` / `catalog`) are driven directly per the evidence-archive policy. |

## Heuristic System

| Skill | Purpose |
| --- | --- |
| [heuristic-inbox](./heuristic-inbox/) | Manages curated heuristic-system inbox cases and operation records. |
| [heuristic-session-closeout](./heuristic-session-closeout/) | Reviews session evidence for heuristic-system updates and writes retained records when warranted. |

## Delivery And Repo Maintenance

| Skill | Purpose |
| --- | --- |
| [semantic-commit](./semantic-commit/) | Commits staged changes with Semantic Commit format through `semantic-commit`. |
| [worktree-triage](./worktree-triage/) | Scans local git worktrees and classifies merged, patch-equivalent, rescue, and review-needed branches. |
| [nils-cli-bump](./nils-cli-bump/) | Proposes the coordinated runtime-kit update when a new pinned nils-cli release ships. |
| [repo-retro](./repo-retro/) | Generates local repository retrospective data through `repo-retro`. |
