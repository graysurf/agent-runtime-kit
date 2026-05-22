#!/usr/bin/env bash
set -euo pipefail

name="$(basename "$0" .sh)"
out_dir="${PROJECT_LOCAL_SMOKE_OUT:?PROJECT_LOCAL_SMOKE_OUT is required}"
mkdir -p "$out_dir"
printf 'project-local-smoke:%s:called args=%s\n' "$name" "$*"
printf '%s\n' "$*" >"$out_dir/${name}.args"
: >"$out_dir/${name}.invoked"
