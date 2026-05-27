# Execution State: Forge Label Taxonomy

<!-- execute-from-tracking-issue:state:v1 -->
## Execution State

- Status: implementation and rollout validation in progress.
- Target scope: define one GitHub/GitLab label taxonomy, add provider label
  audit/ensure/apply support through `forge-cli`, and update agent workflows so
  issue and PR/MR creation automatically applies the selected labels.
- Current task: merge PR #97 and run tracking-issue closeout for issue #91.
- Next task: close issue #91 after merged PR and closeout gate evidence are
  recorded.
- Last updated: 2026-05-24
- Branch: feat/forge-label-taxonomy-plan
- Tracking issue: https://github.com/graysurf/agent-runtime-kit/issues/91
- Linked nils-cli issue: https://github.com/sympoies/nils-cli/issues/473
- nils-cli release: v0.20.1
- PR: https://github.com/graysurf/agent-runtime-kit/pull/97
- Source document: `docs/plans/2026-05-24-forge-label-taxonomy/forge-label-taxonomy-plan.md`
- Discussion source: docs/plans/2026-05-24-forge-label-taxonomy/forge-label-taxonomy-discussion-source.md
- Trigger: user requested a durable plan for unified GitHub/GitLab labels and
  automatic agent label application on issues, PRs, and MRs.

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | done | Add the machine-readable label catalog | `manifests/forge-labels.yaml`; `forge-cli label audit --dry-run` parsed catalog | Catalog includes core and optional automation groups; `size::s` color corrected after GitHub rejected a 7-character hex value. |
| 1.2 | done | Add human policy and root pointers | `core/policies/forge-label-taxonomy.md`; `AGENT_HOME.md`; `AGENTS.md` | Root files link to the canonical policy. |
| 2.1 | done | Open linked nils-cli implementation issue | https://github.com/sympoies/nils-cli/issues/473 | Issue separated CLI provider work from runtime-kit policy work. |
| 2.2 | done | Consume released forge-cli label support | nils-cli `v0.20.1`; PRs sympoies/nils-cli#476 and #477 | `forge-cli 0.20.1` is installed locally and exposes `label list|audit|ensure`, repeatable `--label`, `--label-catalog`, and `--strict-labels`. |
| 3.1 | done | Update issue and PR/MR skills | `core/skills/issue/`; `core/skills/pr/`; rendered golden snapshots | Skills choose, ensure, validate, and pass selected labels. |
| 3.2 | done | Update plan and dispatch label usage | `core/skills/dispatch/`; runtime-smoke dispatch domain | Plan, tracking, and dispatch workflows apply `workflow::*` labels while preserving `plan` compatibility. |
| 3.3 | done | Refresh rendered outputs and smoke coverage | `agent-runtime render --product codex/claude --update-golden`; runtime-smoke issue/pr/dispatch | Golden and smoke coverage prove label arguments reach dry-run plans. |
| 4.1 | done | Ensure labels on representative repositories | `agent-runtime-kit-label-audit.json`; `nils-cli-label-audit.json` | GitHub audits pass for `graysurf/agent-runtime-kit` and `sympoies/nils-cli`; GitLab blocked by `glab auth status` timeout against `gitlab.gamania.com`. |
| 4.2 | done | Exercise end-to-end labeled creation | Scratch issue #96 created/viewed/closed with taxonomy labels; PR #97 opened with taxonomy labels | PR #97 has `type::feature`, `area::provider`, `size::l`, `provider::both`, and `workflow::tracking`. |

## Validation

| Command | Status | Summary |
| --- | --- | --- |
| `AGENT_DOCS_HOME=/Users/terry/.codex/worktrees/574c/agent-runtime-kit agent-docs resolve --context startup --strict --format checklist` | passed | Required startup docs present. |
| `AGENT_DOCS_HOME=/Users/terry/.codex/worktrees/574c/agent-runtime-kit agent-docs resolve --context project-dev --strict --format checklist` | passed | Required project-dev docs present. |
| `AGENT_DOCS_HOME=/Users/terry/.codex/worktrees/574c/agent-runtime-kit agent-docs resolve --context task-tools --strict --format checklist` | passed | Required task-tools docs present before external provider verification. |
| `gh label list --repo graysurf/agent-runtime-kit --limit 200 --json name,color,description` | passed | Current repo has legacy `plan` and `issue` labels plus GitHub defaults. |
| `gh label list --repo sympoies/nils-cli --limit 200 --json name,color,description` | passed | nils-cli has legacy `plan`, `issue`, `needs-review`, and default labels. |
| `plan-tooling validate --file docs/plans/2026-05-24-forge-label-taxonomy/forge-label-taxonomy-plan.md --format json` | passed | `ok=true`; no plan errors. |
| `cargo test -p nils-forge-cli --test integration label_ -- --nocapture` | passed | nils-cli label list/audit/ensure integration coverage passed before release. |
| `cargo test -p nils-forge-cli --test integration pr_deliver_dry_run_threads_labels_into_create_step -- --nocapture` | passed | `pr deliver` carries labels into the create step. |
| `cargo llvm-cov nextest --profile ci --workspace --summary-only --fail-under-lines 85` | passed | nils-cli workspace coverage gate passed at 85.06% line coverage. |
| `forge-cli label audit --catalog manifests/forge-labels.yaml --provider github --repo graysurf/agent-runtime-kit --format json` | passed | GitHub audit status is `pass`; no missing labels or drift. |
| `forge-cli label audit --catalog manifests/forge-labels.yaml --provider github --repo sympoies/nils-cli --format json` | passed | GitHub audit status is `pass`; no missing labels or drift. |
| `glab auth status` | blocked | `gitlab.gamania.com` API call timed out; GitLab target verification deferred. |
| `forge-cli issue create/view/close --provider github --repo graysurf/agent-runtime-kit ...` | passed | Scratch issue #96 was created with `type::test`, `area::provider`, `state::needs-triage`, and `workflow::follow-up`, verified, then closed. |
| `forge-cli issue edit/view 91 --provider github --repo graysurf/agent-runtime-kit ...` | passed | Tracking issue #91 now has `plan`, `type::feature`, `area::provider`, `state::ready`, `workflow::plan`, and `workflow::tracking`. |
| `forge-cli pr deliver --provider github --repo graysurf/agent-runtime-kit --label ... --no-merge --format json` | passed | Created draft PR #97 with selected taxonomy labels and completed the required-check wait step. |
| `forge-cli pr view 97 --provider github --repo graysurf/agent-runtime-kit --format json` | passed | PR #97 labels are `type::feature`, `area::provider`, `size::l`, `provider::both`, and `workflow::tracking`. |
| `gh pr checks 97 --repo graysurf/agent-runtime-kit --watch --interval 10` | passed | GitHub Actions `scripts/ci/all.sh` completed successfully for PR #97. |
| `review-specialists scope --repo . --base origin/main --testing --maintainability --red-team --format json` | passed | Forced testing, maintainability, and red-team lenses; red-team was required because diff size exceeded 200 lines. |
| `review-evidence verify --out .../review-evidence-pr-97 --format json` | passed | Delivery review evidence bundle is complete. |
| `forge-cli pr comment 97 --provider github --repo graysurf/agent-runtime-kit --body-file .../delivery-review-outcome-pr-97.md --format json` | passed | Posted the delivery review outcome comment before merge. |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain issue` | passed | Issue create dry-run includes selected taxonomy labels. |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain pr` | passed | GitHub/GitLab create and deliver dry-runs include selected taxonomy labels under strict catalog validation. |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch` | passed | Dispatch lane PR dry-runs include selected taxonomy labels under strict catalog validation. |

## Closeout Gate

- Close condition: the linked nils-cli issue has delivered and released the
  required `forge-cli` label support; agent-runtime-kit consumes that release;
  labels are ensured in representative GitHub/GitLab repos; and smoke/live
  evidence proves agents apply labels to issue and PR/MR creation.
- Reopen triggers: provider label ensure drifts from GitHub/GitLab behavior,
  `forge-cli pr deliver` fails to preserve labels, agent skills create provider
  records without required labels, or the taxonomy becomes too broad for
  routine issue/PR/MR triage.
