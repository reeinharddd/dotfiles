#!/usr/bin/env bash
set -euo pipefail

CONTRACT="/home/reeinharrrd/projects/personal/dotfiles/stow/opencode/.config/opencode/instructions/00-global-contract.md"
[ -f "$CONTRACT" ] || { echo "FAIL: contract file missing"; exit 1; }

for section in Identity Veracity Security Context Memory Tools Routing Completion; do
  grep -qi "$section" "$CONTRACT" || { echo "FAIL: missing section $section"; exit 1; }
done
echo "Contract loading: all sections present"
