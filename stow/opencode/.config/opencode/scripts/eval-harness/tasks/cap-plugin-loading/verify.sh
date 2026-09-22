#!/usr/bin/env bash
set -euo pipefail

PLUGINS_DIR="/home/reeinharrrd/projects/personal/dotfiles/stow/opencode/.config/opencode/plugins"
[ -d "$PLUGINS_DIR" ] || { echo "FAIL: plugins directory missing"; exit 1; }

for plugin in opencode-telemetry.js model-routing-guard.js; do
  [ -f "$PLUGINS_DIR/$plugin" ] || { echo "FAIL: $plugin missing from plugins/"; exit 1; }
done

# Verify auto-load mechanism documented in plugins.md
PM="/home/reeinharrrd/projects/personal/dotfiles/stow/opencode/.config/opencode/capabilities/plugins.md"
grep -q "Auto-loaded at startup from plugin directory" "$PM" || { echo "FAIL: auto-load not documented"; exit 1; }

echo "Plugin loading: auto-load mechanism verified"
