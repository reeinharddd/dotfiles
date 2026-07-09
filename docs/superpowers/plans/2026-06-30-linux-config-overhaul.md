# Linux Environment Overhaul — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Overhaul reeinharrrd's Linux environment across 5 phases: dotfiles restructure (stow + modular zsh + portability), tool redundancy cleanup, performance optimization, aesthetics, and package documentation.

**Architecture:** Current `configs/` + `deploy.sh` → GNU Stow `stow/` tree with per-machine `hosts/<hostname>/` overrides, modular `$ZDOTDIR` zsh config, `adopt-current.sh` to capture system state first. Source of truth = local system state; dotfiles follows.

**Tech Stack:** GNU Stow, Zsh 5.9, Oh My Zsh (minimal), Starship, Kitty, Atuin, mise, cargo, GNOME, systemd

## Global Constraints

- **Source of truth is LOCAL SYSTEM.** Dotfiles must never force a config the system doesn't already use.
- For every modified config: first `adopt-current.sh` captures current state into stow tree, THEN we improve.
- No nix, no brew, no flatpak added.
- Keep `mise` for language runtimes — do not migrate version management.
- Do NOT suppress type errors (`as any`, `@ts-ignore`) in any code/scripts.
- All commits in this plan are conventional commits.
- All shell scripts must be POSIX sh (except where zsh is explicit).

---

## Phase 1: Dotfiles Restructure (Stow + Modular Zsh + Portability)

### Task 1: Create `adopt-current.sh` — snapshot system state into stow tree

**Files:**
- Create: `~/projects/personal/dotfiles/scripts/adopt-current.sh`
- Create: `~/projects/personal/dotfiles/stow/` (top-level dir)
- Test: none — dry-run flags for safety

**Interfaces:**
- Consumes: system files at `~/.zshrc`, `~/.config/kitty/kitty.conf`, etc.
- Produces: `adopt-current.sh` copies current system files into `stow/<package>/` tree

- [ ] **Step 1: Create the adopt-current.sh script**

```bash
#!/usr/bin/env sh
#
# adopt-current.sh — Adopt current system configs into stow tree
#
# Source of truth is the LOCAL SYSTEM. This script captures current
# system state into dotfiles/stow/ so we can version it and improve
# from there. Backs up existing stow files first.
#
# Usage: ./scripts/adopt-current.sh [--dry-run]
#   --dry-run  Preview what would be adopted without copying

set -u

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
STOW_DIR="$DOTFILES_DIR/stow"
BACKUP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles-adopt-backup/$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
  esac
done

adopt() {
  src="$1"          # system source (e.g., $HOME/.zshrc)
  dst="$STOW_DIR/$2"  # stow target (e.g., shell/.zshrc)
  label="$3"

  if [ ! -f "$src" ] && [ ! -d "$src" ]; then
    echo "  SKIP  source missing: $src"
    return
  fi

  if [ -f "$dst" ] || [ -d "$dst" ]; then
    if [ "$(cat "$dst" 2>/dev/null | md5sum)" = "$(cat "$src" 2>/dev/null | md5sum)" ]; then
      echo "  OK    unchanged: $label"
      return
    fi
    if $DRY_RUN; then
      echo "  BACKUP would backup: $dst"
    else
      mkdir -p "$(dirname "$BACKUP_DIR/$2")"
      cp "$dst" "$BACKUP_DIR/$2"
      echo "  BACKUP backed up old: $label"
    fi
  fi

  if $DRY_RUN; then
    echo "  ADOPT  $src -> $dst"
    return
  fi

  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo "  ADOPT  $label"
}

echo "==> Adopting current system configs into stow tree"
echo "    Dry run: $DRY_RUN"
echo ""

# shell
adopt "$HOME/.zshrc" "shell/.zshrc" "zshrc"
adopt "$HOME/.zshenv" "shell/.zshenv" "zshenv" 2>/dev/null || true

# git
adopt "$HOME/.gitconfig" "git/.gitconfig" "gitconfig"
adopt "$HOME/.gitignore_global" "git/.gitignore_global" "gitignore_global" 2>/dev/null || true

# kitty
adopt "$HOME/.config/kitty/kitty.conf" "kitty/kitty.conf" "kitty.conf"

# starship
adopt "$HOME/.config/starship/starship.toml" "starship/starship.toml" "starship.toml"

# atuin
adopt "$HOME/.config/atuin/config.toml" "atuin/config.toml" "atuin config"

# mise
adopt "$HOME/.config/mise/config.toml" "mise/config.toml" "mise config"

# fontconfig
adopt "$HOME/.config/fontconfig/fonts.conf" "fontconfig/fonts.conf" "fonts.conf"

# gh
adopt "$HOME/.config/gh/config.yml" "gh/config.yml" "gh config"

echo ""
echo "==> Done. Stow tree ready at $STOW_DIR"
```

- [ ] **Step 2: Create stow subdirectories (empty initial structure)**

Run: `mkdir -p ~/projects/personal/dotfiles/stow/{shell,git,kitty,starship,atuin,mise,fontconfig,gh,opencode}`

- [ ] **Step 3: Run adopt-current.sh to capture current state**

Run: `cd ~/projects/personal/dotfiles && bash scripts/adopt-current.sh`

Expected: copies current configs into `stow/` tree.

- [ ] **Step 4: Verify stow tree has files**

Run: `ls -la stow/*/` — confirm each package dir has its files.

- [ ] **Step 5: Commit**

```bash
git add scripts/adopt-current.sh stow/
git commit -m "feat: add adopt-current.sh and initial stow tree from system state"
```

---

### Task 2: Replace `deploy.sh` with Stow wrapper

**Files:**
- Modify: `scripts/deploy.sh` → replace with stow wrapper
- Modify: `README.md` → update structure and usage

**Interfaces:**
- Consumes: `stow/<package>/` directories
- Produces: stow creates symlinks to `$HOME`

- [ ] **Step 1: Write new deploy.sh using stow**

```bash
#!/usr/bin/env sh
#
# deploy.sh — Deploy dotfiles via GNU Stow
#
# Idempotent, backup-first. Uses stow for symlink management.
# Run with --dry-run to preview.
#
# Usage: ./scripts/deploy.sh [--dry-run] [package...]
#   Without args, deploys all packages.
#   With package names, deploys only those.

set -u

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
STOW_DIR="$DOTFILES_DIR/stow"
BACKUP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false
STOW_ARGS=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --adopt) STOW_ARGS="$STOW_ARGS --adopt" ;;
    -*)
      echo "Unknown option: $arg"
      echo "Usage: $0 [--dry-run] [--adopt] [package...]"
      exit 1
      ;;
  esac
done

# Collect package targets (shift past flags)
PACKAGES=""
for arg in "$@"; do
  case "$arg" in
    -*) ;;
    *) PACKAGES="$PACKAGES $arg" ;;
  esac
done

if [ -z "$PACKAGES" ]; then
  # Default: all stow packages (directories with no dot prefix)
  for d in "$STOW_DIR"/*/; do
    PACKAGES="$PACKAGES $(basename "$d")"
  done
fi

echo "==> Deploying dotfiles via stow"
echo "    Stow dir: $STOW_DIR"
echo "    Dry run: $DRY_RUN"
echo "    Home: $HOME"
echo ""

# Check stow is installed
if ! command -v stow >/dev/null 2>&1; then
  echo "ERROR: stow not found. Install it first: sudo apt install stow"
  exit 1
fi

stow_cmd="stow -d $STOW_DIR -t $HOME"
if $DRY_RUN; then
  stow_cmd="$stow_cmd --no"  # stow --no = simulate
fi
$RESTOW && stow_cmd="$stow_cmd --restow"

deploy_count=0
fail_count=0

for pkg in $PACKAGES; do
  pkg_dir="$STOW_DIR/$pkg"
  if [ ! -d "$pkg_dir" ]; then
    echo "  SKIP  package not found: $pkg"
    continue
  fi

  if $DRY_RUN; then
    echo "  STOW  would deploy: $pkg"
  else
    # Backup any existing file that would be overwritten
    # (stow refuses if file exists and is not a symlink)
    needs_backup=false
    # Use stow's --no to check what it would do
    if $stow_cmd --no "$pkg" 2>&1 | grep -q "existing target"; then
      needs_backup=true
    fi

    if $needs_backup; then
      # Find what stow would conflict with
      for f in $(find "$pkg_dir" -type f -o -type l | sed "s|$pkg_dir/||"); do
        target="$HOME/$f"
        if [ -f "$target" ] && [ ! -L "$target" ]; then
          mkdir -p "$(dirname "$BACKUP_DIR/$f")"
          cp "$target" "$BACKUP_DIR/$f"
          echo "  BACKUP backed up: $target"
        fi
      done
    fi

    if $stow_cmd "$pkg" 2>&1; then
      echo "  STOW  deployed: $pkg"
      deploy_count=$((deploy_count + 1))
    else
      echo "  FAIL  could not stow: $pkg"
      fail_count=$((fail_count + 1))
    fi
  fi
done

echo ""
echo "==> Summary: $deploy_count deployed, $fail_count failed"
```

- [ ] **Step 2: Update README.md with new structure**

Edit `README.md` to reflect the new stow-based layout.

```markdown
# dotfiles — Personal Config Backup

Personal configuration files with stow management and per-machine support.

## Structure

```
dotfiles/
├── stow/                     # stow-managed packages (one dir per app)
│   ├── shell/                # .zshrc, .zshenv
│   ├── git/                  # .gitconfig, .gitignore_global
│   ├── kitty/                # kitty.conf
│   ├── starship/             # starship.toml
│   ├── atuin/                # config.toml
│   ├── mise/                 # config.toml
│   ├── fontconfig/           # fonts.conf
│   ├── gh/                   # config.yml
│   └── opencode/             # opencode.json, etc.
├── hosts/                    # per-machine overrides (gitignored system-specific)
├── scripts/
│   ├── deploy.sh             # stow wrapper — deploys all or specific packages
│   ├── adopt-current.sh      # snapshot system state into stow tree
│   └── bootstrap.sh          # initial setup on new machine
├── config/
│   └── local/                # *.local files (gitignored)
├── docs/
│   └── superpowers/
└── README.md
```

## Quick Install

```bash
git clone ssh://git@github.com/reeinharddd/dotfiles ~/projects/personal/dotfiles
~/projects/personal/dotfiles/scripts/deploy.sh
```

## Commands

| Command | Description |
|---------|-------------|
| `./scripts/deploy.sh` | Deploy all configs via stow |
| `./scripts/deploy.sh --dry-run` | Preview what would change |
| `./scripts/deploy.sh <package>` | Deploy only one package |
| `./scripts/adopt-current.sh` | Snapshot current system configs into stow |
| `./scripts/bootstrap.sh` | Full bootstrap on new machine |
```

- [ ] **Step 3: Remove old `configs/` directory contents that were migrated to `stow/`**

```bash
# Verify stow has everything first
diff <(ls configs/) <(ls stow/) || echo "Check manually — some may differ"
# Remove old configs/ if stow tree is complete
git rm -r configs/shell configs/git configs/kitty configs/starship configs/atuin configs/mise configs/fontconfig configs/gh configs/opencode
rmdir configs/ 2>/dev/null || true
```

Keep `configs/.gitkeep` initially until migration is fully verified.

- [ ] **Step 4: Commit**

```bash
git add README.md scripts/deploy.sh
git commit -m "refactor: replace deploy.sh with stow wrapper, update README"
```

---

### Task 3: Set up ZDOTDIR with modular Zsh config

**Files:**
- Create: `stow/shell/.zshenv`
- Create: `stow/shell/.zshrc` (modular — sources modules)
- Create: `stow/shell/modules/00-options.zsh`
- Create: `stow/shell/modules/05-completion.zsh`
- Create: `stow/shell/modules/10-history.zsh`
- Create: `stow/shell/modules/20-keybindings.zsh`
- Create: `stow/shell/modules/30-aliases.zsh`
- Create: `stow/shell/modules/40-functions.zsh`
- Create: `stow/shell/modules/50-prompt.zsh`
- Create: `stow/shell/modules/60-plugins.zsh`
- Create: `stow/shell/modules/70-fzf.zsh`
- Create: `stow/shell/modules/80-zoxide.zsh`
- Create: `stow/shell/modules/90-atuin.zsh`
- Create: `stow/shell/modules/99-local.zsh`

- [ ] **Step 1: Create .zshenv**

```zsh
# ~/.zshenv — Environment variables only
# This file is sourced by ALL zsh instances (login, interactive, script)

export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"

# XDG Base Directory
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Editors & Browsers
export EDITOR="${EDITOR:-code --wait}"
export VISUAL="${VISUAL:-code --wait}"
export BROWSER="${BROWSER:-brave-browser}"

# PATH basics (only what's needed before .zshrc loads)
typeset -U PATH path
path=(
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "$HOME/.bun/bin"
  "$HOME/go/bin"
  $path
)

# Pager
export LESS="${LESS:--R}"
export PAGER="${PAGER:-less}"
```

- [ ] **Step 2: Create modules/00-options.zsh**

```zsh
# 00-options.zsh — Zsh options (setopt)

# History
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt EXTENDED_HISTORY

# Navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS

# Completion
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt MENU_COMPLETE

# Correction
setopt CORRECT
```

- [ ] **Step 3: Create modules/05-completion.zsh**

```zsh
# 05-completion.zsh — Completion settings

# Fixed compdump path (no accumulation)
autoload -U compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' special-dirs true

# Cache path
ZSH_COMPDUMP="${ZSH_COMPDUMP:-$ZDOTDIR/completions/zcompdump}"

compinit -d "$ZSH_COMPDUMP"

# Clean old compiled dumps
[[ -f "$ZSH_COMPDUMP.zwc" ]] && rm -f "$ZSH_COMPDUMP.zwc"
```

- [ ] **Step 4: Create modules/10-history.zsh**

```zsh
# 10-history.zsh — History settings

HISTSIZE=100000
SAVEHIST=100000
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"

# Ensure history directory exists
[[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}"
```

- [ ] **Step 5: Create modules/20-keybindings.zsh**

```zsh
# 20-keybindings.zsh — Key bindings

bindkey -v  # vi mode

# History search with arrow keys
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search
```

- [ ] **Step 6: Create modules/30-aliases.zsh**

```zsh
# 30-aliases.zsh — All aliases

# Modern CLI replacements
alias ls="eza --icons --group-directories-first"
alias ll="eza -la --icons --git --group-directories-first"
alias l="eza -l --icons --git --group-directories-first"
alias lt="eza --icons --tree --group-directories-first"
alias cat="batcat --paging=never"
alias grep="rg"
alias find="fdfind"
alias fd="fdfind"
alias cd="z"
alias du="dust"
alias top="btop"
alias help="tldr"
alias ps="procs"
alias df="duf"

# Editors
alias vim="nvim"
alias vi="nvim"

# TUIs
alias lg="lazygit"
alias ld="lazydocker"
alias gl="glow"
alias yz="yazi"
alias nv="navi"

# Git shorthand
alias gc="git clone"
alias gs="git status"
alias gp="git push"
alias ga="git add"
alias gcm="git commit -m"
alias gco="git checkout"
alias gb="git branch"
alias gj="jj"

# Navigation
alias dev="cd ~/projects"
alias dotfiles="cd ~/projects/personal/dotfiles"
```

- [ ] **Step 7: Create modules/40-functions.zsh**

```zsh
# 40-functions.zsh — Helper functions

# Quick directory creation + entry
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Extract any archive
extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2) tar xjf "$1" ;;
      *.tar.gz)  tar xzf "$1" ;;
      *.tar.xz)  tar xJf "$1" ;;
      *.bz2)     bunzip2 "$1" ;;
      *.rar)     unrar x "$1" ;;
      *.gz)      gunzip "$1" ;;
      *.tar)     tar xf "$1" ;;
      *.tbz2)    tar xjf "$1" ;;
      *.tgz)     tar xzf "$1" ;;
      *.zip)     unzip "$1" ;;
      *.Z)       uncompress "$1" ;;
      *)         echo "Unknown archive: $1" ;;
    esac
  else
    echo "Not a file: $1"
  fi
}

# Open code with context
ctx() {
  bash ~/projects/personal/dotfiles/scripts/agent-context.sh --fast 2>/dev/null
}
```

- [ ] **Step 8: Create modules/50-prompt.zsh**

```zsh
# 50-prompt.zsh — Starship prompt init
eval "$(starship init zsh)"
```

- [ ] **Step 9: Create modules/60-plugins.zsh**

```zsh
# 60-plugins.zsh — Oh My Zsh plugin loading

export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_THEME=""  # Starship handles prompt

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  fzf
  zoxide
  docker
  gh
  mise
)

source "$ZSH/oh-my-zsh.sh"
```

- [ ] **Step 10: Create modules/70-fzf.zsh**

```zsh
# 70-fzf.zsh — fzf integration

source /usr/share/doc/fzf/examples/key-bindings.zsh 2>/dev/null
source /usr/share/doc/fzf/examples/completion.zsh 2>/dev/null

export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
export FZF_CTRL_T_OPTS="--preview 'batcat --color=always --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --icons --tree {} | head -50'"
```

- [ ] **Step 11: Create modules/80-zoxide.zsh**

```zsh
# 80-zoxide.zsh — zoxide init
eval "$(zoxide init zsh)"
```

- [ ] **Step 12: Create modules/90-atuin.zsh**

```zsh
# 90-atuin.zsh — Atuin history
. "$HOME/.atuin/bin/env" 2>/dev/null
eval "$(atuin init zsh --disable-up-arrow)" 2>/dev/null
```

- [ ] **Step 13: Create modules/99-local.zsh**

```zsh
# 99-local.zsh — Local overrides (machine-specific, not in dotfiles)
# Sources *.local files in $ZDOTDIR/modules/
for f in "$ZDOTDIR/modules/"*.local(N); do
  source "$f"
done

# Also source ~/.config/local/*.sh if exists
for f in "$HOME/.config/local/"*.sh(N); do
  source "$f"
done
```

- [ ] **Step 14: Create main .zshrc**

```zsh
# ~/.config/zsh/.zshrc — Main zsh config
# Sources modular components from $ZDOTDIR/modules/

# Source all modules in order
for module in "$ZDOTDIR/modules/"*.zsh(N); do
  source "$module"
done

# Runtime managers (eval-based, must be after PATH)
eval "$(mise activate zsh)"
source "$HOME/.cargo/env" 2>/dev/null

# OpenCode PATH
export PATH="$HOME/.opencode/bin:$PATH"
export PLAYWRIGHT_HOST_PLATFORM_OVERRIDE=ubuntu24.04-x64
```

- [ ] **Step 15: Commit**

```bash
git add stow/shell/
git commit -m "feat: add modular zsh config with ZDOTDIR setup"
```

---

### Task 4: Create hosts/ structure for per-machine overrides

**Files:**
- Create: `hosts/thinkpad-t14/` directory with `.gitkeep`
- Create: `docs/SETUP-NEW-MACHINE.md`
- Create: `scripts/bootstrap.sh`
- Modify: `stow/shell/modules/99-local.zsh` (already done above)

- [ ] **Step 1: Create hosts directory structure**

```bash
mkdir -p ~/projects/personal/dotfiles/hosts/thinkpad-t14
touch ~/projects/personal/dotfiles/hosts/thinkpad-t14/.gitkeep
```

- [ ] **Step 2: Create bootstrap.sh**

```bash
#!/usr/bin/env sh
#
# bootstrap.sh — Set up dotfiles on a new machine
#
# Steps: install stow, stow packages, set ZDOTDIR, install mise deps.

set -u

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"

echo "==> Bootstrap: setting up dotfiles on $(hostname)"

# 1. Install stow if missing
if ! command -v stow >/dev/null 2>&1; then
  echo "==> Installing stow..."
  sudo apt install -y stow
fi

# 2. Set ZDOTDIR symlink (only if not already set)
if [ ! -d "$HOME/.config/zsh" ]; then
  echo "==> Setting up ZDOTDIR..."
  # Ensure .zshenv points to ZDOTDIR
  if [ ! -f "$HOME/.zshenv" ]; then
    echo 'export ZDOTDIR="$HOME/.config/zsh"' > "$HOME/.zshenv"
  fi
fi

# 3. Deploy all stow packages
echo "==> Deploying dotfiles..."
"$DOTFILES_DIR/scripts/deploy.sh"

echo ""
echo "==> Bootstrap complete. Start a new shell to apply changes."
```

- [ ] **Step 3: Create per-machine setup doc**

```markdown
# Setting Up a New Machine

1. Install base deps: `sudo apt install -y git stow zsh curl`
2. Clone dotfiles: `git clone ssh://git@github.com/reeinharddd/dotfiles ~/projects/personal/dotfiles`
3. Run bootstrap: `~/projects/personal/dotfiles/scripts/bootstrap.sh`
4. Create host override dir: `mkdir -p ~/projects/personal/dotfiles/hosts/$(hostname)`
5. Add machine-specific overrides as `*.local` files in `~/.config/local/`
6. Commit overrides: `git -C ~/projects/personal/dotfiles add hosts/$(hostname) && git commit`
7. Restart shell: `exec zsh`
```

- [ ] **Step 4: Commit**

```bash
git add hosts/ scripts/bootstrap.sh docs/SETUP-NEW-MACHINE.md
git commit -m "feat: add hosts/ structure for per-machine configs and bootstrap"
```

---

### Task 5: Create config/local/ structure for secrets and gitignored overrides

**Files:**
- Create: `config/local/` with `.gitignore`
- Create: `config/local/README.md`

- [ ] **Step 1: Create local config structure**

```bash
mkdir -p ~/projects/personal/dotfiles/config/local
```

- [ ] **Step 2: Create .gitignore for config/local/**

```
# Ignore all local overrides
*
!.gitignore
!README.md
```

- [ ] **Step 3: Create README for local configs**

```markdown
# Local Overrides

Files in this directory are machine-specific and gitignored.
They are NOT tracked in the dotfiles repo.

Use for:
- Secrets and tokens
- Machine-specific environment variables
- Host-specific config overrides
- Temporary debug configs

Files are sourced automatically via `99-local.zsh` when they
exist in `~/.config/local/*.sh`.

To add a local override:
1. Create `~/.config/local/machine.sh`
2. Add env vars, aliases, or overrides
3. Source is automatic via the 99-local.zsh module
```

- [ ] **Step 4: Commit**

```bash
git add config/local/
git commit -m "feat: add config/local/ for untracked machine-specific overrides"
```

---

## Phase 2: Tool Redundancy Cleanup

### Task 6: Create tool-audit.sh — catalog all installed tools

**Files:**
- Create: `scripts/tool-audit.sh`
- Create: `docs/TOOLS.md` (output)

- [ ] **Step 1: Create audit script**

```bash
#!/usr/bin/env sh
#
# tool-audit.sh — Catalog all installed tools by category
#
# Output: categorized list for manual review

set -u

echo "============================================"
echo "  Tool Audit — reeinharrrd's environment"
echo "  Date: $(date)"
echo "============================================"
echo ""

# apt manual packages
echo "--- apt (manual via apt-mark showmanual) ---"
apt-mark showmanual 2>/dev/null | sort || echo "(apt-mark not available)"
echo ""

# cargo installed tools
echo "--- cargo install ---"
ls "$HOME/.cargo/bin/" 2>/dev/null | sort || echo "(no cargo bins)"
echo ""

# npm global packages
echo "--- npm global ---"
npm list -g --depth=0 2>/dev/null | grep -v "^/" | grep -v "npm@" || echo "(no npm globals)"
echo ""

# snap packages
echo "--- snap ---"
snap list 2>/dev/null | awk 'NR>1 {print $1}' | sort || echo "(no snaps)"
echo ""

# mise installed tools
echo "--- mise ---"
mise list 2>/dev/null || echo "(no mise)"
echo ""

# bun tools
echo "--- bun ---"
bun --version 2>/dev/null && echo "bun installed" || echo "bun not installed"
echo ""

# pipx / pip user packages
echo "--- pip user packages ---"
pip list --user 2>/dev/null | awk 'NR>2 {print $1" "$2}' | sort || echo "(no pip user)"
echo ""

echo "============================================"
echo "  Report saved to docs/TOOLS.md (after review)"
echo "============================================"
```

- [ ] **Step 2: Run the audit**

```bash
bash scripts/tool-audit.sh
```
Expected: categorized list of all tools.

- [ ] **Step 3: Create initial TOOLS.md from audit output**

Create `docs/TOOLS.md` with the categorized output. Mark known essential tools. Review and mark:
- Keep: cargo bins you actually use (delta, bat, fd, ripgrep, dust, duf, just, navi, sd, zoxide, etc.)
- Keep: npm globals needed for JS/TS work (typescript, prettier, etc.)
- Review: snaps — which can move to apt
- Remove: any stale/test tools no longer needed

```markdown
# Tools Inventory

## Essential (keep)

| Tool | Install Method | Purpose |
|------|---------------|---------|
| stow | apt | Dotfiles symlink management |
| batcat | apt | File preview with syntax highlighting |
| eza | cargo | Modern ls replacement |
| ripgrep (rg) | cargo | Fast text search |
| fd-find | cargo | Fast file search |
| dust | cargo | Disk usage visualization |
| duf | cargo | Disk usage (interactive) |
| btop | apt | System monitor |
| procs | cargo | Modern ps replacement |
| lazygit | (check) | Git TUI |
| lazydocker | (check) | Docker TUI |
| glow | (check) | Markdown renderer |
| yazi | cargo | Terminal file manager |
| navi | cargo | Interactive cheatsheet |
| tldr | (to install) | Simplified man pages |
| delta | cargo | Git diff viewer |
| just | cargo | Task runner |
| sd | cargo | Find-and-replace |
| zoxide | cargo | Smarter cd |
| mise | (check) | Runtime version manager |

## Language Runtimes (mise)

- node, python, go — managed by mise

## Under Review

[List items from audit marked for review]
```

- [ ] **Step 4: Commit**

```bash
git add scripts/tool-audit.sh docs/TOOLS.md
git commit -m "docs: add tool-audit.sh and initial TOOLS.md inventory"
```

---

### Task 7: Clean up redundancies

**Files:** System-level — no dotfiles changes

- [ ] **Step 1: Clean cargo stale tools**

```bash
# List installed cargo tools
cargo install --list | grep -E '^[a-z]' | awk '{print $1}'

# Remove anything confirmed unused
# cargo uninstall <tool-name>
```

- [ ] **Step 2: Clean npm global packages**

```bash
# List npm globals
npm list -g --depth=0

# Remove node/noir tooling not needed globally
# npm uninstall -g <package>
```

- [ ] **Step 3: Clean snaps**

```bash
# List all snaps
snap list

# Remove snaps with apt equivalents
# sudo snap remove <snap-name>
# sudo apt install <apt-equivalent>
```

- [ ] **Step 4: Install tldr (alias help points there but not installed)**

```bash
# Install via cargo (recommended for speed)
cargo install tealdeer
# Or via apt
# sudo apt install tldr
```

- [ ] **Step 5: Commit TOOLS.md updates**

```bash
git add docs/TOOLS.md
git commit -m "docs: update TOOLS.md after redundancy cleanup"
```

---

### Task 8: Clean up .opencode-notify.log (148MB)

**Files:** System-level

- [ ] **Step 1: Truncate the log**

```bash
# Check current size
ls -lh ~/.opencode-notify.log

# Truncate (safe — just log data)
: > ~/.opencode-notify.log
```

- [ ] **Step 2: OpenCode log configuration**

Check `stow/opencode/opencode.json` or `stow/opencode/oh-my-openagent.json` for log settings. If the log is managed by opencode internals, we may not have config control. Document the truncation.

- [ ] **Step 3: Set up log rotation as a safety net**

```bash
# Create logrotate config for opencode notify log
sudo tee /etc/logrotate.d/opencode-notify > /dev/null << 'EOF'
/home/reeinharrrd/.opencode-notify.log {
    weekly
    rotate 4
    size 10M
    compress
    missingok
    notifempty
}
EOF
```

- [ ] **Step 4: Commit**

```bash
git add docs/TOOLS.md  # log cleanup note
git commit -m "chore: truncate .opencode-notify.log, add logrotate config"
```

---

## Phase 3: Performance & Startup Optimization

### Task 9: Measure current Zsh startup time

**Files:** None — measurement only

- [ ] **Step 1: Hyperfine zsh startup**

```bash
# Install hyperfine if not present
# cargo install hyperfine

# Before measurement
hyperfine 'zsh -i -c exit' 2>&1
```

Expected: current baseline time (record it).

- [ ] **Step 2: Measure OMZ loading separately**

```zsh
# Quick check inside zsh
zsh -i -c 'echo "OMZ loaded: $ZSH_VERSION, plugins: $plugins"'
```

- [ ] **Step 3: Record baseline**

Note: "Before: Xms zsh startup" in commit.

---

### Task 10: Audit Oh My Zsh plugins — remove unnecessary

**Files:**
- Modify: `stow/shell/modules/60-plugins.zsh`

- [ ] **Step 1: Review current plugin list**

```zsh
# Current plugins: git, zsh-autosuggestions, zsh-syntax-highlighting, fzf, zoxide, docker, gh, mise
```

Decisions:
- Keep: `git` (light), `zsh-autosuggestions`, `zsh-syntax-highlighting`, `fzf`, `zoxide`, `mise`
- Review: `docker`, `gh` — check if aliases are actually used, if not remove
- Condense: if `gh` plugin only provides aliases you don't use, remove

- [ ] **Step 2: Update 60-plugins.zsh if removing plugins**

Remove any unnecessary plugins.

- [ ] **Step 3: Commit**

```bash
git add stow/shell/modules/60-plugins.zsh
git commit -m "perf: audit OMZ plugins, remove unnecessary"
```

---

### Task 11: Clean cache directories

**Files:** None — system cleanup

- [ ] **Step 1: Clean zsh compdump files**

```bash
# Remove old compdump files
rm -f ~/.zcompdump* ~/.cache/zsh/*
```

- [ ] **Step 2: Clean starship cache**

```bash
starship clear-cache 2>/dev/null || true
```

- [ ] **Step 3: Clean mise cache**

```bash
mise cache clear 2>/dev/null || true
```

- [ ] **Step 4: Clean cargo registry cache**

```bash
# Cargo registry can be large
cargo cache --autoclean 2>/dev/null || true
# Or manually:
rm -rf ~/.cargo/registry/cache/* 2>/dev/null || true
```

- [ ] **Step 5: Create cleanup.sh script**

```bash
#!/usr/bin/env sh
#
# cleanup.sh — Clean caches and temp files

set -u

echo "==> Cleaning caches..."

# Zsh compdump
rm -f ~/.zcompdump* 2>/dev/null
rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/" 2>/dev/null

# Starship
starship clear-cache 2>/dev/null && echo "  starship cache cleared" || true

# Mise
mise cache clear 2>/dev/null && echo "  mise cache cleared" || true

# Cargo
cargo cache --autoclean 2>/dev/null && echo "  cargo cache cleaned" || true

echo "==> Done"
```

```bash
git add scripts/cleanup.sh
git commit -m "chore: add cleanup.sh, clear caches"
```

- [ ] **Step 6: Measure after**

```bash
hyperfine 'zsh -i -c exit' 2>&1
```

Expected: improvement over baseline.

---

### Task 12: Systemd user services audit

**Files:** None

- [ ] **Step 1: List enabled user services**

```bash
systemctl --user list-unit-files --state=enabled
```

- [ ] **Step 2: Disable unnecessary ones**

```bash
# Review each. Disable with:
# systemctl --user disable <service>
```

- [ ] **Step 3: Check boot time**

```bash
systemd-analyze blame | head -20
```

---

### Task 13: GNOME extensions audit

**Files:** None

- [ ] **Step 1: List enabled extensions**

```bash
gnome-extensions list --enabled
```

- [ ] **Step 2: Disable unused**

```bash
# gnome-extensions disable <uuid>
```

---

## Phase 4: Aesthetics

### Task 14: Design and configure Starship prompt

**Files:**
- Modify: `stow/starship/starship.toml`

- [ ] **Step 1: Design starship.toml**

```toml
# ~/.config/starship/starship.toml

# Format: timestamp + directory + git + line break + prompt char
format = """
[░▒▓](#a277ff)\
$time\
$all\
$character"""

# Right format on same line as prompt for clean look
right_format = """$cmd_duration"""

# --- Time module ---
[time]
disabled = false
format = '[$time]($style)'
style = 'bright-black'
time_format = '%H:%M:%S'

# --- Directory ---
[directory]
truncation_length = 3
truncation_symbol = '…/'
style = 'cyan'
format = '[$path]($style)'

# --- Git branch ---
[git_branch]
format = '[$symbol$branch]($style)'
style = 'purple'
symbol = ' '

# --- Git status ---
[git_status]
format = '[$all_status$ahead_behind]($style)'
style = 'yellow'
conflicted = '🏳'
up_to_date = ''
ahead = '⇡${count}'
behind = '⇣${count}'
diverged = '⇕⇡${ahead_count}⇣${behind_count}'
stashed = '📦'

# --- Node.js ---
[nodejs]
format = 'via [⬢ $version](green) '
detect_files = ['package.json', '.node-version']
disabled = false

# --- Python ---
[python]
format = 'via [🐍 $version](blue) '
detect_files = ['pyproject.toml', 'requirements.txt', '.python-version', 'Pipfile']

# --- Go ---
[golang]
format = 'via [🦫 $version](cyan) '
detect_files = ['go.mod', 'go.sum']

# --- Rust ---
[rust]
format = 'via [🦀 $version](red) '
detect_files = ['Cargo.toml']

# --- Command duration ---
[cmd_duration]
format = '⏱️ $duration'
min_time = 2000
style = 'bright-black'

# --- Character ---
[character]
success_symbol = '[❯](green)'
error_symbol = '[❯](red)'
vimcmd_symbol = '[❮](green)'
```

- [ ] **Step 2: Apply and test**

```bash
stow -d ~/projects/personal/dotfiles/stow -t ~ starship
```
Open a new terminal — verify prompt renders correctly with Nerd Font icons.

- [ ] **Step 3: Commit**

```bash
git add stow/starship/starship.toml
git commit -m "feat: design starship prompt with time, git, language modules"
```

---

### Task 15: Configure LS_COLORS with vivid

**Files:** None (shell module already handles)

- [ ] **Step 1: Generate LS_COLORS with vivid**

```bash
# Install vivid if not present
cargo install vivid

# Generate dracula theme
vivid generate dracula

# Add to zsh modules (in 00-options or 30-aliases)
echo 'export LS_COLORS="$(vivid generate dracula)"' >> ~/.config/zsh/modules/00-options.zsh
```

- [ ] **Step 2: Update stow/shell/modules/00-options.zsh**

Add the vivid line to the module file in dotfiles.

- [ ] **Step 3: Commit**

```bash
git add stow/shell/modules/00-options.zsh
git commit -m "feat: add vivid LS_COLORS generation for consistent file coloring"
```

---

### Task 16: GNOME dark theme consistency

**Files:** None

- [ ] **Step 1: Set GTK theme to Adwaita-dark**

```bash
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
```

- [ ] **Step 2: Match terminal colors (already done via kitty theme)**

Verify kitty theme (Nightlion V1) is consistent with system Adwaita-dark.

---

## Phase 5: Package Documentation + Final Verification

### Task 17: Create DEPENDENCIES.md

**Files:**
- Create: `docs/DEPENDENCIES.md`

- [ ] **Step 1: Create dependency documentation**

```markdown
# Dependency Reference

## Installation Methods

| Method | Scope | Config Location |
|--------|-------|----------------|
| apt | System packages | stow/ — none (system managed) |
| mise | Language runtimes | stow/mise/config.toml |
| cargo | Rust tools | stow/ — none (Cargo.toml per project) |
| npm -g | JS/TS tools | ~/.npm-global (if configured) |
| snap | Confined apps | stow/ — none (snap manages its own) |
| bun | JS runtime | ~/.bun |

## Core Tools

| Tool | Method | Purpose | Config |
|------|--------|---------|--------|
| stow | apt | Dotfiles management | — |
| kitty | apt | Terminal emulator | stow/kitty/ |
| zsh | apt | Shell | stow/shell/ |
| starship | cargo (or apt) | Prompt | stow/starship/ |
| atuin | cargo | Shell history | stow/atuin/ |
| mise | curl (official) | Runtime versions | stow/mise/ |
| eza | cargo | ls replacement | — |
| ripgrep | cargo | Text search | — |
| fd-find | cargo | File search | — |
| batcat | apt | File preview | — |
| fzf | apt | Fuzzy finder | — |
| zoxide | cargo | Directory jump | — |

## Development Runtimes

| Runtime | Version | Managed by |
|---------|---------|-----------|
| Node.js | (current LTS) | mise |
| Python | (current) | mise |
| Go | (current) | mise |
| Rust toolchain | stable | rustup |

## LSP Servers

Managed by opencode.json — see `stow/opencode/opencode.json`
```

- [ ] **Step 2: Commit**

```bash
git add docs/DEPENDENCIES.md
git commit -m "docs: add DEPENDENCIES.md with install method and config location"
```

---

### Task 18: Final verification and measurement

**Files:** None

- [ ] **Step 1: Verify all stow packages deployed**

```bash
~/projects/personal/dotfiles/scripts/deploy.sh
```

- [ ] **Step 2: Measure zsh startup**

```bash
hyperfine 'zsh -i -c exit'
```
Expected: < 100ms.

- [ ] **Step 3: Verify no stale configs remain**

```bash
# Old configs/ directory should be gone
ls ~/projects/personal/dotfiles/configs/ 2>/dev/null || echo "configs/ removed ✓"

# New stow tree should be populated
ls ~/projects/personal/dotfiles/stow/
```

- [ ] **Step 4: Verify dotfiles are symlinked properly**

```bash
ls -la ~/.zshrc
ls -la ~/.gitconfig
ls -la ~/.config/starship/starship.toml
ls -la ~/.config/kitty/kitty.conf
```
All should point to `~/projects/personal/dotfiles/stow/<pkg>/...`

- [ ] **Step 5: Quick e2e test**

```zsh
# Start fresh zsh
exec zsh
# Test aliases work
ll
gs
gl --version
# Test prompt shows
echo $STARSHIP_SHELL
```

- [ ] **Step 6: Final commit (if any remaining changes)**

```bash
git add -A && git commit -m "chore: final verification and cleanup"
```

---

## Success Criteria (from spec)

- [ ] `deploy.sh` replaced by stow — symlink management via `stow` only
- [ ] `git clone` on new machine + `bootstrap.sh` gets a working environment
- [ ] Zsh startup < 100ms (`hyperfine 'zsh -i -c exit'`)
- [ ] No duplicate configs, all known redundancies removed
- [ ] Starship prompt shows useful information (time, dir, git, language)
- [ ] Kitty terminal visually consistent
- [ ] `.opencode-notify.log` no longer growing unbounded
- [ ] Compdump files cleaned, no further accumulation
- [ ] `docs/TOOLS.md` and `docs/DEPENDENCIES.md` document everything
