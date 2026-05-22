# Delivery Specialist Review Gate

Use this shared gate from end-to-end delivery workflows before final PR or MR
merge. The gate gives provider delivery skills one consistent review contract
without making low-level close skills mandatory review orchestrators.

## Ownership

- `deliver-github-pr` and `deliver-gitlab-mr` own this mandatory gate for
  end-to-end delivery.
- `close-github-pr` and `close-gitlab-mr` keep their optional user-requested
  review gate for direct close or merge requests.
- `deliver-plan-tracking-issue` relies on this delivery gate for each PR, then adds
  issue-visible evidence, runtime-finding disposition, lifecycle completion, and
  closeout requirements.
- `review-dispatch-lane-pr` may use `code-review-specialists` before a main-agent
  decision for broad, high-risk, security-sensitive, migration-heavy, or
  API-contract-heavy dispatch PRs.
- `code-review-specialists` remains read-only. It supplies scope detection,
  specialist findings, and reports; it does not fix code, post PR or MR
  comments, mark draft reviewables ready, merge, close issues, or clean
  branches.

## Mandatory Gate

For every end-to-end delivery PR or MR:

1. Resolve reviewable metadata and diff base:
   - GitHub PR: use `forge-cli --provider github pr view <pr>` or the
     equivalent `gh pr view` JSON fields to resolve the PR number, URL, base
     branch, head branch, draft state, check state, and closing issue links.
   - GitLab MR: use `forge-cli --provider gitlab pr view <mr>` or the
     equivalent `glab mr view` output to resolve the MR number, URL, target
     branch, source branch, draft state, and pipeline state.
   - Use the PR base branch or MR target branch as the `code-review-specialists`
     diff base.
2. Run deterministic scope detection with forced minimum lenses:

   ```bash
   review-specialists scope --base "$BASE_REF" --testing --maintainability --format json
   ```

3. Run the selected specialist lenses. The forced minimum means a small diff is
   still reviewed; do not skip only because `diff_lines < 50`.
4. Add risk lenses when the scope warrants them:
   - `--security` for auth, permission, credential-handling, dependency,
     supply-chain, or backend changes over 100 diff lines.
   - `--api-contract` for route, controller, API schema, OpenAPI, GraphQL,
     event, protocol, CLI, or other external contract changes.
   - `--data-migration` for schema, migration, data transform, fixture
     migration, or persistence changes.
   - `--performance` for runtime hot paths, build/runtime loops, query behavior,
     concurrency, rendering, or deployment-time execution.
   - `--red-team` when `diff_lines > 200`, a previous specialist pass found a
     critical issue, or the reviewable changes safety/security-sensitive
     behavior.
5. For doc-only, generated-only, formatting-only, or mechanical metadata
   reviewables, the review may be a short testing/maintainability pass that
   records "no concrete findings" plus why broader lenses were not selected.

## Findings And Repair Loop

- Treat evidence-backed concrete findings as blocking before merge.
- Repair concrete findings on the same delivery branch when they are inside the
  accepted delivery scope.
- After repairs, rerun focused validation, provider checks or pipelines, and the
  affected specialist lenses.
- Repeat review and repair until no concrete unresolved findings remain, or
  stop with an exact blocker and unblock action.
- Do not treat user-authorized review fixes as a successful stopping point; they
  are part of the delivery repair loop.
- Weakly evidenced concerns, accepted tradeoffs, cleanup notes, and residual
  risks must be reported by the owning delivery workflow. Issue-backed delivery
  must also record their issue-visible disposition before closeout.
- The owning delivery workflow must post the final or blocked outcome using
  `references/DELIVERY_REVIEW_OUTCOME_COMMENT.md` before final merge/close.
