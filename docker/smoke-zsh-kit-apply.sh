#!/usr/bin/env bash
set -euo pipefail

kit_src="${AGENT_KIT_SRC:-/opt/agent-runtime-kit}"
fixture_hook="${kit_src}/docker/fixtures/zsh-kit-setup/bootstrap/zsh-kit-setup.zsh"
work_root="${ZSH_KIT_SMOKE_WORKDIR:-${AGENT_HOME:-${HOME}/.local/state/agent-runtime-kit}/docker-zsh-kit-apply-smoke}"
repo="${work_root}/fixture-repo"
dest="${work_root}/installed-zsh"
output_json="${work_root}/zsh-kit-setup.json"

test -f "${fixture_hook}"
test ! -e "${HOME}/.config/zsh"
test ! -e /opt/private-skills

rm -rf "${work_root}"
mkdir -p "${repo}/bootstrap" "$(dirname "${dest}")"
cp "${fixture_hook}" "${repo}/bootstrap/zsh-kit-setup.zsh"
chmod 0755 "${repo}/bootstrap/zsh-kit-setup.zsh"

git -C "${repo}" init -b main >/dev/null
git -C "${repo}" add bootstrap/zsh-kit-setup.zsh
git -C "${repo}" \
  -c commit.gpgsign=false \
  -c user.name='agent-runtime-kit smoke' \
  -c user.email='agent-runtime-kit-smoke@example.invalid' \
  commit -m 'add zsh-kit fixture setup hook' >/dev/null

zsh-kit setup \
  --repo "${repo}" \
  --dest "${dest}" \
  --apply \
  --features docker \
  --install-tools skip \
  --format json >"${output_json}"

python3 - "${output_json}" "${dest}" <<'PY'
import json
import pathlib
import sys

output_path = pathlib.Path(sys.argv[1])
dest = pathlib.Path(sys.argv[2])
data = json.loads(output_path.read_text())

assert data["schema_version"] == "cli.zsh-kit.setup.v1", data
assert data["ok"] is True, data
payload = data["data"]
assert payload["mode"] == "apply", payload
assert payload["mutation_status"] == "applied", payload
assert payload["features"] == ["docker"], payload
assert payload["install_tools"] == "skip", payload
assert payload["hook_path"].endswith("bootstrap/zsh-kit-setup.zsh"), payload

marker = dest / ".zsh-kit-smoke" / "hook-ran.txt"
result = dest / ".zsh-kit-smoke" / "result.txt"
assert marker.read_text() == "ran\n"
assert result.read_text() == "features=docker\ninstall_tools=skip\n"

print(f"zsh-kit apply smoke ok: dest={dest}")
PY
