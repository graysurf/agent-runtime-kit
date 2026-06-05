#!/usr/bin/env python3
"""Read-only triage of a repo's git worktrees against a base ref.

Enumerates every linked worktree, classifies each by how its branch relates to
the base ref (default ``origin/main``), and emits a structured envelope the
``worktree-triage`` skill reasons over. The script never mutates anything: it
does not fetch, remove worktrees, delete branches, or touch the index.

Dispositions
------------
- ``primary``         the repo's primary working tree; never a removal target.
- ``dirty``           uncommitted changes present; blocked from removal so the
                      caller cannot lose in-progress work.
- ``locked``          worktree is git-locked; surfaced, never auto-removed.
- ``safe-merged``     branch tip is an ancestor of the base (nothing ahead);
                      its history is fully in the base. Safe to prune.
- ``safe-superseded`` branch is ahead by commit SHA, but every commit is
                      patch-equivalent to one already in the base (``git
                      cherry`` reports them all as ``-``). Safe to prune.
- ``rescue-candidate``branch has commits whose patch is NOT in the base. This
                      MAY still be already-on-base content that arrived via a
                      different commit (patch-id is unreliable — see the net
                      two-dot diff in ``evidence``), or it may be genuine
                      unmerged work. Requires human judgment; never auto-pruned.

The ``rescue-candidate`` evidence deliberately carries the two-dot
``git diff <base> <tip>`` shortstat (insertions/deletions/``net_subtractive``):
when a branch was cut from old base and its work already landed on the base via
another PR, that diff is empty or purely subtractive even though ``git cherry``
still lists the commits as unique. That is exactly the signal a reviewer needs.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys

SCHEMA = "worktree-triage.scan.v1"


class GitError(RuntimeError):
    pass


def git(repo: str, *args: str, check: bool = True) -> str:
    proc = subprocess.run(
        ["git", "-C", repo, *args],
        capture_output=True,
        text=True,
    )
    if check and proc.returncode != 0:
        raise GitError(
            f"git {' '.join(args)} failed ({proc.returncode}): {proc.stderr.strip()}"
        )
    return proc.stdout


def parse_worktrees(repo: str) -> list[dict]:
    """Parse ``git worktree list --porcelain`` into structured records."""
    raw = git(repo, "worktree", "list", "--porcelain")
    entries: list[dict] = []
    current: dict = {}
    for line in raw.splitlines():
        if not line:
            if current:
                entries.append(current)
                current = {}
            continue
        if line.startswith("worktree "):
            current = {"path": line[len("worktree ") :]}
        elif line.startswith("HEAD "):
            current["head"] = line[len("HEAD ") :]
        elif line.startswith("branch "):
            ref = line[len("branch ") :]
            current["branch"] = ref.removeprefix("refs/heads/")
        elif line == "detached":
            current["detached"] = True
        elif line == "bare":
            current["bare"] = True
        elif line.startswith("locked"):
            current["locked"] = True
    if current:
        entries.append(current)
    return entries


def rev_count(repo: str, range_spec: str) -> int:
    out = git(repo, "rev-list", "--count", range_spec, check=False).strip()
    return int(out) if out.isdigit() else 0


def is_ancestor(repo: str, ancestor: str, descendant: str) -> bool:
    proc = subprocess.run(
        ["git", "-C", repo, "merge-base", "--is-ancestor", ancestor, descendant],
        capture_output=True,
        text=True,
    )
    return proc.returncode == 0


def cherry_unique_commits(repo: str, base: str, tip: str) -> list[str]:
    """Commits on ``tip`` whose patch is NOT already in ``base`` (cherry ``+``)."""
    out = git(repo, "cherry", "-v", base, tip, check=False)
    unique = []
    for line in out.splitlines():
        if line.startswith("+ "):
            # "+ <sha> <subject>"
            parts = line[2:].split(" ", 1)
            unique.append(parts[1] if len(parts) > 1 else parts[0])
    return unique


def two_dot_shortstat(repo: str, base: str, tip: str) -> dict:
    """Insertions/deletions for the full ``base..tip`` content delta.

    This is the supersession tell: a branch already represented on ``base`` via
    another commit shows an empty or purely-subtractive diff here even when
    ``git cherry`` still lists its commits as unique.
    """
    numstat = git(repo, "diff", "--numstat", base, tip, check=False)
    insertions = deletions = files = 0
    for line in numstat.splitlines():
        cols = line.split("\t")
        if len(cols) < 3:
            continue
        files += 1
        if cols[0].isdigit():
            insertions += int(cols[0])
        if cols[1].isdigit():
            deletions += int(cols[1])
    return {
        "files": files,
        "insertions": insertions,
        "deletions": deletions,
        "net_subtractive": deletions > insertions,
        "identical": files == 0,
    }


def is_dirty(repo: str) -> bool:
    return bool(git(repo, "status", "--porcelain", check=False).strip())


def classify(repo: str, base: str, wt: dict, primary_path: str) -> dict:
    path = wt["path"]
    branch = wt.get("branch")
    tip = wt.get("head", branch or "HEAD")
    record: dict = {
        "path": path,
        "branch": branch,
        "head": wt.get("head"),
        "detached": wt.get("detached", False),
        "is_primary": os.path.realpath(path) == os.path.realpath(primary_path),
        "locked": wt.get("locked", False),
    }

    # Primary worktree and locked worktrees are surfaced but never removal
    # targets — pruning the primary tree or a deliberately locked one is never
    # safe to automate.
    if record["is_primary"]:
        record["disposition"] = "primary"
        record["suggested_action"] = "leave in place (primary working tree)"
        return record

    dirty = is_dirty(path)
    record["dirty"] = dirty
    if dirty:
        record["disposition"] = "dirty"
        record["suggested_action"] = (
            "inspect uncommitted changes; commit or discard before removing"
        )
        return record
    if record["locked"]:
        record["disposition"] = "locked"
        record["suggested_action"] = "git worktree unlock first if intentional"
        return record

    ahead = rev_count(repo, f"{base}..{tip}")
    behind = rev_count(repo, f"{tip}..{base}")
    record["ahead"] = ahead
    record["behind"] = behind

    if ahead == 0 and is_ancestor(repo, tip, base):
        record["disposition"] = "safe-merged"
        record["suggested_action"] = (
            "git-cli worktree remove + delete branch (fully in base)"
        )
        return record

    unique = cherry_unique_commits(repo, base, tip)
    record["unique_commit_count"] = len(unique)
    if not unique:
        record["disposition"] = "safe-superseded"
        record["suggested_action"] = (
            "git-cli worktree remove + delete branch "
            "(all commits patch-equivalent in base)"
        )
        return record

    # Has commits whose patch is not in base. Attach the two-dot net diff so the
    # caller can tell genuine unmerged work from content that reached base via a
    # different commit (patch-id false-positive).
    evidence = two_dot_shortstat(repo, base, tip)
    evidence["sample_unique_commits"] = unique[:8]
    record["evidence"] = evidence
    record["disposition"] = "rescue-candidate"
    if evidence["identical"] or evidence["net_subtractive"]:
        record["suggested_action"] = (
            "likely already on base via another commit (net diff is "
            f"{'empty' if evidence['identical'] else 'subtractive'}); "
            "review then close/discard"
        )
        record["likely_superseded"] = True
    else:
        record["suggested_action"] = (
            "open a draft PR for review (carries unique content not in base)"
        )
        record["likely_superseded"] = False
    return record


def render_text(envelope: dict) -> str:
    s = envelope["summary"]
    lines = [
        f"base: {envelope['base']}   worktrees: {s['total']}",
        (
            f"  safe-merged={s.get('safe-merged', 0)} "
            f"safe-superseded={s.get('safe-superseded', 0)} "
            f"rescue-candidate={s.get('rescue-candidate', 0)} "
            f"dirty={s.get('dirty', 0)} locked={s.get('locked', 0)} "
            f"primary={s.get('primary', 0)}"
        ),
        "",
    ]
    for wt in envelope["worktrees"]:
        head = (wt.get("branch") or wt.get("head", "")[:12]) or "(detached)"
        extra = ""
        if "ahead" in wt:
            extra = f" [ahead {wt['ahead']}, behind {wt['behind']}]"
        ev = wt.get("evidence")
        if ev:
            extra += f" net(+{ev['insertions']}/-{ev['deletions']})"
        lines.append(f"  {wt['disposition']:<18} {head}{extra}")
        lines.append(f"      {wt['path']}")
        lines.append(f"      -> {wt['suggested_action']}")
    return "\n".join(lines)


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Read-only git worktree triage.")
    parser.add_argument("--repo", default=".", help="repo root (default: cwd)")
    parser.add_argument(
        "--base",
        default="origin/main",
        help="base ref to classify against (default: origin/main)",
    )
    parser.add_argument(
        "--format", choices=["text", "json"], default="text", help="output format"
    )
    args = parser.parse_args(argv)

    repo = args.repo
    try:
        git(repo, "rev-parse", "--git-dir")
    except GitError as exc:
        print(f"worktree-triage: not a git repo: {exc}", file=sys.stderr)
        return 1
    # Confirm the base ref resolves; a missing origin/main is the most common
    # caller mistake (forgot to fetch / different default branch).
    if not git(repo, "rev-parse", "--verify", "--quiet", args.base, check=False).strip():
        print(
            f"worktree-triage: base ref '{args.base}' not found "
            "(fetch first, or pass --base)",
            file=sys.stderr,
        )
        return 1

    worktrees = parse_worktrees(repo)
    primary_path = worktrees[0]["path"] if worktrees else repo
    records = [classify(repo, args.base, wt, primary_path) for wt in worktrees]

    summary = {"total": len(records)}
    for rec in records:
        summary[rec["disposition"]] = summary.get(rec["disposition"], 0) + 1

    envelope = {
        "schema_version": SCHEMA,
        "base": args.base,
        "summary": summary,
        "worktrees": records,
    }

    if args.format == "json":
        print(json.dumps(envelope, indent=2))
    else:
        print(render_text(envelope))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
