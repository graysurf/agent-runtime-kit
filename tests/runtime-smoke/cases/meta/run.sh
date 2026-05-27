#!/usr/bin/env bash
# Deterministic probes for Plan 06 meta skills.
# shellcheck disable=SC2329

set -euo pipefail

: "${REPO_ROOT:?}"
: "${SCRIPT_DIR:?}"
: "${TMP_ROOT:?}"
: "${ARTIFACTS_DIR:?}"
: "${RESULTS_FILE:?}"

# shellcheck disable=SC1091
# shellcheck source=tests/runtime-smoke/lib/results.sh
. "$SCRIPT_DIR/lib/results.sh"

META_ARTIFACTS_DIR="$ARTIFACTS_DIR/meta"
META_WORKSPACE="$TMP_ROOT/workspaces/meta-basic-repo"
mkdir -p "$META_ARTIFACTS_DIR" "$TMP_ROOT/workspaces"
cp -R "$SCRIPT_DIR/workspaces/basic-repo/." "$META_WORKSPACE"
git -C "$META_WORKSPACE" init -q

require_meta_bin() {
  local bin="$1"
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "runtime-smoke meta: required binary not on PATH: $bin" >&2
    return 1
  fi
}

record_case() {
  local id="$1"
  local note="$2"
  shift 2

  if "$@"; then
    results_add "$id" "shared-cli" "pass" "1" "$note"
    return 0
  fi

  results_add "$id" "shared-cli" "fail" "0" "$note"
  return 1
}

run_agent_docs_probe() {
  local out="$META_ARTIFACTS_DIR/agent-docs.checklist.txt"
  require_meta_bin agent-docs || return 1
  (
    cd "$META_WORKSPACE"
    agent-docs \
      --docs-home "$REPO_ROOT" \
      --project-path "$REPO_ROOT" \
      resolve --context project-dev --strict --format checklist
  ) >"$out" 2>&1
  grep -q 'REQUIRED_DOCS_END .*missing=0' "$out"
}

run_agent_out_probe() {
  local out="$META_ARTIFACTS_DIR/agent-out.json"
  local agent_home="$TMP_ROOT/meta-agent-home"
  local path physical_agent_home physical_path
  require_meta_bin agent-out || return 1
  mkdir -p "$agent_home"
  (
    cd "$META_WORKSPACE"
    AGENT_HOME="$agent_home" agent-out project \
      --repo "$META_WORKSPACE" \
      --topic runtime-smoke-meta \
      --mkdir \
      --format json
  ) >"$out" 2>&1
  grep -q '"ok": true' "$out"
  path="$(sed -n 's/.*"path": "\([^"]*\)".*/\1/p' "$out" | head -1)"
  physical_agent_home="$(cd "$agent_home" && pwd -P)"
  physical_path="$(cd "$path" && pwd -P)"
  case "$physical_path" in
    "$physical_agent_home"/out/*)
      test -d "$path"
      ;;
    *)
      echo "runtime-smoke meta: agent-out path outside temp AGENT_HOME: $path" >&2
      return 1
      ;;
  esac
}

run_agent_scope_lock_probe() {
  local create_out="$META_ARTIFACTS_DIR/agent-scope-lock.create.json"
  local validate_out="$META_ARTIFACTS_DIR/agent-scope-lock.validate.json"
  require_meta_bin agent-scope-lock || return 1
  mkdir -p "$META_WORKSPACE/tests/runtime-smoke"
  printf 'scope-lock fixture\n' >"$META_WORKSPACE/tests/runtime-smoke/scope-lock.txt"
  (
    cd "$META_WORKSPACE"
    agent-scope-lock create \
      --path README.md \
      --path tests/runtime-smoke \
      --owner runtime-smoke \
      --format json
    agent-scope-lock validate --changes all --format json
  ) >"$create_out" 2>&1
  sed -n '/"schema_version": "cli.agent-scope-lock.validate.v1"/,$p' "$create_out" >"$validate_out"
  grep -q '"schema_version": "cli.agent-scope-lock.create.v1"' "$create_out"
  grep -q '"schema_version": "cli.agent-scope-lock.validate.v1"' "$create_out"
  grep -q '"ok": true' "$validate_out"
}

run_heuristic_inbox_probe() {
  local shared_root="$REPO_ROOT/core/policies/heuristic-system"
  local inbox_dir="$shared_root/error-inbox"
  local archived_case="$inbox_dir/archive/2026/deliver-gitlab-mr-skipped-pipeline-and-cleanup"
  local operation_record="$shared_root/operation-records/github-pr-required-check-gating"
  local product out
  require_meta_bin heuristic-inbox || return 1
  test -f "$shared_root/HEURISTIC_SYSTEM.md"
  test -d "$inbox_dir"
  test -d "$archived_case"
  test -d "$operation_record"

  for product in codex claude; do
    out="$META_ARTIFACTS_DIR/heuristic-inbox.${product}.json"
    (
      cd "$META_WORKSPACE"
      export AGENT_RUNTIME_PRODUCT="$product"
      export AGENT_RUNTIME_HEURISTIC_SYSTEM_ROOT="$shared_root"
      heuristic-inbox list \
        --inbox-dir "$AGENT_RUNTIME_HEURISTIC_SYSTEM_ROOT/error-inbox" \
        --include-archived \
        --format json
    ) >"$out" 2>&1
    grep -q '"schema_version": "cli.heuristic-inbox.list.v1"' "$out"
    grep -q '"ok": true' "$out"
    grep -q 'Deliver GitLab MR Skipped Pipeline And Cleanup Gaps' "$out"
  done

  heuristic-inbox verify "$archived_case" --strict --format json \
    >"$META_ARTIFACTS_DIR/heuristic-inbox.archived-case.verify.json"
  grep -q '"ok": true' "$META_ARTIFACTS_DIR/heuristic-inbox.archived-case.verify.json"

  heuristic-inbox verify "$operation_record" --strict --format json \
    >"$META_ARTIFACTS_DIR/heuristic-inbox.operation-record.verify.json"
  grep -q '"ok": true' "$META_ARTIFACTS_DIR/heuristic-inbox.operation-record.verify.json"
}

run_heuristic_session_closeout_probe() {
  local body="$REPO_ROOT/core/skills/meta/heuristic-session-closeout/SKILL.md.tera"
  local shared_root="$REPO_ROOT/core/policies/heuristic-system"
  local out="$META_ARTIFACTS_DIR/heuristic-session-closeout.contract.txt"

  test -f "$body"
  test -d "$shared_root/error-inbox"
  test -d "$shared_root/operation-records"
  grep -q "session's goal has been achieved" "$body"
  grep -q "heuristic-inbox verify" "$body"
  grep -q "semantic-commit" "$body"
  grep -q "push origin main" "$body"
  grep -q "Do not include unrelated staged or unstaged changes" "$body"
  {
    printf 'body=%s\n' "$body"
    printf 'shared_root=%s\n' "$shared_root"
    printf 'verified=session-goal-trigger commit-boundary retained-record-routing\n'
  } >"$out"
}

run_lifecycle_skill_probe() {
  local skill="$1"
  local fixture="$2"
  local out="$META_ARTIFACTS_DIR/${skill}.governance.txt"
  local body="$REPO_ROOT/core/skills/meta/$skill/SKILL.md.tera"

  test -f "$body"
  test -f "$REPO_ROOT/build/codex/plugins/meta/skills/$skill/SKILL.md"
  test -f "$REPO_ROOT/build/claude/plugins/meta/skills/$skill/SKILL.md"
  grep -q 'core/skills' "$body"
  grep -q 'manifests/skills.yaml' "$body"
  grep -q 'manifests/plugins.yaml' "$body"
  grep -q 'agent-runtime' "$body"

  bash "$REPO_ROOT/scripts/ci/skill-governance-audit.sh" --fixture "$fixture" >"$out" 2>&1
  grep -q "skill-governance-audit: ${fixture} fixture OK" "$out"
}

run_create_skill_probe() {
  run_lifecycle_skill_probe create-skill create
}

run_remove_skill_probe() {
  run_lifecycle_skill_probe remove-skill remove
}

run_project_lifecycle_skill_probe() {
  local skill="$1"
  local fixture="$2"
  local out="$META_ARTIFACTS_DIR/${skill}.governance.txt"
  local body="$REPO_ROOT/core/skills/meta/$skill/SKILL.md.tera"

  test -f "$body"
  test -f "$REPO_ROOT/build/codex/plugins/meta/skills/$skill/SKILL.md"
  test -f "$REPO_ROOT/build/claude/plugins/meta/skills/$skill/SKILL.md"
  grep -q '.agents/skills' "$body"
  grep -q 'git rev-parse --show-toplevel' "$body"
  grep -q '.agents/scripts' "$body"

  bash "$REPO_ROOT/scripts/ci/skill-governance-audit.sh" --fixture "$fixture" >"$out" 2>&1
  grep -q "skill-governance-audit: ${fixture} fixture OK" "$out"
}

run_create_project_helper_probe() {
  local helper="$REPO_ROOT/core/skills/meta/create-project-skill/scripts/create-project-skill.sh"
  local default_root="$TMP_ROOT/workspaces/create-project-default"
  local codex_root="$TMP_ROOT/workspaces/create-project-codex"
  local bridge_root="$TMP_ROOT/workspaces/create-project-bridge"
  local bridge_no_name_root="$TMP_ROOT/workspaces/create-project-bridge-no-name"
  local reject_root="$TMP_ROOT/workspaces/create-project-reject"

  test -x "$helper"

  rm -rf "$default_root" "$codex_root" "$bridge_root" "$bridge_no_name_root" "$reject_root"
  mkdir -p "$default_root" "$codex_root" "$bridge_root" "$bridge_no_name_root" "$reject_root"
  git -C "$default_root" init -q
  git -C "$codex_root" init -q
  git -C "$bridge_root" init -q
  git -C "$bridge_no_name_root" init -q
  git -C "$reject_root" init -q

  (
    cd "$default_root"
    "$helper" sample-project-skill \
      --description "Sample project skill." \
      --with-script \
      --with-tests \
      --with-wrapper sample-project-skill \
      >"$META_ARTIFACTS_DIR/create-project-default.txt" 2>&1
  )
  test -f "$default_root/.agents/skills/sample-project-skill/SKILL.md"
  test -x "$default_root/.agents/skills/sample-project-skill/scripts/sample-project-skill.sh"
  test -x "$default_root/.agents/scripts/sample-project-skill.sh"
  test -L "$default_root/.claude/skills"
  test "$(readlink "$default_root/.claude/skills")" = "../.agents/skills"
  grep -q '^\.claude/$' "$default_root/.gitignore"
  test ! -e "$default_root/.agents/scripts/pre-pr.sh"

  (
    cd "$codex_root"
    "$helper" codex-only-skill \
      --description "Codex only skill." \
      --codex-only \
      >"$META_ARTIFACTS_DIR/create-project-codex.txt" 2>&1
  )
  test -f "$codex_root/.agents/skills/codex-only-skill/SKILL.md"
  test ! -e "$codex_root/.claude"

  (
    cd "$bridge_root"
    "$helper" existing-bridge-skill \
      --description "Existing bridge skill." \
      --codex-only \
      --with-script \
      >"$META_ARTIFACTS_DIR/create-project-bridge-create.txt" 2>&1
    "$helper" existing-bridge-skill \
      --bridge-only \
      --with-wrapper existing-bridge-skill \
      >"$META_ARTIFACTS_DIR/create-project-bridge-only.txt" 2>&1
  )
  test -L "$bridge_root/.claude/skills"
  test "$(readlink "$bridge_root/.claude/skills")" = "../.agents/skills"
  test -x "$bridge_root/.agents/scripts/existing-bridge-skill.sh"

  mkdir -p "$bridge_no_name_root/.agents/skills"
  if (cd "$bridge_no_name_root" && "$helper" --bridge-only --with-wrapper missing-name >"$META_ARTIFACTS_DIR/create-project-reject-bridge-wrapper-no-name.txt" 2>&1); then
    return 1
  fi
  test ! -e "$bridge_no_name_root/.claude"

  if (cd "$reject_root" && "$helper" rejected-skill --claude-only >"$META_ARTIFACTS_DIR/create-project-reject-claude-only.txt" 2>&1); then
    return 1
  fi
  if (cd "$reject_root" && "$helper" rejected-skill --target claude >"$META_ARTIFACTS_DIR/create-project-reject-target-claude.txt" 2>&1); then
    return 1
  fi
  if (cd "$reject_root" && "$helper" --link-only >"$META_ARTIFACTS_DIR/create-project-reject-link-only.txt" 2>&1); then
    return 1
  fi
}

run_create_project_skill_probe() {
  run_project_lifecycle_skill_probe create-project-skill create-project
  run_create_project_helper_probe
}

run_remove_project_skill_probe() {
  run_project_lifecycle_skill_probe remove-project-skill remove-project
}

run_repo_retro_probe() {
  local out="$META_ARTIFACTS_DIR/repo-retro.json"
  require_meta_bin repo-retro || return 1
  (
    cd "$META_WORKSPACE"
    repo-retro report \
      --repo "$META_WORKSPACE" \
      --from 2026-05-01 \
      --to 2026-05-02 \
      --format json
  ) >"$out" 2>&1
  grep -q '"schema_version": "cli.repo-retro.report.v1"' "$out"
  grep -q '"ok": true' "$out"
}

run_semantic_commit_probe() {
  local out="$META_ARTIFACTS_DIR/semantic-commit.dry-run.txt"
  local msg="$META_ARTIFACTS_DIR/semantic-commit-message.txt"
  require_meta_bin semantic-commit || return 1
  printf 'semantic fixture\n' >"$META_WORKSPACE/semantic-fixture.txt"
  printf '%s\n' \
    'test(runtime-smoke): validate semantic commit probe' \
    '' \
    '- Adds a staged temp fixture for dry-run validation.' >"$msg"
  (
    cd "$META_WORKSPACE"
    git add semantic-fixture.txt
    semantic-commit commit --repo "$META_WORKSPACE" --message-file "$msg" --dry-run --summary none
    ! git rev-parse --verify HEAD >/dev/null 2>&1
  ) >"$out" 2>&1
}

run_sync_runtime_skills_probe() {
  local out="$META_ARTIFACTS_DIR/sync-runtime-skills.dry-run.txt"

  (
    cd "$REPO_ROOT"
    bash scripts/sync-runtime-skills.sh \
      --source-root "$REPO_ROOT" \
      --product codex \
      --no-pull
  ) >"$out" 2>&1

  grep -q "git pull skipped (--no-pull)" "$out"
  grep -q "skill-governance-audit.sh --check-counts" "$out"
  grep -q "skill-governance-audit: counts OK" "$out"
  grep -q "agent-runtime render" "$out"
  grep -q "agent-runtime install" "$out"
  grep -q "agent-runtime prune-stale" "$out"
  grep -q -- "--dry-run" "$out"
  grep -q "agent-runtime doctor" "$out"
  grep -q "codex debug prompt-input" "$out"
  grep -q "summary: synced skills for codex; mode=dry-run; prune=planned; doctor=planned" "$out"
}

run_sync_runtime_skills_no_prune_probe() {
  local out="$META_ARTIFACTS_DIR/sync-runtime-skills.no-prune.txt"

  (
    cd "$REPO_ROOT"
    bash scripts/sync-runtime-skills.sh \
      --source-root "$REPO_ROOT" \
      --product codex \
      --no-pull \
      --no-prune
  ) >"$out" 2>&1

  grep -q "prune skipped (--no-prune) for product=codex" "$out"
  grep -q "summary: synced skills for codex; mode=dry-run; prune=skipped; doctor=planned" "$out"
  ! grep -q "agent-runtime prune-stale" "$out"
}

run_sync_runtime_skills_worktree_guard_probe() {
  local out="$META_ARTIFACTS_DIR/sync-runtime-skills.worktree-guard.txt"
  local worktree_root="$TMP_ROOT/workspaces/sync-runtime-skills-linked-worktree"
  local status

  rm -rf "$worktree_root"
  git -C "$REPO_ROOT" worktree add --detach "$worktree_root" HEAD >"$out" 2>&1
  set +e
  bash "$REPO_ROOT/scripts/sync-runtime-skills.sh" \
    --source-root "$worktree_root" \
    --apply \
    --product codex \
    --no-pull \
    --no-verify >>"$out" 2>&1
  status=$?
  set -e
  git -C "$REPO_ROOT" worktree remove --force "$worktree_root" >>"$out" 2>&1 || true
  git -C "$REPO_ROOT" worktree prune >>"$out" 2>&1 || true

  [ "$status" -ne 0 ]
  grep -q "refusing live sync from a git worktree" "$out"
  grep -q "durable primary checkout" "$out"
}

run_sync_runtime_skills_prune_fixture_probe() {
  local out="$META_ARTIFACTS_DIR/sync-runtime-skills.prune-fixture.txt"
  local codex_home="$TMP_ROOT/sync-prune/codex-home"
  local claude_home="$TMP_ROOT/sync-prune/claude-home"
  local codex_stale="$codex_home/skills/meta/removed-skill"
  local codex_foreign="$codex_home/skills/meta/foreign-skill"
  local codex_regular="$codex_home/skills/meta/user-note"
  local claude_stale_dir="$claude_home/plugins/meta/skills/removed-skill"
  local claude_foreign="$claude_home/plugins/meta/skills/foreign-skill/SKILL.md"
  local claude_regular="$claude_home/plugins/meta/skills/user-note/SKILL.md"

  require_meta_bin agent-runtime || return 1
  mkdir -p "$codex_home/skills/meta" "$claude_stale_dir/scripts" \
    "$claude_home/plugins/meta/skills/foreign-skill" \
    "$claude_home/plugins/meta/skills/user-note"

  ln -s "$REPO_ROOT/build/codex/plugins/meta/skills/removed-skill" "$codex_stale"
  ln -s /var/empty/foreign-skill "$codex_foreign"
  printf 'user note\n' >"$codex_regular"
  ln -s "$REPO_ROOT/build/claude/plugins/meta/skills/removed-skill/SKILL.md" "$claude_stale_dir/SKILL.md"
  ln -s "$REPO_ROOT/build/claude/plugins/meta/skills/removed-skill/scripts/tool.sh" "$claude_stale_dir/scripts/tool.sh"
  ln -s /var/empty/foreign-skill "$claude_foreign"
  printf 'user note\n' >"$claude_regular"

  {
    agent-runtime prune-stale \
      --source-root "$REPO_ROOT" \
      --product codex \
      --live-home "$codex_home" \
      --apply
    agent-runtime prune-stale \
      --source-root "$REPO_ROOT" \
      --product claude \
      --live-home "$claude_home" \
      --apply
  } >"$out" 2>&1

  grep -q "removed symlink skills/meta/removed-skill" "$out"
  grep -q "removed symlink plugins/meta/skills/removed-skill/SKILL.md" "$out"
  grep -q "removed empty directory plugins/meta/skills/removed-skill" "$out"
  grep -q "skip foreign symlink" "$out"
  grep -q "skip regular file" "$out"
  test ! -L "$codex_stale"
  test -L "$codex_foreign"
  test -f "$codex_regular"
  test ! -d "$claude_stale_dir"
  test -L "$claude_foreign"
  test -f "$claude_regular"
}

run_project_local_shim_probe() {
  local name="$1"
  local script="$REPO_ROOT/tests/projects/project-local-smoke/.agents/scripts/${name}.sh"
  local out_dir="$META_ARTIFACTS_DIR/project-local-shims"
  local stdout="$out_dir/${name}.stdout"

  if [ ! -x "$script" ]; then
    echo "runtime-smoke meta: project-local shim is not executable: $script" >&2
    return 1
  fi

  mkdir -p "$out_dir"
  (
    cd "$REPO_ROOT/tests/projects/project-local-smoke"
    PROJECT_LOCAL_SMOKE_OUT="$out_dir" "$script" --runtime-smoke "$name"
  ) >"$stdout" 2>&1
  grep -q "project-local-smoke:${name}:called" "$stdout"
  test -f "$out_dir/${name}.invoked"
}

run_setup_project_probe() {
  local helper="$REPO_ROOT/core/skills/meta/setup-project/scripts/setup-project.sh"
  local out_dir="$META_ARTIFACTS_DIR/setup-project"
  local unadopted="$TMP_ROOT/workspaces/setup-project-unadopted"
  local partial="$TMP_ROOT/workspaces/setup-project-partial"
  local apply_root="$TMP_ROOT/workspaces/setup-project-apply"
  local status

  test -x "$helper"
  mkdir -p "$out_dir"

  mkdir -p "$unadopted"
  git -C "$unadopted" init -q
  "$helper" --repo "$unadopted" --dry-run >"$out_dir/unadopted.txt" 2>&1
  grep -q "setup-project: adoption=unadopted" "$out_dir/unadopted.txt"
  test ! -e "$unadopted/.agents"

  mkdir -p "$partial/.agents/scripts"
  git -C "$partial" init -q
  set +e
  "$helper" --repo "$partial" --dry-run >"$out_dir/partial.txt" 2>&1
  status=$?
  set -e
  [ "$status" -ne 0 ]
  grep -q "setup-project: adoption=partial" "$out_dir/partial.txt"
  grep -q "setup-project: block adopted repo missing executable .agents/scripts/pre-pr.sh" "$out_dir/partial.txt"

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
    --pre-pr-command "bash scripts/ci/all.sh" >"$out_dir/apply.txt" 2>&1
  grep -q "setup-project: wrote .agents/scripts/pre-pr.sh" "$out_dir/apply.txt"
  test -x "$apply_root/.agents/scripts/pre-pr.sh"
  (
    cd "$apply_root"
    ./.agents/scripts/pre-pr.sh --fixture
  ) >"$out_dir/apply-pre-pr.txt" 2>&1
  grep -q "setup-project fixture validation:--fixture" "$out_dir/apply-pre-pr.txt"
  test -f "$apply_root/setup-project-validation.invoked"
}

run_plan_archive_migrate_probe() {
  local out="$META_ARTIFACTS_DIR/plan-archive-migrate.dry-run.json"
  require_meta_bin plan-archive || return 1
  local root="$META_ARTIFACTS_DIR/plan-archive-migrate"
  local src="$root/source"
  local archive="$root/archive"
  rm -rf "$root"
  mkdir -p "$src" "$archive/config"
  (
    cd "$src"
    git init -q -b main
    git remote add origin git@github.com:graysurf/agent-runtime-kit.git
    mkdir -p docs/plans/2026-05-27-smoke-plan
    printf '# smoke plan\n' >docs/plans/2026-05-27-smoke-plan/PLAN.md
    git add docs/plans
    git -c user.name=smoke -c user.email=smoke@example.com commit -q -m "seed plan"
  )
  printf 'version: 1\nhosts:\n  github.com:\n    class: personal\n    primary_identity: graysurf\n' \
    >"$archive/config/hosts.yaml"
  plan-archive migrate \
    --plan docs/plans/2026-05-27-smoke-plan \
    --source-repo "$src" \
    --archive "$archive" \
    --hosts "$archive/config/hosts.yaml" \
    --issue https://github.com/graysurf/agent-runtime-kit/issues/126 \
    --format json >"$out" 2>&1
  grep -q '"schema_version":"cli.plan-archive.migrate.v1"' "$out"
  grep -q 'plans/github.com/graysurf/agent-runtime-kit/2026-05-27-smoke-plan' "$out"
}

run_plan_archive_query_probe() {
  local out="$META_ARTIFACTS_DIR/plan-archive-query.single.json"
  require_meta_bin plan-archive || return 1
  local archive="$META_ARTIFACTS_DIR/plan-archive-query/archive"
  local dir="$archive/_index/github.com/graysurf/agent-runtime-kit/issues/126"
  rm -rf "$archive"
  mkdir -p "$dir"
  printf '{"title":"smoke"}' >"$dir/20260527T010000Z.json"
  plan-archive query \
    --ref https://github.com/graysurf/agent-runtime-kit/issues/126 \
    --archive "$archive" \
    --format json >"$out" 2>&1
  grep -q '"schema_version":"cli.plan-archive.query.v1"' "$out"
  grep -q '"fetched_at":"2026-05-27T01:00:00Z"' "$out"
}

failures=0
record_case "meta.agent-docs" "project-dev docs resolve passed from fixture workspace" run_agent_docs_probe || failures=1
record_case "meta.agent-out" "agent-out wrote under temp AGENT_HOME" run_agent_out_probe || failures=1
record_case "meta.agent-scope-lock" "scope lock create and validate passed in temp git workspace" run_agent_scope_lock_probe || failures=1
record_case "meta.bootstrap" "project-local bootstrap shim executed fixture script" run_project_local_shim_probe bootstrap || failures=1
record_case "meta.deploy" "project-local deploy shim executed fixture script" run_project_local_shim_probe deploy || failures=1
record_case "meta.heuristic-inbox" "heuristic inbox shared-root list and strict verification passed" run_heuristic_inbox_probe || failures=1
record_case "meta.heuristic-session-closeout" "session closeout contract preserves retained heuristic records on main" run_heuristic_session_closeout_probe || failures=1
record_case "meta.create-skill" "skill lifecycle create surface and governance fixture passed" run_create_skill_probe || failures=1
record_case "meta.create-project-skill" "project skill lifecycle create surface and fixture passed" run_create_project_skill_probe || failures=1
record_case "meta.remove-skill" "skill lifecycle removal surface and governance fixture passed" run_remove_skill_probe || failures=1
record_case "meta.remove-project-skill" "project skill lifecycle removal surface and fixture passed" run_remove_project_skill_probe || failures=1
record_case "meta.pre-pr" "project-local pre-pr shim executed fixture script" run_project_local_shim_probe pre-pr || failures=1
record_case "meta.release" "project-local release shim executed fixture script" run_project_local_shim_probe release || failures=1
record_case "meta.repo-retro" "repo-retro JSON report probe passed against temp git workspace" run_repo_retro_probe || failures=1
record_case "meta.semantic-commit" "semantic-commit dry-run validated staged temp change without commit" run_semantic_commit_probe || failures=1
record_case "meta.setup-project" "setup-project dry-run/apply adoption probes passed" run_setup_project_probe || failures=1
record_case "meta.plan-archive-migrate" "plan-archive migrate dry-run JSON probe resolved archive target" run_plan_archive_migrate_probe || failures=1
record_case "meta.plan-archive-query" "plan-archive query single-ref JSON probe surfaced fetched_at" run_plan_archive_query_probe || failures=1
record_case "meta.sync-runtime-skills" "sync-runtime-skills dry-run planned codex refresh without mutation" run_sync_runtime_skills_probe || failures=1
record_case "meta.sync-runtime-skills" "sync-runtime-skills no-prune flag reports skipped prune" run_sync_runtime_skills_no_prune_probe || failures=1
record_case "meta.sync-runtime-skills" "sync-runtime-skills apply refuses linked git worktree source roots" run_sync_runtime_skills_worktree_guard_probe || failures=1
record_case "meta.sync-runtime-skills" "sync-runtime-skills prune fixture removes stale owned surfaces only" run_sync_runtime_skills_prune_fixture_probe || failures=1

exit "$failures"
