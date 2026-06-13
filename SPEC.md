# System Context Universal — Specification

## Purpose
A portable, cross-platform system context generator that produces a comprehensive, agent-consumable description of a development machine. Enables any AI agent to understand the full environment: hardware, software, security, secrets, workflows, and agent guidelines.

## Goals
1. **Universal** — Runs on Linux, macOS, WSL, BSD
2. **Complete** — Captures everything an agent needs to work effectively
3. **Portable** — Single script, no external deps beyond standard OS tools
4. **Structured** — Outputs JSON (for machines) + Markdown (for humans/agents)
5. **Secure** — Never outputs secrets, only references to secret locations
5. **Extensible** — Plugin system for custom detectors

## Output Format

### Primary: JSON (machine-readable, schema-validated)
```json
{
  "schema_version": "1.0",
  "generated_at": "2026-06-12T16:30:00Z",
  "generator_version": "1.0.0",
  "machine_id": "sha256-hostname-username",
  "hardware": { ... },
  "os": { ... },
  "shell": { ... },
  "terminal": { ... },
  "editor": { ... },
  "runtimes": { ... },
  "tools": { ... },
  "security": { ... },
  "secrets": { ... },
  "dotfiles": { ... },
  "services": { ... },
  "workflows": { ... },
  "agent_guidelines": { ... },
  "environment": { ... }
}
```

### Secondary: Markdown (agent/human-readable)
Structured sections with clear headers, tables, and references.

## Core Sections

### 1. Hardware
- CPU (model, cores, threads, arch)
- RAM (total, used, available)
- GPU (model, VRAM if detectable)
- Disks (model, size, type, usage)
- Network interfaces

### 2. OS & Environment
- Distribution, version, kernel, arch
- Desktop environment, session type (Wayland/X11)
- Shell (type, version, config location)
- Terminal emulator (type, version, config)
- Environment variables (filtered)

### 3. Shell Configuration
- Shell type, version, config files
- Prompt (Starship, p10k, Oh My Posh, etc.)
- History (atuin, native, sync status)
- Completions, keybindings
- Aliases (modern replacements mapped)

### 4. Terminal Emulator
- Type (Kitty, Ghostty, WezTerm, iTerm2, Ptyxis, etc.)
- Font (family, size, Nerd Font status)
- Theme/palette
- Multiplexer (tmux, zellij, screen, none)
- GPU acceleration status

### 5. Editor & IDE
- Primary editor (VS Code, Neovim, Zed, etc.)
- Config location, key extensions
- AI assistants (Continue.dev, Copilot, etc.)
- Language servers configured

### 6. Runtimes & Package Managers
- Runtime managers (mise, asdf, nvm, pyenv, sdkman, etc.)
- Installed runtimes (versions, paths)
- Language-specific package managers (npm, pip, cargo, go, bun, etc.)
- System package managers (apt, brew, pacman, dnf, etc.)
- Binary managers (cargo, go install, pipx, npm global, etc.)

### 7. Development Tools (Categorized)
- **Core**: eza, bat, rg, fd, zoxide, delta, dust, duf
- **TUI**: yazi, navi, procs, btm, jj, git-cliff, lazygit, lazydocker
- **System**: btop, fzf, glow, just, cmake, make
- **Git**: git, gh, delta, jj, git-cliff
- **Containers**: docker, podman, colima, k8s tools
- **API/HTTP**: httpie, curl, atac, postman-cli

### 7. Security & Identity
- SSH keys (types, locations, agents)
- GPG/SSH signing keys (signing configured?)
- Secret managers (1Password, Bitwarden, pass, age, sops, gopass, etc.)
- Secret locations (referenced, never exposed)
- Pre-commit hooks (global + per-project)
- Security scanners (gitleaks, trivy, semgrep, etc.)
- Sudo configuration (passwordless, askpass, biometric)

### 8. Secrets References (Never Values)
For each secret manager detected:
- Type (bitwarden, 1password, pass, age, sops, etc.)
- CLI available
- Session/access method
- What it typically stores (API keys, DB passwords, tokens)
- How agents should request access

### 9. Dotfiles & Sync
- Manager (chezmoi, stow, yadm, bare repo, custom)
- Source repo (local path, remote URL)
- Template engine (if any)
- Secrets integration
- Cross-machine sync status

### 10. Services & Containers
- Running services (docker, ollama, postgres, redis, etc.)
- Container runtime (docker, podman, colima, containerd)
- Orchestration (k8s, k3d, kind, docker-compose)
- Local databases

### 11. Workflows & Patterns
- Git workflow (conventional commits, branching, signing)
- TDD/BDD setup
- Pre-commit (global + per-project)
- CI/CD local tools (act, dagger, etc.)
- Testing frameworks per language
- Code quality tools (lint, format, typecheck)

### 12. Agent Guidelines (Critical)
**Rules the agent MUST follow on this machine:**

| Category | Rules |
|----------|-------|
| **Security** | Never output secrets, use secret refs, sudo via askpass, GPG sign commits |
| **Tools** | Use modern replacements (eza not ls, rg not grep, fd not find, bat not cat) |
| **Git** | Conventional commits, GPG sign, jj for complex history |
| **Testing** | TDD mandatory, 80% coverage, pre-commit on every change |
| **Secrets** | Request via BW/1Password CLI, never hardcode, use sops for files |
| **Sudo** | Use `sudo -S` with password from BW, or askpass |
| **Paths** | Use mise shims, cargo bin, bun bin — not system packages |
| **Patterns** | Avoid legacy tools, prefer jj over git for complex ops, use yazi for files |
| **Cleanup** | No temp files in /tmp, use ~/tmp, clean up after |

### 13. Environment Variables (Filtered)
- Relevant: PATH components, EDITOR, VISUAL, PAGER, TERM, SHELL
- Secret refs: `BW_SESSION`, `OP_SESSION`, `GPG_TTY`, `SSH_AUTH_SOCK`
- Build: `CARGO_TARGET_DIR`, `GOPATH`, `NODE_OPTIONS`, etc.

## Cross-Platform Detection Strategy

| Platform | Detection | Tools |
|----------|-----------|-------|
| Linux | `/etc/os-release`, `uname`, `systemd` | `lscpu`, `lsblk`, `lspci`, `free`, `df` |
| macOS | `sw_vers`, `sysctl`, `system_profiler` | `sysctl`, `diskutil`, `ioreg` |
| WSL | `/proc/version`, `WSL_DISTRO_NAME` | Linux tools + `wsl.exe` |
| BSD | `uname`, `sysctl`, `pciconf` | `sysctl`, `df`, `df` |

## Security Model

1. **Never output secret values** — only references
2. **Redact sensitive env vars** — API keys, tokens, passwords
3. **Hash machine ID** — for privacy, not tracking
4. **Local-only by default** — no network calls unless explicit
5. **Read-only** — never modifies system state

## Installation

```bash
# One-liner install
curl -fsSL https://raw.githubusercontent.com/.../system-context/main/install.sh | bash

# Or via package managers
brew install system-context
cargo install system-context
go install github.com/.../system-context@latest
```

## Usage

```bash
# Generate JSON (for agents)
system-context --format json --output context.json

# Generate Markdown (for humans/agents)
system-context --format markdown --output CONTEXT.md

# Quick context for agent injection
system-context --format markdown --compact

# Update cached context
system-context --cache

# Install as skill for agents
system-context --install-skill
```

## Skill Interface

The generated skill provides:
- `load_context()` — loads cached or generates fresh
- `get_capabilities()` — returns tool capabilities matrix
- `get_secret_access()` — returns secret access patterns
- `get_guidelines()` — returns agent rules for this machine
- `refresh()` — regenerates context

## Versioning & Schema

- Semantic versioning for generator
- JSON Schema for output validation
- Backward compatibility guaranteed within major version
- Migration path for schema changes

---

## Implementation Plan

### Phase 1: Core Detector (Python)
- Cross-platform hardware/OS detection
- Tool detection with version parsing
- Security/secrets detection
- JSON + Markdown output

### Phase 2: Shell Integration (Bash)
- Shell-specific config parsing
- Alias/function detection
- Path/env analysis

### Phase 3: Skill Generator
- Universal skill template
- Agent guideline injection
- Cache management

### Phase 4: Distribution
- Installers for each platform
- Auto-update mechanism
- Plugin system