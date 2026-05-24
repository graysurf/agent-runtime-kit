# Execution State: Forge Label Taxonomy

<!-- execute-from-tracking-issue:state:v1 -->
## Execution State

- Status: plan bundle authored; tracking issue creation in progress.
- Target scope: define one GitHub/GitLab label taxonomy, add provider label
  audit/ensure/apply support through `forge-cli`, and update agent workflows so
  issue and PR/MR creation automatically applies the selected labels.
- Current task: create the `agent-runtime-kit` tracking issue from this bundle.
- Next task: open the linked `sympoies/nils-cli` follow-up issue for
  `forge-cli` label implementation.
- Last updated: 2026-05-24
- Branch: feat/forge-label-taxonomy-plan
- Tracking issue: pending
- Linked nils-cli issue: pending
- PR: pending
- Source document: `docs/plans/forge-label-taxonomy/forge-label-taxonomy-plan.md`
- Discussion source: docs/plans/forge-label-taxonomy/forge-label-taxonomy-discussion-source.md
- Trigger: user requested a durable plan for unified GitHub/GitLab labels and
  automatic agent label application on issues, PRs, and MRs.

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | pending | Add the machine-readable label catalog | — | Catalog includes core and optional automation groups. |
| 1.2 | pending | Add human policy and root pointers | — | Keep root files concise; policy owns details. |
| 2.1 | pending | Open linked nils-cli implementation issue | — | Issue must cover `forge-cli label` and `pr deliver --label`. |
| 2.2 | pending | Consume released forge-cli label support | — | Requires a released nils-cli version. |
| 3.1 | pending | Update issue and PR/MR skills | — | Skills choose, ensure, and pass labels. |
| 3.2 | pending | Update plan and dispatch label usage | — | Preserve legacy `plan` compatibility during rollout. |
| 3.3 | pending | Refresh rendered outputs and smoke coverage | — | Golden and runtime smoke coverage prove label arguments. |
| 4.1 | pending | Ensure labels on representative repositories | — | At least agent-runtime-kit and nils-cli. |
| 4.2 | pending | Exercise end-to-end labeled creation | — | Provider records show taxonomy labels. |

## Validation

| Command | Status | Summary |
| --- | --- | --- |
| `AGENT_DOCS_HOME=/Users/terry/Project/graysurf/agent-runtime-kit agent-docs resolve --context startup --strict --format checklist` | passed | Required startup docs present. |
| `AGENT_DOCS_HOME=/Users/terry/Project/graysurf/agent-runtime-kit agent-docs resolve --context project-dev --strict --format checklist` | passed | Required project-dev docs present. |
| `gh label list --repo graysurf/agent-runtime-kit --limit 200 --json name,color,description` | passed | Current repo has legacy `plan` and `issue` labels plus GitHub defaults. |
| `gh label list --repo sympoies/nils-cli --limit 200 --json name,color,description` | passed | nils-cli has legacy `plan`, `issue`, `needs-review`, and default labels. |
| `plan-tooling validate --file docs/plans/forge-label-taxonomy/forge-label-taxonomy-plan.md --format json` | passed | `ok=true`; no plan errors. |
| `plan-issue record open --profile tracking --repo graysurf/agent-runtime-kit --bundle docs/plans/forge-label-taxonomy --format json` | pending | Opens the live tracking issue after commit/push. |
| `forge-cli issue create --provider github --repo sympoies/nils-cli ...` | pending | Opens the linked nils-cli follow-up after the tracking issue URL exists. |

## Closeout Gate

- Close condition: the linked nils-cli issue has delivered and released the
  required `forge-cli` label support; agent-runtime-kit consumes that release;
  labels are ensured in representative GitHub/GitLab repos; and smoke/live
  evidence proves agents apply labels to issue and PR/MR creation.
- Reopen triggers: provider label ensure drifts from GitHub/GitLab behavior,
  `forge-cli pr deliver` fails to preserve labels, agent skills create provider
  records without required labels, or the taxonomy becomes too broad for
  routine issue/PR/MR triage.
