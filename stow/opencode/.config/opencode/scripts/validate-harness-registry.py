#!/usr/bin/env python3
"""Validate harness-registry.jsonc structural invariants.

Enforces the structural contract defined by OLA 12:
  1. Required top-level keys present
  2. mcpPolicy: no overlap between alwaysOn and onDemand
  3. mcpPolicy: neverGlobalByDefault ⊆ onDemand
  4. mcpPolicy: alwaysOn MCPs exist in opencode.jsonc mcp{}
  5. pinnedTools versions match opencode.jsonc npx pins and plugin[] pins
  6. Routing object has valid structure
  7. No duplicate MCP across policy lists

Exit 0 + PASS when valid. Exit 1 + list violations when invalid.
Supports --quiet for CI. No network, no secrets in output.
"""

from __future__ import annotations

import argparse
import json
import json5
import re
import sys
from pathlib import Path
from typing import Any


REGISTRY_PATH = Path(__file__).parent.parent / "harness-registry.jsonc"
OPENCODE_PATH = Path(__file__).parent.parent / "opencode.jsonc"

REQUIRED_TOP_LEVEL = [
    "sourceOfTruth", "policy", "lifecycle", "security",
    "projectContract", "routing", "mcpPolicy", "pinnedTools", "retention",
]
REQUIRED_MCP_POLICY = ["alwaysOn", "onDemand"]


def load_jsonc(path: Path) -> dict[str, Any]:
    """Load a .jsonc file using json5 (handles comments)."""
    text = path.read_text(encoding="utf-8")
    return json5.loads(text)


def get_npx_version(command: list[str]) -> str | None:
    """Extract version from an npx command like ['npx', '-y', '@pkg@1.2.3']."""
    for arg in command:
        m = re.match(r'^@?[^@]+@(.+)$', arg)
        if m:
            return m.group(1)
    return None


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate harness-registry.jsonc structural invariants"
    )
    parser.add_argument("--quiet", action="store_true", help="Suppress non-error output")
    parser.add_argument(
        "--registry", default=str(REGISTRY_PATH), help="Path to harness-registry.jsonc"
    )
    parser.add_argument(
        "--opencode", default=str(OPENCODE_PATH), help="Path to opencode.jsonc"
    )
    args = parser.parse_args()

    violations: list[str] = []

    registry = load_jsonc(Path(args.registry))
    opencode = load_jsonc(Path(args.opencode))

    # ── 1. Required top-level keys ────────────────────────────────
    missing_keys = [k for k in REQUIRED_TOP_LEVEL if k not in registry]
    for k in missing_keys:
        violations.append(f"Missing required top-level key: '{k}'")

    # ── 2. Required mcpPolicy sub-keys ────────────────────────────
    mcp_policy = registry.get("mcpPolicy", {})
    missing_mcp = [k for k in REQUIRED_MCP_POLICY if k not in mcp_policy]
    for k in missing_mcp:
        violations.append(f"Missing required mcpPolicy key: '{k}'")

    # ── 3. No overlap between alwaysOn and onDemand ──────────────
    always_on = set(mcp_policy.get("alwaysOn", []))
    on_demand = set(mcp_policy.get("onDemand", []))
    never_global = set(mcp_policy.get("neverGlobalByDefault", []))

    overlap = always_on & on_demand
    for mcp in sorted(overlap):
        violations.append(f"mcpPolicy overlap: '{mcp}' in both alwaysOn and onDemand")

    # ── 4. neverGlobalByDefault ⊆ onDemand ────────────────────────
    not_in_ondemand = never_global - on_demand
    for mcp in sorted(not_in_ondemand):
        violations.append(
            f"neverGlobalByDefault '{mcp}' not in onDemand"
        )

    MCP_TO_PACKAGE = {
    "sequential-thinking": "@modelcontextprotocol/server-sequential-thinking",
    "github": "@modelcontextprotocol/server-github",
    "playwright": "@playwright/mcp",
    "filesystem": "@modelcontextprotocol/server-filesystem",
}

    # ── 5. alwaysOn MCPs must exist in opencode.jsonc mcp{} ───────
    opencode_mcp = opencode.get("mcp", {})
    opencode_mcp_names = set(opencode_mcp.keys())
    for mcp in sorted(always_on):
        if mcp not in opencode_mcp_names:
            violations.append(
                f"alwaysOn MCP '{mcp}' not found in opencode.jsonc mcp{{}}"
            )

    # ── 6. pinnedTools version alignment ──────────────────────────
    pinned_tools = registry.get("pinnedTools", {})
    opencode_plugins = opencode.get("plugin", [])

    # Build map from plugin string to version
    plugin_versions: dict[str, str] = {}
    for p in opencode_plugins:
        m = re.match(r'^(@?[^@]+)@(.+)$', p.strip())
        if m:
            plugin_versions[m.group(1)] = m.group(2)

    # Check npx pins in opencode.jsonc mcp{} against pinnedTools
    for mcp_name, mcp_conf in opencode_mcp.items():
        if isinstance(mcp_conf, dict):
            cmd = mcp_conf.get("command", [])
            npx_ver = get_npx_version(cmd) if isinstance(cmd, list) else None
            if npx_ver:
                pkg_name = MCP_TO_PACKAGE.get(mcp_name, mcp_name)
                if pkg_name in pinned_tools:
                    pinned_ver = pinned_tools[pkg_name]
                    if npx_ver != pinned_ver:
                        violations.append(
                            f"pinnedTools '{pkg_name}'='{pinned_ver}' "
                            f"does not match opencode.jsonc npx pin '{npx_ver}'"
                        )
                else:
                    violations.append(
                        f"pinnedTools missing '{pkg_name}' "
                        f"(opencode.jsonc MCP '{mcp_name}' npx pin '{npx_ver}')"
                    )

    # Check plugin[] pins against pinnedTools
    for plugin_name, pinned_ver in pinned_tools.items():
        if plugin_name in plugin_versions:
            expected = plugin_versions[plugin_name]
            if expected != pinned_ver:
                violations.append(
                    f"pinnedTools '{plugin_name}'='{pinned_ver}' "
                    f"does not match opencode.jsonc plugin[] '{plugin_name}@{expected}'"
                )

    # ── 7. Routing structure validation ───────────────────────────
    routing = registry.get("routing", {})
    if not isinstance(routing, dict) or len(routing) == 0:
        violations.append("routing object is empty or missing")
    else:
        for agent_name, agent_cfg in routing.items():
            if not isinstance(agent_cfg, dict):
                violations.append(f"routing '{agent_name}' is not an object")
                continue
            if "primary" not in agent_cfg:
                violations.append(f"routing '{agent_name}' missing 'primary'")

    # ── 8. No duplicate MCP across policy lists ───────────────────
    # alwaysOn must not overlap with onDemand or neverGlobalByDefault
    # neverGlobalByDefault ⊆ onDemand is by design (not a duplicate)
    always_on_overlap = always_on & on_demand | always_on & never_global
    for mcp in sorted(always_on_overlap):
        violations.append(
            f"alwaysOn MCP '{mcp}' also classified in onDemand/neverGlobalByDefault"
        )

    # ── Report ────────────────────────────────────────────────────
    if args.quiet:
        if violations:
            print(f"FAIL: {len(violations)} violation(s)")
            for v in violations:
                print(f"  {v}")
            return 1
        print("PASS")
        return 0

    if violations:
        print(f"FAIL: {len(violations)} violation(s) found:\n")
        for i, v in enumerate(violations, 1):
            print(f"  {i}. {v}")
        print(f"\n{'=' * 60}")
        print(f"Registry: {args.registry}")
        print(f"OpenCode: {args.opencode}")
        print(f"Violations: {len(violations)}")
        print(f"{'=' * 60}")
        return 1

    print("PASS: harness-registry.jsonc structural contract validated")
    print(f"  {len(always_on)} alwaysOn MCPs, {len(on_demand)} onDemand MCPs, {len(never_global)} neverGlobalByDefault")
    print(f"  {len(pinned_tools)} pinned tools, {len(routing)} routing agents")
    return 0


if __name__ == "__main__":
    sys.exit(main())
