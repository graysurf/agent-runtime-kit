#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
HEX40_RE = re.compile(r"^[0-9a-f]{40}$")
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
USES_RE = re.compile(r"uses:\s*([^@\s#]+)@([^\s#]+)")


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def check_workflow_action_pins(errors: list[str]) -> None:
    workflow_dir = ROOT / ".github" / "workflows"
    for path in sorted(workflow_dir.glob("*.yml")):
        for line_no, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            match = USES_RE.search(line)
            if not match:
                continue
            action, ref = match.groups()
            if not HEX40_RE.fullmatch(ref):
                fail(
                    errors,
                    f"{path.relative_to(ROOT)}:{line_no}: action {action}@{ref} is not pinned to a 40-hex commit",
                )


def check_dependabot(errors: list[str]) -> None:
    path = ROOT / ".github" / "dependabot.yml"
    if not path.is_file():
        fail(errors, ".github/dependabot.yml is missing")
        return
    text = path.read_text(encoding="utf-8")
    for ecosystem in ("github-actions", "docker"):
        if f"package-ecosystem: {ecosystem}" not in text:
            fail(errors, f".github/dependabot.yml missing {ecosystem} ecosystem")


def pin_value(text: str, key: str) -> str | None:
    match = re.search(rf"^\s*{re.escape(key)}:\s*\"?([0-9a-f]{{64}})\"?\s*$", text, re.MULTILINE)
    return match.group(1) if match else None


def arg_value(text: str, key: str) -> str | None:
    match = re.search(rf"^\s*ARG\s+{re.escape(key)}=([0-9a-f]{{64}})\s*$", text, re.MULTILINE)
    return match.group(1) if match else None


def check_nils_pin_manifest(errors: list[str]) -> None:
    text = read("docs/source/nils-cli-pin.yaml")
    for key in ("linux_amd64", "linux_arm64"):
        if not pin_value(text, key):
            fail(errors, f"docs/source/nils-cli-pin.yaml missing nils_cli.release_sha256.{key}")


def check_dockerfile(errors: list[str]) -> None:
    dockerfile = read("docker/Dockerfile")
    for line_no, line in enumerate(dockerfile.splitlines(), 1):
        stripped = line.strip()
        if stripped.startswith("FROM ") and "@sha256:" not in stripped:
            fail(errors, f"docker/Dockerfile:{line_no}: FROM line is not digest-pinned")

    required_args = (
        "NILS_CLI_SHA256_AMD64",
        "NILS_CLI_SHA256_ARM64",
        "GH_SHA256_AMD64",
        "GH_SHA256_ARM64",
        "GLAB_SHA256_AMD64",
        "GLAB_SHA256_ARM64",
        "YQ_SHA256_AMD64",
        "YQ_SHA256_ARM64",
    )
    for arg in required_args:
        if not arg_value(dockerfile, arg):
            fail(errors, f"docker/Dockerfile missing 64-hex ARG {arg}")

    pin_text = read("docs/source/nils-cli-pin.yaml")
    manifest_pairs = {
        "NILS_CLI_SHA256_AMD64": pin_value(pin_text, "linux_amd64"),
        "NILS_CLI_SHA256_ARM64": pin_value(pin_text, "linux_arm64"),
    }
    for arg, manifest_value in manifest_pairs.items():
        docker_value = arg_value(dockerfile, arg)
        if docker_value != manifest_value:
            fail(errors, f"docker/Dockerfile {arg} default does not match docs/source/nils-cli-pin.yaml")

    required_fragments = (
        "test \"$expected\" = \"$published\"",
        "test \"$gh_sha\" = \"$gh_published\"",
        "test \"$glab_sha\" = \"$glab_published\"",
        "echo \"${yq_sha}  /tmp/${yq_file}\" | sha256sum -c -",
    )
    for fragment in required_fragments:
        if fragment not in dockerfile:
            fail(errors, f"docker/Dockerfile missing checksum verification fragment: {fragment}")


def check_docker_build_entrypoint(errors: list[str]) -> None:
    script = read("docker/build.sh")
    for key in ("NILS_CLI_VERSION", "NILS_CLI_SHA256_AMD64", "NILS_CLI_SHA256_ARM64"):
        if f'--build-arg "{key}=' not in script:
            fail(errors, f"docker/build.sh does not pass {key} from docs/source/nils-cli-pin.yaml")


def check_publish_workflow(errors: list[str]) -> None:
    workflow = read(".github/workflows/publish-image.yml")
    for fragment in (
        "id-token: write",
        "attestations: write",
        "provenance: true",
        "sbom: true",
        "actions/attest-build-provenance@",
        "NILS_CLI_SHA256_AMD64=${{ steps.pin.outputs.nils_cli_sha256_amd64 }}",
        "NILS_CLI_SHA256_ARM64=${{ steps.pin.outputs.nils_cli_sha256_arm64 }}",
    ):
        if fragment not in workflow:
            fail(errors, f".github/workflows/publish-image.yml missing {fragment}")
    for line_no, line in enumerate(workflow.splitlines(), 1):
        if "actions/attest-build-provenance@" in line:
            ref = line.split("@", 1)[1].split()[0]
            if not HEX40_RE.fullmatch(ref):
                fail(errors, f".github/workflows/publish-image.yml:{line_no}: attestation action is not SHA-pinned")


def main() -> int:
    errors: list[str] = []
    check_workflow_action_pins(errors)
    check_dependabot(errors)
    check_nils_pin_manifest(errors)
    check_dockerfile(errors)
    check_docker_build_entrypoint(errors)
    check_publish_workflow(errors)

    if errors:
        print("security-hardening-audit: FAIL", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1
    print("security-hardening-audit: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
