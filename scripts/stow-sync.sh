#!/bin/bash
# stow-sync.sh — Restow all stow packages (idempotent, safe)
# Usage: stow-sync.sh [--dry-run]
set -euo pipefail

DRY_RUN=false
[ "${1:-}" = "--dry-run" ] && DRY_RUN=true

DOTDIR="$(cd "$(dirname "$0")/.." && pwd)"
STOW_DIR="$DOTDIR/stow"
BACKUP_DIR="$HOME/.local/share/dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

if [ ! -d "$STOW_DIR" ]; then
  echo "ERROR: $STOW_DIR not found"
  exit 1
fi

mkdir -p "$BACKUP_DIR"

for pkg_dir in "$STOW_DIR"/*/; do
  [ -d "$pkg_dir" ] || continue
  pkg="$(basename "$pkg_dir")"
  echo "  $pkg"
  if [ "$DRY_RUN" = true ]; then
    stow --simulate -R -d "$STOW_DIR" -t "$HOME" "$pkg" || echo "  WARN: $pkg (simulate)"
  else
    # Backup existing files before restow
    find "$pkg_dir" -type f -printf "$HOME/%P\n" 2>/dev/null | while read -r f; do
      [ -e "$f" ] && [ ! -L "$f" ] && cp -p "$f" "$BACKUP_DIR/" 2>/dev/null || true
    done
    stow -R -d "$STOW_DIR" -t "$HOME" "$pkg" 2>/dev/null || echo "  WARN: $pkg failed"
  fi
done

[ "$DRY_RUN" = false ] && echo "Backup saved to: $BACKUP_DIR"