#!/usr/bin/env python3
"""Create and inspect a durable, project-local OpenCode task packet."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


def now() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def root_from(path: str) -> Path:
    return Path(path).expanduser().resolve()


def packet_path(root: Path) -> Path:
    return root / ".opencode" / "state" / "task.json"


def git_status(root: Path) -> list[str]:
    result = subprocess.run(
        ["git", "-C", str(root), "status", "--short"],
        capture_output=True,
        text=True,
        check=False,
    )
    return result.stdout.splitlines()


def load(path: Path) -> dict[str, object]:
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    init = sub.add_parser("init")
    init.add_argument("path", nargs="?", default=os.getcwd())
    init.add_argument("--title", required=True)
    init.add_argument("--kind", default="implementation")
    init.add_argument("--risk", choices=("low", "medium", "high"), default="medium")

    show = sub.add_parser("show")
    show.add_argument("path", nargs="?", default=os.getcwd())

    update = sub.add_parser("update")
    update.add_argument("path", nargs="?", default=os.getcwd())
    update.add_argument("--phase")
    update.add_argument("--note")
    update.add_argument("--status", choices=("planned", "in_progress", "blocked", "verified", "completed"))

    args = parser.parse_args()
    root = root_from(args.path)
    target = packet_path(root)

    if args.command == "init":
        if target.exists():
            print(f"Refusing to overwrite existing task packet: {target}", file=sys.stderr)
            return 3
        target.parent.mkdir(parents=True, exist_ok=True)
        packet = {
            "schema": 1,
            "id": f"{root.name}-{datetime.now().strftime('%Y%m%d-%H%M%S')}",
            "project": root.name,
            "root": str(root),
            "title": args.title,
            "kind": args.kind,
            "risk": args.risk,
            "status": "planned",
            "phase": "discovery",
            "createdAt": now(),
            "updatedAt": now(),
            "doneCriteria": [],
            "changedFiles": [],
            "commands": [],
            "verification": [],
            "fallbacks": [],
            "risks": [],
            "notes": [],
            "initialDirtyWorktree": git_status(root),
        }
        target.write_text(json.dumps(packet, indent=2) + "\n", encoding="utf-8")
        print(target)
        return 0

    if not target.exists():
        print(f"No task packet found: {target}", file=sys.stderr)
        return 2
    packet = load(target)
    if args.command == "show":
        print(json.dumps(packet, indent=2))
        return 0

    if args.phase:
        packet["phase"] = args.phase
    if args.status:
        packet["status"] = args.status
    if args.note:
        notes = packet.setdefault("notes", [])
        if isinstance(notes, list):
            notes.append({"at": now(), "text": args.note})
    packet["updatedAt"] = now()
    target.write_text(json.dumps(packet, indent=2) + "\n", encoding="utf-8")
    print(target)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
