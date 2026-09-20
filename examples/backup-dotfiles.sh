#!/usr/bin/env bash
# backup-dotfiles.sh — Auto commit + push to PRIVATE repo
# Configure: DOTFILES_BACKUP_REMOTE=git@github.com:username/dotfiles-private.git

set -euo pipefail

REPO="$HOME/projects/personal/dotfiles"
PRIVATE_REMOTE="${DOTFILES_BACKUP_REMOTE:-}"
cd "$REPO"

# Check if there are changes
if [ -z "$(git status --porcelain)" ]; then
  echo "✅ No changes to backup"
  exit 0
fi

# Auto commit with timestamp
git add -A
git commit -m "auto: backup $(date '+%Y-%m-%d %H:%M')" || true

# Push to private remote if configured
if [ -n "$PRIVATE_REMOTE" ]; then
  if git remote get-url private-backup >/dev/null 2>&1; then
    git push private-backup HEAD:main 2>/dev/null || echo "⚠️  Private push failed"
  else
    git remote add private-backup "$PRIVATE_REMOTE"
    git push private-backup HEAD:main 2>/dev/null || echo "⚠️  Private push failed"
  fi
else
  echo "ℹ️  DOTFILES_BACKUP_REMOTE not set — skipping push"
fi

echo "✅ Dotfiles backed up at $(date)"