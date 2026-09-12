# SISTEMA_DOC: Documentación del sistema (fuente de verdad)

> Última actualización: 2026-09-11 (post-purga 81G). Mantener con `just doc`.
> Par de entrada de sesión: STATE.md (estado) + WORKFLOW.md (cómo trabajar).

## Hardware / OS

- ThinkPad T14 Gen 3: AMD Ryzen 7 PRO 6850U (16 threads), 13Gi RAM, NVMe 468G
- Ubuntu 26.04.1 LTS "Resolute Raccoon", kernel 7.0.0-29
- Sesión: GNOME (diaria) + Hyprland (configurada con theming completo)
- Disco: 119G usados / 325G libres (27% usado)

## Performance

- zram: zstd 6.9G (ALGO=zstd PERCENT=50 PRIORITY=100, /etc/default/zramswap)
- governor=performance, swappiness=10
- tracker-miner-fs-3 masked (GNOME indexer inútil con este stack)
- fstrim semanal (systemd timer)

## Docker (4 contenedores)

| Contenedor | Imagen | Puerto | Propósito |
|---|---|---|---|
| wedo-db | postgres:16-alpine | :5433 | BD WeDo (proyecto activo) |
| qdrant | qdrant/qdrant | :6333 | Vector DB (opencode-knowledge) |
| taskchampion-sync | taskchampion-sync-server | :8090 | Sync Taskwarrior 3 |
| mikedb_container | postgres:15-alpine | :5432 | BD lab2 dispositivos 9° (detenido por diseño) |

Volúmenes: 6 (wedo_pgdata, qdrant_storage, 02b84f9e=mikedb, supabase uspace x3 = proyecto pausado).

## Stack de desarrollo

- mise: 55 tools (eza bat fd fzf atuin delta dust zellij lazygit just gh yt-dlp supabase...)
- stow: 32+1 paquetes (nuevo: matugen): `stow --adopt -R -d stow -t ~ <pkg>`
- ~/.local/bin: 45 binarios (opencode, codex, maestro, matugen, swww x2, task TW3.5, television, engram, carapace...)
- Snaps: 25 (brave firefox discord bitwarden thunderbird insomnia vlc trivy auto-cpufreq + runtimes)
- apt: 2116 paquetes (code, google-chrome, flameshot, ksnip, libreoffice, docker)

## Modo de trabajo

-> Ver WORKFLOW.md (stow/opencode). opencode es el hub central.

## IA / Agentes

- **opencode** (central): TUI Bubble Tea, providers 12, LSPs 11, agents 23, plugins 14, skills 24 core + bodega on-demand
- **codex** (0.152), **Antigravity** (MCP vivo, 2 cuentas)
- ~~hermes~~ REMOVIDO 2026-09-11 (zen free-tier solo dentro de opencode; backup en /var/tmp)
- Cascade: orquestadores nemotron-3-ultra-free / workers zen/*-free / vision mistral-pixtral

## Memoria

- **engram**: 15 proyectos, 673 observaciones (unificado 2026-09-11 de 40 proyectos)
- **opencode.db**: 5.0G (1230 sesiones; purgada de 8.6G)

## Taskwarrior / Timewarrior

- TW 3.5.0 (~/.local/bin/task, sombra del 2.6.2 apt), sync contra taskchampion-sync :8090
- .taskrc -> stow/taskman (keys: sync.server.url, sync.server.client_id, sync.encryption_secret)
- Timewarrior standalone (hook TW2 removido en migración TW3)

## Backups

- restic timer diario 03:00 (systemd): Documents, projects, .config, Pictures, .local/bin, zsh_history, .ssh, .gnupg
- Exclude: .git (GitHub cubre history: todos los repos synced), Downloads, multimedia grande
- GitHub: TODAS las repos personales pusheadas (username reeinharddd, gh auth OK)

## Theming dinámico

- matugen 4.2.0 + swww 0.11.2: wallpaper -> colores -> hyprland, fuzzel, waybar, mako, ghostty
- Uso: `matugen image ~/Pictures/wallpapers/<file>.png`
- Wallpaper daemon (swww) SOLO en Hyprland (GNOME no tiene wlr-layer-shell)

## Integraciones IA (cross-app)

- Hyprland `$mainMod+O` -> ghostty -e opencode
- `ocp` (~/.local/bin) -> fuzzel proyectos -> opencode en cwd
- Notificaciones mako/GNOME al terminar agentes: nativo `tui.json attention` (ya activo) + hook notify-hook.sh para subagentes (yaml-hooks plugin, evento tool.execute.after scope child).

## Proyectos vivos

| Proyecto | Ruta | Estado |
|---|---|---|
| wedo | ~/projects/personal/wedo | ACTIVO (5+ sesiones opencode) |
| dispositivos 9° | ~/School/dispositivos | ACTIVO (lab2, labC) |
| maestro | ~/projects/personal/maestro | activo intermitente |
| snapmcp | ~/projects/personal/snapmcp | release cycle |
| Uspace | ~/projects/personal/Uspace | PAUSADO (vols supabase intactos) |
| job-search | ~/projects/personal/job-search | búsqueda activa |
| dotfiles | ~/projects/personal/dotfiles | este repo |
| ideas / landing / ctx-analyze / sys-inspector / bks / brain / mnemos | ~/projects/{personal,cold}/ | archivo personal |

## Mantenimiento

- `just doc`: refrescar INVENTORY.md
- Timer semanal doc-refresh (systemd user)
- `just status`: health check
- Purge por RECENCIA: candidato = no tocado/modificado/ejecutado en mucho tiempo, NO "no está corriendo ahora"
