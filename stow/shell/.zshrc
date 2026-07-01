# ~/.zshrc — Modern Zsh config (Starship + Atuin + Zellij)
# No Powerlevel10k, no OMZ bloat — solo lo esencial

# -------------------------------------------------------------------
# Oh My Zsh (mínimo)
# -------------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""  # Starship maneja el prompt

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

source $ZSH/oh-my-zsh.sh

# -------------------------------------------------------------------
# Editors & Browsers
# -------------------------------------------------------------------
export EDITOR="code --wait"
export VISUAL="code --wait"
export BROWSER="brave-browser"

# -------------------------------------------------------------------
# PATH
# -------------------------------------------------------------------
export BUN_INSTALL="$HOME/.bun"
export GOPATH="$HOME/go"
typeset -U PATH path
path=(
  "$HOME/.cargo/bin"
  "$HOME/.local/bin"
  "$BUN_INSTALL/bin"
  "$GOPATH/bin"
  $path
)

# -------------------------------------------------------------------
# Runtime managers
# -------------------------------------------------------------------
eval "$(mise activate zsh)"
source "$HOME/.cargo/env"

# -------------------------------------------------------------------
# Modern CLI aliases — default a herramientas modernas
# -------------------------------------------------------------------
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

# Editores
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
alias gj="jj"  # jujutsu

# Navegación
alias dev="cd ~/projects"
alias dotfiles="cd ~/projects/dotfiles"
alias ctx="~/projects/dotfiles/scripts/agent-context.sh --fast"
alias ctx-full='zsh -c "source ~/.zshrc; bash ~/projects/dotfiles/scripts/agent-context.sh" > ~/projects/dotfiles/CONTEXT.md'

# -------------------------------------------------------------------
# fzf
# -------------------------------------------------------------------
source /usr/share/doc/fzf/examples/key-bindings.zsh 2>/dev/null
source /usr/share/doc/fzf/examples/completion.zsh 2>/dev/null
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
export FZF_CTRL_T_OPTS="--preview 'batcat --color=always --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --icons --tree {} | head -50'"

# -------------------------------------------------------------------
# History (atuin lo maneja, pero config base)
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
export GITHUB_TOKEN="${GITHUB_TOKEN:-}"

# -------------------------------------------------------------------
# Completions
# -------------------------------------------------------------------
autoload -U compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# -------------------------------------------------------------------
# Starship prompt (reemplaza Powerlevel10k)
# -------------------------------------------------------------------
eval "$(starship init zsh)"

# -------------------------------------------------------------------
# Atuin (historia mágica + sync)
# -------------------------------------------------------------------
. "$HOME/.atuin/bin/env"
eval "$(atuin init zsh --disable-up-arrow)"

# -------------------------------------------------------------------
# Zellij (multiplexer) — auto-attach si no estamos dentro
# -------------------------------------------------------------------
if [[ -z "$ZELLIJ" && -z "$TMUX" && $- == *i* ]]; then
  zellij attach --create dev 2>/dev/null || true
fi

# -------------------------------------------------------------------
# Direnv (via mise)
# -------------------------------------------------------------------

# -------------------------------------------------------------------
# chezmoi (dotfiles sync)
# -------------------------------------------------------------------
command -v chezmoi >/dev/null && alias cz="chezmoi"

# -------------------------------------------------------------------
# Terminal
# -------------------------------------------------------------------
export TERMINAL=kittyexport PATH="$HOME/.opencode/bin:$PATH"
export PLAYWRIGHT_HOST_PLATFORM_OVERRIDE=ubuntu24.04-x64
