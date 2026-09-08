#!/usr/bin/env python3
"""Plan or create an isolated git worktree without deleting or resetting data."""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path


def run(root: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(["git", "-C", str(root), *args], capture_output=True, text=True, check=False)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", nargs="?", default=os.getcwd())
    parser.add_argument("--name", required=True, help="short task name used in branch and path")
    parser.add_argument("--base", default="HEAD")
    parser.add_argument("--create", action="store_true", help="actually create the worktree")
    parser.add_argument("--root", help="parent directory for worktrees")
    args = parser.parse_args()

    root = Path(args.path).expanduser().resolve()
    git = run(root, "rev-parse", "--show-toplevel")
    if git.returncode != 0:
        print("not a git worktree", file=sys.stderr)
        return 2
    repo = Path(git.stdout.strip())
    safe_name = "".join(c if c.isalnum() or c in "-_" else "-" for c in args.name).strip("-")
    if not safe_name:
        print("invalid empty worktree name", file=sys.stderr)
        return 2
    parent = Path(args.root).expanduser().resolve() if args.root else repo.parent / ".opencode-worktrees"
    target = parent / safe_name
    branch = f"opencode/{safe_name}"
    status = run(repo, "status", "--short")
    dirty = bool(status.stdout.strip())
    print(f"repository: {repo}")
    print(f"worktree: {target}")
    print(f"branch: {branch}")
    print(f"base: {args.base}")
    print(f"source dirty: {'yes' if dirty else 'no'}")
    if not args.create:
        print("mode: plan-only; pass --create to make the isolated worktree")
        return 0
    if target.exists():
        print(f"refusing to overwrite existing path: {target}", file=sys.stderr)
        return 3
    parent.mkdir(parents=True, exist_ok=True)
    result = run(repo, "worktree", "add", "-b", branch, str(target), args.base)
    if result.returncode != 0:
        print(result.stderr, file=sys.stderr)
        return result.returncode
    print(result.stdout, end="")
    print("note: pre-existing dirty changes were intentionally not copied")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
