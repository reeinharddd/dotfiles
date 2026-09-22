#!/usr/bin/env bash
set -euo pipefail

# Verify state-tracking skill exists
STATE_SKILL="/home/reeinharrrd/projects/personal/dotfiles/stow/opencode/.config/opencode/skills/state-tracking/SKILL.md"
[ -f "$STATE_SKILL" ] || { echo "FAIL: state-tracking skill missing"; exit 1; }

# Verify STATE.md referenced in hooks.yaml
HOOKS="/home/reeinharrrd/projects/personal/dotfiles/stow/opencode/.config/opencode/hooks.yaml"
grep -q "STATE.md" "$HOOKS" || { echo "FAIL: STATE.md not referenced in hooks.yaml"; exit 1; }

# Verify state-tracking in skills.md
SKILLS="/home/reeinharrrd/projects/personal/dotfiles/stow/opencode/.config/opencode/capabilities/skills.md"
grep -q "state-tracking" "$SKILLS" || { echo "FAIL: state-tracking not in skills.md"; exit 1; }

echo "State tracking: STATE.md mechanism verified"
