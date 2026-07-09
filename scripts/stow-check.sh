#!/bin/bash
# stow-check.sh — Verify all stow packages (simulation mode)
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
  echo "  $pkg:"
  stow --no -d "$STOW_DIR" -t "$HOME" "$pkg" 2>&1 || true
done
