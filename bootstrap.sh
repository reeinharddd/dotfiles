#!/usr/bin/env bash
# ============================================================
# bootstrap.sh — reproducible dotfiles setup for Ubuntu/Debian
# Idempotent: safe to run multiple times.
# Usage: curl -fsSL https://raw.githubusercontent.com/reeinharrrd/dotfiles/main/bootstrap.sh | bash
# ============================================================
set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/reeinharrrd/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/projects/personal/dotfiles}"
MISE_VERSION="${MISE_VERSION:-v2025.10.6}"
GHOSTTY_VERSION="${GHOSTTY_VERSION:-1.3.0}"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${CYAN}[bootstrap]${NC} $*"; }
ok()   { echo -e "${GREEN}  ok${NC} $*"; }
warn() { echo -e "${YELLOW}  !!${NC} $*"; }
fail() { echo -e "${RED}  XX${NC} $*"; exit 1; }

# ── Preflight ───────────────────────────────────────────────
preflight() {
  log "Checking OS..."
  if [ ! -f /etc/os-release ]; then
    fail "Only Ubuntu/Debian is supported (no /etc/os-release)"
  fi
  . /etc/os-release
  case "$ID" in ubuntu|debian|pop|linuxmint) ;; *)
    fail "Unsupported distro: $ID"
  ;; esac
  ok "$ID $VERSION_ID"

  log "Installing essential system packages..."
  sudo apt-get update -qq
  sudo apt-get install -y -qq \
    curl wget git stow zsh build-essential \
    unzip xz-utils ca-certificates jq \
    zsh-syntax-highlighting \
    zsh-autosuggestions
  ok "System packages installed"
}

# ── Ghostty ─────────────────────────────────────────────────
install_ghostty() {
  if command -v ghostty &>/dev/null; then
    ok "Ghostty already installed"
    return
  fi
  log "Installing Ghostty $GHOSTTY_VERSION..."
  local deb="ghostty_${GHOSTTY_VERSION}_amd64.deb"
  local url="https://release.files.ghostty.org/${GHOSTTY_VERSION}/${deb}"
  wget -q "$url" -O "/tmp/$deb"
  sudo dpkg -i "/tmp/$deb"
  rm -f "/tmp/$deb"
  ok "Ghostty $GHOSTTY_VERSION installed"
}

# ── mise ────────────────────────────────────────────────────
install_mise() {
  if command -v mise &>/dev/null; then
    local cur; cur=$(mise --version 2>/dev/null | awk '{print $1}')
    ok "mise already installed ($cur)"
    return
  fi
  log "Installing mise..."
  curl -fsSL https://mise.run | MISE_VERSION="$MISE_VERSION" bash
  ok "mise $MISE_VERSION installed"
}

install_mise_tools() {
  if [ ! -f "$HOME/.config/mise/config.toml" ]; then
    warn "No mise config found"
    return
  fi
  log "Installing mise-managed tools..."
  eval "$(mise activate bash)"
  mise install --yes 2>&1 | sed 's/^/  /'
  ok "All mise tools installed"
}

# ── Cargo tools ─────────────────────────────────────────────
install_cargo_tools() {
  if ! command -v cargo &>/dev/null; then
    warn "Cargo not available"
    return
  fi
  local tools=(procs navi btop)
  for t in "${tools[@]}"; do
    if command -v "$t" &>/dev/null; then
      ok "$t already installed"
    else
      log "Installing $t via cargo..."
      cargo install "$t" 2>&1 | sed 's/^/  /' || warn "$t install failed"
    fi
  done
}

# ── Extra binary tools ──────────────────────────────────────
install_extra_tools() {
  if command -v lazydocker &>/dev/null; then
    ok "lazydocker already installed"
  else
    log "Installing lazydocker..."
    curl -sS https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash 2>&1 | sed 's/^/  /'
    ok "lazydocker installed"
  fi
}

# ── Dotfiles ────────────────────────────────────────────────
setup_dotfiles() {
  if [ -d "$DOTFILES_DIR/.git" ]; then
    ok "Dotfiles already cloned at $DOTFILES_DIR"
    return
  fi
  log "Cloning dotfiles..."
  mkdir -p "$(dirname "$DOTFILES_DIR")"
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  ok "Dotfiles cloned"

  log "Symlinking configs via stow..."
  cd "$DOTFILES_DIR"
  for dir in stow/*/; do
    pkg=$(basename "$dir")
    stow -R -d stow -t "$HOME" "$pkg" 2>/dev/null || warn "stow $pkg failed"
  done
  cd "$OLDPWD"
  ok "Config symlinks created"
}

# ── Shell ───────────────────────────────────────────────────
setup_shell() {
  if [ "$SHELL" != "$(command -v zsh)" ]; then
    log "Changing default shell to zsh..."
    chsh -s "$(command -v zsh)"
    ok "Default shell changed to zsh (re-login to take effect)"
  else
    ok "zsh is already the default shell"
  fi
}

# ── Ghostty as default terminal ─────────────────────────────
set_default_terminal() {
  if ! command -v ghostty &>/dev/null; then
    warn "Ghostty not found"
    return
  fi
  local ghostty_path
  ghostty_path=$(command -v ghostty)

  if command -v update-alternatives &>/dev/null; then
    sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$ghostty_path" 30 2>/dev/null || true
    sudo update-alternatives --set x-terminal-emulator "$ghostty_path" 2>/dev/null || true
  fi

  if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.default-applications.terminal 'ghostty' 2>/dev/null || true
  fi

  ok "Ghostty set as default terminal"
}

# ── Summary ─────────────────────────────────────────────────
summary() {
  echo ""
  echo "============================================"
  echo "  Dotfiles bootstrap complete!"
  echo "============================================"
  echo ""
  echo "  Next steps:"
  echo "    1. Log out and back in (or 'exec zsh')"
  echo "    2. Open Ghostty terminal"
  echo "    3. Run 'atuin login' for shell history sync"
  echo ""
}

# ── Main ────────────────────────────────────────────────────
main() {
  echo ""
  echo "+------------------------------------------+"
  echo "| reeinharrrd's dotfiles bootstrap         |"
  echo "+------------------------------------------+"
  echo ""

  preflight
  install_ghostty
  install_mise
  install_mise_tools
  install_cargo_tools
  install_extra_tools
  setup_dotfiles
  set_default_terminal
  setup_shell
  summary
}

main "$@"
