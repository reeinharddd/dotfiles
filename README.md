# dotfiles — Reproducible Linux + AI Agent Harness

> **One-command setup** for a complete development environment: configs, tools, secrets, and an autonomous AI agent harness with observability.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        AI AGENT HARNESS ARCHITECTURE                        │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 1. INTERFACE & EXECUTION (Runtime / CLI)                                   │
│    ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │
│    │    OpenCode     │  │  opencode-      │  │  Model Routing Guard        │ │
│    │  (TUI / VSCode) │──│  antigravity-auth│──│  (plugin: model-routing-    │ │
│    │                 │  │  (Google OAuth, │  │   guard.js)                  │ │
│    │  • Agent loops  │  │   multi-account, │  │  • Agent→Model decisions    │ │
│    │  • MCP client   │  │   fallback)     │  │  • Fallback chains          │ │
│    │  • Permission   │  │                 │  │  • Budget enforcement       │ │
│    │    system       │  │                 │  │                             │ │
│    └─────────────────┘  └─────────────────┘  └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 2. TOOLS & CONTEXT (MCP / Sandbox)                                         │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌────────────────────┐ │
│  │ Context7 MCP │ │ Filesystem   │ │ GitHub MCP   │ │ Docker / E2B       │ │
│  │ (live docs)  │ │ (read/write) │ │ (repos/PRs)  │ │ (code execution)   │ │
│  └──────────────┘ └──────────────┘ └──────────────┘ └────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 3. MEMORY & PERSISTENCE                                                    │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │
│  │ Engram (local)  │  │ AGENTS.md /     │  │ Qdrant (optional,          │ │
│  │ • Session memory│  │ PROJECT_CONTEXT │  │  vector search)            │ │
│  │ • Decisions     │  │  (project rules)│  │  • Episodic memory         │ │
│  │ • Patterns      │  │                 │  │  • Semantic search         │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 4. OBSERVABILITY & EVALS                                                   │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │
│  │ Langfuse        │  │ OpenTelemetry   │  │ opencode-harness-eval      │ │
│  │ (traces, costs, │  │ (OTel collector)│  │ (deterministic test suite) │ │
│  │  evals)         │  │                 │  │  • 15-20 tasks             │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 5. INFERENCE GATEWAY (AI Gateway)                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      LiteLLM Proxy (Docker)                         │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐  │   │
│  │  │  Anthropic  │ │   Google    │ │  OpenRouter │ │   Ollama    │  │   │
│  │  │  (Claude)   │ │  (Gemini)   │ │  (free tiers)│ │  (local)    │  │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘  │   │
│  │  • Virtual keys + budgets    • Fallbacks & retries                │   │
│  │  • Semantic caching          • Langfuse callbacks                 │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Quick Start

```bash
# One-liner (validates checksums, installs tools, stows configs, builds plugins, decrypts secrets)
curl -fsSL https://raw.githubusercontent.com/reeinharddd/dotfiles/main/bootstrap.sh | bash

# Or clone + run
git clone https://github.com/reeinharddd/dotfiles.git ~/projects/personal/dotfiles
cd ~/projects/personal/dotfiles
./bootstrap.sh
```

**Requires**: Ubuntu 24.04+ / Debian 12+ (other distros: adapt `bootstrap.sh`)

---

## 📦 What Gets Installed

| Category | Tools |
|----------|-------|
| **Shell** | zsh, Starship, atuin, fzf, zoxide, direnv |
| **Editor** | Neovim (LazyVim), ghostty terminal |
| **AI** | OpenCode, opencode-antigravity-auth, LiteLLM, Langfuse |
| **Infra** | Docker, mise, restic, pueue, taskwarrior, jrnl |
| **Search** | ripgrep, fd, eza, bat, delta, lazygit, gh |
| **Languages** | Node (via mise), Python, Go, Rust, Cargo tools |

---

## 🔐 Secrets Management (sops + age)

All secrets are **encrypted at rest** in the repo. Decrypt at bootstrap:

```bash
# Age public key (in .sops.yaml)
age1amvy0n3pruw5ndwhd9pkpn2667tykde9dleh5xzt498xy9d52d0strz8uv

# Private key: NEVER in repo → ~/.config/sops/age/keys.txt (mode 600)
# Generate: age-keygen -o ~/.config/sops/age/keys.txt

# Encrypt a file:
sops -e .env > .env.sops

# Decrypt (bootstrap does this automatically):
sops -d .env.sops > .env
```

**Encrypted files in repo**:
- `.env.sops` — API keys for all providers
- `stow/taskman/.config/task/secrets.conf.sops` — Taskwarrior encryption key

**Gitignored (local only)**:
- `.env` (decrypted at runtime)
- `stow/taskman/.config/task/secrets.conf` (decrypted at runtime)
- `~/.config/sops/age/keys.txt` (age private key)

---

## 🤖 AI Harness Usage

```bash
# Start OpenCode (uses antigravity for free tier access)
opencode

# With specific model via LiteLLM
opencode --model litellm/claude-3-5-sonnet

# Run eval suite
opencode-harness-eval

# Security audit
opencode-security-audit
```

**Key plugins** (auto-loaded):
- `opencode-antigravity-auth` — Google OAuth, multi-account, auto-fallback
- `@langfuse/opencode-observability-plugin` — Traces, costs, evals
- `envsitter-guard` — Blocks `.env*` read/write via tools
- `model-routing-guard` — Agent→Model decisions, budgets, fallbacks

---

## 🛠 Configuration

| File | Purpose |
|------|---------|
| `stow/opencode/.config/opencode/opencode.jsonc` | Main OpenCode config (providers, models, plugins, permissions) |
| `stow/litellm/.config/litellm/config.yaml` | LiteLLM model list, virtual keys, routing, budgets |
| `stow/opencode/.config/opencode/oh-my-openagent.json` | Agent definitions, model cascades, categories |
| `stow/misc/.config/systemd/user/*.service` | Systemd user services (litellm, pueued, metronous, restic-backup) |
| `stow/taskman/.config/task/config` | Taskwarrior config (includes encrypted secrets) |
| `.sops.yaml` | sops creation rules (age recipient) |
| `.gitleaks.toml` | Secret detection rules (incl. URL tokens) |

---

## 🔄 Maintenance

```bash
# Sync configs after edits
stow-sync.sh          # Safe restow with backup
stow-sync.sh --dry-run # Preview changes

# Update tools
mise upgrade

# Update plugins
cd stow/opencode/.config/opencode && npm ci && npm run build

# Rotate secrets
sops -e new.env > .env.sops  # Re-encrypt
```

---

## 🧪 CI / Reproducibility

GitHub Actions (`.github/workflows/ci.yml`):
- Bootstrap dry-run in clean Ubuntu container
- `stow-sync.sh --dry-run`
- `shellcheck` on all scripts
- `gitleaks` secret scan (with URL-token rules)
- JSON config validation
- Duplicate config detection

---

## 📁 Repository Structure

```
.
├── .github/workflows/ci.yml       # CI pipeline
├── .sops.yaml                     # sops encryption rules
├── .gitleaks.toml                 # Secret detection config
├── .env.example                   # Template for .env
├── .env.sops                      # Encrypted API keys
├── THREAT_MODEL.md                # This threat model
├── bootstrap.sh                   # One-shot installer
├── scripts/
│   ├── stow-sync.sh               # Safe stow with backup
│   ├── backup-dotfiles.sh         # Auto-commit to private repo
│   └── *.sh                       # Other utilities
├── stow/                          # Stow packages (32)
│   ├── opencode/                  # OpenCode config + plugins
│   ├── litellm/                   # LiteLLM config
│   ├── misc/                      # Systemd services, monitors
│   ├── taskman/                   # Taskwarrior, jrnl, restic
│   └── ... (hyprland, waybar, nvim, etc.)
├── examples/                      # Sanitized config examples
└── docs/                          # Architecture, specs, plans
```

---

## ⚠️ Security Notes

- **No secrets in history** — Rotated; `gitleaks` enforced in CI
- **No personal paths** — All `$HOME`/`%h` templated
- **No sudo password** — Uses `sudo -S` prompt or `sudoers NOPASSWD` for specific commands
- **Backup pushes to private repo** — Set `DOTFILES_BACKUP_REMOTE`
- **Permissions tightened** — `bash`/`webfetch` = `ask` + allowlist

See [THREAT_MODEL.md](THREAT_MODEL.md) for full threat model.

---

## 📄 License

MIT — Use freely. See [THREAT_MODEL.md](THREAT_MODEL.md) for security considerations before deploying in production.

---

**Maintainer**: reeinharddd | **Architecture**: OpenCode + LiteLLM + Langfuse + Engram + MCP