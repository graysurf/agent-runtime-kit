# Skill Decision-Minimal Review Inventory

Status: baseline complete
Date: 2026-06-05 UTC
Tracker: <https://github.com/graysurf/agent-runtime-kit/issues/288>

## Purpose

This inventory is the Task 1.2 baseline for the decision-minimal review. It
classifies every repo-managed skill by domain, rough size, mutation risk,
rewrite need, shared-spec opportunity, and validation surface before the edit
batches begin.

The classification uses the source rubric from
`2026-06-05-skill-decision-minimal-review-discussion-source.md`: keep text that
changes agent decisions, stop conditions, provider behavior, mutation safety, or
validation; remove or centralize repeated narrative and examples.

## Validation Baseline

| Command | Status | Summary |
| --- | --- | --- |
| `find core/skills -name SKILL.md.tera -print0 \| xargs -0 wc -l` | pass | 62 managed skill templates; 6812 total lines. |
| `bash scripts/ci/skill-governance-audit.sh --check-counts` | pass | `skill-governance-audit: counts OK skills=62 targets=6`. |

## Batch Order

| Batch | Domains | Rationale | Primary validation |
| --- | --- | --- | --- |
| B1 | `core/skills/README.md`, shared-spec decisions | Establish the reusable rubric and domain routing before editing individual skills. | `bash scripts/ci/skill-governance-audit.sh --check-counts`, `git diff --check` |
| B2 | `pr`, `issue` | Highest provider-mutation risk outside the plan-issue family; repeated PR/MR body, label, and provider-boundary prose. | `agent-runtime render --product codex --update-golden`, `agent-runtime render --product claude --update-golden`, deterministic `pr` and `issue` smoke |
| B3 | `meta` | Repository, runtime-home, archive, release, and retained-record mutations; keep exact dry-run/apply and semantic-commit gates. | deterministic `meta` smoke, project-local smoke, render/golden |
| B4 | `code-review`, `evidence` | Mostly read-only or evidence-record contracts; reduce repeated review/evidence wording without weakening schemas. | deterministic `code-review` and `evidence` smoke, render/golden |
| B5 | `conversation`, `browser`, `media`, `reporting` | Lower mutation risk; prompt/reporting skills need light-touch source and artifact clarity rather than more process. | deterministic domain smoke, render/golden |
| B6 | all | Final integration and close-ready evidence. | `bash scripts/ci/all.sh`, `bash tests/hooks/run.sh` |

## Shared-Spec Candidates

| Domain | Decision | Notes |
| --- | --- | --- |
| `dispatch` | Reuse existing specs | `core/skills/dispatch/plan-issue-spec/` already owns the shared plan-issue family rules. Lane-oriented dispatch references remain domain-local because the handoff and review contracts are materially different from lightweight tracking. |
| `pr` | Added `core/skills/pr/pr-lifecycle/README.md` | Owns branch-kind rule, `## Summary` body requirement, direct provider command boundary, label taxonomy, non-closing issue references, and pre-merge lifecycle gates. |
| `issue` | Added `core/skills/issue/issue-lifecycle/README.md` | Owns label taxonomy use, `label audit|ensure` choice, concise checkpoint comments, no-auto-close discipline, and duplicate/split caution. |
| `meta` | Keep routing in `core/skills/meta/README.md`; no new shared spec yet | Meta skills differ by mutation target. A single generic dry-run/apply spec would risk hiding skill-specific stop conditions. |
| `code-review` | Reuse existing code-review references | Specialist contract and delivery review templates already carry shared schemas. |
| `evidence` | No new shared spec | Evidence skills are short and CLI-owned; repeated structure is useful because each skill is a record envelope. |
| `reporting` | No new shared spec in the first pass | Reporting skills share source-grounding principles but differ by source mix and output shape. Keep source rules inline unless B5 uncovers real duplication. |
| `conversation`, `browser`, `media` | No new shared spec | Short prompt/host-capability skills are clearer with local contracts. |

## Review Outcome

- `pr`: added `core/skills/pr/pr-lifecycle/README.md`; reduced duplicated
  provider auth, branch/body, label, and issue-backed merge prose in all four
  PR/MR skills while keeping local close/delivery gates inline.
- `issue`: added `core/skills/issue/issue-lifecycle/README.md`; reduced
  repeated label/comment/close discipline in issue follow-up, triage, and
  plan-issue finding reporting.
- `dispatch`: reviewed dispatch-plan and lane skills. No new spec was added:
  the lightweight plan-issue family already points at
  `core/skills/dispatch/plan-issue-spec/`, while lane and review skills keep
  distinct handoff and scope-leak stop conditions inline.
- `meta`: kept mutation-specific stop conditions inline. One stale command was
  fixed: `worktree-triage` now recommends `git-cli worktree remove` instead of
  direct `git worktree remove`, including its helper output.
- `code-review` and `evidence`: reviewed as light-touch/no-change. Existing
  references and short record contracts already carry the reusable rules.
- `conversation`, `browser`, `media`, and `reporting`: reviewed as
  light-touch/no-change for this pass. Long prompt/reporting skills keep
  domain-specific source, artifact, and output-shape instructions inline.

## Skill Matrix

Action values:

- `rewrite`: expected source-body changes in the domain batch.
- `light-touch`: inspect and reduce obvious duplication, but preserve current
  shape if already decision-minimal.
- `no-change`: already short or CLI-contract-like; only update if a shared
  reference makes a local sentence obsolete.

| Domain | Skill | Lines | Risk | Action | Shared-spec opportunity | Validation key |
| --- | --- | ---: | --- | --- | --- | --- |
| `browser` | `browser-session` | 55 | repo/fs | no-change | none | V-browser |
| `browser` | `canary-check` | 53 | repo/fs | no-change | none | V-browser |
| `code-review` | `code-review-focused-lens` | 103 | provider/repo | light-touch | existing code-review refs | V-code-review |
| `code-review` | `code-review-follow-up` | 106 | provider/repo | light-touch | existing code-review refs | V-code-review |
| `code-review` | `code-review-pre-merge-gate` | 112 | provider/repo | light-touch | existing code-review refs | V-code-review |
| `code-review` | `code-review-quick-pass` | 100 | provider/repo/external | light-touch | existing code-review refs | V-code-review |
| `code-review` | `code-review-specialists` | 170 | provider/repo/external | rewrite | existing code-review refs | V-code-review |
| `conversation` | `actionable-advice` | 43 | external | no-change | none | V-conversation |
| `conversation` | `actionable-knowledge` | 43 | external | no-change | none | V-conversation |
| `conversation` | `discussion-to-implementation-doc` | 254 | provider/repo/external | rewrite | none | V-conversation |
| `conversation` | `handoff-session-prompt` | 198 | provider/external | rewrite | none | V-conversation |
| `conversation` | `orchestrator-first` | 43 | repo/external | no-change | none | V-conversation |
| `conversation` | `parallel-first` | 45 | repo/external | no-change | none | V-conversation |
| `conversation` | `test-first` | 43 | external | no-change | none | V-conversation |
| `dispatch` | `create-plan-tracking-issue` | 132 | provider/repo/external | no-change | existing plan-issue spec | V-dispatch |
| `dispatch` | `deliver-dispatch-plan` | 155 | provider/repo/external | rewrite | lane/dispatch refs | V-dispatch |
| `dispatch` | `deliver-plan-tracking-issue` | 160 | provider/repo | no-change | existing plan-issue spec | V-dispatch |
| `dispatch` | `dispatch-plan-closeout` | 110 | provider/repo | light-touch | lane/dispatch refs | V-dispatch |
| `dispatch` | `execute-dispatch-lane` | 177 | provider/repo | rewrite | lane/dispatch refs | V-dispatch |
| `dispatch` | `execute-plan-tracking-issue` | 127 | provider/repo/external | no-change | existing plan-issue spec | V-dispatch |
| `dispatch` | `plan-tracking-issue-closeout` | 145 | provider/repo | no-change | existing plan-issue spec | V-dispatch |
| `dispatch` | `review-dispatch-lane-pr` | 131 | provider/repo | rewrite | lane/dispatch refs | V-dispatch |
| `evidence` | `docs-impact` | 52 | provider/repo/external | no-change | none | V-evidence |
| `evidence` | `model-cross-check` | 54 | provider/repo/external | no-change | none | V-evidence |
| `evidence` | `review-evidence` | 61 | provider/repo/external | no-change | none | V-evidence |
| `evidence` | `skill-usage` | 62 | provider/repo | no-change | none | V-evidence |
| `evidence` | `test-first-evidence` | 56 | repo | no-change | none | V-evidence |
| `evidence` | `web-evidence` | 53 | provider/repo/external | no-change | none | V-evidence |
| `issue` | `issue-follow-up` | 208 | provider/repo/external | rewrite | candidate issue lifecycle ref | V-issue |
| `issue` | `issue-triage` | 131 | provider/repo/external | rewrite | candidate issue lifecycle ref | V-issue |
| `issue` | `report-plan-issue-finding` | 198 | provider/repo/external | rewrite | candidate issue lifecycle ref | V-issue |
| `media` | `image-processing` | 57 | repo/external | no-change | none | V-media |
| `media` | `screen-record` | 55 | repo | no-change | none | V-media |
| `meta` | `agent-docs` | 80 | repo | light-touch | meta README | V-meta |
| `meta` | `agent-out` | 54 | repo | no-change | none | V-meta |
| `meta` | `agent-scope-lock` | 54 | repo | no-change | none | V-meta |
| `meta` | `bootstrap` | 68 | repo | no-change | none | V-meta |
| `meta` | `create-project-skill` | 133 | repo/external | rewrite | meta README | V-meta |
| `meta` | `create-skill` | 110 | provider/repo/external | rewrite | meta README | V-meta |
| `meta` | `deploy` | 68 | repo | no-change | none | V-meta |
| `meta` | `heuristic-inbox` | 63 | repo | no-change | heuristic policy | V-meta |
| `meta` | `heuristic-session-closeout` | 220 | provider/repo/external | rewrite | heuristic policy | V-meta |
| `meta` | `nils-cli-bump` | 141 | provider/repo/external | rewrite | meta README | V-meta |
| `meta` | `plan-archive-discover` | 121 | provider/repo/external | light-touch | plan archive commands | V-meta |
| `meta` | `plan-archive-migrate` | 110 | provider/repo/external | light-touch | plan archive commands | V-meta |
| `meta` | `plan-archive-query` | 116 | provider/repo | light-touch | plan archive commands | V-meta |
| `meta` | `pre-pr` | 73 | repo | no-change | none | V-meta |
| `meta` | `release` | 69 | repo | no-change | none | V-meta |
| `meta` | `remove-project-skill` | 113 | repo/external | rewrite | meta README | V-meta |
| `meta` | `remove-skill` | 107 | repo/external | rewrite | meta README | V-meta |
| `meta` | `repo-retro` | 56 | repo/external | no-change | none | V-meta |
| `meta` | `semantic-commit` | 120 | provider/repo | rewrite | git-delivery policy | V-meta |
| `meta` | `setup-project` | 109 | repo | light-touch | meta README | V-meta |
| `meta` | `sync-runtime-surfaces` | 129 | provider/repo/external | rewrite | meta README | V-meta |
| `meta` | `worktree-triage` | 132 | provider/repo/external | rewrite | git-delivery policy | V-meta |
| `pr` | `close-pr` | 113 | provider/repo/external | rewrite | candidate PR/MR lifecycle ref | V-pr |
| `pr` | `create-dispatch-lane-pr` | 115 | provider/repo | rewrite | candidate PR/MR lifecycle ref | V-pr |
| `pr` | `create-pr` | 160 | provider/repo/external | rewrite | candidate PR/MR lifecycle ref | V-pr |
| `pr` | `deliver-pr` | 211 | provider/repo/external | rewrite | candidate PR/MR lifecycle ref | V-pr |
| `reporting` | `daily-brief` | 192 | provider/repo/external | rewrite | none | V-reporting |
| `reporting` | `project-retro` | 158 | provider/repo/external | light-touch | none | V-reporting |
| `reporting` | `topic-radar` | 187 | provider/repo/external | rewrite | none | V-reporting |

## Validation Keys

| Key | Commands |
| --- | --- |
| V-browser | `bash tests/runtime-smoke/run.sh --mode deterministic --domain browser`; render/golden when source changes. |
| V-code-review | `bash tests/runtime-smoke/run.sh --mode deterministic --domain code-review`; render/golden when source changes. |
| V-conversation | `bash tests/runtime-smoke/run.sh --mode deterministic --domain conversation`; render/golden when source changes. |
| V-dispatch | `bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch`; `bash tests/smoke/deliver-lifecycle.sh` dry-run if delivery mechanics change; render/golden when source changes. |
| V-evidence | `bash tests/runtime-smoke/run.sh --mode deterministic --domain evidence`; render/golden when source changes. |
| V-issue | `bash tests/runtime-smoke/run.sh --mode deterministic --domain issue`; render/golden when source changes. |
| V-media | `bash tests/runtime-smoke/run.sh --mode deterministic --domain media`; render/golden when source changes. |
| V-meta | `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`; `bash tests/projects/project-local-smoke/run.sh`; render/golden when source changes. |
| V-pr | `bash tests/runtime-smoke/run.sh --mode deterministic --domain pr`; render/golden when source changes. |
| V-reporting | `bash tests/runtime-smoke/run.sh --mode deterministic --domain reporting`; render/golden when source changes. |
