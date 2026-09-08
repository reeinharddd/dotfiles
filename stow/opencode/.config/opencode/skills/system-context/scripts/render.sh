#!/usr/bin/env bash
# Render CONTEXT.md from JSON data + live system info
# Zero hardcoded values – everything is dynamic
set -euo pipefail

BASE="$(cd "$(dirname "$0")/.." && pwd)"
HW="$BASE/hardware/current.json"
SW="$BASE/software/current.json"
PR="$BASE/projects/registry.json"

[[ -f "$HW" ]] || { echo "Run scan.sh first (missing hardware data)" >&2; exit 1; }
[[ -f "$SW" ]] || { echo "Run scan.sh first (missing software data)" >&2; exit 1; }
[[ -f "$PR" ]] || { echo "Run scan.sh first (missing projects data)" >&2; exit 1; }

jq() { command jq -r "$@" 2>/dev/null || echo "unknown"; }
kv() { printf -- "- **%s**: %s\n" "$1" "${2:-}"; }
list() { printf -- "- %s\n" "$@"; }
_cmd_ver() { "$@" 2>/dev/null | head -1 | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^[[:space:]]*//' | xargs || echo "unknown"; }
_tool() { jq ".\"$1\" // \"not found\"" "$SW"; }
_gl() { jq ".$1 // \"unknown\"" "$HW"; }

GEN=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
HOST=$(_gl hostname)
OS=$(_gl os)
KERNEL=$(_gl kernel)
ARCH=$(uname -m)
UPTIME=$(uptime -p 2>/dev/null | sed 's/up //')
DESKTOP=${XDG_SESSION_DESKTOP:-${XDG_CURRENT_DESKTOP:-unknown}}
SESSION=${XDG_SESSION_TYPE:-wayland}
SHELL_PATH=$(basename "${SHELL:-zsh}")
SHELL_VER=$(_cmd_ver "$SHELL" --version)
OH_MY_ZSH=$([ -d "$HOME/.oh-my-zsh" ] && echo "+ Oh My Zsh" || echo "")

CPU=$(_gl cpu)
CORES=$(_gl cores)
RAM_TOTAL=$(_gl ram)
RAM_USED=$(_gl ram_used)
GPU=$(_gl gpu)
DISK=$(df -h / | awk 'NR==2{print $2 " total, " $3 " used (" $5 ")"}')

FONT_NAME=$(fc-match "monospace" 2>/dev/null | awk -F: '{print $2}' | sed 's/^ *//; s/ *$//; s/"//g' || echo "unknown")
FONT_FILE=$(fc-match "monospace" 2>/dev/null | awk -F: '{print $1}' || echo "unknown")

KITTY_CONF="$HOME/.config/kitty/kitty.conf"
PALETTE_BG=$(grep -oP '^background\s+\K#\w+' "$KITTY_CONF" 2>/dev/null || echo "#000000")
PALETTE_FG=$(grep -oP '^foreground\s+\K#\w+' "$KITTY_CONF" 2>/dev/null || echo "#BBBBBB")
PALETTE_FGBRIGHT=$(grep -oP '^color7\s+\K#\w+' "$KITTY_CONF" 2>/dev/null || echo "#BBBBBB")

TERMINAL_CMD=$(cat /etc/xdg-terminals.list 2>/dev/null | grep -v '^#' | head -1 | awk -F: '{print $1}' || echo "kitty")
TERMINAL_VER=$(_cmd_ver "$TERMINAL_CMD" --version 2>/dev/null || echo "unknown")

KITTY_VER=$(_cmd_ver kitty --version | sed 's/kitty //' | sed 's/ created by.*//')

cat > "$BASE/CONTEXT.md" << CONTEXT_EOF
# System Context: $HOST

## System Overview
$(kv "Hostname" "$HOST")
$(kv "OS" "$OS")
$(kv "Kernel" "$KERNEL")
$(kv "Architecture" "$ARCH")
$(kv "Uptime" "$UPTIME")
$(kv "Desktop" "$DESKTOP")
$(kv "Session Type" "$SESSION")
$(kv "Default Shell" "$SHELL_PATH — $SHELL_VER $OH_MY_ZSH")

## Hardware
$(kv "CPU" "$CPU")
$(kv "Cores" "$CORES threads")
$(kv "RAM" "$RAM_TOTAL total, $RAM_USED used")
$(kv "GPU" "$GPU")
$(kv "Disk" "$DISK")

## Shell Environment
$(kv "Prompt" "Starship $(_cmd_ver starship --version | sed 's/starship //')")
$(kv "Terminal" "$(_cmd_ver "$TERMINAL_CMD" --version 2>/dev/null | head -1 | sed 's/ created by.*//' || echo "$TERMINAL_CMD")")
$(kv "Font" "$FONT_NAME ($FONT_FILE)")
$(kv "Palette" "bg: $PALETTE_BG, fg: $PALETTE_FG, bright: $PALETTE_FGBRIGHT")

## Shell Aliases
$(grep -oP '^alias \K\w+="[^"]*"' "$HOME/.zshrc" 2>/dev/null | sed 's/="/=/' | sed 's/"$//' | while IFS='=' read -r name val; do
  kv "$name" "$val"
done)

## Development Runtimes
$(for t in mise node python go bun cargo rustc; do
  v=$(_tool "$t")
  [[ "$v" != "not found" ]] && kv "$t" "$v"
done)

## Tool Inventory
$(python3 -c "
import json
sw = json.load(open('$SW'))
for name in sorted(sw):
    print(f\"- **{name}**: {sw[name]}\")
")

## Services & Containers
$(for svc in Docker Ollama SSH; do
  s=$(echo "$svc" | tr '[:upper:]' '[:lower:]')
  status=$(systemctl is-active "$s" 2>/dev/null || true)
  status=${status:-inactive}
  kv "$svc" "$status"
done)

## Configuration Files
$(python3 -c "
from pathlib import Path
import re
home = Path.home()
files = {
    '.zshrc': 'Zsh config: plugins, theme, aliases, PATH, tools',
    '.config/starship.toml': 'Starship prompt: palette, format, modules',
    '.gitconfig': 'Git config: delta pager, zdiff3, remotes',
    '.config/mise/config.toml': 'mise runtimes: versions, env vars',
    '.config/Code/User/settings.json': 'VS Code: font, theme, terminal',
    '.config/kitty/kitty.conf': 'Kitty terminal: palette, font, keybinds',
    '.config/opencode/opencode.json': 'OpenCode: agents, MCP servers',
    '.config/fontconfig/fonts.conf': 'Fontconfig: font preferences',
}
for path, desc in sorted(files.items()):
    full = home / path
    if full.exists():
        print(f\"- ~/{path} — {desc}\")
")

## Project Directories
$(python3 -c "
import json
projs = json.load(open('$PR'))
if projs:
    for p in projs:
        lang = p.get('lang', '')
        name = p.get('name', '')
        desc = p.get('version', '')
        if desc:
            print(f\"- {lang}/{name} — v{desc}\")
        else:
            print(f\"- {lang}/{name} — (workspace)\")
else:
    print(\"- (none detected)\")
")

## system-context Skill
$(kv "Path" "\`$BASE\`")
$(kv "Scripts" "\`scripts/scan.sh\` (scan), \`scripts/render.sh\` (render)")
$(kv "Data" "\`hardware/current.json\`, \`software/current.json\`, \`projects/registry.json\`")
$(kv "Cache" "\`CONTEXT.md\` (generated by render.sh)")

## User Preferences
$(kv "UI" "Dark themes everywhere")
$(kv "Editor" "VS Code + One Dark Pro Darker + Material Icons + Continue.dev")

## Quick Reference
$(kv "Rescan system" "\`$BASE/scripts/scan.sh\`")
$(kv "Regen context" "\`$BASE/scripts/render.sh\`")
$(kv "OpenCode start" "opencode --mcp ~/.config/opencode/opencode.json")
$(kv "Run models" "ollama run qwen3:8b")

---
_Generated: $GEN | Mode: full_
_System Context for AI Agent Consumption_
CONTEXT_EOF