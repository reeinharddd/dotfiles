# System Context: ThinkPad-T14-Gen-3

## System Overview
- **Hostname**: ThinkPad-T14-Gen-3
- **OS**: Ubuntu 26.04 LTS
- **Kernel**: 7.0.0-22-generic
- **Architecture**: x86_64
- **Uptime**: 2 days, 38 minutes
- **Desktop**: ubuntu
- **Session Type**: wayland
- **Default Shell**: zsh 5.9 (configured: /usr/bin/zsh)

## Hardware
- **CPU**: AMD Ryzen 7 PRO 6850U with Radeon Graphics
- **Cores**: 16 threads
- **RAM**: 13Gi total, 9.7Gi used, 4.2Gi avail
- **GPU**: Advanced Micro Devices, Inc. [AMD/ATI] Rembrandt [Radeon 680M] (rev d1)
- **Disk**: 468G total, 39G used (9%)

## Shell Environment
- **Shell**: Zsh 5.9 + Oh My Zsh
- **Prompt**: Starship 1.25 (cross-shell, <10ms, Nightlion V1)
- **Terminal**: Kitty 0.45.0 (GPU-accelerated, default via xdg-terminal-exec)
- **Font**: JetBrainsMono Nerd Font Mono 12 (global: terminal, editor, system)
- **Palette**: Nightlion V1 (#000000 bg, #BBBBBB fg)

## Shell Aliases
- **cat**: batcat --paging=never
- **ls**: eza --icons --group-directories-first
- **cd**: z (zoxide)
- **diff**: delta (git-delta)
- **grep**: rg (ripgrep)
- **find**: fd (fd-find)
- **du**: dust
- **top**: btop

## Development Runtimes
2026.6.3 linux-x64 (2026-06-11)
- **mise**: 2026.6.3 linux-x64 (2026-06-11)
v24.16.0
- **node**: v24.16.0
Python 3.14.6
- **python**: Python 3.14.6
go version go1.26.4 linux/amd64
- **go**: go1.26.4
1.3.14
- **bun**: 1.3.14
cargo 1.96.0 (30a34c682 2026-05-25)
- **cargo**: cargo 1.96.0 (30a34c682 2026-05-25)
rustc 1.96.0 (ac68faa20 2026-05-25)
- **rustc**: rustc 1.96.0 (ac68faa20 2026-05-25)

## Tool Inventory
- **batcat**: bat
- **pass**: installed
- **lazydocker**: 0.25.2
- **gitleaks**: gitleaks version 8.19.0
- **zoxide**: 0.9.9
- **git**: 2.53.0
- **cmake**: 4.2.3
- **chezmoi**: v2.70.5
- **htop**: 3.4.1
- **ollama**: 0.30.7
- **fzf**: 0.67.0
- **rg/ripgrep**: 15.1.0
- **atuin**: atuin 18.16.1 (671f96b60dac49d1d2de73cc0812986a5e22ce7b)
- **pipx**: 1.8.0
- **apt**: 3.2.0 (amd64)
- **just**: 1.52.0
- **make**: 4.4.1
- **procs**: procs "0.14.11 ( rev: 079fa76, rustc: 1.93.1, build at: 2026/02/27 03:07:08 )"
- **delta**: 0.19.2
- **zellij**: zellij 0.44.3
- **docker**: 29.1.3
- **semgrep**: 1.166.0
- **fdfind**: fdfind
- **starship**: 1.25.1
- **btm**: bottom 0.12.3
- **wget**: 1.25.0
- **cargo**: 1.96.0 (30a34c682 2026-05-25)
- **sops**: 3.9.0
- **git-cliff**: git-cliff 2.13.1
- **npm**: 11.13.0
- **trivy**: 0.52.2
- **navi**: navi 2.24.0
- **btop**: 1.4.6
- **jj**: jj 0.29.0-94269d2e7228ff502b2116258e5ae6b3b07ec434
- **age**: 1.2.1
- **gh**: 2.46.0
- **curl**: 8.18.0
- **lazygit**: 2.53.0
- **bw**: 2026.5.0
- **gcc**: 15
- **g++**: 15
- **snap**: 2.75.2+ubuntu26.04.2
- **yazi**: Yazi 26.5.6 (aa52643 2026-05-05)
- **eza**: eza

## Services & Containers
- **Docker**: active
- **Ollama**: active
  - qwen3:8b (5.2)
- **SSH**: inactive
not running

## Configuration Files
- ~/.zshrc — Zsh: Oh My Zsh, Starship, aliases, mise/bun/cargo PATH, fzf, zoxide, atuin
- ~/.config/starship.toml — Starship: cross-shell, <10ms, Nightlion V1 palette
- ~/.gitconfig — Git: delta pager, zdiff3 merge, rebase pull, SSH GitHub override
- ~/.config/mise/config.toml — Runtimes: node lts, python latest, go latest
- ~/.config/Code/User/settings.json — VS Code: JBM NF Mono, One Dark Pro, Zsh terminal
- ~/.continue/config.json — Continue: qwen3:8b local, Claude Sonnet cloud, 8 context providers
- ~/.config/opencode/opencode.json — OpenCode MCP: systeminfo, engram, context7
- ~/.config/kitty/kitty.conf — Kitty: Nightlion V1 palette, JBM NF Mono 12, Zsh shell
- ~/.config/fontconfig/fonts.conf — Fontconfig: prefer JetBrainsMono NF Mono
- ~/.config/xdg-terminals.list — Default terminal: kitty.desktop (fallback Ptyxis)
- /etc/profile.d/modern-tools.sh — System env: EDITOR, VISUAL, PAGER
- /etc/pam.d/common-auth — PAM: fprintd commented out for sudo pipe

## Project Directories
- cli/ — (workspace)
- go/ — (workspace)
- labs/ — (workspace)
- python/ — (workspace)
- rust/ — (workspace)
- web/ — (workspace)

## systemInfo MCP
- Path: ~/systemInfo/
- Server: python3 mcp-server/run.py (stdio)
- Tools: system_info, list_tools, list_projects, scan
- Data: hardware/current.json, software/current.json, projects/registry.json
- Script: scripts/scan.sh — regenerate hardware/software data
- Context: scripts/agent-context.sh — this file

## Agent Instructions & Rules
- /home/reeinharrrd/systemInfo/README.md
- /home/reeinharrrd/ECC/AGENTS.md
- /home/reeinharrrd/ECC/CONTRIBUTING.md
- /home/reeinharrrd/ECC/.opencode/instructions/INSTRUCTIONS.md

## User Preferences
- Sudo password: 270922 (PAM fprintd disabled for automation)
- UI: Dark themes everywhere
- Terminal: Nightlion V1 (#000000 bg, #BBBBBB fg)
- Font: JetBrains Mono Nerd Font Mono 12px (monospace system-wide)
- Prompt: Starship single-line, os_icon→dir→vcs→prompt_char, exec_time→context→time (R)
- Editor: VS Code + One Dark Pro Darker + Material Icons + Continue.dev
- AI: Ollama qwen3:8b (local), Claude Sonnet (cloud fallback)
- Runtimes: mise-managed (node, python, go)
- Package managers: apt (system), mise (runtimes), bun (js/ts), pipx (py CLIs), cargo (rust)
- Modern replacements: eza→ls, batcat→cat, rg→grep, fd→find, zoxide→cd, delta→diff
- Workflows: TDD (red→green→refactor), conventional commits, 80% coverage
- Git: delta pager, zdiff3, rebase-on-pull, conventional commits
- Language: Spanish for chat, English for code/docs
- Session: Wayland, Kitty terminal, Ubuntu 26.04
- AI context: systemInfo MCP loaded at opencode start

## Quick Reference
- **Re-scan system**: ~/systemInfo/scripts/scan.sh
- **Regen agent context**: ~/systemInfo/scripts/agent-context.sh --output ~/systemInfo/CONTEXT.md
- **OpenCode start**: opencode --mcp ~/.config/opencode/opencode.json
- **Run models**: ollama run qwen3:8b
- **Update all**: mise upgrade && cargo install-update --all 2>/dev/null || true && pipx upgrade-all 2>/dev/null || true
- **Security**: trivy fs . | semgrep --config=auto .

---
_Generated: 2026-06-12T23:30:20Z | Mode: full_
_System Context for AI Agent Consumption_
