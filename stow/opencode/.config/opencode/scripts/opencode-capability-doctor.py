#!/usr/bin/env python3
"""Validate global OpenCode capabilities without starting or mutating MCP servers."""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import json
from pathlib import Path


INLINE_SECRET = re.compile(r'"apiKey"\s*:\s*"(?:sk-|gsk_|AQ\.|gho_|eyJ|jRS|csk-)')
REQUIRED_TOOLS = ("opencode", "engram", "dcg", "node", "npx", "uvx")
ENV_KEYS = ("OPENCODE_ZEN_API_KEY", "TOKENROUTER_API_KEY", "MISTRAL_API_KEY", "GOOGLE_API_KEY", "NVIDIA_API_KEY", "OPENROUTER_API_KEY", "GITHUB_TOKEN")
REQUIRED_AGENTS = ("oracle", "smart", "build", "fast", "plan", "code-reviewer", "security-reviewer", "explore", "subagent-orchestrator", "vision")
REQUIRED_MCPS = ("context7", "engram", "firecrawl", "codebase-memory", "sequential-thinking", "playwright")


def check_config(config: Path) -> list[str]:
    errors: list[str] = []
    if not config.exists():
        return [f"missing config: {config}"]
    content = config.read_text(encoding="utf-8", errors="replace")
    if INLINE_SECRET.search(content):
        errors.append(f"inline provider credential detected: {config}")
    mode = config.stat().st_mode & 0o777
    if mode != 0o600:
        errors.append(f"config mode must be 600, got {oct(mode)}: {config}")
    enabled_match = re.search(r'"enabled_providers"s*:s*[(.*?)]', content, re.DOTALL)
    if enabled_match and re.search(r'"opencode"s*,?', enabled_match.group(1)):
        errors.append(f"native opencode provider must stay disabled: {config}")
    if re.search(r'"model"s*:s*"opencode/', content):
        errors.append(f"native opencode model route detected: {config}")
    return errors


def check_omo_routes(config: Path) -> list[str]:
    omo = config.parent / "oh-my-openagent.json"
    if not omo.exists():
        return []
    try:
        data = json.loads(omo.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return [f"invalid oh-my-openagent.json: {exc}"]
    routes: list[tuple[str, str]] = []
    for group in ("agents", "categories"):
        for name, value in data.get(group, {}).items():
            if not isinstance(value, dict):
                continue
            models = [value.get("model")]
            models.extend(
                item if isinstance(item, str) else item.get("model")
                for item in value.get("fallback_models", [])
            )
            routes.extend((f"{group}.{name}", model) for model in models if model)
    errors = []
    native = [f"{where}={model}" for where, model in routes if model.startswith("opencode/")]
    paid_zen = [
        f"{where}={model}"
        for where, model in routes
        if model.startswith("opencode-zen/") and not model.endswith("-free")
    ]
    if native:
        errors.append("native opencode routes detected: " + ", ".join(native))
    if paid_zen:
        errors.append("non-free Zen routes detected: " + ", ".join(paid_zen))
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", default=str(Path.home() / ".config/opencode/opencode.jsonc"))
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    config = Path(args.config).expanduser()
    checks: dict[str, object] = {"config": str(config), "errors": [], "warnings": [], "tools": {}}
    errors = checks["errors"]
    warnings = checks["warnings"]
    errors.extend(check_config(config))
    errors.extend(check_omo_routes(config))

    for tool in REQUIRED_TOOLS:
        path = shutil.which(tool)
        checks["tools"][tool] = path or False
        if not path:
            warnings.append(f"missing optional/required binary: {tool}")

    env_file = config.parent / "opencode.env"
    env_text = env_file.read_text(encoding="utf-8", errors="replace") if env_file.exists() else ""
    env_names = {line.split("=", 1)[0] for line in env_text.splitlines() if line and not line.startswith("#") and "=" in line}
    missing_env = [name for name in ENV_KEYS if name not in os.environ and name not in env_names]
    if missing_env:
        warnings.append("missing provider environment names: " + ", ".join(missing_env))
    if env_file.exists() and (env_file.stat().st_mode & 0o777) != 0o600:
        errors.append(f"private env file mode must be 600: {env_file}")

    try:
        result = subprocess.run(
            ["opencode", "debug", "config", "--pure"],
            check=False,
            capture_output=True,
            text=True,
            timeout=15,
        )
        checks["effectiveConfig"] = result.returncode == 0
        if result.returncode != 0:
            errors.append("opencode debug config failed")
        else:
            # The resolved config can exceed OpenCode's diagnostic output limit. Inventory the
            # source-of-truth files instead of treating a truncated diagnostic as corruption.
            source = config.read_text(encoding="utf-8", errors="replace")
            checks["agents"] = {name: bool(re.search(rf'"{re.escape(name)}"\s*:\s*\{{', source)) for name in REQUIRED_AGENTS}
            checks["mcps"] = {name: bool(re.search(rf'"{re.escape(name)}"\s*:\s*\{{[\s\S]*?"enabled"\s*:\s*true', source)) for name in REQUIRED_MCPS}
            checks["skillRoots"] = [str(config.parent / "plugins/bodega-global-skills.json")] if (config.parent / "plugins/bodega-global-skills.json").exists() else []
            missing_agents = [name for name, present in checks["agents"].items() if not present]
            missing_mcps = [name for name, enabled in checks["mcps"].items() if not enabled]
            if missing_agents:
                errors.append("required agents missing: " + ", ".join(missing_agents))
            if missing_mcps:
                errors.append("required MCPs disabled/missing: " + ", ".join(missing_mcps))
            if not checks["skillRoots"]:
                errors.append("no skill manifest found")
    except (OSError, subprocess.TimeoutExpired):
        checks["effectiveConfig"] = False
        errors.append("could not execute opencode debug config")

    checks["status"] = "healthy" if not errors else "degraded"
    if args.json:
        print(json.dumps(checks, indent=2))
    else:
        print(f"OpenCode capability doctor: {checks['status']}")
        for tool, path in checks["tools"].items():
            print(f"  {'OK' if path else 'WARN'} {tool}")
        for item in errors:
            print(f"  FAIL {item}")
        for item in warnings:
            print(f"  WARN {item}")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
