#!/usr/bin/env python3
"""Read-only project contract and capability audit for the global harness."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path


def command_exists(name: str) -> bool:
    return subprocess.run(
        ["sh", "-lc", f"command -v {name} >/dev/null 2>&1"],
        check=False,
    ).returncode == 0


def detect(root: Path) -> dict[str, object]:
    names = {path.name for path in root.iterdir()} if root.is_dir() else set()
    wp = (root / "wp-content").is_dir() or (root / "wp-config.php").exists()
    node = (root / "package.json").exists()
    python_project = any((root / name).exists() for name in ("pyproject.toml", "setup.py", "requirements.txt"))
    go = (root / "go.mod").exists()
    rust = (root / "Cargo.toml").exists()
    frontend = node or wp or (root / "index.html").exists()

    artifacts = {
        "AGENTS.md": (root / "AGENTS.md").exists(),
        "PROJECT_CONTEXT.md": (root / "PROJECT_CONTEXT.md").exists()
        or (root / ".opencode" / "PROJECT_CONTEXT.md").exists(),
        ".codegraph": (root / ".codegraph").exists(),
        ".opencode/MANIFEST.md": (root / ".opencode" / "MANIFEST.md").exists(),
        "tests": (root / "tests").is_dir() or (root / "test").is_dir(),
        "CI": (root / ".github" / "workflows").is_dir(),
    }

    capabilities: list[str] = []
    if wp:
        capabilities.extend(["wp-wpcli-and-ops", "wp-performance"])
    if frontend:
        capabilities.append("playwright")
    if node:
        capabilities.append("javascript-tooling")
    if python_project:
        capabilities.append("python-tooling")
    if go:
        capabilities.append("go-tooling")
    if rust:
        capabilities.append("rust-tooling")
    if (root / ".git").exists():
        capabilities.append("code-review-graph")

    risks: list[str] = []
    if (root / ".env").exists():
        risks.append("project .env exists; keep it out of memory and generated artifacts")
    if (root / "wp-config.php").exists():
        risks.append("WordPress config may contain credentials; do not ingest raw contents")
    if (root / ".opencode" / "node_modules").exists():
        risks.append("project-local node_modules present; exclude from scans and memory")
    try:
        status = subprocess.run(
            ["git", "-C", str(root), "status", "--short"],
            check=False,
            capture_output=True,
            text=True,
        )
        dirty = bool(status.stdout.strip())
    except OSError:
        dirty = False
    if dirty:
        risks.append("worktree is dirty; preserve existing changes")

    required = [name for name, present in artifacts.items() if name in ("PROJECT_CONTEXT.md", ".codegraph") and not present]
    recommended = [name for name, present in artifacts.items() if name in ("AGENTS.md", ".opencode/MANIFEST.md", "tests") and not present]

    return {
        "project": root.name,
        "root": str(root),
        "stack": {
            "wordpress": wp,
            "node": node,
            "python": python_project,
            "go": go,
            "rust": rust,
            "frontend": frontend,
        },
        "artifacts": artifacts,
        "requiredMissing": required,
        "recommendedMissing": recommended,
        "capabilities": sorted(set(capabilities)),
        "risks": risks,
        "tools": {name: command_exists(name) for name in ("opencode", "engram", "dcg", "wp", "node", "npx")},
        "mode": "read-only-audit",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", nargs="?", default=os.getcwd())
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--write-proposal", action="store_true")
    args = parser.parse_args()
    root = Path(args.path).expanduser().resolve()
    if not root.is_dir():
        print(f"project root does not exist: {root}", file=sys.stderr)
        return 2
    report = detect(root)
    if args.write_proposal:
        target = root / ".opencode" / "harness-proposal.json"
        if target.exists():
            print(f"proposal already exists; refusing to overwrite: {target}", file=sys.stderr)
            return 3
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        report["proposal"] = str(target)
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print(f"Project: {report['project']} ({report['root']})")
        print(f"Mode: {report['mode']}")
        print(f"Capabilities: {', '.join(report['capabilities']) or 'none detected'}")
        print(f"Required missing: {', '.join(report['requiredMissing']) or 'none'}")
        print(f"Recommended missing: {', '.join(report['recommendedMissing']) or 'none'}")
        for risk in report["risks"]:
            print(f"Risk: {risk}")
        if args.write_proposal:
            print(f"Proposal: {report['proposal']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
