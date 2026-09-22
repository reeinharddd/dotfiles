#!/usr/bin/env bash
set -euo pipefail

PLUGINS="/home/reeinharrrd/projects/personal/dotfiles/stow/opencode/.config/opencode/capabilities/plugins.md"
grep -q "Exactly ONE enabled" "$PLUGINS" || { echo "FAIL: single-path policy not documented"; exit 1; }

CONFIG="/home/reeinharrrd/projects/personal/dotfiles/stow/opencode/.config/opencode/opencode.jsonc"
grep -q '"openTelemetry": true' "$CONFIG" || { echo "FAIL: openTelemetry not enabled"; exit 1; }

# Verify opencode-telemetry.js plugin exists
TELEMETRY="/home/reeinharrrd/projects/personal/dotfiles/stow/opencode/.config/opencode/plugins/opencode-telemetry.js"
[ -f "$TELEMETRY" ] || { echo "FAIL: opencode-telemetry.js missing"; exit 1; }

echo "Telemetry: single-path policy documented"
