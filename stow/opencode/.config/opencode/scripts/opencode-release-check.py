#!/usr/bin/env python3
"""Run the no-commit release gate for a project."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path


def run(command: list[str], cwd: Path) -> dict[str, object]:
    try:
        result = subprocess.run(command, cwd=cwd, capture_output=True, text=True, timeout=600, check=False)
        return {"command": command, "status": result.returncode, "ok": result.returncode == 0, "output": (result.stdout + result.stderr).strip()[-4000:]}
    except (OSError, subprocess.TimeoutExpired) as error:
        return {"command": command, "status": 124, "ok": False, "output": str(error)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", nargs="?", default=os.getcwd())
    args = parser.parse_args()
    root = Path(args.path).expanduser().resolve()
    config = Path.home() / ".config/opencode"
    checks = [
        run([str(config / "scripts/opencode-verify"), str(root), "--run-tests"], config),
        run([str(config / "scripts/opencode-security-audit"), str(root)], config),
    ]
    task_file = root / ".opencode/state/task.json"
    task = {}
    if task_file.exists():
        try:
            task = json.loads(task_file.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            task = {"status": "invalid"}
    task_ok = bool(task) and task.get("status") in {"verified", "completed"}
    checks.append({"command": ["task-packet-status"], "status": 0 if task_ok else 1, "ok": task_ok, "output": str(task.get("status", "missing"))})
    report = {
        "schema": 1,
        "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "project": root.name,
        "root": str(root),
        "status": "passed" if all(item["ok"] for item in checks) else "blocked",
        "checks": checks,
        "note": "No commit, push, deploy, reset, or cleanup was performed.",
    }
    artifact_dir = root / ".opencode" / "artifacts"
    artifact_dir.mkdir(parents=True, exist_ok=True)
    report_path = artifact_dir / f"release-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"Release gate: {report['status']}")
    print(f"Report: {report_path}")
    for item in checks:
        print(f"{'PASS' if item['ok'] else 'FAIL'}: {' '.join(item['command'])}")
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    raise SystemExit(main())
