#!/usr/bin/env bash
#
# deploy.sh — Deploy all dotfiles via GNU Stow
#
# Usage: ./scripts/deploy.sh [--dry-run]
#   --dry-run  Preview what would change without modifying files

set -euo pipefail

DOTDIR="$(cd "$(dirname "$0")/.." && pwd)"

case "${1:-}" in
  --dry-run|-n)
    echo "==> Dry-run: would stow all packages from $DOTDIR/stow"
    find "$DOTDIR/stow" -maxdepth 1 -mindepth 1 -type d | while read -r pkg; do
      echo "  $(basename "$pkg")"
    done
    echo "==> Run without --dry-run to deploy."
    ;;
  *)
    exec "$DOTDIR/scripts/stow-sync.sh"
    ;;
esac
