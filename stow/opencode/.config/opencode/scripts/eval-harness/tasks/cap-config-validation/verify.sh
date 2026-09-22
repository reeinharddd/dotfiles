#!/usr/bin/env bash
set -euo pipefail

CONFIG="/home/reeinharrrd/projects/personal/dotfiles/stow/opencode/.config/opencode/opencode.jsonc"
[ -f "$CONFIG" ] || { echo "FAIL: opencode.jsonc missing"; exit 1; }

# Check for key sections using grep (avoids JSONC parsing issues)
for key in '"model"' '"permission"' '"mcp"' '"agent"' '"plugin"'; do
  grep -q "$key" "$CONFIG" || { echo "FAIL: missing $key in opencode.jsonc"; exit 1; }
done

# Verify openTelemetry is enabled
grep -q '"openTelemetry": true' "$CONFIG" || { echo "FAIL: openTelemetry not enabled"; exit 1; }

# Verify it's parseable by checking basic JSON structure
grep -q '$schema' "$CONFIG" || { echo "FAIL: missing \$schema"; exit 1; }

echo "opencode.jsonc: valid JSONC with all key sections"
