# Repro: setup-project dispatcher drops the command after `&&`

Captured 2026-06-02 in sympoies/symphony-board. No secrets — shell only.

## Generated pre-pr.sh (verbatim, before manual fix)

```sh
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$repo_root"
exec pnpm run typecheck && pnpm test "$@"
```

Invocation that produced it:

```sh
setup-project.sh --repo <repo> --apply \
  --pre-pr-command "pnpm run typecheck && pnpm test" \
  --bootstrap-command "pnpm install --frozen-lockfile" \
  --deploy-command "docker compose -f docker/compose.yaml up -d --build"
```

## Why it is wrong

`exec` replaces the shell with `pnpm run typecheck`; `&& pnpm test "$@"` is
unreachable, so the test suite never runs. The gate reports success on
typecheck alone.

## Minimal standalone repro

```sh
setup-project.sh --repo /tmp/r --apply --pre-pr-command "echo first && echo second"
bash /tmp/r/.agents/scripts/pre-pr.sh   # prints only: first
```
