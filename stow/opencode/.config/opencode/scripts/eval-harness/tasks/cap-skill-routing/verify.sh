#!/usr/bin/env bash
set -euo pipefail

SKILLS="/home/reeinharrrd/projects/personal/dotfiles/stow/opencode/.config/opencode/capabilities/skills.md"
[ -f "$SKILLS" ] || { echo "FAIL: skills.md missing"; exit 1; }

grep -q "skill-router" "$SKILLS" || { echo "FAIL: skill-router not documented"; exit 1; }
grep -qi "sole skill-loading authority" "$SKILLS" || { echo "FAIL: skill-router not marked as sole authority"; exit 1; }

# Verify skill-router skill file exists
SKILL_ROUTER="/home/reeinharrrd/projects/personal/dotfiles/stow/opencode/.config/opencode/skills/skill-router/SKILL.md"
[ -f "$SKILL_ROUTER" ] || { echo "FAIL: skill-router SKILL.md missing"; exit 1; }

echo "Skill routing: skill-router is sole authority"
