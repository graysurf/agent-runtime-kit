#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]
HOOK_DIR = REPO_ROOT / "core" / "hooks" / "shared"


def parse_stdout(stdout: str) -> dict[str, object] | None:
    stripped = stdout.strip()
    if not stripped:
        return None
    parsed = json.loads(stripped)
    if not isinstance(parsed, dict):
        raise AssertionError(f"hook stdout was not a JSON object: {stdout!r}")
    return parsed


def run_hook(
    script_name: str,
    payload: dict[str, Any],
    *,
    cwd: Path | None = None,
    env: dict[str, str] | None = None,
    dont_write_bytecode: bool = True,
) -> tuple[int, dict[str, object] | None, str]:
    full_env = dict(os.environ)
    full_env["PYTHONPATH"] = str(HOOK_DIR)
    if dont_write_bytecode:
        full_env["PYTHONDONTWRITEBYTECODE"] = "1"
    else:
        full_env.pop("PYTHONDONTWRITEBYTECODE", None)
    if env:
        full_env.update(env)
    completed = subprocess.run(
        [sys.executable, str(HOOK_DIR / script_name)],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        cwd=cwd,
        env=full_env,
        check=False,
    )
    return completed.returncode, parse_stdout(completed.stdout), completed.stderr


def run_shell_hook(
    script_name: str,
    payload: dict[str, Any],
    *,
    cwd: Path | None = None,
    env: dict[str, str] | None = None,
) -> tuple[int, dict[str, object] | None, str]:
    """Run a shell (bash) shared hook; mirrors run_hook for `.sh` hooks."""
    full_env = dict(os.environ)
    if env:
        full_env.update(env)
    completed = subprocess.run(
        ["bash", str(HOOK_DIR / script_name)],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        cwd=cwd,
        env=full_env,
        check=False,
    )
    return completed.returncode, parse_stdout(completed.stdout), completed.stderr


def command_payload(command: str, **tool_input: str) -> dict[str, Any]:
    return {"tool_name": "Bash", "tool_input": {"command": command, **tool_input}}


def write_payload(path: str, content: str) -> dict[str, Any]:
    return {"tool_name": "Write", "tool_input": {"file_path": path, "content": content}}


def codex_link_map_hook_body() -> str:
    lines = (REPO_ROOT / "targets" / "codex" / "link-map.yaml").read_text(
        encoding="utf-8"
    ).splitlines()
    in_codex_config = False
    in_body = False
    body: list[str] = []
    for line in lines:
        if line == "  - id: hooks.codex-config":
            in_codex_config = True
            continue
        if in_codex_config and line == "    body_template: |-":
            in_body = True
            continue
        if in_body:
            if line.startswith("  - id: "):
                break
            body.append(line[6:] if line.startswith("      ") else line)
    return "\n".join(body).rstrip() + "\n"


class SharedHookTests(unittest.TestCase):
    def assert_blocked(self, decision: dict[str, object] | None, fragment: str) -> None:
        self.assertIsNotNone(decision)
        assert decision is not None
        self.assertEqual(decision.get("decision"), "block")
        self.assertIn(fragment, str(decision.get("reason", "")))

    def assert_allowed(self, decision: dict[str, object] | None) -> None:
        self.assertIsNone(decision)

    def test_blocks_direct_git_commit(self) -> None:
        code, decision, stderr = run_hook(
            "block-direct-git-commit.py",
            command_payload("git commit -m test"),
        )
        self.assertEqual(code, 0, stderr)
        self.assert_blocked(decision, "semantic-commit")

    def test_blocks_direct_git_worktree_and_allows_git_cli(self) -> None:
        blocked_commands = (
            "git -C repo worktree add ../repo-topic",
            "env GIT_OPTIONAL_LOCKS=0 git worktree remove ../repo-topic",
            "git status && git worktree prune",
            "command git worktree lock ../repo-topic",
            "printf 'ALLOW_DIRECT_GIT_WORKTREE=1'; git worktree add ../repo-topic",
            "ALLOW_DIRECT_GIT_WORKTREE=0 git worktree add ../repo-topic",
        )
        for command in blocked_commands:
            with self.subTest(command=command):
                code, decision, stderr = run_hook(
                    "block-direct-git-worktree.py",
                    command_payload(command),
                )
                self.assertEqual(code, 0, stderr)
                self.assert_blocked(decision, "git-cli worktree")

        allowed_commands = (
            "git worktree list",
            "git worktree --help",
            "git-cli worktree list",
            "git status",
            "printf 'git worktree list\\n'",
            "ALLOW_DIRECT_GIT_WORKTREE=1 git worktree add ../repo-topic",
            "env ALLOW_DIRECT_GIT_WORKTREE=1 git worktree add ../repo-topic",
        )
        for command in allowed_commands:
            with self.subTest(command=command):
                code, decision, stderr = run_hook(
                    "block-direct-git-worktree.py",
                    command_payload(command),
                )
                self.assertEqual(code, 0, stderr)
                self.assert_allowed(decision)

        code, decision, stderr = run_hook(
            "block-direct-git-worktree.py",
            command_payload("git worktree add ../repo-topic"),
            env={"AGENT_RUNTIME_ALLOW_DIRECT_GIT_WORKTREE": "1"},
        )
        self.assertEqual(code, 0, stderr)
        self.assert_allowed(decision)

    def test_python_hooks_do_not_write_bytecode_in_source_checkout(self) -> None:
        pycache = HOOK_DIR / "__pycache__"
        if pycache.exists():
            for path in pycache.iterdir():
                path.unlink()
            pycache.rmdir()

        code, decision, stderr = run_hook(
            "block-direct-git-commit.py",
            command_payload("git status"),
            dont_write_bytecode=False,
        )
        self.assertEqual(code, 0, stderr)
        self.assert_allowed(decision)
        self.assertFalse(pycache.exists())

    def test_blocks_nontrivial_semantic_commit_without_body(self) -> None:
        code, decision, stderr = run_hook(
            "semantic-commit-body-gate.py",
            command_payload("semantic-commit commit --message 'fix(agent): tighten hook parser'"),
        )
        self.assertEqual(code, 0, stderr)
        self.assert_blocked(decision, "missing a body")

    def test_blocks_nontrivial_body_gate_via_structured_subject_without_bullet(self) -> None:
        # Bypass repro: a non-trivial commit carried via structured
        # --type/--scope/--subject with no --body-bullet had no --message body
        # for extract_message() to recover, so the gate fell through to ALLOW.
        command = (
            "semantic-commit commit --type fix --scope hooks --subject 'tighten gate'"
        )
        code, decision, stderr = run_hook(
            "semantic-commit-body-gate.py",
            command_payload(command),
        )
        self.assertEqual(code, 0, stderr)
        self.assert_blocked(decision, "missing a body")

    def test_blocks_nontrivial_body_gate_via_message_file_without_body(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            msg = Path(tmp) / "msg.txt"
            msg.write_text("fix(agent): tighten hook parser\n", encoding="utf-8")
            code, decision, stderr = run_hook(
                "semantic-commit-body-gate.py",
                command_payload(f"semantic-commit commit --message-file {msg}"),
            )
            self.assertEqual(code, 0, stderr)
            self.assert_blocked(decision, "missing a body")

    def test_body_gate_trailer_does_not_count_as_body(self) -> None:
        # A --trailer is metadata, not an explanatory body bullet; a non-trivial
        # commit with only a trailer must still be blocked.
        command = (
            "semantic-commit commit --subject 'fix(hooks): tighten gate' "
            "--trailer 'Reviewed-by: Jane Dev <jane@example.com>'"
        )
        code, decision, stderr = run_hook(
            "semantic-commit-body-gate.py",
            command_payload(command),
        )
        self.assertEqual(code, 0, stderr)
        self.assert_blocked(decision, "missing a body")

    def test_allows_body_gate_with_structured_body_bullet(self) -> None:
        command = (
            "semantic-commit commit --type fix --scope hooks "
            "--subject 'tighten gate' --body-bullet 'covers structured args'"
        )
        code, decision, stderr = run_hook(
            "semantic-commit-body-gate.py",
            command_payload(command),
        )
        self.assertEqual(code, 0, stderr)
        self.assert_allowed(decision)

    def test_allows_trivial_structured_type_without_body(self) -> None:
        # --type chore is trivial; reconstructing the conventional header from
        # the structured flags keeps the trivial allowance intact.
        command = "semantic-commit commit --type chore --subject 'bump pinned surface'"
        code, decision, stderr = run_hook(
            "semantic-commit-body-gate.py",
            command_payload(command),
        )
        self.assertEqual(code, 0, stderr)
        self.assert_allowed(decision)

    def test_allows_body_gate_message_file_with_body(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            msg = Path(tmp) / "msg.txt"
            msg.write_text("fix(agent): tighten parser\n\n- explain why\n", encoding="utf-8")
            code, decision, stderr = run_hook(
                "semantic-commit-body-gate.py",
                command_payload(f"semantic-commit commit --message-file {msg}"),
            )
            self.assertEqual(code, 0, stderr)
            self.assert_allowed(decision)

    def test_blocks_claude_coauthor_trailer_in_heredoc(self) -> None:
        command = (
            "semantic-commit commit --message \"$(cat <<'MSG'\n"
            "feat(hook): add gate\n\n"
            "- explain why\n\n"
            "Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>\n"
            "MSG\n)\""
        )
        code, decision, stderr = run_hook(
            "block-claude-coauthor-trailer.py",
            command_payload(command),
        )
        self.assertEqual(code, 0, stderr)
        self.assert_blocked(decision, "Claude Co-Authored-By trailer")

    def test_blocks_claude_coauthor_for_any_model_inline(self) -> None:
        # Model name after `Claude` must not matter — block Sonnet/Haiku too.
        command = (
            "semantic-commit commit --message "
            "'fix: thing\n\n- why\n\nCo-authored-by: Claude Sonnet 4.6 <noreply@anthropic.com>'"
        )
        code, decision, stderr = run_hook(
            "block-claude-coauthor-trailer.py",
            command_payload(command),
        )
        self.assertEqual(code, 0, stderr)
        self.assert_blocked(decision, "Claude Co-Authored-By trailer")

    def test_allows_non_claude_coauthor(self) -> None:
        command = (
            "semantic-commit commit --message "
            "'feat: thing\n\n- why\n\nCo-Authored-By: Jane Dev <jane@example.com>'"
        )
        code, decision, stderr = run_hook(
            "block-claude-coauthor-trailer.py",
            command_payload(command),
        )
        self.assertEqual(code, 0, stderr)
        self.assert_allowed(decision)

    def test_allows_message_without_claude_trailer(self) -> None:
        code, decision, stderr = run_hook(
            "block-claude-coauthor-trailer.py",
            command_payload("semantic-commit commit --message 'feat: thing\n\n- why'"),
        )
        self.assertEqual(code, 0, stderr)
        self.assert_allowed(decision)

    def test_allows_claude_trailer_on_dry_run(self) -> None:
        command = (
            "semantic-commit commit --dry-run --message "
            "'feat: thing\n\nCo-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>'"
        )
        code, decision, stderr = run_hook(
            "block-claude-coauthor-trailer.py",
            command_payload(command),
        )
        self.assertEqual(code, 0, stderr)
        self.assert_allowed(decision)

    def test_blocks_claude_coauthor_via_trailer_flag(self) -> None:
        # Reproduces the gate bypass: the Claude trailer is passed via
        # `--trailer` alongside structured `--subject`/`--body-bullet`, so there
        # is no `--message` body for extract_message() to recover.
        command = (
            "semantic-commit commit --type fix --scope hooks "
            "--subject 'tighten gate' --body-bullet 'why it matters' "
            "--trailer 'Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>'"
        )
        code, decision, stderr = run_hook(
            "block-claude-coauthor-trailer.py",
            command_payload(command),
        )
        self.assertEqual(code, 0, stderr)
        self.assert_blocked(decision, "Claude Co-Authored-By trailer")

    def test_blocks_claude_coauthor_in_body_bullet(self) -> None:
        command = (
            "semantic-commit commit --subject 'fix: thing' "
            "--body-bullet 'Co-authored-by: Claude Haiku 4.5 <noreply@anthropic.com>'"
        )
        code, decision, stderr = run_hook(
            "block-claude-coauthor-trailer.py",
            command_payload(command),
        )
        self.assertEqual(code, 0, stderr)
        self.assert_blocked(decision, "Claude Co-Authored-By trailer")

    def test_blocks_claude_coauthor_via_message_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            msg = Path(tmp) / "msg.txt"
            msg.write_text(
                "feat: thing\n\n- why\n\n"
                "Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>\n",
                encoding="utf-8",
            )
            code, decision, stderr = run_hook(
                "block-claude-coauthor-trailer.py",
                command_payload(f"semantic-commit commit --message-file {msg}"),
            )
            self.assertEqual(code, 0, stderr)
            self.assert_blocked(decision, "Claude Co-Authored-By trailer")

    def test_allows_non_claude_trailer_flag(self) -> None:
        command = (
            "semantic-commit commit --subject 'feat: thing' --body-bullet 'why' "
            "--trailer 'Co-Authored-By: Jane Dev <jane@example.com>'"
        )
        code, decision, stderr = run_hook(
            "block-claude-coauthor-trailer.py",
            command_payload(command),
        )
        self.assertEqual(code, 0, stderr)
        self.assert_allowed(decision)

    def test_allows_structured_fields_without_trailer(self) -> None:
        command = (
            "semantic-commit commit --type fix --scope hooks "
            "--subject 'tighten gate' --body-bullet 'why it matters'"
        )
        code, decision, stderr = run_hook(
            "block-claude-coauthor-trailer.py",
            command_payload(command),
        )
        self.assertEqual(code, 0, stderr)
        self.assert_allowed(decision)

    def test_claude_coauthor_gate_is_claude_only(self) -> None:
        script = "block-claude-coauthor-trailer.py"
        self.assertTrue((HOOK_DIR / script).is_file(), script)
        claude_fragment = (
            REPO_ROOT / "core" / "hooks" / "claude" / "settings.hooks.jsonc"
        ).read_text(encoding="utf-8")
        codex_block = (
            REPO_ROOT / "targets" / "codex" / "hooks" / "config.block.toml"
        ).read_text(encoding="utf-8")
        self.assertIn(f"hooks/{script}", claude_fragment)
        self.assertNotIn(f"hooks/{script}", codex_block)

    def test_blocks_bare_python_in_uv_project_and_allows_shared_bypass(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            (repo / "uv.lock").write_text("# fixture\n", encoding="utf-8")
            payload = command_payload("python3 -m pytest", workdir=str(repo))

            code, decision, stderr = run_hook("block-direct-python.py", payload, cwd=repo)
            self.assertEqual(code, 0, stderr)
            self.assert_blocked(decision, "uv run --locked python")

            code, decision, stderr = run_hook(
                "block-direct-python.py",
                payload,
                cwd=repo,
                env={"AGENT_RUNTIME_ALLOW_SYSTEM_PYTHON": "1"},
            )
            self.assertEqual(code, 0, stderr)
            self.assert_allowed(decision)

    def test_blocks_direct_pr_create_unless_neutral_marker(self) -> None:
        code, decision, stderr = run_hook(
            "block-direct-pr-create.py",
            command_payload("gh pr create --draft"),
        )
        self.assertEqual(code, 0, stderr)
        self.assert_blocked(decision, "AGENT_RUNTIME_PR_SKILL")

        for marker in (
            "AGENT_RUNTIME_PR_SKILL=create-pr",
            "AGENT_RUNTIME_PR_SKILL=pr:create-pr",
        ):
            code, decision, stderr = run_hook(
                "block-direct-pr-create.py",
                command_payload(f"{marker} gh pr create --draft"),
            )
            self.assertEqual(code, 0, stderr)
            self.assert_allowed(decision)

        # Retired legacy product markers must no longer bypass the gate.
        for legacy in (
            "AGENT_KIT_PR_SKILL=create-pr",
            "CLAUDE_KIT_PR_SKILL=pr:create-pr",
        ):
            code, decision, stderr = run_hook(
                "block-direct-pr-create.py",
                command_payload(f"{legacy} gh pr create --draft"),
            )
            self.assertEqual(code, 0, stderr)
            self.assert_blocked(decision, "AGENT_RUNTIME_PR_SKILL")

    def test_block_hooks_are_not_bypassed_by_multiline_commands(self) -> None:
        # Regression: an unquoted newline must act as a command separator in the
        # block guards. Otherwise a blocked command placed after a preamble line
        # (commonly `cd <dir>`) is glued onto that line's command, so the guard
        # inspects the preamble's command position and never sees the blocked
        # one. Same root cause fixed in simple_commands() for the finish-line
        # matcher; here it is a guard bypass, not just a missed validation.
        cases = (
            (
                "block-direct-git-commit.py",
                "cd repo\ngit commit -m test",
                "semantic-commit",
            ),
            (
                "block-direct-git-worktree.py",
                "cd repo\ngit worktree add ../repo-topic",
                "git-cli worktree",
            ),
            (
                "block-direct-pr-create.py",
                "cd repo\ngh pr create --draft",
                "AGENT_RUNTIME_PR_SKILL",
            ),
        )
        for hook, command, fragment in cases:
            with self.subTest(hook=hook):
                code, decision, stderr = run_hook(hook, command_payload(command))
                self.assertEqual(code, 0, stderr)
                self.assert_blocked(decision, fragment)

        # block-direct-python: a python invocation on a second physical line, in
        # a workspace with a project virtualenv, must still be blocked.
        with tempfile.TemporaryDirectory() as tmp:
            venv = Path(tmp) / ".venv"
            venv.mkdir()
            (venv / "pyvenv.cfg").write_text("home = /usr\n", encoding="utf-8")
            code, decision, stderr = run_hook(
                "block-direct-python.py",
                command_payload("echo setup\npython manage.py migrate"),
                cwd=Path(tmp),
            )
            self.assertEqual(code, 0, stderr)
            self.assert_blocked(decision, "local virtualenv")

    def test_forge_label_reminder_fires_only_without_label(self) -> None:
        reminded_commands = (
            "forge-cli pr create --title x",
            "forge-cli pr deliver --kind feature",
            "forge-cli issue create --title x",
            # A global option value must not be mistaken for the subcommand.
            "forge-cli --repo owner/x --format json pr create --title x",
            # The agent-run exec wrapper is unwrapped before matching.
            "agent-run exec --cwd /repo -- forge-cli issue create --title x",
            # --label-catalog is not a label selection.
            "forge-cli pr create --label-catalog manifests/forge-labels.yaml",
        )
        for command in reminded_commands:
            with self.subTest(command=command):
                code, decision, stderr = run_hook(
                    "forge-label-reminder.py", command_payload(command)
                )
                self.assertEqual(code, 0, stderr)
                self.assert_blocked(decision, "--label")

        allowed_commands = (
            "forge-cli pr create --title x --label type::feature",
            "forge-cli issue create --label=type::bug",
            "forge-cli pr deliver --kind feature --label size::m",
            # Non-labelable subcommands and non-forge commands stay silent.
            "forge-cli pr view 123",
            "forge-cli issue list",
            "forge-cli label ensure",
            "gh pr create --title x",
            # Explicit no-label opt-out via the inline bypass marker.
            "FORGE_NO_LABELS=1 forge-cli pr create --title x",
            "AGENT_RUNTIME_FORGE_NO_LABELS=true forge-cli issue create --title x",
        )
        for command in allowed_commands:
            with self.subTest(command=command):
                code, decision, stderr = run_hook(
                    "forge-label-reminder.py", command_payload(command)
                )
                self.assertEqual(code, 0, stderr)
                self.assert_allowed(decision)

        # The bypass also honours the process environment.
        code, decision, stderr = run_hook(
            "forge-label-reminder.py",
            command_payload("forge-cli pr create --title x"),
            env={"FORGE_NO_LABELS": "1"},
        )
        self.assertEqual(code, 0, stderr)
        self.assert_allowed(decision)

    def test_blocks_project_memory_write(self) -> None:
        code, decision, stderr = run_hook(
            "block-project-memory-write.py",
            write_payload(".codex/memories/project_state/project_notes.md", "x"),
        )
        self.assertEqual(code, 0, stderr)
        self.assert_blocked(decision, "project-state memory")

    def test_blocks_mcp_secret_and_portable_path_writes(self) -> None:
        code, decision, stderr = run_hook(
            "mcp-secret-scan.py",
            write_payload(".mcp.json", '{"apiKey": "sk-proj-abcdefghijklmnopqrstuvwxyz"}'),
        )
        self.assertEqual(code, 0, stderr)
        self.assert_blocked(decision, ".mcp.json")

        code, decision, stderr = run_hook(
            "portable-paths-scan.py",
            write_payload("docs/example.md", "Path: /Users/example/project\n"),
        )
        self.assertEqual(code, 0, stderr)
        self.assert_blocked(decision, "portable-paths")

    def test_skill_usage_reminder_uses_catalog(self) -> None:
        code, decision, stderr = run_hook(
            "skill-usage-reminder.py",
            {"prompt": "please run deliver-pr for this branch"},
            env={"AGENT_RUNTIME_PRODUCT": "codex"},
        )
        self.assertEqual(code, 0, stderr)
        self.assertIsNotNone(decision)
        assert decision is not None
        output = decision.get("hookSpecificOutput")
        self.assertIsInstance(output, dict)
        assert isinstance(output, dict)
        self.assertIn("deliver-pr", str(output.get("additionalContext", "")))

    def _require_agent_docs(self) -> None:
        if shutil.which("agent-docs") is None:
            self.skipTest("agent-docs not on PATH")

    @staticmethod
    def _init_contract_repo(
        tmp: str, commands: tuple[str, ...] = ("bash scripts/ci/all.sh",)
    ) -> Path:
        repo = Path(tmp)
        subprocess.run(["git", "init", "-q"], cwd=repo, check=True)
        rendered = ", ".join(f'"{command}"' for command in commands)
        (repo / "AGENT_DOCS.toml").write_text(
            '[[validation]]\ncontext = "project-dev"\n'
            f"commands = [{rendered}]\n"
            'marker = ".cache/agent-validation/project-dev.ok"\n',
            encoding="utf-8",
        )
        return repo

    @staticmethod
    def _write_fake_agent_docs(bin_dir: Path, body: str) -> None:
        script = bin_dir / "agent-docs"
        script.write_text(body, encoding="utf-8")
        script.chmod(0o755)

    def test_finish_line_gate_blocks_unvalidated_edit_then_releases(self) -> None:
        self._require_agent_docs()
        with tempfile.TemporaryDirectory() as tmp:
            repo = self._init_contract_repo(tmp)
            env = {"AGENT_RUNTIME_DOCS_HOME": str(repo)}

            # No edits yet: the gate allows.
            code, decision, stderr = run_hook(
                "stop-finish-line-gate.py", {}, cwd=repo, env=env
            )
            self.assertEqual(code, 0, stderr)
            self.assert_allowed(decision)

            # A code edit marks the repo dirty.
            code, _, stderr = run_hook(
                "finish-line-record.py",
                write_payload("src/lib.rs", "fn main() {}\n"),
                cwd=repo,
                env=env,
            )
            self.assertEqual(code, 0, stderr)

            # The gate now blocks, naming the outstanding validation command.
            code, decision, stderr = run_hook(
                "stop-finish-line-gate.py", {}, cwd=repo, env=env
            )
            self.assertEqual(code, 0, stderr)
            self.assert_blocked(decision, "scripts/ci/all.sh")

            # Running the declared validation records the run.
            code, _, stderr = run_hook(
                "finish-line-record.py",
                command_payload("bash scripts/ci/all.sh"),
                cwd=repo,
                env=env,
            )
            self.assertEqual(code, 0, stderr)

            # The gate releases now that validation ran after the edit.
            code, decision, stderr = run_hook(
                "stop-finish-line-gate.py", {}, cwd=repo, env=env
            )
            self.assertEqual(code, 0, stderr)
            self.assert_allowed(decision)

    def test_finish_line_record_requires_real_validation_command_invocation(self) -> None:
        self._require_agent_docs()
        with tempfile.TemporaryDirectory() as tmp:
            repo = self._init_contract_repo(
                tmp, ("bash scripts/ci/all.sh", "bash tests/hooks/run.sh")
            )
            env = {"AGENT_RUNTIME_DOCS_HOME": str(repo)}

            code, _, stderr = run_hook(
                "finish-line-record.py",
                write_payload("src/lib.rs", "fn main() {}\n"),
                cwd=repo,
                env=env,
            )
            self.assertEqual(code, 0, stderr)

            fake_command = 'printf %s "bash scripts/ci/all.sh && bash tests/hooks/run.sh"'
            code, _, stderr = run_hook(
                "finish-line-record.py",
                command_payload(fake_command),
                cwd=repo,
                env=env,
            )
            self.assertEqual(code, 0, stderr)

            code, decision, stderr = run_hook(
                "stop-finish-line-gate.py", {}, cwd=repo, env=env
            )
            self.assertEqual(code, 0, stderr)
            self.assert_blocked(decision, "scripts/ci/all.sh")

    def test_finish_line_record_matches_multiline_command_with_cd_preamble(self) -> None:
        # Regression: agents routinely run the declared validation as a
        # multi-line Bash command with a `cd` preamble, e.g.
        #     cd /repo
        #     bash scripts/ci/all.sh && bash tests/hooks/run.sh
        # An unquoted newline must act as a command separator; otherwise the
        # validation command on the second physical line is glued onto `cd`,
        # never recognized, and the gate stays spuriously blocked.
        self._require_agent_docs()
        with tempfile.TemporaryDirectory() as tmp:
            repo = self._init_contract_repo(
                tmp, ("bash scripts/ci/all.sh", "bash tests/hooks/run.sh")
            )
            env = {"AGENT_RUNTIME_DOCS_HOME": str(repo)}

            code, _, stderr = run_hook(
                "finish-line-record.py",
                write_payload("src/lib.rs", "fn main() {}\n"),
                cwd=repo,
                env=env,
            )
            self.assertEqual(code, 0, stderr)

            multiline = (
                "cd /repo\n"
                "bash scripts/ci/all.sh && bash tests/hooks/run.sh\n"
                'echo "done=$?"'
            )
            code, _, stderr = run_hook(
                "finish-line-record.py",
                command_payload(multiline),
                cwd=repo,
                env=env,
            )
            self.assertEqual(code, 0, stderr)

            # Both declared validations ran after the edit, so the gate releases.
            code, decision, stderr = run_hook(
                "stop-finish-line-gate.py", {}, cwd=repo, env=env
            )
            self.assertEqual(code, 0, stderr)
            self.assert_allowed(decision)

    def test_finish_line_record_ignores_validation_text_inside_quotes(self) -> None:
        # Guard against a false positive: a multi-line command whose only
        # mention of the validation command is inside a quoted string (here a
        # newline-bearing double-quoted argument) must NOT satisfy the gate.
        self._require_agent_docs()
        with tempfile.TemporaryDirectory() as tmp:
            repo = self._init_contract_repo(tmp, ("bash scripts/ci/all.sh",))
            env = {"AGENT_RUNTIME_DOCS_HOME": str(repo)}

            code, _, stderr = run_hook(
                "finish-line-record.py",
                write_payload("src/lib.rs", "fn main() {}\n"),
                cwd=repo,
                env=env,
            )
            self.assertEqual(code, 0, stderr)

            quoted = 'cd /repo\nprintf "%s\nbash scripts/ci/all.sh\n" "header"'
            code, _, stderr = run_hook(
                "finish-line-record.py",
                command_payload(quoted),
                cwd=repo,
                env=env,
            )
            self.assertEqual(code, 0, stderr)

            code, decision, stderr = run_hook(
                "stop-finish-line-gate.py", {}, cwd=repo, env=env
            )
            self.assertEqual(code, 0, stderr)
            self.assert_blocked(decision, "scripts/ci/all.sh")

    def test_finish_line_gate_enforces_every_declared_validation_intent(self) -> None:
        self._require_agent_docs()
        with tempfile.TemporaryDirectory() as tmp:
            repo = self._init_contract_repo(tmp)
            with (repo / "AGENT_DOCS.toml").open("a", encoding="utf-8") as handle:
                handle.write(
                    '\n[[validation]]\ncontext = "task-tools"\n'
                    'commands = ["bash scripts/task-tools.sh"]\n'
                    'marker = ".cache/agent-validation/task-tools.ok"\n'
                )
            env = {"AGENT_RUNTIME_DOCS_HOME": str(repo)}

            code, _, stderr = run_hook(
                "finish-line-record.py",
                write_payload("src/lib.rs", "fn main() {}\n"),
                cwd=repo,
                env=env,
            )
            self.assertEqual(code, 0, stderr)

            code, _, stderr = run_hook(
                "finish-line-record.py",
                command_payload("bash scripts/ci/all.sh"),
                cwd=repo,
                env=env,
            )
            self.assertEqual(code, 0, stderr)

            code, decision, stderr = run_hook(
                "stop-finish-line-gate.py", {}, cwd=repo, env=env
            )
            self.assertEqual(code, 0, stderr)
            self.assert_blocked(decision, "scripts/task-tools.sh")

            code, _, stderr = run_hook(
                "finish-line-record.py",
                command_payload("bash scripts/task-tools.sh"),
                cwd=repo,
                env=env,
            )
            self.assertEqual(code, 0, stderr)

            code, decision, stderr = run_hook(
                "stop-finish-line-gate.py", {}, cwd=repo, env=env
            )
            self.assertEqual(code, 0, stderr)
            self.assert_allowed(decision)

    def test_finish_line_uses_guarded_preflight_when_supported(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = self._init_contract_repo(tmp)
            bin_dir = repo / "bin"
            bin_dir.mkdir()
            self._write_fake_agent_docs(
                bin_dir,
                """#!/usr/bin/env bash
set -euo pipefail
args="$*"
if [[ "$args" == *"preflight --help"* ]]; then
  printf '%s\n' '      --require-declared-intent'
  exit 0
fi
if [[ "$args" == *"list --format json"* ]]; then
  printf '%s\n' '{"intents":["project-dev"]}'
  exit 0
fi
if [[ "$args" == *"explain"* ]]; then
  echo "explain should not be used" >&2
  exit 66
fi
if [[ "$args" == *"preflight"* && "$args" == *"--intent project-dev"* ]]; then
  if [[ "$args" != *"--require-declared-intent"* ]]; then
    echo "missing declared-intent guard" >&2
    exit 64
  fi
  printf '%s\n' '{"intent":"project-dev","documents":[],"validation":{"context":"project-dev","declared":true,"commands":["bash scripts/ci/all.sh"],"marker":".cache/agent-validation/project-dev.ok"}}'
  exit 0
fi
exit 65
""",
            )
            env = {
                "AGENT_RUNTIME_DOCS_HOME": str(repo),
                "PATH": f"{bin_dir}{os.pathsep}{os.environ.get('PATH', '')}",
            }

            code, _, stderr = run_hook(
                "finish-line-record.py",
                write_payload("src/lib.rs", "fn main() {}\n"),
                cwd=repo,
                env=env,
            )
            self.assertEqual(code, 0, stderr)

            code, decision, stderr = run_hook(
                "stop-finish-line-gate.py", {}, cwd=repo, env=env
            )
            self.assertEqual(code, 0, stderr)
            self.assert_blocked(decision, "scripts/ci/all.sh")

    def test_finish_line_gate_waiver_and_suppress_release(self) -> None:
        self._require_agent_docs()
        with tempfile.TemporaryDirectory() as tmp:
            repo = self._init_contract_repo(tmp)
            base_env = {"AGENT_RUNTIME_DOCS_HOME": str(repo)}
            run_hook(
                "finish-line-record.py",
                {"tool_name": "Edit", "tool_input": {"file_path": "src/lib.rs"}},
                cwd=repo,
                env=base_env,
            )

            _, decision, _ = run_hook("stop-finish-line-gate.py", {}, cwd=repo, env=base_env)
            self.assert_blocked(decision, "validation")

            _, decision, _ = run_hook(
                "stop-finish-line-gate.py",
                {},
                cwd=repo,
                env={**base_env, "AGENT_RUNTIME_VALIDATION_WAIVER": "deliberate skip"},
            )
            self.assert_allowed(decision)

            _, decision, _ = run_hook(
                "stop-finish-line-gate.py",
                {},
                cwd=repo,
                env={**base_env, "AGENT_RUNTIME_SUPPRESS_FINISH_GATE": "1"},
            )
            self.assert_allowed(decision)

    def test_finish_line_record_ignores_markdown_only_edits(self) -> None:
        self._require_agent_docs()
        with tempfile.TemporaryDirectory() as tmp:
            repo = self._init_contract_repo(tmp)
            env = {"AGENT_RUNTIME_DOCS_HOME": str(repo)}
            run_hook(
                "finish-line-record.py",
                write_payload("docs/note.md", "# note\n"),
                cwd=repo,
                env=env,
            )
            code, decision, stderr = run_hook(
                "stop-finish-line-gate.py", {}, cwd=repo, env=env
            )
            self.assertEqual(code, 0, stderr)
            self.assert_allowed(decision)

    def test_finish_line_gate_noops_without_contract(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            subprocess.run(["git", "init", "-q"], cwd=repo, check=True)
            run_hook(
                "finish-line-record.py",
                write_payload("src/lib.rs", "fn main() {}\n"),
                cwd=repo,
            )
            code, decision, stderr = run_hook("stop-finish-line-gate.py", {}, cwd=repo)
            self.assertEqual(code, 0, stderr)
            self.assert_allowed(decision)

    def test_preflight_cue_covers_every_declared_intent(self) -> None:
        self._require_agent_docs()
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            subprocess.run(["git", "init", "-q"], cwd=repo, check=True)
            (repo / "DEV.md").write_text("# Dev\n", encoding="utf-8")
            (repo / "core" / "policies").mkdir(parents=True)
            (repo / "core" / "policies" / "ext.md").write_text(
                "# Ext\n", encoding="utf-8"
            )
            (repo / "AGENT_DOCS.toml").write_text(
                '[[document]]\ncontext = "project-dev"\nscope = "project"\n'
                'path = "DEV.md"\nrequired = true\nwhen = "always"\n\n'
                '[[document]]\ncontext = "task-tools"\nscope = "project"\n'
                'path = "core/policies/ext.md"\nrequired = true\nwhen = "always"\n\n'
                '[[validation]]\ncontext = "project-dev"\n'
                'commands = ["bash scripts/ci/all.sh"]\n'
                'marker = ".cache/agent-validation/project-dev.ok"\n',
                encoding="utf-8",
            )
            home = repo / "home"
            home.mkdir()
            env = {"AGENT_RUNTIME_DOCS_HOME": str(repo), "HOME": str(home)}

            code, decision, stderr = run_shell_hook(
                "user-prompt-agent-docs.sh",
                {"session_id": "cue-test", "prompt": "hello"},
                cwd=repo,
                env=env,
            )
            self.assertEqual(code, 0, stderr)
            self.assertIsNotNone(decision)
            assert decision is not None
            hook_output = decision.get("hookSpecificOutput", {})
            ctx = ""
            if isinstance(hook_output, dict):
                ctx = str(hook_output.get("additionalContext", ""))
            # The project-dev intent still surfaces (doc + validation command).
            self.assertIn("project-dev", ctx)
            self.assertIn("DEV.md", ctx)
            self.assertIn("scripts/ci/all.sh", ctx)
            # The generalization: a declared non-project-dev intent surfaces too.
            self.assertIn("task-tools", ctx)
            self.assertIn("ext.md", ctx)

    def test_preflight_cue_fails_closed_for_undeclared_intent_when_guarded(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            subprocess.run(["git", "init", "-q"], cwd=repo, check=True)
            (repo / "AGENT_DOCS.toml").write_text(
                '[[document]]\ncontext = "project-dev"\nscope = "project"\n'
                'path = "DEV.md"\nrequired = true\nwhen = "always"\n',
                encoding="utf-8",
            )
            (repo / "DEV.md").write_text("# Dev\n", encoding="utf-8")
            bin_dir = repo / "bin"
            bin_dir.mkdir()
            self._write_fake_agent_docs(
                bin_dir,
                """#!/usr/bin/env bash
set -euo pipefail
args="$*"
if [[ "$args" == *"preflight --help"* ]]; then
  printf '%s\n' '      --require-declared-intent'
  exit 0
fi
if [[ "$args" == *"list --format json"* ]]; then
  printf '%s\n' '{"intents":["project-dev","project_dev"]}'
  exit 0
fi
if [[ "$args" == *"preflight"* && "$args" == *"--intent project-dev"* ]]; then
  if [[ "$args" != *"--require-declared-intent"* ]]; then
    echo "missing declared-intent guard" >&2
    exit 64
  fi
  printf '%s\n' '{"intent":"project-dev","documents":[{"path":"DEV.md","required":true}],"validation":{"declared":false,"commands":[]}}'
  exit 0
fi
if [[ "$args" == *"preflight"* && "$args" == *"--intent project_dev"* ]]; then
  if [[ "$args" != *"--require-declared-intent"* ]]; then
    echo "missing declared-intent guard" >&2
    exit 64
  fi
  echo '{"ok":false,"error":{"code":"undeclared-intent"}}' >&2
  exit 65
fi
exit 65
""",
            )
            home = repo / "home"
            home.mkdir()
            env = {
                "AGENT_RUNTIME_DOCS_HOME": str(repo),
                "HOME": str(home),
                "PATH": f"{bin_dir}{os.pathsep}{os.environ.get('PATH', '')}",
            }

            code, decision, stderr = run_shell_hook(
                "user-prompt-agent-docs.sh",
                {"session_id": "cue-guard-test", "prompt": "hello"},
                cwd=repo,
                env=env,
            )
            self.assertNotEqual(code, 0)
            self.assertIsNone(decision)
            self.assertIn("project_dev", stderr)

    def test_preflight_cue_marks_required_doc_overflow(self) -> None:
        self._require_agent_docs()
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            subprocess.run(["git", "init", "-q"], cwd=repo, check=True)
            docs = repo / "docs"
            docs.mkdir()
            entries: list[str] = []
            for index in range(1, 8):
                path = docs / f"doc-{index}.md"
                path.write_text(f"# Doc {index}\n", encoding="utf-8")
                entries.append(
                    '[[document]]\ncontext = "project-dev"\nscope = "project"\n'
                    f'path = "docs/doc-{index}.md"\n'
                    'required = true\nwhen = "always"\n'
                )
            (repo / "AGENT_DOCS.toml").write_text("\n".join(entries), encoding="utf-8")
            home = repo / "home"
            home.mkdir()
            env = {"AGENT_RUNTIME_DOCS_HOME": str(repo), "HOME": str(home)}

            code, decision, stderr = run_shell_hook(
                "user-prompt-agent-docs.sh",
                {"session_id": "cue-overflow-test", "prompt": "hello"},
                cwd=repo,
                env=env,
            )
            self.assertEqual(code, 0, stderr)
            self.assertIsNotNone(decision)
            assert decision is not None
            hook_output = decision.get("hookSpecificOutput", {})
            ctx = ""
            if isinstance(hook_output, dict):
                ctx = str(hook_output.get("additionalContext", ""))
            self.assertIn("doc-1.md", ctx)
            self.assertIn("doc-6.md", ctx)
            self.assertNotIn("doc-7.md", ctx)
            self.assertIn("+1 more", ctx)

    def test_target_hook_fragments_reference_installed_shared_scripts(self) -> None:
        expected_scripts = {
            "agent-scope-lock-guard.py",
            "block-direct-git-commit.py",
            "block-direct-git-worktree.py",
            "block-direct-pr-create.py",
            "block-direct-python.py",
            "block-project-memory-write.py",
            "finish-line-record.py",
            "forge-label-reminder.py",
            "mcp-secret-scan.py",
            "portable-paths-scan.py",
            "semantic-commit-body-gate.py",
            "session-start-healthcheck.sh",
            "skill-usage-reminder.py",
            "stop-finish-line-gate.py",
            "stop-pre-pr-reminder.sh",
            "user-prompt-agent-docs.sh",
        }
        for script in expected_scripts:
            self.assertTrue((HOOK_DIR / script).is_file(), script)

        codex_block = (REPO_ROOT / "targets" / "codex" / "hooks" / "config.block.toml").read_text(
            encoding="utf-8"
        )
        claude_fragment = (REPO_ROOT / "core" / "hooks" / "claude" / "settings.hooks.jsonc").read_text(
            encoding="utf-8"
        )
        for script in expected_scripts:
            self.assertIn(f"hooks/{script}", codex_block)
            self.assertIn(f"hooks/{script}", claude_fragment)

    def test_codex_hook_paths_fall_back_when_codex_home_is_unset(self) -> None:
        codex_block = (REPO_ROOT / "targets" / "codex" / "hooks" / "config.block.toml").read_text(
            encoding="utf-8"
        )
        path_exprs: list[str] = []
        for line in codex_block.splitlines():
            stripped = line.strip()
            if not stripped.startswith("command = "):
                continue
            command = json.loads(stripped.split("=", 1)[1].strip())
            parts = command.split('"')
            self.assertEqual(parts[0], "AGENT_RUNTIME_PRODUCT=codex ")
            self.assertEqual(len(parts), 3)
            path_exprs.append(parts[1])

        self.assertGreater(len(path_exprs), 0)
        for path_expr in path_exprs:
            script_name = path_expr.rsplit("/", 1)[-1]
            completed = subprocess.run(
                [
                    "env",
                    "-u",
                    "CODEX_HOME",
                    "HOME=/Users/example",
                    "sh",
                    "-c",
                    f'printf "%s\\n" "{path_expr}"',
                ],
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(completed.returncode, 0, completed.stderr)
            self.assertEqual(
                completed.stdout.strip(),
                f"/Users/example/.codex/hooks/{script_name}",
            )

    def test_codex_hook_block_source_matches_install_body_template(self) -> None:
        source_block = (REPO_ROOT / "targets" / "codex" / "hooks" / "config.block.toml").read_text(
            encoding="utf-8"
        )
        self.assertEqual(source_block, codex_link_map_hook_body())


if __name__ == "__main__":
    unittest.main(verbosity=2)
