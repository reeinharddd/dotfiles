#!/usr/bin/env bash
set -euo pipefail

HOOKS="/home/reeinharrrd/projects/personal/dotfiles/stow/opencode/.config/opencode/hooks.yaml"
[ -f "$HOOKS" ] || { echo "FAIL: hooks.yaml missing"; exit 1; }

for event in tool.before.bash session.idle tool.execute.after; do
  grep -q "$event" "$HOOKS" || { echo "FAIL: missing hook event $event"; exit 1; }
done

echo "Hooks: lifecycle events configured"
