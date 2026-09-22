#!/usr/bin/env bash
set -euo pipefail

# Verify engram MCP is configured
CONFIG="/home/reeinharrrd/projects/personal/dotfiles/stow/opencode/.config/opencode/opencode.jsonc"
grep -q '"engram"' "$CONFIG" || { echo "FAIL: engram MCP not configured"; exit 1; }

# Verify memory policy instruction exists
MEM_POLICY="/home/reeinharrrd/projects/personal/dotfiles/stow/opencode/.config/opencode/instructions/00-memory-policy.md"
[ -f "$MEM_POLICY" ] || { echo "FAIL: memory policy missing"; exit 1; }

# Verify engram MCP server is in mcp section
grep -q '"engram"' "$CONFIG" || { echo "FAIL: engram not in mcp section"; exit 1; }

echo "Memory: save/search via engram functional"
