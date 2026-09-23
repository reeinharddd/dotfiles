#!/usr/bin/env bash
# ============================================================
# bootstrap.sh — reproducible dotfiles setup for Ubuntu/Debian
# Idempotent: safe to run multiple times.
# Usage: curl -fsSL https://raw.githubusercontent.com/reeinharddd/dotfiles/main/bootstrap.sh | bash
# ============================================================
set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/reeinharddd/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/projects/personal/dotfiles}"
MISE_VERSION="${MISE_VERSION:-v2025.10.6}"
GHOSTTY_VERSION="${GHOSTTY_VERSION:-1.3.0}"

# Checksums for pinned downloads
GHOSTTY_SHA256="a1b2c3d4e5f67890..."  # TODO: update with actual sha256
MISE_INSTALL_SCRIPT_SHA256="sha256:..."  # TODO: update with actual sha256
LAZYDOCKER_INSTALL_SCRIPT_SHA256="sha256:..."  # TODO: update with actual sha256

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${CYAN}[bootstrap]${NC} $*"; }
ok()   { echo -e "${GREEN}  ok${NC} $*"; }
warn() { echo -e "${YELLOW}  !!${NC} $*"; }
fail() { echo -e "${RED}  XX${NC} $*"; exit 1; }

verify_checksum() {
  local file="$1"
  local expected="$2"
  local actual
  actual=$(sha256sum "$file" | cut -d' ' -f1)
  if [ "$actual" != "$expected" ]; then
    fail "Checksum mismatch for $file: expected $expected, got $actual"
  fi
}

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
  # verify_checksum "/tmp/$deb" "$GHOSTTY_SHA256"
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
  local mise_script="/tmp/mise_install.sh"
  curl -fsSL https://mise.run -o "$mise_script"
  # verify_checksum "$mise_script" "$MISE_INSTALL_SCRIPT_SHA256"
  MISE_VERSION="$MISE_VERSION" bash "$mise_script"
  rm -f "$mise_script"
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
    local lazydocker_script="/tmp/lazydocker_install.sh"
    curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh -o "$lazydocker_script"
    # verify_checksum "$lazydocker_script" "$LAZYDOCKER_INSTALL_SCRIPT_SHA256"
    bash "$lazydocker_script" 2>&1 | sed 's/^/  /'
    rm -f "$lazydocker_script"
    ok "lazydocker installed"
  fi
}

# ── Dotfiles ────────────────────────────────────────────────
setup_dotfiles() {
  if [ -d "$DOTFILES_DIR/.git" ]; then
    ok "Dotfiles already cloned at $DOTFILES_DIR"
  else
    log "Cloning dotfiles..."
    mkdir -p "$(dirname "$DOTFILES_DIR")"
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    ok "Dotfiles cloned"
  fi

  git -C "$DOTFILES_DIR" config core.hooksPath .githooks

  log "Symlinking configs via stow..."
  cd "$DOTFILES_DIR"
  ./scripts/stow-sync.sh
  cd "$OLDPWD"
  ok "Config symlinks created"

  log "Building opencode plugins..."
  if [ -f "$DOTFILES_DIR/stow/opencode/.config/opencode/package.json" ]; then
    cd "$DOTFILES_DIR/stow/opencode/.config/opencode"
    npm ci 2>&1 | sed 's/^/  /'
    npm run build 2>&1 | sed 's/^/  /' || warn "Plugin build failed"
    cd "$OLDPWD"
  fi
  ok "OpenCode plugins built"

  log "Decrypting sops secrets..."
  if command -v sops &>/dev/null && [ -f "$DOTFILES_DIR/.env.sops" ]; then
    sops -d "$DOTFILES_DIR/.env.sops" > "$HOME/.env" 2>/dev/null && ok "Decrypted .env from sops" || warn "Failed to decrypt .env.sops (need age key in ~/.config/sops/age/keys.txt)"
  fi
  if command -v sops &>/dev/null && [ -f "$DOTFILES_DIR/stow/taskman/.config/task/secrets.conf.sops" ]; then
    sops -d "$DOTFILES_DIR/stow/taskman/.config/task/secrets.conf.sops" > "$HOME/.config/task/secrets.conf" 2>/dev/null && ok "Decrypted Taskwarrior secrets" || warn "Failed to decrypt Taskwarrior secrets"
  fi
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
  echo "| reeinharddd's dotfiles bootstrap         |"
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