#!/usr/bin/env bash
set -euo pipefail

# Check hard-rules.md for conventional commits in BASE PROTOCOL
HR="/home/reeinharrrd/projects/personal/dotfiles/stow/opencode/.config/opencode/instructions/02-hard-rules.md"
[ -f "$HR" ] || { echo "FAIL: hard-rules.md missing"; exit 1; }
grep -q "Conventional commits" "$HR" || { echo "FAIL: conventional commits not in hard-rules"; exit 1; }

# Check global contract
GC="/home/reeinharrrd/projects/personal/dotfiles/stow/opencode/.config/opencode/instructions/00-global-contract.md"
[ -f "$GC" ] || { echo "FAIL: global-contract.md missing"; exit 1; }
grep -q "Conventional commits" "$GC" || { echo "FAIL: conventional commits not in global contract"; exit 1; }

echo "Conventional commits: documented in hard-rules and global contract"
