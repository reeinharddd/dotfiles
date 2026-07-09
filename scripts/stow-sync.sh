#!/bin/bash
# stow-sync.sh — Restow all stow packages (idempotent)
set -euo pipefail

DOTDIR="$(cd "$(dirname "$0")/.." && pwd)"
STOW_DIR="$DOTDIR/stow"

if [ ! -d "$STOW_DIR" ]; then
  echo "ERROR: $STOW_DIR not found"
  exit 1
fi

for pkg_dir in "$STOW_DIR"/*/; do
  [ -d "$pkg_dir" ] || continue
  pkg="$(basename "$pkg_dir")"
  echo "  $pkg"
  stow --adopt -R -d "$STOW_DIR" -t "$HOME" "$pkg" 2>/dev/null || echo "  WARN: $pkg"
done
