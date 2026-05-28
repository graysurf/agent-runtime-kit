# Runtime Skills

This directory contains the portable source templates for runtime-kit skills.
`manifests/skills.yaml` is the machine-checkable inventory; this README is the
human index for scanning the skill catalog by category and skill series.

## Summary

| Category | Skills | Main series |
| --- | ---: | --- |
| `browser` | 2 | Browser-session evidence, canary checks |
| `code-review` | 5 | Quick pass, focused lenses, pre-merge gate, follow-up, specialist review |
| `conversation` | 7 | Advice, knowledge, handoff, work modes |
| `dispatch` | 8 | Plan-tracking issues, dispatch plans, dispatch lanes |
| `evidence` | 6 | Evidence records, impact scans, cross-checks |
| `issue` | 2 | Issue triage and durable follow-up |
| `media` | 2 | Image conversion, screen capture |
| `meta` | 17 | Runtime primitives, script dispatchers, skill lifecycle, heuristics |
| `pr` | 7 | GitHub PRs, GitLab MRs, dispatch-lane PRs |
| `reporting` | 3 | Topic radar, daily brief, project retrospective |

## Browser

| Series | Skill | Purpose |
| --- | --- | --- |
| Browser-session evidence | [browser-session](./browser/browser-session/) | Records browser-session goals, steps, artifacts, and verification status through `browser-session`. |
| Canary checks | [canary-check](./browser/canary-check/) | Runs a local canary command, persists redacted evidence, and verifies status through `canary-check`. |

## Code Review

Routing guidance for the skill family lives in
[code-review/README.md](./code-review/README.md).

| Series | Skill | Purpose |
| --- | --- | --- |
| Quick pass | [code-review-quick-pass](./code-review/code-review-quick-pass/) | Runs a lightweight read-only review for small or ordinary diffs before escalating to specialist review. |
| Focused lens | [code-review-focused-lens](./code-review/code-review-focused-lens/) | Runs one or more explicitly requested specialist review lenses without invoking the full specialist bundle. |
| Pre-merge gate | [code-review-pre-merge-gate](./code-review/code-review-pre-merge-gate/) | Runs the shared read-only specialist review gate before PR or MR merge decisions. |
| Follow-up | [code-review-follow-up](./code-review/code-review-follow-up/) | Re-checks previous review findings after fixes and classifies each item by disposition. |
| Specialist review | [code-review-specialists](./code-review/code-review-specialists/) | Decomposes risky or broad diffs into read-only specialist review passes and merges normalized findings. |

## Conversation

| Series | Skill | Purpose |
| --- | --- | --- |
| Advice and knowledge | [actionable-advice](./conversation/actionable-advice/) | Structures actionable engineering advice around options, tradeoffs, assumptions, and one recommendation. |
| Advice and knowledge | [actionable-knowledge](./conversation/actionable-knowledge/) | Explains concepts or confusion through multiple lenses with one recommended next step. |
| Durable discussion artifacts | [discussion-to-implementation-doc](./conversation/discussion-to-implementation-doc/) | Converts completed requirements, design, feasibility, or customer-facing discussion into implementation-ready source material. |
| Durable discussion artifacts | [handoff-session-prompt](./conversation/handoff-session-prompt/) | Generates a next-session initialization prompt from current context and user-specified references. |
| Work modes | [orchestrator-first](./conversation/orchestrator-first/) | Makes the main agent own scope, dispatch, integration, validation, and final synthesis while subagents own lanes. |
| Work modes | [parallel-first](./conversation/parallel-first/) | Applies the shared parallel delegation protocol for safely parallelizable sidecar work. |
| Work modes | [test-first](./conversation/test-first/) | Governs implementation with failing-test evidence or an explicit waiver before production code changes. |

## Dispatch

| Series | Skill | Purpose |
| --- | --- | --- |
| Plan-tracking issue | [create-plan-tracking-issue](./dispatch/create-plan-tracking-issue/) | Creates or previews a lightweight issue-backed plan tracker with shared dashboard and append-only lifecycle comments. |
| Plan-tracking issue | [execute-plan-tracking-issue](./dispatch/execute-plan-tracking-issue/) | Resumes lightweight issue-backed plan execution from lifecycle comments and keeps the dashboard current. |
| Plan-tracking issue | [deliver-plan-tracking-issue](./dispatch/deliver-plan-tracking-issue/) | Delivers a lightweight issue-backed plan through implementation, review, PR delivery, and close readiness gates. |
| Plan-tracking issue | [plan-tracking-issue-closeout](./dispatch/plan-tracking-issue-closeout/) | Closes a lightweight plan-tracking issue after lifecycle audit, validation, approval, PR evidence, and dashboard repair. |
| Dispatch plan | [deliver-dispatch-plan](./dispatch/deliver-dispatch-plan/) | Delivers a dispatch-ready plan by creating the shared issue record, dispatching lanes, reviewing PRs, and closing gates. |
| Dispatch plan | [dispatch-plan-closeout](./dispatch/dispatch-plan-closeout/) | Closes out a shared dispatch plan record after lane PRs, review, validation, approval, and lifecycle gates pass. |
| Dispatch lane | [execute-dispatch-lane](./dispatch/execute-dispatch-lane/) | Executes an assigned lane, opens or updates its PR, and reports lane state back to the shared issue record. |
| Dispatch lane | [review-dispatch-lane-pr](./dispatch/review-dispatch-lane-pr/) | Reviews dispatch-lane PRs with retained evidence, provider comments, and issue-visible lifecycle updates. |

## Evidence

| Series | Skill | Purpose |
| --- | --- | --- |
| Web evidence | [web-evidence](./evidence/web-evidence/) | Captures redacted HTTP metadata, previews, and manifests through `web-evidence`. |
| Review evidence | [review-evidence](./evidence/review-evidence/) | Persists review findings, validation commands, artifacts, and verification status through `review-evidence`. |
| Test-first evidence | [test-first-evidence](./evidence/test-first-evidence/) | Records failing-test evidence, waivers, and final validation through `test-first-evidence`. |
| Skill usage evidence | [skill-usage](./evidence/skill-usage/) | Records skill invocation intent, linked evidence, validation, failures, and outcomes through `skill-usage`. |
| Documentation impact | [docs-impact](./evidence/docs-impact/) | Scans Git changes for documentation impact through `docs-impact`. |
| Model cross-check | [model-cross-check](./evidence/model-cross-check/) | Records primary and checker model observations through `model-cross-check` without owning provider calls. |

## Issue

| Series | Skill | Purpose |
| --- | --- | --- |
| Issue triage | [issue-triage](./issue/issue-triage/) | Reviews open GitHub or GitLab issues from `forge-cli inbox`, classifies readiness and blockers, and recommends execution order. |
| Durable issue follow-up | [issue-follow-up](./issue/issue-follow-up/) | Opens or continues a GitHub or GitLab issue as the durable timeline for a discovered problem, blocker, or handoff. |
| Plan-issue finding report | [report-plan-issue-finding](./issue/report-plan-issue-finding/) | Files plan-issue / plan-tracking family skill, CLI, or driver drift as a labeled issue in the canonical tracker, and closes it when the upstream fix lands. |

## Media

| Series | Skill | Purpose |
| --- | --- | --- |
| Image processing | [image-processing](./media/image-processing/) | Validates SVG inputs and converts SVG, PNG, JPEG, or WebP files through `image-processing`. |
| Screen capture | [screen-record](./media/screen-record/) | Captures screenshots or recordings from windows or displays through `screen-record`. |

## Meta

| Series | Skill | Purpose |
| --- | --- | --- |
| Runtime primitives | [agent-docs](./meta/agent-docs/) | Resolves, scaffolds, and validates required agent documentation for home and project scopes. |
| Runtime primitives | [agent-out](./meta/agent-out/) | Allocates canonical project-scoped output directories and audits workflow artifacts. |
| Runtime primitives | [agent-scope-lock](./meta/agent-scope-lock/) | Creates, reads, validates, and clears edit-scope locks through `agent-scope-lock`. |
| Runtime primitives | [sync-runtime-skills](./meta/sync-runtime-skills/) | Refreshes active runtime-kit skill surfaces into local Codex and Claude runtime homes. |
| Repo script dispatchers | [bootstrap](./meta/bootstrap/) | Dispatches project bootstrap requests to a repository-owned `.agents/scripts/bootstrap.sh` implementation. |
| Repo script dispatchers | [deploy](./meta/deploy/) | Dispatches deploy requests to a repository-owned `.agents/scripts/deploy.sh` implementation. |
| Repo script dispatchers | [pre-pr](./meta/pre-pr/) | Dispatches pre-PR validation requests to a repository-owned `.agents/scripts/pre-pr.sh` implementation. |
| Repo script dispatchers | [release](./meta/release/) | Dispatches release requests to a repository-owned `.agents/scripts/release.sh` implementation. |
| Project setup | [setup-project](./meta/setup-project/) | Guides a repository into the `.agents/` conventions used by retained dispatcher skills. |
| Skill lifecycle | [create-skill](./meta/create-skill/) | Adds a repo-owned runtime-kit skill with source, manifests, product render surfaces, acceptance coverage, and governance validation. |
| Skill lifecycle | [remove-skill](./meta/remove-skill/) | Removes a repo-owned runtime-kit skill with dry-run-first reference audit and retained historical records. |
| Project skill lifecycle | [create-project-skill](./meta/create-project-skill/) | Scaffolds a consuming-repo project-local skill under `.agents/skills` without mutating runtime-kit manifests. |
| Project skill lifecycle | [remove-project-skill](./meta/remove-project-skill/) | Removes a consuming-repo project-local skill with dry-run-first inventory and explicit approval for cleanup. |
| Heuristic system | [heuristic-inbox](./meta/heuristic-inbox/) | Manages curated heuristic-system inbox cases and operation records. |
| Heuristic system | [heuristic-session-closeout](./meta/heuristic-session-closeout/) | Reviews session evidence for heuristic-system updates and writes retained records when warranted. |
| Commit and retrospectives | [semantic-commit](./meta/semantic-commit/) | Commits staged changes with Semantic Commit format through `semantic-commit`. |
| Commit and retrospectives | [repo-retro](./meta/repo-retro/) | Generates local repository retrospective data through `repo-retro`. |

## PR And MR

| Series | Skill | Purpose |
| --- | --- | --- |
| GitHub PR lifecycle | [create-github-pr](./pr/create-github-pr/) | Creates a GitHub pull request through the released `forge-cli pr create` surface. |
| GitHub PR lifecycle | [close-github-pr](./pr/close-github-pr/) | Closes or merges GitHub pull requests through released `forge-cli pr` lifecycle surfaces. |
| GitHub PR lifecycle | [deliver-github-pr](./pr/deliver-github-pr/) | Delivers GitHub pull requests end to end through the released `forge-cli pr deliver` macro. |
| GitLab MR lifecycle | [create-gitlab-mr](./pr/create-gitlab-mr/) | Creates a GitLab merge request through the released `forge-cli pr create` surface. |
| GitLab MR lifecycle | [close-gitlab-mr](./pr/close-gitlab-mr/) | Closes or merges GitLab merge requests through released `forge-cli pr` lifecycle surfaces. |
| GitLab MR lifecycle | [deliver-gitlab-mr](./pr/deliver-gitlab-mr/) | Delivers GitLab merge requests end to end through the released `forge-cli pr deliver` macro. |
| Dispatch-lane PR | [create-dispatch-lane-pr](./pr/create-dispatch-lane-pr/) | Creates a GitHub dispatch-lane pull request after a plan issue assigns the lane. |

## Reporting

| Series | Skill | Purpose |
| --- | --- | --- |
| Topic radar | [topic-radar](./reporting/topic-radar/) | Aggregates read-only AI and technology trend signals into source-grounded Markdown or JSON digests. |
| Topic radar | [daily-brief](./reporting/daily-brief/) | Prepares a source-grounded daily information brief and orchestrates `topic-radar` JSON output. |
| Project retrospective | [project-retro](./reporting/project-retro/) | Generates a repo-local project implementation retrospective through `repo-retro`. |
