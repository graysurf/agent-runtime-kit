#!/usr/bin/env bash
# Validate repo-owned skill lifecycle invariants without adding another CLI
# implementation layer. The parser is intentionally scoped to this repo's
# manifests and fixture shapes.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODE="repo"
SHAPE_PATHS=()

usage() {
  cat <<'USAGE'
Usage: bash scripts/ci/skill-governance-audit.sh [--check-counts|--update-counts] [--fixture create|remove|create-project|remove-project|count-refresh] [--shape-only [paths...]]

Checks:
  default                   Validate active repo source/manifests/plugins/reminders/counts.
  --check-counts            Check maintained active skill-count references only.
  --update-counts           Refresh maintained active skill-count references.
  --fixture create          Validate the create-skill fixture completeness.
  --fixture remove          Validate the remove-skill dry-run fixture coverage.
  --fixture create-project  Validate the create-project-skill fixture completeness.
  --fixture remove-project  Validate the remove-project-skill dry-run fixture coverage.
  --fixture count-refresh   Validate stale count detection and whitelist updates.
  --shape-only [paths...]   Lint H2 section shape on the given SKILL.md.tera paths
                            (fast pre-commit gate; consumes all remaining args).
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --check-counts)
      MODE="count-check"
      shift
      ;;
    --update-counts)
      MODE="count-update"
      shift
      ;;
    --fixture)
      if [ "$#" -lt 2 ]; then
        echo "skill-governance-audit: --fixture requires create|remove|create-project|remove-project|count-refresh" >&2
        exit 2
      fi
      case "$2" in
        create | remove | create-project | remove-project)
          MODE="$2-fixture"
          ;;
        count-refresh)
          MODE="count-refresh-fixture"
          ;;
        *)
          echo "skill-governance-audit: unsupported fixture: $2" >&2
          exit 2
          ;;
      esac
      shift 2
      ;;
    --shape-only)
      MODE="shape-only"
      shift
      while [ "$#" -gt 0 ]; do
        SHAPE_PATHS+=("$1")
        shift
      done
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

python3 - "$MODE" "$REPO_ROOT" ${SHAPE_PATHS[@]+"${SHAPE_PATHS[@]}"} <<'PY'
from __future__ import annotations

import json
import os
import re
import shutil
import sys
import tempfile
from pathlib import Path


MODE = sys.argv[1]
ROOT = Path(sys.argv[2])
SHAPE_ARG_PATHS = sys.argv[3:]


CANONICAL_SECTIONS = ("Contract", "Entrypoint", "Workflow", "Boundary")


COUNT_TARGETS = [
    {
        "path": "docs/source/harness-shape-codex.md",
        "label": "Codex local skill root declaration",
        "pattern": r"(?P<prefix>; )(?P<count>\d+)(?P<suffix> Codex skill\s+entries are declared)",
    },
    {
        "path": "docs/source/harness-shape-codex.md",
        "label": "Codex sandbox expected skill range",
        "pattern": r"(?P<prefix>tests/sandbox/codex/expected-skills\.txt:1-)(?P<count>\d+)(?P<suffix>)",
    },
    {
        "path": "tests/runtime-smoke/expected/install-summary.json",
        "label": "Codex install expected skill count",
        "pattern": r"(?P<prefix>\"id\":\"install\.codex\"[^}\n]*\"skill_count\":)(?P<count>\d+)(?P<suffix>)",
    },
    {
        "path": "tests/runtime-smoke/expected/install-summary.json",
        "label": "Claude install expected skill count",
        "pattern": r"(?P<prefix>\"id\":\"install\.claude\"[^}\n]*\"skill_count\":)(?P<count>\d+)(?P<suffix>)",
    },
    {
        "path": "tests/runtime-smoke/product/expected/product-summary.json",
        "label": "Codex product install expected skill count",
        "pattern": r"(?P<prefix>\"id\":\"product\.codex\.install\"[^}\n]*\"skill_count\":)(?P<count>\d+)(?P<suffix>)",
    },
    {
        "path": "tests/runtime-smoke/product/expected/product-summary.json",
        "label": "Claude product install expected skill count",
        "pattern": r"(?P<prefix>\"id\":\"product\.claude\.install\"[^}\n]*\"skill_count\":)(?P<count>\d+)(?P<suffix>)",
    },
]


def fail(message: str) -> None:
    print(f"skill-governance-audit: {message}", file=sys.stderr)
    raise SystemExit(1)


def read(path: Path) -> str:
    if not path.exists():
        try:
            rel = path.relative_to(ROOT)
        except ValueError:
            rel = path
        fail(f"missing required file: {rel}")
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


def active_skill_count(root: Path) -> int:
    return len(parse_skills(root / "manifests" / "skills.yaml"))


def apply_count_targets(root: Path, update: bool) -> tuple[int, list[str]]:
    count = active_skill_count(root)
    changes: list[str] = []

    for target in COUNT_TARGETS:
        rel = Path(str(target["path"]))
        if rel.parts[:2] == ("docs", "plans"):
            fail(f"count target is outside maintained whitelist: {rel}")

        path = root / rel
        text = read(path)
        pattern = re.compile(str(target["pattern"]))
        matches = list(pattern.finditer(text))
        label = str(target["label"])
        if len(matches) != 1:
            fail(
                f"count target pattern must match exactly once: "
                f"{rel} label={label!r} matches={len(matches)}"
            )

        match = matches[0]
        old = match.group("count")
        updated = pattern.sub(
            lambda item: f"{item.group('prefix')}{count}{item.group('suffix')}",
            text,
            count=1,
        )
        if updated != text:
            changes.append(f"{rel}: {label} {old}->{count}")
            if update:
                path.write_text(updated, encoding="utf-8")

    return count, changes


def validate_counts(root: Path) -> int:
    count, changes = apply_count_targets(root, update=False)
    if changes:
        fail("active skill count drift: " + "; ".join(changes))
    return count


def update_counts(root: Path) -> None:
    count, changes = apply_count_targets(root, update=True)
    if changes:
        print(
            "skill-governance-audit: counts updated "
            f"skills={count} targets={len(COUNT_TARGETS)}"
        )
    else:
        print(
            "skill-governance-audit: counts OK "
            f"skills={count} targets={len(COUNT_TARGETS)}"
        )


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


def parse_h2_sections(text: str) -> list[str]:
    headings: list[str] = []
    in_code_fence = False
    for raw in text.splitlines():
        line = raw.rstrip()
        if line.startswith("```"):
            in_code_fence = not in_code_fence
            continue
        if in_code_fence:
            continue
        if line.startswith("## "):
            headings.append(line[3:].strip())
    return headings


def audit_skill_body_shape(skill_id: str, source: str) -> None:
    path = ROOT / source / "SKILL.md.tera"
    text = read(path)
    headings = parse_h2_sections(text)
    if not headings:
        fail(f"{skill_id} missing any H2 section in {source}/SKILL.md.tera")
    if headings[0] != "Contract":
        fail(
            f"{skill_id} first H2 must be `## Contract`, found `## {headings[0]}` "
            f"(see core/skills/meta/create-skill for the standard skill shape)"
        )
    last_canonical_index = -1
    last_canonical_name = "Contract"
    for heading in headings:
        if heading in CANONICAL_SECTIONS:
            position = CANONICAL_SECTIONS.index(heading)
            if position <= last_canonical_index:
                fail(
                    f"{skill_id} canonical H2 order must be "
                    f"Contract -> Entrypoint -> Workflow -> Boundary; "
                    f"found `## {heading}` after `## {last_canonical_name}`"
                )
            last_canonical_index = position
            last_canonical_name = heading


def shape_skill_id_from_path(path: Path) -> tuple[str, str] | None:
    try:
        rel = path.resolve().relative_to(ROOT)
    except ValueError:
        return None
    parts = rel.parts
    if (
        len(parts) < 5
        or parts[0] != "core"
        or parts[1] != "skills"
        or parts[-1] != "SKILL.md.tera"
    ):
        return None
    domain = parts[2]
    skill = "/".join(parts[3:-1])
    return f"{domain}.{skill}", f"core/skills/{domain}/{skill}"


def validate_shape_only(raw_paths: list[str]) -> None:
    if not raw_paths:
        print("skill-governance-audit: shape OK files_checked=0")
        return
    checked = 0
    for raw in raw_paths:
        path = Path(raw)
        if not path.is_absolute():
            path = (ROOT / path).resolve()
        if not path.is_file():
            # Files removed in this commit are not lintable; skip silently.
            continue
        ids = shape_skill_id_from_path(path)
        if ids is None:
            continue
        skill_id, source = ids
        audit_skill_body_shape(skill_id, source)
        checked += 1
    print(f"skill-governance-audit: shape OK files_checked={checked}")


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
    lifecycle_ids = {
        "meta.create-skill",
        "meta.create-project-skill",
        "meta.remove-skill",
        "meta.remove-project-skill",
    }
    repo_lifecycle_ids = {"meta.create-skill", "meta.remove-skill"}
    project_lifecycle_ids = {
        "meta.create-project-skill",
        "meta.remove-project-skill",
    }

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
        audit_skill_body_shape(skill_id, source)
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

        if skill_id in repo_lifecycle_ids:
            body = read(ROOT / source / "SKILL.md.tera")
            for needle in ("core/skills", "manifests/skills.yaml", "manifests/plugins.yaml", "agent-runtime"):
                if needle not in body:
                    fail(f"{skill_id} missing lifecycle contract phrase: {needle}")
        if skill_id in project_lifecycle_ids:
            body = read(ROOT / source / "SKILL.md.tera")
            for needle in (".agents/skills", ".agents/scripts", "git rev-parse --show-toplevel"):
                if needle not in body:
                    fail(f"{skill_id} missing project lifecycle contract phrase: {needle}")

    reminders = json.loads(read(ROOT / "core" / "hooks" / "shared" / "skill-usage-reminder.skills.json"))
    exact = {
        entry.get("skill")
        for entry in reminders
        if entry.get("tier") == "exact-only"
    }
    expected_exact = {
        "create-skill",
        "create-project-skill",
        "remove-skill",
        "remove-project-skill",
    }
    if not expected_exact.issubset(exact):
        fail(f"missing lifecycle exact-only reminder entries: {sorted(expected_exact - exact)}")
    if "skill-governance" in exact:
        fail("skill-governance is a repo governance tool, not a user-facing skill")

    count = validate_counts(ROOT)
    print(
        "skill-governance-audit: repo OK "
        f"skills={len(skills)} plugins={len(plugins)} lifecycle={len(lifecycle_ids)} "
        f"count_targets={len(COUNT_TARGETS)} active_count={count}"
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


def validate_create_project_fixture() -> None:
    fixture = ROOT / "tests" / "runtime-smoke" / "fixtures" / "skill-lifecycle" / "create-project-skill"
    helper = ROOT / "core" / "skills" / "meta" / "create-project-skill" / "scripts" / "create-project-skill.sh"
    if not helper.is_file() or not os.access(helper, os.X_OK):
        fail("create-project helper missing or not executable")
    expected = [
        ".agents/skills/sample-project-skill/SKILL.md",
        ".agents/skills/sample-project-skill/scripts/sample-project-skill.sh",
        ".agents/scripts/sample-project-skill.sh",
        ".claude/skills",
        ".gitignore",
        "expected-created-paths.txt",
    ]
    for rel in expected:
        path = fixture / rel
        if rel == ".claude/skills":
            if not path.is_symlink() or os.readlink(path) != "../.agents/skills":
                fail("create-project fixture missing .claude/skills bridge")
        elif not path.is_file():
            fail(f"create-project fixture missing {rel}")
    body = read(fixture / ".agents" / "skills" / "sample-project-skill" / "SKILL.md")
    for needle in ("name: sample-project-skill", "## Contract", "## Workflow"):
        if needle not in body:
            fail(f"create-project fixture SKILL.md missing {needle!r}")
    created = {
        line.strip()
        for line in read(fixture / "expected-created-paths.txt").splitlines()
        if line.strip()
    }
    for rel in expected[:-1]:
        if rel not in created:
            fail(f"create-project fixture expected-created-paths missing {rel}")
    if ".agents/scripts/pre-pr.sh" in created or (fixture / ".agents" / "scripts" / "pre-pr.sh").exists():
        fail("create-project fixture must not create pre-pr by default")
    print("skill-governance-audit: create-project fixture OK skill=sample-project-skill")


def validate_remove_project_fixture() -> None:
    fixture = ROOT / "tests" / "runtime-smoke" / "fixtures" / "skill-lifecycle" / "remove-project-skill"
    expected_classes = {
        "project-skill-source",
        "skill-owned-script",
        "project-command-wrapper",
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
        fail(f"remove-project fixture missing dry-run classes: {missing}")
    for rel in [
        ".agents/skills/removable-project-skill/SKILL.md",
        ".agents/skills/removable-project-skill/scripts/removable-project-skill.sh",
        ".agents/scripts/removable-project-skill.sh",
        "docs/source/removable-project-skill.md",
        "docs/plans/removable-project-skill-history.md",
    ]:
        if not (fixture / rel).is_file():
            fail(f"remove-project fixture missing {rel}")
    print("skill-governance-audit: remove-project fixture OK classes=5 retained_history=true")


def validate_count_refresh_fixture() -> None:
    fixture = ROOT / "tests" / "runtime-smoke" / "fixtures" / "skill-lifecycle" / "count-refresh"
    expected_root = fixture / "expected"
    history_rel = Path("docs/plans/stale-skill-count-history.md")

    with tempfile.TemporaryDirectory(prefix="skill-count-refresh-") as tmp:
        work_root = Path(tmp) / "fixture"
        shutil.copytree(fixture, work_root)

        history_before = read(work_root / history_rel)
        _, drift = apply_count_targets(work_root, update=False)
        if not drift:
            fail("count-refresh fixture did not start with stale maintained counts")

        apply_count_targets(work_root, update=True)
        _, remaining = apply_count_targets(work_root, update=False)
        if remaining:
            fail("count-refresh fixture still has drift after update: " + "; ".join(remaining))

        for rel in [
            Path("docs/source/harness-shape-codex.md"),
            Path("tests/runtime-smoke/expected/install-summary.json"),
            Path("tests/runtime-smoke/product/expected/product-summary.json"),
        ]:
            actual = read(work_root / rel)
            expected = read(expected_root / rel)
            if actual != expected:
                fail(f"count-refresh fixture mismatch after update: {rel}")

        if read(work_root / history_rel) != history_before:
            fail("count-refresh fixture rewrote historical docs/plans content")

    print(
        "skill-governance-audit: count-refresh fixture OK "
        f"updated_targets={len(COUNT_TARGETS)} historical_docs_retained=true"
    )


if MODE == "repo":
    validate_repo()
elif MODE == "count-check":
    count = validate_counts(ROOT)
    print(
        "skill-governance-audit: counts OK "
        f"skills={count} targets={len(COUNT_TARGETS)}"
    )
elif MODE == "count-update":
    update_counts(ROOT)
elif MODE == "shape-only":
    validate_shape_only(SHAPE_ARG_PATHS)
elif MODE == "create-fixture":
    validate_create_fixture()
elif MODE == "remove-fixture":
    validate_remove_fixture()
elif MODE == "create-project-fixture":
    validate_create_project_fixture()
elif MODE == "remove-project-fixture":
    validate_remove_project_fixture()
elif MODE == "count-refresh-fixture":
    validate_count_refresh_fixture()
else:
    fail(f"unknown mode: {MODE}")
PY
