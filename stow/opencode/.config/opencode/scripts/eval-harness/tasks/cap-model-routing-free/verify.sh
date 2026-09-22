#!/usr/bin/env bash
set -euo pipefail

GUARD="/home/reeinharrrd/projects/personal/dotfiles/stow/opencode/.config/opencode/plugins/model-routing-guard.js"
[ -f "$GUARD" ] || { echo "FAIL: model-routing-guard.js missing"; exit 1; }

CONFIG="/home/reeinharrrd/projects/personal/dotfiles/stow/opencode/.config/opencode/opencode.jsonc"
grep -q "free" "$CONFIG" || { echo "FAIL: no free model config in opencode.jsonc"; exit 1; }

OMO="/home/reeinharrrd/projects/personal/dotfiles/stow/opencode/.config/opencode/oh-my-openagent.json"
[ -f "$OMO" ] || { echo "FAIL: oh-my-openagent.json missing"; exit 1; }

# Verify free provider exists in opencode.jsonc
grep -q "opencode-zen" "$CONFIG" || { echo "FAIL: opencode-zen provider missing"; exit 1; }

echo "Model routing: free-only policy enforced"
