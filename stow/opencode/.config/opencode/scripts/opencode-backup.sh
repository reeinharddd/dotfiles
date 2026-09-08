#!/usr/bin/env bash
# opencode-backup.sh — Manual backup of OpenCode config to dotfiles
# Run: bash ~/.config/opencode/scripts/opencode-backup.sh

set -euo pipefail

CONFIG_DIR="$HOME/.config/opencode"
DOTFILES_STOW="$HOME/projects/personal/dotfiles/stow/opencode"
BACKUP_TAG="opencode-config"
DATE=$(date +%Y-%m-%d)

echo "=== OpenCode Config Backup ==="
echo "From: $CONFIG_DIR"
echo "To:   $DOTFILES_STOW"
echo ""

# Copy critical files (not node_modules/)
FILES=(
    "opencode.jsonc"
    "oh-my-openagent.json"
    "dcp.jsonc"
    "hooks.yaml"
    "MASTER-INDEX.md"
    "MCP-INVENTORY.md"
    "CONFIG-CHANGES.md"
)

for f in "${FILES[@]}"; do
    if [ -f "$CONFIG_DIR/$f" ]; then
        cp "$CONFIG_DIR/$f" "$DOTFILES_STOW/"
        echo "  ✓ $f"
    else
        echo "  ✗ $f (not found)"
    fi
done

echo ""
echo "Done. Re-stow with: stow --adopt -R -d ~/projects/personal/dotfiles/stow -t ~ opencode"
