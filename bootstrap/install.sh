#!/usr/bin/env sh
#
# bootstrap/install.sh — One-shot dotfiles installation
#
# Clones repo, runs sys-inspector for detection (optional), deploys configs.
# Idempotent: safe to re-run.
#
# Usage: bash -c "$(curl -fsSL https://raw.githubusercontent.com/reeinharddd/dotfiles/main/bootstrap/install.sh)"
#        or: ./bootstrap/install.sh [--no-detect] [--no-deploy] [--dry-run]

set -u

REPO_URL="ssh://git@github.com/reeinharddd/dotfiles"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/projects/personal/dotfiles}"
CLONE=false
DETECT=true
DEPLOY=true
DRY_RUN=false
SYS_INSPECTOR_DIR="$HOME/projects/personal/sys-inspector"

for arg in "$@"; do
  case "$arg" in
    --no-detect) DETECT=false ;;
    --no-deploy) DEPLOY=false ;;
    --dry-run) DRY_RUN=true ;;
  esac
done

say() { echo "==> $*"; }
warn() { echo "!! $*" >&2; }
err() { echo "XX $*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

require_git() {
  if ! have git; then
    err "git not found. Install git first."
  fi
}

clone_repo() {
  if [ -d "$DOTFILES_DIR/.git" ]; then
    say "Repo already exists at $DOTFILES_DIR"
    say "Pulling latest..."
    if ! $DRY_RUN; then
      git -C "$DOTFILES_DIR" pull --ff-only || warn "git pull failed, continuing anyway"
    fi
  else
    say "Cloning dotfiles to $DOTFILES_DIR"
    if ! $DRY_RUN; then
      mkdir -p "$(dirname "$DOTFILES_DIR")"
      git clone "$REPO_URL" "$DOTFILES_DIR" || err "Failed to clone repo"
    fi
  fi
}

run_detection() {
  if [ ! -x "$SYS_INSPECTOR_DIR/src/inspect.sh" ]; then
    warn "sys-inspector not found at $SYS_INSPECTOR_DIR"
    warn "Skipping detection. Install with: git clone ssh://git@github.com/reeinharddd/sys-inspector $SYS_INSPECTOR_DIR"
    return
  fi

  say "Running sys-inspector detection..."
  if ! $DRY_RUN; then
    cd "$SYS_INSPECTOR_DIR" && ./src/inspect.sh >/dev/null 2>&1 || warn "Detection failed, continuing anyway"
    say "Detection complete. Skill generated at $SYS_INSPECTOR_DIR/skill.md"
  else
    say "Dry run: would run sys-inspector detection"
  fi
}

run_deploy() {
  deploy_script="$DOTFILES_DIR/scripts/deploy.sh"
  if [ ! -x "$deploy_script" ]; then
    err "deploy.sh not found at $deploy_script"
  fi

  say "Deploying configs..."
  if ! $DRY_RUN; then
    DRY_FLAG=""
    [ "$DRY_RUN" = true ] && DRY_FLAG="--dry-run"
    sh "$deploy_script" $DRY_FLAG || err "Deploy failed"
  else
    say "Dry run: would run deploy.sh"
  fi
}

main() {
  say "Bootstrap starting"
  say "  Target: $DOTFILES_DIR"
  say "  Detect: $DETECT"
  say "  Deploy: $DEPLOY"
  say "  Dry run: $DRY_RUN"

  require_git
  clone_repo

  if [ "$DETECT" = true ]; then
    run_detection
  fi

  if [ "$DEPLOY" = true ]; then
    run_deploy
  fi

  say "Bootstrap complete!"
  say "  Dotfiles: $DOTFILES_DIR"
  say "  Run 'deploy.sh --dry-run' anytime to preview changes"
}

main "$@"
