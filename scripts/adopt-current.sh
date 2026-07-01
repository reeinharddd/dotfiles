#!/usr/bin/env sh
#
# adopt-current.sh — Adopt current system configs into stow tree
#
# Source of truth is the LOCAL SYSTEM. This script captures current
# system state into dotfiles/stow/ so we can version it and improve
# from there. Backs up existing stow files first.
#
# Usage: ./scripts/adopt-current.sh [--dry-run]
#   --dry-run  Preview what would be adopted without copying

set -u

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
STOW_DIR="$DOTFILES_DIR/stow"
BACKUP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles-adopt-backup/$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
  esac
done

adopt() {
  src="$1"          # system source (e.g., $HOME/.zshrc)
  dst="$STOW_DIR/$2"  # stow target (e.g., shell/.zshrc)
  label="$3"

  if [ ! -f "$src" ] && [ ! -d "$src" ]; then
    echo "  SKIP  source missing: $src"
    return
  fi

  if [ -f "$dst" ] || [ -d "$dst" ]; then
    src_hash="$(cat "$dst" 2>/dev/null | md5sum)"
    dst_hash="$(cat "$src" 2>/dev/null | md5sum)"
    if [ "$src_hash" = "$dst_hash" ]; then
      echo "  OK    unchanged: $label"
      return
    fi
    if $DRY_RUN; then
      echo "  BACKUP would backup: $dst"
    else
      mkdir -p "$(dirname "$BACKUP_DIR/$2")"
      cp "$dst" "$BACKUP_DIR/$2"
      echo "  BACKUP backed up old: $label"
    fi
  fi

  if $DRY_RUN; then
    echo "  ADOPT  $src -> $dst"
    return
  fi

  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo "  ADOPT  $label"
}

echo "==> Adopting current system configs into stow tree"
echo "    STOW_DIR=$STOW_DIR"
echo "    Dry run: $DRY_RUN"
echo ""

# shell
adopt "$HOME/.zshrc" "shell/.zshrc" "zshrc"
adopt "$HOME/.zshenv" "shell/.zshenv" "zshenv" 2>/dev/null || true
adopt "$HOME/.zprofile" "shell/.zprofile" "zprofile" 2>/dev/null || true

# git
adopt "$HOME/.gitconfig" "git/.gitconfig" "gitconfig"
adopt "$HOME/.gitignore_global" "git/.gitignore_global" "gitignore_global" 2>/dev/null || true

# kitty
adopt "$HOME/.config/kitty/kitty.conf" "kitty/kitty.conf" "kitty.conf"

# starship
adopt "$HOME/.config/starship/starship.toml" "starship/starship.toml" "starship.toml"

# atuin
adopt "$HOME/.config/atuin/config.toml" "atuin/config.toml" "atuin config"

# mise
adopt "$HOME/.config/mise/config.toml" "mise/config.toml" "mise config"

# fontconfig
adopt "$HOME/.config/fontconfig/fonts.conf" "fontconfig/fonts.conf" "fonts.conf"

# gh
adopt "$HOME/.config/gh/config.yml" "gh/config.yml" "gh config"

# opencode
adopt "$HOME/.config/opencode/opencode.json" "opencode/opencode.json" "opencode.json"
adopt "$HOME/.config/opencode/opencode.jsonc" "opencode/opencode.jsonc" "opencode.jsonc" 2>/dev/null || true
adopt "$HOME/.config/opencode/tui.json" "opencode/tui.json" "tui.json" 2>/dev/null || true

echo ""
echo "==> Done. Stow tree ready at $STOW_DIR"
