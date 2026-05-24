#!/usr/bin/env bash
# Validate repo-owned skill lifecycle invariants without adding another CLI
# implementation layer. The parser is intentionally scoped to this repo's
# manifests and fixture shapes.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODE="repo"

usage() {
  cat <<'USAGE'
Usage: bash scripts/ci/skill-governance-audit.sh [--fixture create|remove]

Checks:
  default          Validate active repo source/manifests/plugins/reminders.
  --fixture create Validate the create-skill fixture completeness.
  --fixture remove Validate the remove-skill dry-run fixture coverage.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --fixture)
      if [ "$#" -lt 2 ]; then
        echo "skill-governance-audit: --fixture requires create|remove" >&2
        exit 2
      fi
      case "$2" in
        create | remove)
          MODE="$2-fixture"
          ;;
        *)
          echo "skill-governance-audit: unsupported fixture: $2" >&2
          exit 2
          ;;
      esac
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "skill-governance-audit: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

python3 - "$MODE" "$REPO_ROOT" <<'PY'
from __future__ import annotations

import json
import re
import sys
from pathlib import Path


MODE = sys.argv[1]
ROOT = Path(sys.argv[2])


def fail(message: str) -> None:
    print(f"skill-governance-audit: {message}", file=sys.stderr)
    raise SystemExit(1)


def read(path: Path) -> str:
    if not path.exists():
        fail(f"missing required file: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def strip_quotes(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
        return value[1:-1]
    return value


def parse_skills(path: Path) -> list[dict[str, object]]:
    entries: list[dict[str, object]] = []
    current: dict[str, object] | None = None
    product: str | None = None
    in_required = False
    for raw in read(path).splitlines():
        line = raw.rstrip()
        if line.startswith("  - id: "):
            if current is not None:
                entries.append(current)
            current = {
                "id": strip_quotes(line.split(": ", 1)[1]),
                "products": {},
                "required_clis": {},
            }
            product = None
            in_required = False
            continue
        if current is None:
            continue
        if line.startswith("    domain: "):
            current["domain"] = strip_quotes(line.split(": ", 1)[1])
            in_required = False
        elif line.startswith("    source: "):
            current["source"] = strip_quotes(line.split(": ", 1)[1])
            in_required = False
        elif line.startswith("    required_clis: {}"):
            current["required_clis"] = {}
            in_required = False
        elif line.startswith("    required_clis:"):
            current["required_clis"] = {}
            in_required = True
        elif in_required and line.startswith("      ") and ": " in line:
            key, value = line.strip().split(": ", 1)
            required = current["required_clis"]
            assert isinstance(required, dict)
            required[key] = strip_quotes(value)
        elif line.startswith("      codex:") or line.startswith("      claude:"):
            product = line.strip().removesuffix(":")
            products = current["products"]
            assert isinstance(products, dict)
            products[product] = {}
            in_required = False
        elif product and line.startswith("        ") and ": " in line:
            key, value = line.strip().split(": ", 1)
            products = current["products"]
            assert isinstance(products, dict)
            product_data = products[product]
            assert isinstance(product_data, dict)
            product_data[key] = strip_quotes(value)
            in_required = False
        elif line and not line.startswith("      "):
            in_required = False
    if current is not None:
        entries.append(current)
    return entries


def parse_plugins(path: Path) -> list[dict[str, object]]:
    entries: list[dict[str, object]] = []
    current: dict[str, object] | None = None
    in_contained = False
    in_product_manifests = False
    for raw in read(path).splitlines():
        line = raw.rstrip()
        if line.startswith("  - id: "):
            if current is not None:
                entries.append(current)
            current = {
                "id": strip_quotes(line.split(": ", 1)[1]),
                "contained_skills": [],
                "product_manifests": {},
            }
            in_contained = False
            in_product_manifests = False
            continue
        if current is None:
            continue
        if line.startswith("    domain: "):
            current["domain"] = strip_quotes(line.split(": ", 1)[1])
            in_contained = False
            in_product_manifests = False
        elif line.startswith("    contained_skills:"):
            in_contained = True
            in_product_manifests = False
        elif line.startswith("    product_manifests:"):
            in_product_manifests = True
            in_contained = False
        elif in_contained and line.startswith("      - "):
            contained = current["contained_skills"]
            assert isinstance(contained, list)
            contained.append(strip_quotes(line.split("- ", 1)[1]))
        elif in_product_manifests and line.startswith("      ") and ": " in line:
            key, value = line.strip().split(": ", 1)
            manifests = current["product_manifests"]
            assert isinstance(manifests, dict)
            manifests[key] = strip_quotes(value)
    if current is not None:
        entries.append(current)
    return entries


def skill_source_ids(root: Path) -> set[str]:
    ids: set[str] = set()
    for path in sorted((root / "core" / "skills").glob("*/*/SKILL.md.tera")):
        skill = path.parent.name
        domain = path.parent.parent.name
        ids.add(f"{domain}.{skill}")
    return ids


def matrix_skill_ids(root: Path) -> set[str]:
    path = root / "tests" / "runtime-smoke" / "acceptance-matrix.yaml"
    return set(re.findall(r"^\s+skill_id:\s+([a-z0-9-]+\.[a-z0-9-]+)\s*$", read(path), re.M))


def sandbox_skill_ids(root: Path, product: str) -> set[str]:
    path = root / "tests" / "sandbox" / product / "expected-skills.txt"
    return {line.strip() for line in read(path).splitlines() if line.strip()}


def codex_link_skill_ids(root: Path) -> set[str]:
    path = root / "targets" / "codex" / "link-map.yaml"
    text = read(path)
    ids: set[str] = set()
    for domain, skill in re.findall(
        r"destination:\s+skills/([a-z0-9-]+)/([a-z0-9-]+)",
        text,
    ):
        ids.add(f"{domain}.{skill}")
    return ids


def validate_repo() -> None:
    skills = parse_skills(ROOT / "manifests" / "skills.yaml")
    plugins = parse_plugins(ROOT / "manifests" / "plugins.yaml")
    by_id = {str(entry["id"]): entry for entry in skills}
    source_ids = skill_source_ids(ROOT)

    if set(by_id) != source_ids:
        missing = sorted(source_ids - set(by_id))
        stale = sorted(set(by_id) - source_ids)
        fail(f"source/manifest mismatch missing={missing} stale={stale}")

    contained_counts: dict[str, int] = {}
    plugin_domains: dict[str, str] = {}
    for plugin in plugins:
        plugin_id = str(plugin["id"])
        plugin_domains[plugin_id] = str(plugin["domain"])
        manifests = plugin["product_manifests"]
        assert isinstance(manifests, dict)
        for product, manifest in manifests.items():
            if not (ROOT / str(manifest)).is_file():
                fail(f"plugin {plugin_id} missing {product} manifest: {manifest}")
        contained = plugin["contained_skills"]
        assert isinstance(contained, list)
        for skill_id in contained:
            contained_counts[str(skill_id)] = contained_counts.get(str(skill_id), 0) + 1

    matrix_ids = matrix_skill_ids(ROOT)
    codex_ids = sandbox_skill_ids(ROOT, "codex")
    claude_ids = sandbox_skill_ids(ROOT, "claude")
    codex_link_ids = codex_link_skill_ids(ROOT)
    semver = re.compile(r"^>=\d+\.\d+\.\d+(?:[-+][A-Za-z0-9._-]+)?$")
    lifecycle_ids = {"meta.create-skill", "meta.remove-skill"}

    for skill_id, entry in sorted(by_id.items()):
        domain, skill = skill_id.split(".", 1)
        if entry.get("domain") != domain:
            fail(f"{skill_id} domain does not match id")
        source = str(entry.get("source", ""))
        expected_source = f"core/skills/{domain}/{skill}"
        if source != expected_source:
            fail(f"{skill_id} source={source!r} expected={expected_source!r}")
        if not (ROOT / source / "SKILL.md.tera").is_file():
            fail(f"{skill_id} missing source SKILL.md.tera")
        if contained_counts.get(skill_id, 0) != 1:
            fail(f"{skill_id} plugin containment count={contained_counts.get(skill_id, 0)}")
        if skill_id not in matrix_ids:
            fail(f"{skill_id} missing runtime-smoke acceptance matrix row")
        if skill_id not in codex_ids:
            fail(f"{skill_id} missing codex sandbox expected skill")
        if skill_id not in claude_ids:
            fail(f"{skill_id} missing claude sandbox expected skill")
        if skill_id not in codex_link_ids:
            fail(f"{skill_id} missing codex local skill link-map entry")

        products = entry["products"]
        assert isinstance(products, dict)
        for product, product_data in products.items():
            assert isinstance(product_data, dict)
            render_to = str(product_data.get("render_to", ""))
            expected_render = f"plugins/{domain}/skills/{skill}/SKILL.md"
            if render_to != expected_render:
                fail(f"{skill_id} {product} render_to={render_to!r} expected={expected_render!r}")

        required = entry["required_clis"]
        assert isinstance(required, dict)
        for cli, floor in required.items():
            if "<TBD" in floor or not semver.match(floor):
                fail(f"{skill_id} required_clis {cli} has invalid floor {floor!r}")

        if skill_id in lifecycle_ids:
            body = read(ROOT / source / "SKILL.md.tera")
            for needle in ("core/skills", "manifests/skills.yaml", "manifests/plugins.yaml", "agent-runtime"):
                if needle not in body:
                    fail(f"{skill_id} missing lifecycle contract phrase: {needle}")

    reminders = json.loads(read(ROOT / "core" / "hooks" / "shared" / "skill-usage-reminder.skills.json"))
    exact = {
        entry.get("skill")
        for entry in reminders
        if entry.get("tier") == "exact-only"
    }
    expected_exact = {"create-skill", "remove-skill"}
    if not expected_exact.issubset(exact):
        fail(f"missing lifecycle exact-only reminder entries: {sorted(expected_exact - exact)}")
    if "create-project-skill" in exact:
        fail("create-project-skill reminder is active but the workflow is deferred")
    if "skill-governance" in exact:
        fail("skill-governance is a repo governance tool, not a user-facing skill")

    print(
        "skill-governance-audit: repo OK "
        f"skills={len(skills)} plugins={len(plugins)} lifecycle={len(lifecycle_ids)}"
    )


def validate_create_fixture() -> None:
    fixture = ROOT / "tests" / "runtime-smoke" / "fixtures" / "skill-lifecycle" / "create-skill"
    expected = [
        "core/skills/fixture/sample-prose/SKILL.md.tera",
        "manifests/skills.yaml",
        "manifests/plugins.yaml",
        "tests/runtime-smoke/acceptance-matrix.yaml",
        "tests/sandbox/codex/expected-skills.txt",
        "tests/sandbox/claude/expected-skills.txt",
    ]
    for rel in expected:
        if not (fixture / rel).is_file():
            fail(f"create fixture missing {rel}")
    skill_id = "fixture.sample-prose"
    if skill_id not in {str(entry["id"]) for entry in parse_skills(fixture / "manifests" / "skills.yaml")}:
        fail("create fixture missing skill manifest entry")
    plugins = parse_plugins(fixture / "manifests" / "plugins.yaml")
    if not any(skill_id in plugin.get("contained_skills", []) for plugin in plugins):
        fail("create fixture missing plugin containment")
    if skill_id not in matrix_skill_ids(fixture):
        fail("create fixture missing acceptance matrix row")
    for product in ("codex", "claude"):
        if skill_id not in sandbox_skill_ids(fixture, product):
            fail(f"create fixture missing {product} sandbox expected skill")
    print("skill-governance-audit: create fixture OK skill=fixture.sample-prose")


def validate_remove_fixture() -> None:
    fixture = ROOT / "tests" / "runtime-smoke" / "fixtures" / "skill-lifecycle" / "remove-skill"
    expected_classes = {
        "source",
        "skills-manifest",
        "plugin-containment",
        "product-render",
        "golden",
        "sandbox",
        "runtime-smoke",
        "reminder",
        "maintained-doc",
        "historical-doc-retained",
    }
    dry_run = read(fixture / "expected-dry-run.txt")
    present = {
        line.split(":", 1)[0].removeprefix("- ").strip()
        for line in dry_run.splitlines()
        if line.startswith("- ")
    }
    missing = sorted(expected_classes - present)
    if missing:
        fail(f"remove fixture missing dry-run classes: {missing}")
    for rel in [
        "core/skills/fixture/removable-skill/SKILL.md.tera",
        "manifests/skills.yaml",
        "manifests/plugins.yaml",
        "targets/codex/plugins/fixture/.codex-plugin/plugin.json",
        "targets/claude/plugins/fixture/.claude-plugin/plugin.json",
        "tests/golden/codex/plugins/fixture/skills/removable-skill/SKILL.md",
        "tests/golden/claude/plugins/fixture/skills/removable-skill/SKILL.md",
        "tests/runtime-smoke/acceptance-matrix.yaml",
        "tests/sandbox/codex/expected-skills.txt",
        "tests/sandbox/claude/expected-skills.txt",
        "core/hooks/shared/skill-usage-reminder.skills.json",
        "docs/source/removable-skill.md",
        "docs/plans/removable-skill-history.md",
    ]:
        if not (fixture / rel).is_file():
            fail(f"remove fixture missing {rel}")
    print("skill-governance-audit: remove fixture OK classes=10 retained_history=true")


if MODE == "repo":
    validate_repo()
elif MODE == "create-fixture":
    validate_create_fixture()
elif MODE == "remove-fixture":
    validate_remove_fixture()
else:
    fail(f"unknown mode: {MODE}")
PY
