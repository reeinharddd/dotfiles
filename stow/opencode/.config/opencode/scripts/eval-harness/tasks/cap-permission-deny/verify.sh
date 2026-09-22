#!/usr/bin/env bash
set -euo pipefail

CONFIG="/home/reeinharrrd/projects/personal/dotfiles/stow/opencode/.config/opencode/opencode.jsonc"
[ -f "$CONFIG" ] || { echo "FAIL: opencode.jsonc missing"; exit 1; }

# Check for deny rules
grep -q '"deny"' "$CONFIG" || { echo "FAIL: no deny rules in permissions"; exit 1; }
grep -q '\*\.env.*deny' "$CONFIG" || { echo "FAIL: no .env deny rule"; exit 1; }
grep -q '"rm \*".*"deny"' "$CONFIG" || { echo "FAIL: no rm deny rule"; exit 1; }
grep -q '"sudo \*".*"deny"' "$CONFIG" || { echo "FAIL: no sudo deny rule"; exit 1; }

echo "Permissions: deny rules present"
