#!/usr/bin/env python3
"""Evaluate deterministic global harness invariants without calling a model."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path


def check(name: str, command: list[str], cwd: Path) -> dict[str, object]:
    result = subprocess.run(command, cwd=cwd, capture_output=True, text=True, timeout=90, check=False)
    return {"name": name, "command": command, "ok": result.returncode == 0, "status": result.returncode, "output": (result.stdout + result.stderr).strip()[-1500:]}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", nargs="?", default=os.getcwd())
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    root = Path(args.path).expanduser().resolve()
    config = Path.home() / ".config/opencode"
    checks = [
        check("effective-config", ["opencode", "debug", "config", "--pure"], config),
        check("capability-doctor", [str(config / "scripts/opencode-capability-doctor")], config),
        check("project-audit", [str(config / "scripts/opencode-project-audit"), str(root), "--json"], config),
        check("task-packet-tool", [str(config / "scripts/opencode-task"), "show", str(root)], config),
        check("project-contract", ["test", "-f", str(root / "AGENTS.md")], config),
        check("project-context", ["test", "-f", str(root / ".opencode/PROJECT_CONTEXT.md")], config),
        check("codegraph", ["test", "-e", str(root / ".codegraph")], config),
    ]
    report = {
        "schema": 1,
        "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "project": root.name,
        "status": "passed" if all(item["ok"] for item in checks) else "failed",
        "checks": checks,
    }
    output = json.dumps(report, indent=2)
    if args.json:
        print(output)
    else:
        print(f"Harness evaluation: {report['status']}")
        for item in checks:
            print(f"{'PASS' if item['ok'] else 'FAIL'} {item['name']}")
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    raise SystemExit(main())
