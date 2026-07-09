# AGENTS.md — reeinharrrd's Rules

> Lean rules for AI agents (opencode, claude, etc). No bloat.
> Full tool inventory: `mise ls`, `which`, `ls stow/`, `engram mem_search`.

## Quién soy

- Full-stack dev + sysadmin, Ubuntu 26.04 + Wayland/Hyprland
- Hardware: ThinkPad T14 Gen 3, AMD Ryzen 7 PRO 6850U
- Estilo: keyboard-first, sin mouse, todo via atajos

## Dotfiles

- Repo: `~/projects/personal/dotfiles/`
- Stow: 32 packages, `stow --adopt -R -d stow -t ~ <pkg>`
- **Edit stow/ first**, no `~/.config/` directo
- Config nueva: `mise use --global <tool>`, config en `stow/`, re-stow, alias en zshrc, `just ship "msg"`

## Constraints

1. **No sudo** sin password explícito (270922 via `echo "270922" | sudo -S`)
2. **No commits** sin user request
3. **No type suppression** (`as any`, `@ts-ignore`)
4. **No rm -rf** (bloqueado, usar `mv <path> /tmp/`)
5. **Mise for new tools** (no apt, no cargo, no pipx para dev tools)

## Memory (engram)

- **Save** después de bugfix/decision/discovery: `engram mem_save title="..." content="..."`
- **Search** antes de empezar tarea compleja: `engram mem_search query="..."`
- **Topic key** para decisiones evolucionables: `architecture/<name>`, `decision/<name>`

## OpenCode Workflows

- **Plan >3 archivos**: toggle `Tab` para Plan mode, aprobar plan, build
- **Subagents paralelos**: fire-and-forget para research, code review
- **Specialized agents**:
  - `code-reviewer` pre-merge
  - `security-reviewer` para auth/payment/IO
  - `tdd-guide` red-green-refactor
  - `docs-lookup` via context7 (use FIRST para libs)
  - `oracle` cuando stuck >15min
- **MCP servers**: context7 (lib docs), engram (memory), firecrawl (web), github (PRs), royal-mcp (WP/Woo)
- **Skills via triage auto-route** — 30+ skills, no memorizar, deja que triage dispatch
- **NO instalar** avante.nvim/codecompanion.nvim en nvim (fragmentan contexto)

## Tools clave

- **Edit**: nvim (LazyVim) o code
- **Terminal**: ghostty
- **Files TUI**: yazi + broot
- **Search**: fzf + tv + rg + fd
- **Git**: lazygit + jj + gh
- **System**: btop + procs
- **AI**: opencode (TUI) — NO plugin IDE
- **Tasks**: taskwarrior + timewarrior + jrnl
- **Backup**: restic (script en scripts/backup-restic.sh)

## Comandos utiles

- `just --list` — todos los targets
- `just status` — system health
- `just sync` — re-stow todos
- `just ship "msg"` — git add + commit + push
- `just daily` / `just end-day` — rutinas
- `just pq-add "cmd"` — encolar a pueue
- `just backup` — manual restic
- `engram mem_save` — guardar decision
- `mise ls` — listar tools instaladas

## Estilo

- **Keyboard-first** sin mouse
- **Background everything**: subagents paralelos
- **TUI over GUI** cuando posible
- **Plan before build** para tasks >3 archivos
- **Save decisions** con engram mem_save
