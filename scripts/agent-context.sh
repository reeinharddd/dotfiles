#!/usr/bin/env bash
# Agent Context - Genera un markdown completo del sistema consumible por IA
# Uso: ./agent-context.sh [--fast] [--output archivo.md]
set -euo pipefail

FAST=false
OUTPUT_FILE=""
while [[ $# -gt 0 ]]; do
  case "$1" in --fast) FAST=true; shift ;; --output) OUTPUT_FILE="$2"; shift 2 ;; *) echo "Uso: agent-context.sh [--fast] [--output file.md]"; exit 1 ;; esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE="$(dirname "$SCRIPT_DIR")"

# Cargar PATH completo del usuario
export HOME="/home/reeinharrrd"
export USER="reeinharrrd"
source /etc/profile.d/modern-tools.sh 2>/dev/null || true
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.bun/bin:$HOME/.local/share/mise/shims:/usr/local/bin:$PATH"

# Helper functions
sec() { echo "# $1"; }
ssec() { echo "## $1"; }
sssec() { echo "### $1"; }
kv() { printf -- "- **%s**: %s\n" "$1" "${2:-}"; }
list() { printf -- "- %s\n" "$@"; }
sep() { echo "---"; }

run() { "$@" 2>/dev/null || true; }
run_fast() { if $FAST; then return; else "$@" 2>/dev/null || true; fi; }
_ver() { local v=$("$@" 2>/dev/null | head -1); echo "$v" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[[:space:]]*//'; }

# ============================================================
# SYSTEM OVERVIEW
# ============================================================
sec "System Context: $(hostname)"
echo
ssec "System Overview"
kv "Hostname" "$(hostname)"
kv "OS" "$(lsb_release -ds 2>/dev/null || (grep 'PRETTY_NAME' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"'))"
kv "Kernel" "$(uname -r)"
kv "Architecture" "$(uname -m)"
kv "Uptime" "$(uptime -p 2>/dev/null | sed 's/up //')"
kv "Desktop" "${XDG_SESSION_DESKTOP:-ubuntu}"
kv "Session Type" "${XDG_SESSION_TYPE:-wayland}"
kv "Default Shell" "zsh 5.9 (configured: /usr/bin/zsh)"

echo
ssec "Hardware"
kv "CPU" "$(lscpu 2>/dev/null | grep 'Model name' | sed 's/Model name:\s*//' | head -1)"
kv "Cores" "$(nproc) threads"
kv "RAM" "$(free -h | awk '/^Mem:/{print $2 " total, " $3 " used, " $7 " avail"}')"
kv "GPU" "$(lspci 2>/dev/null | grep -E 'VGA|3D' | sed 's/.*: //' | head -1)"
kv "Disk" "$(df -h / | awk 'NR==2{print $2 " total, " $3 " used (" $5 ")"}')"

echo
ssec "Shell Environment"
kv "Shell" "Zsh 5.9 + Oh My Zsh"
kv "Prompt" "Starship 1.25 (cross-shell, <10ms, Nightlion V1)"
kv "Terminal" "Kitty 0.45.0 (GPU-accelerated, default via xdg-terminal-exec)"
kv "Font" "JetBrainsMono Nerd Font Mono 12 (global: terminal, editor, system)"
kv "Palette" "Nightlion V1 (#000000 bg, #BBBBBB fg)"

echo
ssec "Shell Aliases"
for a in "cat=batcat --paging=never" "ls=eza --icons --group-directories-first" "cd=z (zoxide)" "diff=delta (git-delta)" "grep=rg (ripgrep)" "find=fd (fd-find)" "du=dust" "top=btop"; do
  kv "${a%%=*}" "${a#*=}"
done

# ============================================================
# RUNTIMES
# ============================================================
echo
ssec "Development Runtimes"
run_fast mise --version 2>/dev/null && kv "mise" "$(_ver mise --version)" || kv "mise" "not loaded"
run_fast node --version 2>/dev/null && kv "node" "$(_ver node --version)" || kv "node" "not loaded"
run_fast python3 --version 2>/dev/null && kv "python" "$(_ver python3 --version)" || kv "python" "not loaded"
run_fast go version 2>/dev/null && kv "go" "$(go version 2>/dev/null | sed 's/go version //' | sed 's/ .*//')" || kv "go" "not loaded"
run_fast bun --version 2>/dev/null && kv "bun" "$(_ver bun --version)" || kv "bun" "not loaded"
run_fast cargo --version 2>/dev/null && kv "cargo" "$(_ver cargo --version)" || kv "cargo" "not loaded"
run_fast rustc --version 2>/dev/null && kv "rustc" "$(_ver rustc --version)" || kv "rustc" "not loaded"

# ============================================================
# TOOLS
# ============================================================
echo
ssec "Tool Inventory"
declare -A TOOLS=(
  [apt]="apt --version 2>/dev/null | head -1 | sed 's/apt //'"
  [snap]="snap --version 2>/dev/null | awk 'NR==1{print \$2}'"
  [pipx]="pipx --version 2>/dev/null"
  [npm]="npm --version 2>/dev/null"
  [cargo]="cargo --version 2>/dev/null | head -1 | sed 's/cargo //'"
  [git]="git --version 2>/dev/null | sed 's/git version //'"
  [docker]="docker --version 2>/dev/null | sed 's/Docker version //' | sed 's/,.*//'"
  [gh]="gh --version 2>/dev/null | head -1 | sed 's/gh version //' | sed 's/ (.*//'"
  [gcc]="gcc -dumpversion 2>/dev/null"
  [g++]="g++ -dumpversion 2>/dev/null"
  [make]="make --version 2>/dev/null | head -1 | sed 's/GNU Make //' | sed 's/ Built.*//'"
  [cmake]="cmake --version 2>/dev/null | head -1 | sed 's/cmake version //'"
  [just]="just --version 2>/dev/null | head -1 | sed 's/just //'"
  [curl]="curl --version 2>/dev/null | head -1 | sed 's/curl //' | sed 's/ (.*//'"
  [wget]="wget --version 2>/dev/null | head -1 | sed 's/GNU Wget //' | sed 's/ .*//'"
  [btop]="btop --version 2>/dev/null | head -1 | sed 's/btop version: //' | sed 's/\x1b\[[0-9;]*m//g'"
  [htop]="htop --version 2>/dev/null | head -1 | sed 's/htop //' | sed 's/ .*//'"
  [lazygit]="lazygit --version 2>/dev/null | head -1 | sed 's/.*version=//' | sed 's/,.*//'"
  [lazydocker]="lazydocker --version 2>/dev/null | sed 's/.*Version: //' | sed 's/,.*//'"
  [fzf]="fzf --version 2>/dev/null | awk '{print \$1}'"
  [eza]="eza --version 2>/dev/null | head -1 | sed 's/eza v//' | sed 's/ .*//'"
  [batcat]="batcat --version 2>/dev/null | head -1 | sed 's/batcat //' | sed 's/ .*//'"
  [rg/ripgrep]="rg --version 2>/dev/null | head -1 | sed 's/ripgrep //' | sed 's/ .*//'"
  [fdfind]="fdfind --version 2>/dev/null | head -1 | sed 's/fd //' | sed 's/ .*//'"
  [zoxide]="zoxide --version 2>/dev/null | head -1 | sed 's/zoxide //'"
  [delta]="delta --version 2>/dev/null | head -1 | sed 's/delta //' | sed 's/ .*//'"
  [trivy]="trivy --version 2>/dev/null | head -1 | sed 's/Version: //'"
  [semgrep]="semgrep --version 2>/dev/null"
  [ollama]="ollama --version 2>/dev/null | head -1 | sed 's/ollama version is //'"
  [chezmoi]="chezmoi --version 2>/dev/null | head -1 | sed 's/chezmoi version //' | sed 's/,.*//'"
  [atuin]="atuin --version 2>/dev/null | head -1"
  [starship]="starship --version 2>/dev/null | head -1 | sed 's/starship //' | sed 's/ .*//'"
  [zellij]="zellij --version 2>/dev/null | head -1"
  [yazi]="yazi --version 2>/dev/null | head -1"
  [navi]="navi --version 2>/dev/null | head -1"
  [procs]="procs --version 2>/dev/null | head -1"
  [btm]="btm --version 2>/dev/null | head -1"
  [jj]="jj --version 2>/dev/null | head -1"
  [git-cliff]="git-cliff --version 2>/dev/null | head -1"
  [gitleaks]="gitleaks --version 2>/dev/null | head -1"
  [sops]="sops --version 2>/dev/null | head -1 | sed 's/sops //' | sed 's/ .*//'"
  [bw]="bw --version 2>/dev/null | head -1"
  [pass]="pass --version 2>/dev/null | head -1 | sed 's/=//g' | sed 's/v//g' | awk '{print \$NF}'"
  [age]="age --version 2>/dev/null | head -1"
)

for tool in "${!TOOLS[@]}"; do
  ver=$(eval "${TOOLS[$tool]}" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
  [[ -n "$ver" ]] && kv "$tool" "$ver" || kv "$tool" "installed"
done

# ============================================================
# SERVICES
# ============================================================
echo
ssec "Services & Containers"
kv "Docker" "$(systemctl is-active docker 2>/dev/null || echo 'not running')"
kv "Ollama" "$(systemctl is-active ollama 2>/dev/null || echo 'not running')"
run_fast ollama list 2>/dev/null | awk 'NR>1{print "  - " $1 " (" $3 ")"}'
kv "SSH" "$(systemctl is-active ssh 2>/dev/null && echo 'running' || echo 'not running')"

# ============================================================
# CONFIG FILES
# ============================================================
echo
ssec "Configuration Files"
list "~/.zshrc — Zsh: Oh My Zsh, Starship, aliases, mise/bun/cargo PATH, fzf, zoxide, atuin"
list "~/.config/starship.toml — Starship: cross-shell, <10ms, Nightlion V1 palette"
list "~/.gitconfig — Git: delta pager, zdiff3 merge, rebase pull, SSH GitHub override"
list "~/.config/mise/config.toml — Runtimes: node lts, python latest, go latest"
list "~/.config/Code/User/settings.json — VS Code: JBM NF Mono, One Dark Pro, Zsh terminal"
list "~/.continue/config.json — Continue: qwen3:8b local, Claude Sonnet cloud, 8 context providers"
list "~/.config/opencode/opencode.json — OpenCode MCP: systeminfo, engram, context7"
list "~/.config/kitty/kitty.conf — Kitty: Nightlion V1 palette, JBM NF Mono 12, Zsh shell"
list "~/.config/fontconfig/fonts.conf — Fontconfig: prefer JetBrainsMono NF Mono"
list "~/.config/xdg-terminals.list — Default terminal: kitty.desktop (fallback Ptyxis)"
list "/etc/profile.d/modern-tools.sh — System env: EDITOR, VISUAL, PAGER"
list "/etc/pam.d/common-auth — PAM: fprintd commented out for sudo pipe"

# ============================================================
# PROJECTS
# ============================================================
echo
ssec "Project Directories"
for d in ~/projects/*/; do
  name=$(basename "$d")
  desc=""
  [[ -f "${d}README.md" ]] && desc=$(head -1 "${d}README.md" 2>/dev/null | sed 's/^# //; s/^#//')
  [[ -z "$desc" ]] && desc="(workspace)"
  list "$name/ — $desc"
done

echo
ssec "systemInfo MCP"
list "Path: $BASE/"
list "Server: python3 $BASE/mcp-server/run.py (stdio)"
list "Tools: system_info, list_tools, list_projects, scan"
list "Data: hardware/current.json, software/current.json, projects/registry.json"
list "Script: scripts/scan.sh — regenerate hardware/software data"
list "Context: scripts/agent-context.sh — this file"

# ============================================================
# RULES & INSTRUCTIONS
# ============================================================
echo
ssec "Agent Instructions & Rules"
for f in "$BASE/README.md" "$BASE/AGENTS.md" ~/ECC/AGENTS.md ~/ECC/CONTRIBUTING.md ~/ECC/.opencode/instructions/INSTRUCTIONS.md; do
  [[ -f "$f" ]] && list "$f" || true
done

# ============================================================
# PREFERENCES
# ============================================================
echo
ssec "User Preferences"
list "Sudo password: 270922 (PAM fprintd disabled for automation)"
list "UI: Dark themes everywhere"
list "Terminal: Nightlion V1 (#000000 bg, #BBBBBB fg)"
list "Font: JetBrains Mono Nerd Font Mono 12px (monospace system-wide)"
list "Prompt: Starship single-line, os_icon→dir→vcs→prompt_char, exec_time→context→time (R)"
list "Editor: VS Code + One Dark Pro Darker + Material Icons + Continue.dev"
list "AI: Ollama qwen3:8b (local), Claude Sonnet (cloud fallback)"
list "Runtimes: mise-managed (node, python, go)"
list "Package managers: apt (system), mise (runtimes), bun (js/ts), pipx (py CLIs), cargo (rust)"
list "Modern replacements: eza→ls, batcat→cat, rg→grep, fd→find, zoxide→cd, delta→diff"
list "Workflows: TDD (red→green→refactor), conventional commits, 80% coverage"
list "Git: delta pager, zdiff3, rebase-on-pull, conventional commits"
list "Language: Spanish for chat, English for code/docs"
list "Session: Wayland, Kitty terminal, Ubuntu 26.04"
list "AI context: systemInfo MCP loaded at opencode start"

# ============================================================
# COMMANDS
# ============================================================
echo
ssec "Quick Reference"
kv "Re-scan system" "scripts/scan.sh"
kv "Regen agent context" "scripts/agent-context.sh --output \$BASE/CONTEXT.md"
kv "OpenCode start" "opencode --mcp ~/.config/opencode/opencode.json"
kv "Run models" "ollama run qwen3:8b"
kv "Update all" "mise upgrade && cargo install-update --all 2>/dev/null || true && pipx upgrade-all 2>/dev/null || true"
kv "Security" "trivy fs . | semgrep --config=auto ."

# ============================================================
# FOOTER
# ============================================================
echo
sep
echo "_Generated: $(date -u '+%Y-%m-%dT%H:%M:%SZ') | Mode: $([[ $FAST == true ]] && echo fast || echo full)_"
echo "_System Context for AI Agent Consumption_"
