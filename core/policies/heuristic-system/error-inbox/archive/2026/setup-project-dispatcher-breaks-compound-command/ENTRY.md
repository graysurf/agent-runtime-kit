# setup-project.sh dispatcher wrapper breaks compound (&&) commands

## Status

- Status: promoted
- First observed: 2026-06-02
- Area: setup-project
- Severity: medium

## Signal

`setup-project --apply --pre-pr-command "pnpm run typecheck && pnpm test"`
generated a `.agents/scripts/pre-pr.sh` whose validation gate silently ran only
the first half. Diagnosed manually while adopting setup-project in
`sympoies/symphony-board`; no skill-usage record was captured.

## Evidence

- Raw record: `evidence/setup-project-repro.2q6eeec4Qh.md` (redacted repro —
  generated `pre-pr.sh` + minimal repro, captured 2026-06-02, shell only).
- Source: `agent-runtime-kit` (HEAD `1bea6dd`),
  `core/skills/meta/setup-project/scripts/setup-project.sh:189-196`.
- `write_dispatcher()` emits each dispatcher via a heredoc whose final line is
  literally `exec $command "$@"`. The command string is interpolated verbatim
  with no shell wrapping.
- For `--pre-pr-command "pnpm run typecheck && pnpm test"` the generated file is:

  ```sh
  exec pnpm run typecheck && pnpm test "$@"
  ```

  `exec` binds only to the first simple command, so it replaces the shell with
  `pnpm run typecheck`; the `&& pnpm test "$@"` tail is never reached. Net: the
  second command never runs (and `"$@"` is mis-attached to `pnpm test`).

- Minimal repro (any operator — `&&`, `||`, `;`, `|` — triggers it):

  ```sh
  setup-project.sh --repo /tmp/r --apply --pre-pr-command "echo first && echo second"
  cat /tmp/r/.agents/scripts/pre-pr.sh    # -> exec echo first && echo second "$@"
  bash /tmp/r/.agents/scripts/pre-pr.sh   # prints only "first"
  ```

## Impact

A pre-pr (or bootstrap/deploy/release) gate built from a compound command
appears green while running only its first command — a silent partial
validation. High blast radius because pre-pr.sh is the finish-line validation
dispatcher consumed by the `meta:pre-pr` skill; a repo can ship believing
"typecheck && test" passed when only typecheck ran.

## Current Workaround

Either of:

1. Pass a single command and chain inside it — add a project target that runs
   the full gate (e.g. a `check` script) and use
   `--pre-pr-command "pnpm run check"`. A single command is `exec`-safe.
2. Hand-edit the generated dispatcher so only the last command is `exec`-ed
   (what symphony-board did):

   ```sh
   pnpm run typecheck
   exec pnpm test "$@"
   ```

## Promotion Criteria

Promote once `write_dispatcher()` stops blindly `exec`-ing a possibly-compound
string. Candidate fix: run the command string through a shell so operators are
interpreted, e.g. emit `exec sh -c '<command> "$@"' sh "$@"` (or drop `exec` and
let `set -e` propagate). Validate with a compound-command case in the
setup-project acceptance coverage. Link the fix PR/commit here when it lands.

## Next Action

None. Fixed in PR #249 (merge 2fc6aff): write_dispatcher now runs the configured command under set -euo pipefail instead of exec, so compound commands run every stage and any failure aborts; compound-command regression coverage added to the project-local and runtime-smoke meta probes.

Lifecycle link: `https://github.com/graysurf/agent-runtime-kit/pull/249`

## Archive

- Archived: 2026-06-02
- Reason: Fixed in PR #249 (merge 2fc6aff): dispatcher runs commands under set -euo pipefail instead of exec; compound-command regression coverage added.
- Durable link: `https://github.com/graysurf/agent-runtime-kit/pull/249`
