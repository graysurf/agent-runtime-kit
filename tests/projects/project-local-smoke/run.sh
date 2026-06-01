#!/usr/bin/env bash
# Project-local overlay smoke gate for retained dispatcher conventions.

set -euo pipefail

FIXTURE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$FIXTURE_ROOT/../../.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/agent-runtime-kit-project-local.XXXXXX")"
OUT_DIR="$TMP_ROOT/out"
RUNTIME_ROOT="$TMP_ROOT/runtime"

cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

mkdir -p "$OUT_DIR" "$RUNTIME_ROOT/live/codex" "$RUNTIME_ROOT/state/codex"

scripts="bootstrap deploy pre-pr release"
project_skill="project-local-skill"

doctor_block_count() {
  local log="$1"
  sed -n '1s/.* block=\([0-9][0-9]*\).*/\1/p' "$log"
}

run_fixture_script() {
  local name="$1"
  local script="$FIXTURE_ROOT/.agents/scripts/${name}.sh"
  local stdout="$OUT_DIR/${name}.stdout"

  if [ ! -x "$script" ]; then
    echo "project-local-smoke: missing executable script: $script" >&2
    return 1
  fi

  (
    cd "$FIXTURE_ROOT"
    PROJECT_LOCAL_SMOKE_OUT="$OUT_DIR" "$script" --runtime-smoke "$name"
  ) >"$stdout" 2>&1
  grep -q "project-local-smoke:${name}:called" "$stdout"
  test -f "$OUT_DIR/${name}.invoked"
}

run_fixture_skill() {
  local name="$1"
  local skill_dir="$FIXTURE_ROOT/.agents/skills/${name}"
  local script="$skill_dir/scripts/${name}.sh"
  local stdout="$OUT_DIR/${name}.stdout"

  if [ ! -f "$skill_dir/SKILL.md" ]; then
    echo "project-local-smoke: missing project skill body: $skill_dir/SKILL.md" >&2
    return 1
  fi
  if [ ! -x "$script" ]; then
    echo "project-local-smoke: missing executable project skill script: $script" >&2
    return 1
  fi

  grep -q "name: ${name}" "$skill_dir/SKILL.md"
  (
    cd "$FIXTURE_ROOT"
    PROJECT_LOCAL_SMOKE_OUT="$OUT_DIR" "$script" --runtime-smoke "$name"
  ) >"$stdout" 2>&1
  grep -q "project-local-smoke:${name}:called" "$stdout"
  test -f "$OUT_DIR/${name}.invoked"
}

install_temp_runtime() {
  agent-runtime render --product codex >"$OUT_DIR/render.log" 2>&1
  agent-runtime install \
    --source-root "$REPO_ROOT" \
    --product codex \
    --live-home "$RUNTIME_ROOT/live/codex" \
    --state-home "$RUNTIME_ROOT/state/codex" \
    --apply >"$OUT_DIR/install.log" 2>&1
}

assert_doctor_wired() {
  local log="$OUT_DIR/doctor.wired.log"
  local code block name

  set +e
  agent-runtime doctor \
    --source-root "$REPO_ROOT" \
    --product codex \
    --live-home "$RUNTIME_ROOT/live/codex" \
    --state-home "$RUNTIME_ROOT/state/codex" \
    --check-project "$FIXTURE_ROOT" >"$log" 2>&1
  code=$?
  set -e

  block="$(doctor_block_count "$log")"
  if [ "$block" != "0" ]; then
    echo "project-local-smoke: doctor reported blocking findings for wired fixture (exit=$code)" >&2
    cat "$log" >&2
    return 1
  fi

  for name in $scripts; do
    grep -q "ok project-overlay status=wired script=${name} " "$log"
  done
}

assert_doctor_missing() {
  local copy_root="$TMP_ROOT/missing-project"
  local log="$OUT_DIR/doctor.missing.log"
  local code block

  mkdir -p "$copy_root"
  cp -R "$FIXTURE_ROOT/." "$copy_root/"
  rm "$copy_root/.agents/scripts/release.sh"

  set +e
  agent-runtime doctor \
    --source-root "$REPO_ROOT" \
    --product codex \
    --live-home "$RUNTIME_ROOT/live/codex" \
    --state-home "$RUNTIME_ROOT/state/codex" \
    --check-project "$copy_root" >"$log" 2>&1
  code=$?
  set -e

  block="$(doctor_block_count "$log")"
  if [ "$block" != "0" ]; then
    echo "project-local-smoke: missing-script doctor probe should be warning-only (exit=$code)" >&2
    cat "$log" >&2
    return 1
  fi
  grep -q 'warn project-overlay status=missing script=release ' "$log"
  grep -q 'project-local script is missing' "$log"
}

assert_setup_project_adoption_gate() {
  local helper="$REPO_ROOT/core/skills/meta/setup-project/scripts/setup-project.sh"
  local unadopted="$TMP_ROOT/setup-unadopted"
  local partial="$TMP_ROOT/setup-partial"
  local apply_root="$TMP_ROOT/setup-apply"
  local out="$OUT_DIR/setup-project.out"
  local code

  test -x "$helper"

  mkdir -p "$unadopted"
  git -C "$unadopted" init -q
  "$helper" --repo "$unadopted" --dry-run >"$out.unadopted" 2>&1
  grep -q "setup-project: adoption=unadopted" "$out.unadopted"
  test ! -e "$unadopted/.agents"

  mkdir -p "$partial/.agents/scripts"
  git -C "$partial" init -q
  set +e
  "$helper" --repo "$partial" --dry-run >"$out.partial" 2>&1
  code=$?
  set -e
  [ "$code" -ne 0 ]
  grep -q "setup-project: adoption=partial" "$out.partial"
  grep -q "setup-project: block adopted repo missing executable .agents/scripts/pre-pr.sh" "$out.partial"

  mkdir -p "$apply_root/scripts/ci"
  git -C "$apply_root" init -q
  cat >"$apply_root/scripts/ci/all.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf 'setup-project fixture validation:%s\n' "$*"
: > setup-project-validation.invoked
SH
  chmod +x "$apply_root/scripts/ci/all.sh"

  "$helper" \
    --repo "$apply_root" \
    --apply \
    --pre-pr-command "bash scripts/ci/all.sh" >"$out.apply" 2>&1
  grep -q "setup-project: wrote .agents/scripts/pre-pr.sh" "$out.apply"
  test -x "$apply_root/.agents/scripts/pre-pr.sh"
  (
    cd "$apply_root"
    ./.agents/scripts/pre-pr.sh --fixture
  ) >"$out.apply-pre-pr" 2>&1
  grep -q "setup-project fixture validation:--fixture" "$out.apply-pre-pr"
  test -f "$apply_root/setup-project-validation.invoked"
}

assert_setup_project_compound_command() {
  local helper="$REPO_ROOT/core/skills/meta/setup-project/scripts/setup-project.sh"
  local root="$TMP_ROOT/setup-compound"
  local out="$OUT_DIR/setup-project-compound"
  local code

  test -x "$helper"

  # A compound --pre-pr-command (&&) must run every stage, not just the first.
  mkdir -p "$root"
  git -C "$root" init -q
  "$helper" \
    --repo "$root" \
    --apply \
    --pre-pr-command "echo stage-one >stage-one.ran && echo stage-two >stage-two.ran" \
    >"$out.apply" 2>&1
  grep -q "setup-project: wrote .agents/scripts/pre-pr.sh" "$out.apply"
  if grep -Eq '^exec ' "$root/.agents/scripts/pre-pr.sh"; then
    echo "project-local-smoke: dispatcher exec-binds the first command of a compound gate" >&2
    cat "$root/.agents/scripts/pre-pr.sh" >&2
    return 1
  fi
  (
    cd "$root"
    ./.agents/scripts/pre-pr.sh
  ) >"$out.run" 2>&1
  test -f "$root/stage-one.ran"
  test -f "$root/stage-two.ran"

  # A failing first stage must abort the gate (no silent green pass) and skip the tail.
  rm -rf "$root"
  mkdir -p "$root"
  git -C "$root" init -q
  "$helper" \
    --repo "$root" \
    --apply \
    --pre-pr-command "false && echo reached >tail.ran" \
    >"$out.apply-fail" 2>&1
  set +e
  (
    cd "$root"
    ./.agents/scripts/pre-pr.sh
  ) >"$out.run-fail" 2>&1
  code=$?
  set -e
  [ "$code" -ne 0 ]
  test ! -e "$root/tail.ran"
}

for script in $scripts; do
  run_fixture_script "$script"
done
run_fixture_skill "$project_skill"

install_temp_runtime
assert_doctor_wired
assert_doctor_missing
assert_setup_project_adoption_gate
assert_setup_project_compound_command

printf 'project-local-smoke: OK scripts=%s skill=%s\n' "$scripts" "$project_skill"
