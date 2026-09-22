#!/usr/bin/env bash
set -euo pipefail

REG="/home/reeinharrrd/projects/personal/dotfiles/stow/opencode/.config/opencode/harness-registry.jsonc"
[ -f "$REG" ] || { echo "FAIL: harness-registry.jsonc missing"; exit 1; }

grep -q '"onDemand"' "$REG" || { echo "FAIL: no onDemand MCP policy"; exit 1; }
grep -q '"alwaysOn"' "$REG" || { echo "FAIL: no alwaysOn MCP policy"; exit 1; }

# Verify at least one on-demand MCP server exists
grep -q '"github"' "$REG" && echo "MCP on-demand: policy active with github" || { echo "FAIL: on-demand servers missing"; exit 1; }

echo "MCP on-demand: policy configured correctly"
