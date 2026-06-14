#!/usr/bin/env sh
#
# deploy.sh — Symlink dotfiles configs into $HOME
#
# Idempotent, backup-first, POSIX sh. Run with --dry-run to preview.
#
# Usage: ./scripts/deploy.sh [--dry-run]

set -u

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
CONFIG_DIR="$DOTFILES_DIR/configs"
BACKUP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
  esac
done

link_count=0
skip_count=0
backup_count=0
fail_count=0

deploy_link() {
  src="$1"
  dst="$2"

  if [ ! -f "$src" ] && [ ! -d "$src" ]; then
    echo "  SKIP  source missing: $src"
    skip_count=$((skip_count + 1))
    return
  fi

  dst_parent=$(dirname "$dst")

  if [ -L "$dst" ]; then
    current=$(readlink "$dst")
    if [ "$current" = "$src" ]; then
      echo "  OK    already linked: $dst"
      skip_count=$((skip_count + 1))
      return
    else
      echo "  WARN  symlink points elsewhere: $dst -> $current (expected $src)"
      skip_count=$((skip_count + 1))
      return
    fi
  fi

  if [ -f "$dst" ] || [ -d "$dst" ]; then
    if $DRY_RUN; then
      echo "  BACKUP would backup: $dst"
    else
      mkdir -p "$BACKUP_DIR/$(dirname "${dst#$HOME/}")"
      mv "$dst" "$BACKUP_DIR/${dst#$HOME/}"
      echo "  BACKUP backed up: $dst"
    fi
    backup_count=$((backup_count + 1))
  fi

  if $DRY_RUN; then
    echo "  LINK  $src -> $dst"
    link_count=$((link_count + 1))
    return
  fi

  mkdir -p "$dst_parent"

  if ln -s "$src" "$dst" 2>/dev/null; then
    echo "  LINK  $src -> $dst"
    link_count=$((link_count + 1))
  else
    echo "  FAIL  could not link: $src -> $dst"
    fail_count=$((fail_count + 1))
  fi
}

echo "==> Deploying dotfiles from $CONFIG_DIR"
echo "    Dry run: $DRY_RUN"
echo ""

# shell
deploy_link "$CONFIG_DIR/shell/zshrc" "$HOME/.zshrc"

# git
deploy_link "$CONFIG_DIR/git/gitconfig" "$HOME/.gitconfig"

# kitty
deploy_link "$CONFIG_DIR/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"

# starship
deploy_link "$CONFIG_DIR/starship/starship.toml" "$HOME/.config/starship/starship.toml"

# zellij
deploy_link "$CONFIG_DIR/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"

# atuin
deploy_link "$CONFIG_DIR/atuin/config.toml" "$HOME/.config/atuin/config.toml"

# continue (Continue.dev)
deploy_link "$CONFIG_DIR/continue/config.json" "$HOME/.config/continue/config.json"

# fontconfig
deploy_link "$CONFIG_DIR/fontconfig/fonts.conf" "$HOME/.config/fontconfig/fonts.conf"

# gh (GitHub CLI)
deploy_link "$CONFIG_DIR/gh/config.yml" "$HOME/.config/gh/config.yml"

# mise
deploy_link "$CONFIG_DIR/mise/config.toml" "$HOME/.config/mise/config.toml"

# opencode
deploy_link "$CONFIG_DIR/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"

# profile.d
deploy_link "$CONFIG_DIR/profile.d/modern-tools.sh" "$HOME/.profile.d/modern-tools.sh"

# vscode
deploy_link "$CONFIG_DIR/vscode/settings.json" "$HOME/.config/Code/User/settings.json"
deploy_link "$CONFIG_DIR/vscode/prompts/global.instructions.md" "$HOME/.config/Code/User/prompts/global.instructions.md"
deploy_link "$CONFIG_DIR/vscode/prompts/environment.instructions.md" "$HOME/.config/Code/User/prompts/environment.instructions.md"
deploy_link "$CONFIG_DIR/vscode/prompts/tests.instructions.md" "$HOME/.config/Code/User/prompts/tests.instructions.md"

# opencode AGENTS.md
deploy_link "$CONFIG_DIR/opencode/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"

echo ""
echo "==> Summary: $link_count linked, $skip_count skipped, $backup_count backed up, $fail_count failed"
if [ "$backup_count" -gt 0 ] && ! $DRY_RUN; then
  echo "    Backups in: $BACKUP_DIR"
fi

[ "$fail_count" -eq 0 ]
