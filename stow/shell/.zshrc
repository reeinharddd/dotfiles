# ~/.zshrc — Modern Zsh config (Starship + Atuin + Ghostty)
# No OMZ, no bloat — standalone plugins, modern tooling
# Restored from stow (2026-09-06) + deltas: fzf --zsh, atuin directo, herdr attach


# -------------------------------------------------------------------
# Editors & Browsers
# -------------------------------------------------------------------
export EDITOR="nvim"
export VISUAL="nvim"
export BROWSER="/snap/bin/brave"


# -------------------------------------------------------------------
# PATH
# -------------------------------------------------------------------
export BUN_INSTALL="$HOME/.bun"
export GOPATH="$HOME/go"
typeset -U PATH path
path=(
  "$HOME/.cargo/bin"
  "$HOME/.local/bin"
  "$HOME/.local/share/broot/launcher/bash"
  "$BUN_INSTALL/bin"
  "$GOPATH/bin"
  $path
)

# -------------------------------------------------------------------
# Runtime managers
# -------------------------------------------------------------------
eval "$(mise activate zsh)"

source "$HOME/.cargo/env"

# direnv — env vars por directorio (via mise)
eval "$(direnv hook zsh)" 2>/dev/null

# -------------------------------------------------------------------
# Modern CLI aliases — default a herramientas modernas
# -------------------------------------------------------------------
alias ls="eza --icons --group-directories-first"
alias ll="eza -la --icons --git --group-directories-first"
alias l="eza -l --icons --git --group-directories-first"
alias lt="eza --icons --tree --group-directories-first"
alias cat="bat --paging=never"
alias grep="rg"
alias find="fd"
alias cd="z"
alias du="dust"
alias top="btop"
alias help="tldr"
alias ps="procs"
alias df="duf"

# Editores
alias vim="nvim"
alias vi="nvim"

# TUIs
alias lg="lazygit"
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
alias gj="jj"  # jujutsu

# Modern tools 2026
alias hf="hyperfine"
alias tokei="tokei"
alias hexyl="hexyl"
alias wx="watchexec"
alias http="xh"
alias sd="sd"
alias tar="ouch"
alias br="broot"           # broot launcher
alias tv="tv"              # television
alias ch="cliphist"        # cliphist
alias fz="fuzzel"          # fuzzel launcher
alias p="pueue"            # process queue

# Navegación
alias dev="cd ~/projects"
alias dotfiles="cd ~/projects/personal/dotfiles"

# -------------------------------------------------------------------
# fzf
# -------------------------------------------------------------------
source <(fzf --zsh) 2>/dev/null || source /usr/share/doc/fzf/examples/key-bindings.zsh 2>/dev/null
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
export FZF_CTRL_T_OPTS="--preview 'batcat --color=always --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --icons --tree {} | head -50'"

# -------------------------------------------------------------------
# History
# -------------------------------------------------------------------
HISTSIZE=100000
SAVEHIST=100000
HISTFILE="$HOME/.zsh_history"
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt EXTENDED_HISTORY

# -------------------------------------------------------------------
# Misc
# -------------------------------------------------------------------
export LESS="-R"
export PAGER="less"
export _ZO_ECHO=1
export BAT_THEME="Dracula"

# === Secret env vars (opencode MCP, etc.) ===
# Generate token at: https://github.com/settings/tokens (repo scope)
# Despues de agregarlo: source ~/.zshrc
# GitHub credentials are loaded only from the private OpenCode environment file.

# -------------------------------------------------------------------
# Completions
# -------------------------------------------------------------------
autoload -U compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# -------------------------------------------------------------------
# Completions: docker, gh, carapace
# -------------------------------------------------------------------
source <(docker completion zsh) 2>/dev/null
source <(gh completion -s zsh) 2>/dev/null

# carapace — autocompletado universal
export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
# carapace is at ~/.local/bin/carapace (via mise)
source <(carapace _carapace 2>/dev/null)

# -------------------------------------------------------------------
# Starship prompt
# -------------------------------------------------------------------
eval "$(starship init zsh)"

# -------------------------------------------------------------------
# Atuin (historia mágica con full-text search)
# -------------------------------------------------------------------
eval "$(atuin init zsh --disable-up-arrow)"

# -------------------------------------------------------------------
# zoxide — navegación inteligente
# -------------------------------------------------------------------
eval "$(zoxide init zsh)" 2>/dev/null

# -------------------------------------------------------------------
# zsh-autosuggestions
# -------------------------------------------------------------------
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null

# -------------------------------------------------------------------
# Herdr (multiplexer AI) — auto-attach si no estamos dentro
# -------------------------------------------------------------------
if [[ -z "$HERDR_ENV" && -z "$TMUX" && -z "$ZELLIJ" && $- == *i* && -t 1 ]]; then
  exec herdr session attach main 2>/dev/null || exec herdr
fi

# -------------------------------------------------------------------
# chezmoi (dotfiles sync)
# -------------------------------------------------------------------
command -v chezmoi >/dev/null && alias cz="chezmoi"

# -------------------------------------------------------------------
# Terminal
# -------------------------------------------------------------------
export TERMINAL=ghostty
export PATH="$HOME/.opencode/bin:$PATH"
export PLAYWRIGHT_HOST_PLATFORM_OVERRIDE=ubuntu24.04-x64

# -------------------------------------------------------------------
# zsh-syntax-highlighting — DEBE IR AL FINAL
# -------------------------------------------------------------------
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null

# ─── Life Management System ────────────────────────────────────
alias hey="just hey"              # AI Life Assistant
alias today="just daily"          # Daily review
alias endday="just end-day"       # End of day
alias t="task"                    # taskwarrior shorthand
alias tl="task list"
alias oc="opencode"              # opencode shorthand
alias ta="task add"
alias td="task done"
alias tn="just note"
alias tj="jrnl -today"
alias pomo="just pomodoro"
alias focus="just focus"
alias tt="timew summary today"
alias tw="timew"
alias cal="khal calendar"
alias jf="just"

# Better alternatives (cleanup 2026)
alias mlr="mlr"              # miller (csv processor)
alias restic="restic"        # modern backup
alias xsv="xsv"              # csv index/slice
alias htmlq="htmlq"          # HTML processor (jq for HTML)

# ─── AI Provider API Keys (Free Tiers 2026) ─────────────────────
# Source: https://aistudio.google.com/apikey | https://console.groq.com/keys
#         https://cloud.cerebras.ai | https://api.together.ai
#         https://fireworks.ai/account/api-keys | https://console.mistral.ai

# Provider credentials are loaded only from ~/.config/opencode/opencode.env.

# dcg: warn if hook was silently removed from Claude Code settings
if command -v dcg &>/dev/null && command -v jq &>/dev/null; then
  if [ -f "$HOME/.claude/settings.json" ] && \
     ! jq -e '.hooks.PreToolUse[]? | select(.hooks[]?.command | test("dcg$"))' \
       "$HOME/.claude/settings.json" &>/dev/null; then
    printf '\033[1;33m[dcg] Hook missing from ~/.claude/settings.json — run: dcg install\033[0m\n'
  fi
fi

# Secrets (opencode.env)
if [[ -r "$HOME/.config/opencode/opencode.env" ]]; then
  source "$HOME/.config/opencode/opencode.env"
fi