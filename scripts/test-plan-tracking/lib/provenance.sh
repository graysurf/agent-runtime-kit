#!/usr/bin/env bash
# Provenance + CLI-floor helpers for the plan-tracking skill flow test driver
# (finding #19). Sourced by lib/common.sh, so every phase entrypoint gets
# these helpers. This file only defines variables and functions; the floor
# assertion and the provenance stamp are *called* explicitly from setup.sh.
#
# Why this exists:
#   - The driver runs against whichever plan-issue / plan-tooling build is on
#     PATH and against whatever agent-runtime-kit checkout it lives in, but it
#     recorded neither. A finding filed from a run therefore inherited only an
#     ambiguous, hand-typed version number and could not be re-verified against
#     the exact upstream state. (See #18 for the CLI-side build-SHA gap; this
#     stamp uses best-available provenance — checkout SHAs + brew formula
#     version — and improves automatically once #18 lands.)
#   - The skills declare a CLI version floor in prose, but nothing asserted it,
#     so an out-of-floor environment failed late and confusingly instead of at
#     a precondition gate.

# agent-runtime-kit checkout root (two levels up from scripts/test-plan-tracking).
KIT_ROOT="${KIT_ROOT:-$(cd "${DRIVER_ROOT}/../.." && pwd)}"

# The source skills the driver exercises. Each carries a `- CLI floors:` line
# in its Contract; the floor we enforce is derived from these, never hardcoded.
SKILL_FLOOR_GLOB="${KIT_ROOT}/core/skills/dispatch/*plan-tracking-issue*/SKILL.md.tera"

# version_ge A B -> exit 0 when semver-core A >= B. Build metadata (+...) and
# pre-release (-...) suffixes are stripped; comparison is dotted-numeric.
version_ge() {
  local a="${1%%[-+]*}" b="${2%%[-+]*}"
  local IFS=.
  # shellcheck disable=SC2206  # intentional split on dots into version parts.
  local -a av=(${a}) bv=(${b})
  local i max="${#av[@]}"
  [ "${#bv[@]}" -gt "${max}" ] && max="${#bv[@]}"
  for ((i = 0; i < max; i++)); do
    local ai="${av[i]:-0}" bi="${bv[i]:-0}"
    ai="${ai//[!0-9]/}"
    bi="${bi//[!0-9]/}"
    if ((10#${ai:-0} > 10#${bi:-0})); then return 0; fi
    if ((10#${ai:-0} < 10#${bi:-0})); then return 1; fi
  done
  return 0
}

# cli_version BIN -> the version token of `BIN --version`
# (e.g. `plan-issue --version` => `plan-issue 0.27.0 (v0.27.0, rustc ...)`
# => `0.27.0`). version_ge strips any `+build` / `-pre` suffix on compare, so
# this stays correct if #18 makes the field `0.27.0+g<sha>`.
cli_version() {
  "$1" --version 2>/dev/null | awk 'NR==1 {print $2}'
}

# skill_declared_floor CLI -> the highest `CLI >=X.Y.Z` floor any source skill
# declares (CLI is `plan-issue` or `plan-tooling`).
skill_declared_floor() {
  local cli="$1" max="0.0.0" v
  # shellcheck disable=SC2086  # SKILL_FLOOR_GLOB must word-split into paths.
  while IFS= read -r v; do
    [ -z "${v}" ] && continue
    if ! version_ge "${max}" "${v}"; then max="${v}"; fi
  done < <(grep -hoE "${cli} >=[0-9]+\.[0-9]+\.[0-9]+" ${SKILL_FLOOR_GLOB} 2>/dev/null |
    sed -E 's/.*>=//')
  printf '%s\n' "${max}"
}

# cli_source BIN -> human-readable install provenance:
#   `brew release (formula <ver>)` | `local checkout <dir> (<sha>[+dirty])`
#   | `unknown (<path>)` | `not-found`
cli_source() {
  local path real dir brew_prefix
  path="$(command -v "$1" 2>/dev/null)" || true
  if [ -z "${path}" ]; then
    printf 'not-found\n'
    return
  fi
  if command -v realpath >/dev/null 2>&1; then
    real="$(realpath "${path}" 2>/dev/null || printf '%s' "${path}")"
  else
    real="$(readlink -f "${path}" 2>/dev/null || printf '%s' "${path}")"
  fi
  brew_prefix="$(brew --prefix 2>/dev/null || true)"
  if [ -n "${brew_prefix}" ] && [ "${real#"${brew_prefix}"/}" != "${real}" ]; then
    local cellar_ver
    cellar_ver="$(printf '%s' "${real}" | sed -nE 's#.*/Cellar/[^/]+/([^/]+)/.*#\1#p')"
    printf 'brew release%s\n' "${cellar_ver:+ (formula ${cellar_ver})}"
    return
  fi
  dir="$(dirname "${real}")"
  while [ -n "${dir}" ] && [ "${dir}" != "/" ]; do
    if [ -e "${dir}/.git" ]; then
      local sha dirty=""
      sha="$(git -C "${dir}" rev-parse --short HEAD 2>/dev/null || echo unknown)"
      [ -n "$(git -C "${dir}" status --porcelain 2>/dev/null)" ] && dirty="+dirty"
      printf 'local checkout %s (%s%s)\n' "${dir}" "${sha}" "${dirty}"
      return
    fi
    dir="$(dirname "${dir}")"
  done
  printf 'unknown (%s)\n' "${real}"
}

# assert_cli_floor BIN NAME -> die when `BIN --version` is below the floor the
# source skills declare for NAME. Fails fast at a precondition gate.
assert_cli_floor() {
  local bin="$1" name="$2" floor version
  floor="$(skill_declared_floor "${name}")"
  version="$(cli_version "${bin}")"
  if [ -z "${version}" ]; then
    die "could not read '${bin} --version' to check the >=${floor} floor"
  fi
  if version_ge "${version}" "${floor}"; then
    log "floor OK: ${name} ${version} >= ${floor} (skill-declared)"
  else
    die "${name} ${version} is below the skill-declared floor >=${floor}. Upgrade: brew upgrade sympoies/tap/nils-cli"
  fi
}

# kit_provenance -> `<short-sha>[+dirty]` for the agent-runtime-kit checkout
# (the skills carry no semver; their checkout SHA is their only identity).
kit_provenance() {
  local sha dirty=""
  sha="$(git -C "${KIT_ROOT}" rev-parse --short HEAD 2>/dev/null || echo unknown)"
  [ -n "$(git -C "${KIT_ROOT}" status --porcelain 2>/dev/null)" ] && dirty="+dirty"
  printf '%s%s\n' "${sha}" "${dirty}"
}

# stamp_provenance FIXTURE -> write .state/provenance.{md,env} and echo the
# markdown block. Surfaced so a finding filed from this run can embed it.
stamp_provenance() {
  local fixture="${1:-}"
  local now kit pi_v pt_v fc_v pi_src pt_src fc_src pi_floor pt_floor md env
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  kit="$(kit_provenance)"
  pi_v="$(cli_version plan-issue)"
  pt_v="$(cli_version plan-tooling)"
  fc_v="$(cli_version forge-cli)"
  pi_src="$(cli_source plan-issue)"
  pt_src="$(cli_source plan-tooling)"
  fc_src="$(cli_source forge-cli)"
  pi_floor="$(skill_declared_floor plan-issue)"
  pt_floor="$(skill_declared_floor plan-tooling)"
  md="${STATE_DIR}/provenance.md"
  env="${STATE_DIR}/provenance.env"

  cat >"${md}" <<EOF
## Provenance

- Run: fixture \`${fixture}\` at ${now}
- agent-runtime-kit: \`${kit}\` (checkout SHA — skills carry no semver)
- plan-issue: \`${pi_v}\` — ${pi_src}
- plan-tooling: \`${pt_v}\` — ${pt_src}
- forge-cli: \`${fc_v}\` — ${fc_src}
- Declared skill floors: \`plan-issue >=${pi_floor}\`, \`plan-tooling >=${pt_floor}\`
EOF

  {
    printf '# generated by stamp_provenance — do not edit by hand\n'
    printf "PROV_RUN_AT='%s'\n" "${now}"
    printf "PROV_FIXTURE='%s'\n" "${fixture}"
    printf "PROV_KIT_SHA='%s'\n" "${kit}"
    printf "PROV_PLAN_ISSUE_VERSION='%s'\n" "${pi_v}"
    printf "PROV_PLAN_ISSUE_SOURCE='%s'\n" "${pi_src}"
    printf "PROV_PLAN_TOOLING_VERSION='%s'\n" "${pt_v}"
    printf "PROV_PLAN_TOOLING_SOURCE='%s'\n" "${pt_src}"
    printf "PROV_FORGE_CLI_VERSION='%s'\n" "${fc_v}"
    printf "PROV_FORGE_CLI_SOURCE='%s'\n" "${fc_src}"
    printf "PROV_PLAN_ISSUE_FLOOR='%s'\n" "${pi_floor}"
    printf "PROV_PLAN_TOOLING_FLOOR='%s'\n" "${pt_floor}"
  } >"${env}"

  log "provenance stamped -> ${md}"
  cat "${md}" >&2
}
