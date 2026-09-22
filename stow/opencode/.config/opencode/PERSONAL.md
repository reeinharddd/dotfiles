# PERSONAL.md — Personal Preferences (condensed)

> Personal context for the agent. Loaded at session start.

## Identity
- **Handle**: reeinharddd | **Role**: Full-stack dev + sysadmin + automation
- **Location**: Mexico (mx Spanish), UTC-6

## System
- **Hardware**: ThinkPad T14 Gen 3, AMD Ryzen 7 PRO 6850U, 13GiB RAM
- **OS**: Ubuntu 26.04.1, Wayland/Hyprland + GNOME

## Preferences
- **Language**: Spanish (mx) chat; English code/docs
- **Terminal**: ghostty, zsh, Starship
- **Editor**: Neovim (LazyVim), VS Code
- **Theming**: dark, matugen + swww dynamic

## Work Style
- **Caveman mode**: on by default — minimal output
- **AI**: opencode primary, zen/antigravity free, local fallback
- **Automation**: just + pueue + systemd + ntfy
- **Docs**: source of truth = SISTEMA_DOC, INVENTORY, STATE, THREAT_MODEL

## Tools (mise)
- **Runtimes**: Node 24, Python 3.14, Go 1.27, Rust 1.96
- **CLI**: eza, bat, fd, rg, fzf, zoxide, delta, atuin, starship, lazygit, gh
- **Containers**: Docker, restic, pueue, taskwarrior 3.5, jrnl
- **Security**: sops+age, gitleaks, trivy, semgrep

## AI (opencode)
- **Default**: smart (mimo-v2.6-flash-free via zen, SWE-Bench Thinking 78.6)
- **Team**: 4 parallel, background, subagent_depth=2
- **Models**: zen free only — mimo-v2.6 (coding/planes/reviewers), ling-3.0-flash-fin (ejecución/subagentes), nemotron-3-ultra (razonamiento), nemotron-3.5-lightning (rapidez), muse-spark-1.3-contributor (visión); big-pickle/mimo-v2.5 solo fallback (403 previos en subagentes)
- **Routing**: model-routing-guard v21 — default Zen-free por benchmark; fallbacks por función en oh-my-openagent.json + ~/.omo/omo.jsonc + harness-registry.jsonc
- **MCP**: context7, engram, firecrawl, snapmcp, sequential-thinking, metronous, github, playwright, filesystem
- **Security**: envsitter-guard, vibeguard, bash/webfetch=ask+allowlist

## Development
- **Git**: conventional commits, delta, zdiff3, SSH signing
- **Packages**: apt (system), mise (toolchains), flatpak (desktop), cargo binstall (Rust)
- **Testing**: TDD mandatory
- **Quality**: lsp_diagnostics, shellcheck, gitleaks, verify-claims
- **CI**: bootstrap dry-run, stow-sync, shellcheck, gitleaks, JSON validation

## Productivity
- **Tasks**: Taskwarrior 3.5 + sync (127.0.0.1:8090), timew standalone
- **Journal**: jrnl (4 journals)
- **Focus**: pomodoro (25/5), timew
- **Queue**: pueue
- **Reviews**: daily 09:00, end-day 20:00, weekly Sun, monthly restore drill

## Consulting
- **Profiles**: personal (free) / client (local/pay, no training data)
- **Hardware**: laptop (daily), desktop i5-10400/GTX 1070/16GB (canary, local inference)