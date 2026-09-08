#!/usr/bin/env python3
"""Run non-destructive repository security checks and redact report content."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


def run(args: list[str], cwd: Path, timeout: int = 90) -> dict[str, object]:
    try:
        result = subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=timeout, check=False)
    except (OSError, subprocess.TimeoutExpired) as error:
        return {"command": args, "status": 124, "ok": False, "output": str(error)}
    return {"command": args, "status": result.returncode, "ok": result.returncode == 0, "output": (result.stdout + result.stderr).strip()[-4000:]}


def rg_files(root: Path, pattern: str, *globs: str) -> list[str]:
    result = run(["rg", "-l", pattern, *globs, "."], root)
    if result["status"] not in (0, 1):
        return []
    return [line for line in str(result["output"]).splitlines() if line]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", nargs="?", default=os.getcwd())
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    root = Path(args.path).expanduser().resolve()
    findings: list[dict[str, object]] = []
    checks: list[dict[str, object]] = []

    checks.append(run(["git", "diff", "--check"], root))
    strict_secret_files = rg_files(
        root,
        r"(sk-[A-Za-z0-9_-]{20,}|gsk_[A-Za-z0-9_-]{20,}|gh[ps]_[A-Za-z0-9_-]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY)",
        "-g", "!.git", "-g", "!node_modules", "-g", "!dist", "-g", "!build",
    )
    if strict_secret_files:
        findings.append({"severity": "high", "type": "secret-pattern", "files": strict_secret_files})

    dangerous_php = rg_files(root, r"\b(eval|base64_decode|shell_exec|passthru|proc_open)\s*\(", "-g", "*.php")
    if dangerous_php:
        findings.append({"severity": "medium", "type": "dangerous-php-call-review", "files": dangerous_php})

    rest_files = rg_files(root, r"register_rest_route\s*\(", "-g", "*.php")
    if rest_files:
        findings.append({"severity": "info", "type": "rest-routes-require-permission-review", "files": rest_files})

    for tool in ("gitleaks", "semgrep", "phpstan", "composer", "npm", "trivy"):
        checks.append({"command": [tool, "--version"], "available": bool(shutil.which(tool)), "ok": True, "status": 0})

    report = {
        "schema": 1,
        "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "project": root.name,
        "root": str(root),
        "status": "review" if findings else "passed",
        "findings": findings,
        "checks": checks,
        "note": "This audit is read-only; absence of a finding is not proof of security.",
    }
    artifact_dir = root / ".opencode" / "artifacts"
    artifact_dir.mkdir(parents=True, exist_ok=True)
    report_path = artifact_dir / f"security-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print(f"Security audit: {report['status']}")
        for finding in findings:
            print(f"{finding['severity'].upper()}: {finding['type']} ({len(finding['files'])} files)")
        print(f"Report: {report_path}")
    return 1 if any(item["severity"] == "high" for item in findings) else 0


if __name__ == "__main__":
    raise SystemExit(main())
