# Linux Environment Configuration Overhaul — Design Spec

**Date**: 2026-06-30
**Status**: Draft
**Author**: reeinharrrd / Sisyphus

## Overview

Complete overhaul of reeinharrrd's Linux environment (ThinkPad T14 Gen 3, Ubuntu 26.04 GNOME). Based on current **local system state** as source of truth — dotfiles repo documents and divergences, dotfiles follows local.

Five focus areas in order: dotfiles organization/portability, tool redundancy cleanup, performance/startup optimization, terminal/UI aesthetics, and package manager consolidation.

---

## 1. Dotfiles Organization & Portability

### Structure

Keep current repo at `~/projects/personal/dotfiles/` but restructure with GNU Stow (replacing manual `deploy.sh`).

```
dotfiles/
├── stow/                    # stow-managed packages
│   ├── shell/               # .zshrc, .zshenv, profile.d/*
│   ├── git/                 # .gitconfig, .gitignore_global
│   ├── kitty/               # kitty.conf
│   ├── starship/            # starship.toml
│   ├── atuin/               # config.toml
│   ├── atuin/               # config.toml
│   ├── mise/                # config.toml
│   ├── fontconfig/          # fonts.conf
│   ├── gh/                  # gh config.yml
│   └── opencode/            # opencode.json
├── hosts/                   # per-machine overrides
│   └── thinkpad-t14/        # this machine
├── scripts/
│   ├── deploy.sh → stow wrapper (replaces current)
│   ├── bootstrap.sh         # initial setup
│   └── cleanup.sh           # cache/temp cleanup
├── config/
│   ├── env/                 # .zshenv, .zprofile
│   └── local/               # *.local files (gitignore'd)
├── docs/
│   └── superpowers/specs/
└── README.md
```

### Key Changes

| Current | New |
|---------|-----|
| `deploy.sh` with manual symlinks | GNU Stow for all packages |
| No per-machine support | `hosts/<hostname>/` overrides + `*.local` files |
| Hardcoded paths in configs | `$ZDOTDIR`, `XDG_*` env vars for portability |
| Configs directly in repo root | Clean `stow/` tree, one dir per app |

### Source-of-Truth Rule

- **System config is king.** If dotfiles and system disagree, dotfiles updates to match system.
- `adopt-current.sh` snapshots current system state into stow tree.
- Dotfiles should never force a config the system doesn't already use.
- Only after adoption do we improve/template configs.

### Per-Machine Strategy

- **Shared configs** in `stow/` — apply everywhere via `stow -d stow -t ~ <package>`
- **Machine-specific** in `hosts/thinkpad-t14/` — sourced by `*.local` or conditional in .zshrc
- **Secrets/local keys** in `config/local/.gitignore` — never tracked
- **New machine setup**: clone repo → `bootstrap.sh` → `deploy.sh` → done

### Zsh Config Restructure

Move from monolithic `.zshrc` to modular:

```
~/.config/zsh/
├── .zshenv          # env vars only (XDG_*, EDITOR, PATH basics)
├── .zprofile        # login shell (mise, lesspipe, etc.)
├── .zshrc           # main: sources modules
├── modules/
│   ├── 00-options.zsh       # setopt
│   ├── 05-completion.zsh    # compinit, completion settings
│   ├── 10-history.zsh       # HISTFILE, HISTSIZE, savehist
│   ├── 20-keybindings.zsh   # bindkey, vi-mode
│   ├── 30-aliases.zsh       # all aliases
│   ├── 40-functions.zsh     # helper functions
│   ├── 50-prompt.zsh        # starship prompt init
│   ├── 60-plugins.zsh       # oh-my-zsh plugin loading
│   ├── 70-fzf.zsh           # fzf integration
│   ├── 80-zoxide.zsh        # zoxide init
│   ├── 90-atuin.zsh         # atuin init
│   └── 99-local.zsh         # sources *.local if exists
└── completions/     # cached dump files
```

Set `ZDOTDIR=~/.config/zsh` for clean home.

### Zsh Completion Dump Management

Current issue: compdump files ~50-120KB accumulating. Fix:
- Set `ZSH_COMPDUMP=$ZDOTDIR/completions/zcompdump` (fixed path)
- Add post-compinit cleanup: `rm -f $ZSH_COMPDUMP.zwc` (remove old compiled)
- Purge old dumps manually as one-time cleanup

### `.opencode-notify.log` Growth

148MB log. Fix:
- Add log rotation or truncation to opencode config
- Or redirect to `~/.local/state/opencode/` with max-size control

---

## 2. Tool Redundancy Cleanup

### Audit Methodology

For each category, if one tool is clearly superior → remove others. If tools serve different purposes → keep, document.

### Known Duplicates

| Category | Tools | Verdict |
|----------|-------|---------|
| File search | `fd` (cargo), `find` (system) | Keep both — fd for interactive, find in scripts for portability |
| Text search | `rg` (cargo), `grep` (system) | Keep both — ripgrep for speed, grep in scripts |
| Disk usage | `duf` (cargo), `du`/`df` | Keep duf for interactive, system tools in scripts |
| Network | `bandwhich` (cargo), ss/ip | Keep bandwhich for interactive |
| Replace | `sd` (cargo), `sed` (system) | Keep sd for interactive, sed for portability |
| File ops | `fdfind`, `fd`, `find` | fd from cargo is fine, check fdfind alias |
| Make/run | `just` (cargo), `make` | Keep both — just is simpler for tasks |
| Cheat sheets | `navi` (cargo), `tldr` (not installed) | Keep navi, install tldr, set alias |
| LSP | Check for duplicate LSP servers | Audit opencode.json |

### npm Global Cleanup

Current 21 packages. Audit for:
- Remove packages that exist as cargo/system alternatives
- Keep JS/TS-specific tooling (typescript, prettier, etc.)
- Move to mise where applicable (node versions already managed there)

### Snap Audit

22 snaps. Review if any have native apt/flatpak equivalents that integrate better.

### Cargo Bin Audit

28 bins. Review for stale/unused tools.

### Cleanup Process

1. `tool-audit.sh` script that catalogs all installed tools by category
2. Manual review pass — mark keep/remove/consolidate
3. Uninstall confirmed redundancies
4. Document kept tools + purpose in `docs/TOOLS.md`

---

## 3. Performance & Startup Optimization

### Current State

- Zsh compdump ~50-120KB, accumulating stale files
- `.opencode-notify.log` 148MB
- 207 OpenCode domain skills loaded (registry-based, lazy-loaded — check actual impact)
- Oh My Zsh plugins may be loading unnecessary items

### Targets

- Zsh startup < 100ms (currently unknown)
- Clean temp/cache directory structure
- Minimal background services

### Actions

| Area | Action |
|------|--------|
| Zsh startup | Move to modular config, audit OMZ plugins, set fixed compdump path |
| Cache cleanup | Clear compdump, starship cache, mise cache, cargo registry cache |
| Log management | Truncate .opencode-notify.log, configure rotation or redirect |
| OpenCode skills | Audit 207 domain skills — trim unused, ensure lazy-loading works |
| Systemd services | Audit user services — disable unnecessary |
| GNOME extensions | Audit enabled extensions, disable unused |
| Kitty | Check if any performance-heavy features enabled |

### Measurement

- `hyperfine 'zsh -i -c exit'` before/after
- `systemd-analyze blame` for boot
- Track with `health` skill

---

## 4. Aesthetics

### Terminal

| Component | Current | Target |
|-----------|---------|--------|
| Kitty theme | Nightlion V1 | Keep but audit — ensure Nerd Font icons render properly |
| Kitty font | JetBrainsMono Nerd Font | Keep — best for dev |
| Starship | Empty config | Design meaningful prompt sections |
| Zellij theme | Default (gruvbox-ish) | Custom theme matching kitty |
| Kitty opacity/background | Default | Keep solid background for readability |
| LS_COLORS | Default | Configure with vivid for consistent file coloring |

### Starship Prompt Design

Information-dense but clean:

```
┌─ (timestamp) in ~/projects/dotfiles on  main ≡ ❮ v3.5.1
└─ ❯
```

Sections:
- **Timestamp** — `[12:34:56]` — shows when command ran
- **Directory** — truncated path with repo root indicator
- **Git** — branch, status (dirty/clean/ahead/behind)
- **Node/Python/Go** — version when in relevant project (via mise)
- **Cmd duration** — only when > 2s
- **Exit code** — red when non-zero

### Zellij

Not currently in use — skipped. Can be added back later via stow when needed.
### GNOME

- Enforce consistent dark theme across GTK, shell, and apps
- Match terminal color palette to system adwaita-dark
- Review font rendering — keep current fontconfig tweaks
- Disable unused GNOME extensions

---

## 5. Package Manager Consolidation

### Current Inventory

| Manager | Scope | Items |
|---------|-------|-------|
| `apt` | System packages | 91 manual packages |
| `mise` | Language runtimes | node, python, go |
| `cargo` | Rust tools | 28 bins |
| `npm -g` | JS tools | 21 packages |
| `snap` | Confined apps | 22 snaps |
| `bun` | JS runtime/tools | (check) |

### Strategy

**DO NOT** add brew/nix/flatpak — keep minimal surface.

- `apt` — keep for system packages. Use `apt-mark showmanual` to track why installed.
- `mise` — keep for runtimes. Already correct.
- `cargo install` — keep for rust tools. Document which are used.
- `npm -g` — migrate to mise or cargo where possible. Keep JS-only tooling.
- `snap` — review if any can move to apt. Keep only those that need confinement.
- `bun` — keep as JS runtime alternative.

### Dependency Documentation

Create `docs/DEPENDENCIES.md` listing each tool with:
- How it was installed (apt/cargo/npm/snap/mise)
- What it's used for
- Configuration location (which stow package)

---

## Implementation Order

Phase 1 — Dotfiles restructure (stow, modular zsh, portability)
Phase 2 — Cleanup (tools audit, npm/cargo/snap review, log cleanup)
Phase 3 — Performance (zsh startup, cache cleanup, systemd audit)
Phase 4 — Aesthetics (starship, terminal polish, GNOME)
Phase 5 — Package docs + final verification

---

## Success Criteria

- `deploy.sh` replaced by stow — symlink management via `stow` only
- `git clone` on new machine + `bootstrap.sh` gets a working environment
- Zsh startup < 100ms (`hyperfine 'zsh -i -c exit'`)
- No duplicate configs, all known redundancies removed
- Starship prompt shows useful information
- Kitty terminal visually consistent
- `.opencode-notify.log` no longer growing unbounded
- Compdump files cleaned, no further accumulation
- `docs/TOOLS.md` and `docs/DEPENDENCIES.md` document everything
