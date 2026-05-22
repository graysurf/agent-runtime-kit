---
name: issue-follow-up
description:
  Use when the user wants to open or continue a GitHub or GitLab issue as the durable timeline for a discovered problem, investigation, blocker, implementation handoff, or unresolved follow-up loop.
---

# Issue Follow-Up

Issue-centered natural-language entrypoint for turning discovered problems into
provider issue timelines and continuing work through comments, implementation
handoff, PRs/MRs, and closure.

## Contract

Prereqs:

- Run inside the target provider-backed git repository, or pass an explicit
  `--repo` and `--provider` to `forge-cli`.
- `forge-cli` is installed from the released nils-cli package and available on
  `PATH`.
- Existing issue number or URL is known for follow-up mode; otherwise use open
  mode.
- For implementation handoff, the appropriate implementation, PR/MR, or
  dispatch workflow is available.

Inputs:

- New problem report, observation, screenshot/path, source evidence, or user
  instruction to open a tracking issue.
- Existing issue number or URL plus a request to continue, investigate, update,
  unblock, implement, or close.
- Optional desired state: `comment-only`, `blocked`,
  `ready-for-implementation`, `implemented-via-pr`, or `close`.

Outputs:

- New provider issue URL, or a concise follow-up comment posted to the existing
  issue.
- A normalized checkpoint recording what was checked, what changed, the current
  decision, and next action.
- If implementation is appropriate: handoff into the normal implementation or
  PR/MR workflow with issue traceability preserved.
- If unresolved: issue remains open with the blocker or next follow-up action
  recorded.

Failure modes:

- Missing or ambiguous target issue in follow-up mode.
- Provider auth, permission, network, or repository context failure.
- Required evidence cannot be accessed and no safe summary can be recorded.
- User asks to inline a local image but no provider-hosted attachment or URL is
  available.
- Implementation is ready but branch, PR/MR, test, or delivery workflow
  requirements are unclear or blocked.

## Role

Use this skill as the natural-language entrypoint, not as a replacement for
lower-level issue or PR/MR tools.

- Treat `forge-cli issue` as the provider mutation surface, not a separate
  user-facing workflow choice.
- Use `create-plan-tracking-issue` for plan-bundle tracking issue creation.
- Use normal implementation and PR/MR workflows when code/docs changes are
  ready.
- Use `dispatch-pr-review` when PR review decisions or review follow-up must be
  mirrored back to a plan issue.
- Use `tracking-issue-closeout` for lightweight plan-tracking closeout.
- Use `dispatch-issue-closeout` for heavyweight `plan-issue` dispatch runtimes
  with subagent lanes and close gates.

## Modes

### Open Mode

Use when the user discovered a problem and wants a durable issue.

1. Normalize the problem into:
   - summary
   - current behavior
   - expected behavior or desired outcome
   - evidence checked
   - next investigation or implementation path
2. Include screenshots as provider-renderable links when a URL is available.
   If only a local screenshot path is available, include the path plus a short
   visual summary. Do not create unrelated repo artifacts just to host an image
   unless the user asks.
3. Open the issue through `forge-cli`:

   ```bash
   forge-cli issue create \
     --title "$ISSUE_TITLE" \
     --body-file "$ISSUE_BODY" \
     --label issue \
     --format json
   ```

4. Report the issue URL and whether any evidence could not be embedded.

### Follow-Up Mode

Use when an issue already exists and the user asks to continue it.

1. Read the issue body and comments before deciding the next action:

   ```bash
   forge-cli issue view "$ISSUE" --format json
   ```

2. Identify the latest checkpoint, open questions, blockers, linked PRs/MRs, and
   current expected next action.
3. Do the requested investigation or maintenance work.
4. Post one concise issue comment for every meaningful follow-up unless the user
   explicitly asks not to write to the provider:

   ```bash
   forge-cli issue comment "$ISSUE" --body-file "$COMMENT_BODY" --format json
   ```

5. Use this checkpoint shape:

   ```markdown
   ## Follow-up YYYY-MM-DD

   ### Checked
   - ...

   ### Result
   - ...

   ### Decision
   - comment-only | blocked | ready-for-implementation | implemented-via-pr | close

   ### Next
   - ...
   ```

6. Keep unresolved issues open. Close only when the requested outcome is complete
   or the user explicitly chooses not to continue.

## Static HTTP Evidence

- When the follow-up concerns a public or internal HTTP/HTTPS URL and static
  response evidence is enough, use the `web-evidence` skill or:

  ```bash
  web-evidence capture "$URL" --out "$RUN_DIR/web-evidence" --label issue-follow-up --format json
  ```

- Attach, link, or cite only redacted artifacts from the bundle, typically
  `summary.json`, `headers.redacted.json`, and `body-preview.redacted.txt`.
- Use browser-session evidence for JavaScript behavior, screenshots,
  authenticated/cookie-backed state, console logs, or other browser-visible
  behavior. Keep `web-evidence` for static HTTP evidence only.

## Implementation Handoff

Use when follow-up determines the issue is actionable.

1. Record the decision in the issue first or as part of the PR/MR linkage
   comment.
2. Enter the appropriate implementation workflow for the repo and provider.
3. Keep the issue as the durable timeline:
   - link PR/MR URLs
   - summarize tests
   - record blockers
   - mirror review follow-up decisions
   - record merge/close outcome
4. If implementation fails or is blocked, comment on the issue with the exact
   unblock action and leave it open.

## Comment Discipline

- Keep comments concise and evidence-based.
- Do not paste long logs; summarize and link to durable artifacts when
  available.
- Separate facts, inferences, blockers, and next actions when the state is
  uncertain.
- Do not let chat history become the only source of truth once an issue exists.
- Avoid opening replacement issues for the same unresolved problem unless the
  user explicitly wants a split.
