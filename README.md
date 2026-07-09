# dotfiles — Personal Config Backup

Personal configuration files with one-shot bootstrap and idempotent deploy.

## Structure

```
dotfiles/
├── configs/                    # All personal configs (source of truth)
│   ├── shell/                  # .zshrc
│   ├── git/                    # .gitconfig
│   ├── kitty/                  # ~/.config/kitty/
│   ├── starship/               # ~/.config/starship/
│   ├── zellij/                 # ~/.config/zellij/
│   ├── atuin/                  # ~/.config/atuin/
│   ├── continue/               # ~/.config/continue/
│   ├── fontconfig/             # ~/.config/fontconfig/
│   ├── gh/                     # ~/.config/gh/
│   ├── mise/                   # ~/.config/mise/
│   ├── opencode/               # ~/.config/opencode/
│   ├── profile.d/              # ~/.profile.d/
│   └── vscode/                 # ~/.config/Code/User/
├── scripts/
│   └── deploy.sh               # Idempotent symlink deploy (backup-first)
├── bootstrap/
│   └── install.sh              # Clone → detect (sys-inspector) → deploy
└── .gitignore
```

## Quick Install

```bash
# One-shot (clones, detects system, deploys configs)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/reeinharddd/dotfiles/main/bootstrap/install.sh)"

# Or manually
git clone ssh://git@github.com/reeinharddd/dotfiles ~/projects/personal/dotfiles
~/projects/personal/dotfiles/scripts/deploy.sh
```

## Commands

| Command | Description |
|---------|-------------|
| `./scripts/deploy.sh` | Deploy all configs (symlinks, backups existing) |
| `./scripts/deploy.sh --dry-run` | Preview what would change |
| `./bootstrap/install.sh` | Full bootstrap: clone + detect + deploy |
| `./bootstrap/install.sh --no-detect` | Skip sys-inspector detection |
| `./bootstrap/install.sh --dry-run` | Preview bootstrap |

## sys-inspector (Optional)

System detection is delegated to [sys-inspector](https://github.com/reeinharddd/sys-inspector) — a universal, POSIX sh toolkit that generates AI-agent-readable `skill.md` from live system state.

```bash
# Install separately for system detection
git clone ssh://git@github.com/reeinharddd/sys-inspector ~/projects/personal/sys-inspector
~/projects/personal/sys-inspector/src/inspect.sh
```

Bootstrap runs detection automatically if sys-inspector is present.

## Config Management

- **Source of truth**: `configs/` — edit files here
- **Deploy**: `./scripts/deploy.sh` — creates symlinks, backs up existing files
- **Backups**: `~/.local/share/dotfiles-backup/YYYYMMDD-HHMMSS/`

## Remote

```
ssh://git@github.com/reeinharddd/dotfiles (private)
```
