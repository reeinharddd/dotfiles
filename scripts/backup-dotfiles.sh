#!/usr/bin/env bash
# backup-dotfiles.sh — Auto commit + push del dotfiles repo
# Corre via systemd timer

set -euo pipefail

REPO="$HOME/projects/personal/dotfiles"
cd "$REPO"

# Check if there are changes
if [ -z "$(git status --porcelain)" ]; then
  echo "✅ No changes to backup"
  exit 0
fi

# Auto commit with timestamp
git add -A
git commit -m "auto: backup $(date '+%Y-%m-%d %H:%M')" || true
git push 2>/dev/null || echo "⚠️  Push failed — check network"

echo "✅ Dotfiles backed up at $(date)"
