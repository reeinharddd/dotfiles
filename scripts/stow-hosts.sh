#!/usr/bin/env bash
# stow-hosts.sh — Manage host-specific stow overlays
# Usage: stow-hosts.sh [laptop|desktop] [--dry-run]

set -euo pipefail

HOST="${1:-$(hostname)}"
DRY_RUN=false
[ "${2:-}" = "--dry-run" ] && DRY_RUN=true

DOTDIR="$(cd "$(dirname "$0")/.." && pwd)"
STOW_DIR="$DOTDIR/stow"
HOST_DIR="$STOW_DIR/hosts/$HOST"

if [ ! -d "$HOST_DIR" ]; then
    echo "No host-specific overlay for $HOST at $HOST_DIR"
    exit 1
fi

BACKUP_DIR="$HOME/.local/share/dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

for pkg_dir in "$HOST_DIR"/*/; do
    [ -d "$pkg_dir" ] || continue
    pkg="$(basename "$pkg_dir")"
    echo "  $pkg (host: $HOST)"
    if [ "$DRY_RUN" = true ]; then
        stow --simulate -R -d "$STOW_DIR/hosts/$HOST" -t "$HOME" "$pkg" || echo "  WARN: $pkg (simulate)"
    else
        find "$pkg_dir" -type f -printf "$HOME/%P\n" 2>/dev/null | while read -r f; do
            if [ -e "$f" ] && [ ! -L "$f" ]; then
                cp -p "$f" "$BACKUP_DIR/" 2>/dev/null || true
            fi
        done
        stow -R -d "$STOW_DIR/hosts/$HOST" -t "$HOME" "$pkg" 2>/dev/null || echo "  WARN: $pkg failed"
    fi
done

echo "Host overlay applied: $HOST"