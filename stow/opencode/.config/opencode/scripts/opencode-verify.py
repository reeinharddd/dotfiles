#!/usr/bin/env python3
"""Run conservative, stack-aware verification and emit a machine-readable report."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


def command(args: list[str], cwd: Path, timeout: int = 120) -> dict[str, object]:
    try:
        result = subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=timeout, check=False)
    except (OSError, subprocess.TimeoutExpired) as error:
        return {"command": args, "status": 124, "ok": False, "output": str(error)}
    output = (result.stdout + result.stderr).strip()
    return {"command": args, "status": result.returncode, "ok": result.returncode == 0, "output": output[-8000:]}


def files_changed(root: Path) -> list[str]:
    tracked = command(["git", "diff", "--name-only", "--diff-filter=ACMRT"], root, 30)["output"]
    untracked = command(["git", "ls-files", "--others", "--exclude-standard"], root, 30)["output"]
    values = set(str(tracked).splitlines()) | set(str(untracked).splitlines())
    return sorted(
        value for value in values
        if value
        and not value.startswith(".git/")
        and not value.startswith(".opencode/artifacts/")
        and "__pycache__/" not in value
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", nargs="?", default=os.getcwd())
    parser.add_argument("--run-tests", action="store_true", help="run detected project tests")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    root = Path(args.path).expanduser().resolve()
    checks: list[dict[str, object]] = []
    changed = files_changed(root)

    checks.append(command(["git", "diff", "--check"], root, 30))
    secret_scan = command(
        [
            "rg",
            "-n",
            "(api_key|apiKey|secret|token|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY)",
            *changed,
        ],
        root,
        30,
    ) if changed else {"command": ["secret-scan"], "status": 0, "ok": True, "output": "no changed files"}
    secret_scan["name"] = "changed-file-sensitive-pattern-scan"
    secret_scan["ok"] = secret_scan["status"] in (0, 1)
    if secret_scan["status"] == 0:
        secret_scan["warning"] = "review matches manually; generic names are not proof of a secret"
    checks.append(secret_scan)

    for relative in changed:
        path = root / relative
        if path.suffix == ".php" and path.is_file():
            checks.append(command(["php", "-l", str(path)], root, 30))
        if path.suffix == ".py" and path.is_file():
            checks.append(command(["python3", "-m", "py_compile", str(path)], root, 30))

    browser_script = root / "tests" / "test_shop_button.py"
    if browser_script.exists():
        checks.append(command(["python3", str(browser_script)], root, 120))

    if args.run_tests:
        if (root / "pytest.ini").exists() or (root / "pyproject.toml").exists() or list((root / "tests").glob("test_*.py")):
            checks.append(command(["pytest", "-q"], root, 300))
        elif (root / "package.json").exists():
            checks.append(command(["npm", "test", "--", "--runInBand"], root, 300))
        elif (root / "go.mod").exists():
            checks.append(command(["go", "test", "./..."], root, 300))
        elif (root / "Cargo.toml").exists():
            checks.append(command(["cargo", "test"], root, 300))
        else:
            checks.append({
                "command": ["project-tests"],
                "status": 0,
                "ok": True,
                "skipped": True,
                "output": "no supported test manifest detected; standalone and stack-specific checks still ran",
            })

    failures = [item for item in checks if not item.get("ok", False)]
    report = {
        "schema": 1,
        "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "project": root.name,
        "root": str(root),
        "changedFiles": changed,
        "status": "passed" if not failures else "failed",
        "checks": checks,
        "failureCount": len(failures),
    }
    artifact_dir = root / ".opencode" / "artifacts"
    artifact_dir.mkdir(parents=True, exist_ok=True)
    report_path = artifact_dir / f"verify-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print(f"Verification: {report['status']}")
        print(f"Changed files: {len(changed)}")
        for item in checks:
            label = "PASS" if item.get("ok") else "FAIL"
            print(f"{label}: {' '.join(item['command'])}")
        print(f"Report: {report_path}")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
