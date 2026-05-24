#!/usr/bin/env bash
set -euo pipefail

out_dir="${PROJECT_SKILL_FIXTURE_OUT:?PROJECT_SKILL_FIXTURE_OUT is required}"
mkdir -p "$out_dir"
printf 'sample-project-skill:called args=%s\n' "$*"
: >"$out_dir/sample-project-skill.invoked"
