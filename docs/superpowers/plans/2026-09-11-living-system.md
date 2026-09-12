# Living System (docs + fixes + IA cross-app) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convertir el PC en un sistema "vivo" documentado: docs fuente de verdad post-purga, configs reparadas, opencode como hub central de trabajo ($mainMod+O, ocp, notificaciones), y WORKFLOW.md como modo de operación.

**Architecture:** 4 capas sobre infra existente (todo ya es stow en este repo): (1) refrescar docs existentes — no crear ubicaciones nuevas, (2) fixes de configs rotas post-purga, (3) integraciones IA cross-app con opencode central, (4) WORKFLOW.md documentando el modo de trabajo principal. STATE.md + WORKFLOW.md = par de entrada que toda sesión nueva lee al iniciar.

**Tech Stack:** stow (32+1 paquetes), justfile, systemd user timers, fuzzel 1.12, ghostty, mako/notify-send, opencode.jsonc, hermes (zen provider), system-inventory.py, engram.

## Global Constraints

- Editar SIEMPRE `stow/` primero, nunca `~/.config/` directo (regla del repo).
- sudo solo con `echo "270922" | sudo -S` en el MISMO comando.
- No `rm -rf`; mover a `/var/tmp/opencode-trash/` si hay que descartar.
- NO tocar: 3 sesiones opencode activas, wedo, qdrant, taskchampion-sync, mikedb, ProjectZomboid, Antigravity.
- Commits conventional: `feat|fix|docs|chore(scope): descripción`. El push va al remote `ssh://github.com/reeinharddd/dotfiles` (URL rewrite .gitconfig lo maneja: `git push` directo funciona).
- Zona horaria America/Tijuana; fecha de referencia: 2026-09-11.
- Estado post-purga (números fuente de verdad para docs): disco 118G/468G (27% usado, 327G libres), RAM 13Gi total / ~8.6Gi usada, docker 4 conts (wedo-db :5433, qdrant :6333, taskchampion-sync :8090, mikedb :5432 Exited por diseño), zram zstd 6.9G, engram 15 proyectos/673 obs, opencode.db 5.0G.

---

### Task 1: STATE.md — archivo de estado vivo

**Files:**
- Create: `STATE.md` (raíz del repo dotfiles — NO stow, es estado mutable del repo mismo)

**Interfaces:**
- Produces: `STATE.md` con secciones `# Estado`, `## Proyecto activo`, `## Pendientes`, `## Últimos cambios`, `## Git`. Toda sesión nueva de opencode lo lee al iniciar (documentado en Task 2 WORKFLOW.md y Task 3 SISTEMA_DOC).

- [ ] **Step 1: Crear STATE.md con contenido inicial real**

```markdown
# STATE.md — Estado vivo del sistema

> Actualizar al cerrar cada sesión de trabajo significativa.
> Par de entrada: STATE.md (qué está pasando) + WORKFLOW.md (cómo se trabaja).

# Estado

- Fecha: 2026-09-11
- Disco: 118G / 468G usados (27%, 327G libres)
- RAM: 13Gi total / ~8.6Gi en uso, zram zstd 6.9G activo
- Docker: 4 contenedores — wedo-db (:5433, healthy), qdrant (:6333),
  taskchampion-sync (:8090), mikedb (:5432, lab2 9°, detenido por diseño)
- Sesión opencode: múltiples activas (wedo + home) — NUNCA matar

## Proyecto activo

- **wedo** — gestión hogar (~/projects/personal/wedo), 5+ procesos opencode
- **dispositivos 9°** — ~/School/dispositivos (lab2 + labC), cuatrimestre en curso

## Pendientes

- [ ] Verificar provider zen de hermes tras fix (hermes -z debe responder)
- [ ] Correr `just doc` semanal (timer doc-refresh lo automatiza)

## Últimos cambios

- 2026-09-11: purga completa (81G liberados: escolar 8°, docker muerto,
  caches), TW3 3.5.0 + sync server, matugen theming dinámico, zram,
  engram unificado 40→15 proyectos, opencode.db 8.6G→5.0G, commit 2767222
- 2026-09-10: audit + purge inicial (docker images, snaps, binarios muertos)

## Git

- dotfiles: main synced con origin (GitHub reeinharddd/dotfiles)
- ALL repos personales: remotes GitHub verificados synced
```

- [ ] **Step 2: Verificar**

Run: `head -5 STATE.md`
Expected: título + fecha 2026-09-11 visibles.

- [ ] **Step 3: Commit**

```bash
git add STATE.md && git commit -m "feat(state): STATE.md estado vivo del sistema"
```

---

### Task 2: WORKFLOW.md — modo de trabajo con opencode (Capa 4)

**Files:**
- Create: `stow/opencode/.config/opencode/WORKFLOW.md`

**Interfaces:**
- Consumes: estructura de AGENTS.md central (init protocol), SISTEMA_DOC.md (Task 3).
- Produces: documento de referencia de modos de trabajo; referenciado desde SISTEMA_DOC sección "Modo de trabajo".

- [ ] **Step 1: Crear WORKFLOW.md con contenido completo**

```markdown
# WORKFLOW.md — Cómo se trabaja en este PC

> opencode es el modo PRINCIPAL de desarrollo, ideas y diseño.
> Par de entrada: STATE.md (qué está pasando) + este archivo (cómo se trabaja).

## Sesión típica (init protocol)

1. `engram mem_context` — recuperar memoria de sesiones previas
2. `engram mem_current_project` — detectar proyecto actual
3. Leer AGENTS.md del proyecto + STATE.md de dotfiles
4. Al cerrar: `engram mem_session_summary` + actualizar STATE.md

## Modos de trabajo

| Modo | Cuándo | Herramientas |
|---|---|---|
| Implementación | build features, bugfix | opencode TUI, delegación a subagentes, TDD |
| Investigación | "cómo funciona X", auditorías | opencode + explore/librarian + firecrawl |
| Ideas / diseño | specs, brainstorming | opencode + skill brainstorming → specs/ |
| Mantenimiento | limpieza, docs, backups | opencode + just + scripts stow |

## Modelos por tarea (provider zen / cascada)

- **Orquestadores** (deciden, delegan): nemotron-3-ultra-free vía zen
- **Workers** (investigación, código batch): zen/*-free
- **Vision** (imágenes, UI QA): mistral/pixtral
- Cambiar contexto: sesiones opencode, cada una con su modelo asignado

## Background everything

- Subagentes paralelos fire-and-forget desde opencode
- `pueue` (alias `p`) para jobs shell de larga vida
- Delegación: 1-3 lecturas inline; 4+ → subagent; test/lint/research/web → delegar primero

## Memoria

- **engram** (persistente cross-session): decisiones, bugs, descubrimientos — `mem_save` proactivo, 15 proyectos vivos
- **opencode.db** (sesiones): historial completo de conversaciones, 5.0G, VACUUM ocasional
- Regla: knowledge → engram; conversación → opencode.db; estado → STATE.md

## Integraciones invocables desde opencode

- `task` — Taskwarrior 3 con sync (server :8090), alias t/tl
- `timew` — Timewarrior standalone (hook TW2 removido; trackear manual)
- `zellij` — sesiones terminal persistentes
- `yazi` (yz), `lazygit` (lg), `gh`, `just` — dentro de bash tool
- `ocp` — selector fuzzel de proyectos → nueva terminal opencode en cwd
- Notificaciones mako al terminar agentes (notify-hook.sh)

## Reglas de oro

- NUNCA matar sesiones opencode activas — son trabajo en curso
- Editar stow/ primero, re-stow después
- Docs fuente de verdad: SISTEMA_DOC (sistema), INVENTORY (detalle), STATE (vivo)
```

- [ ] **Step 2: Re-stow el paquete opencode**

Run: `stow --adopt -R -d stow -t ~ opencode`
Expected: exit 0, `ls ~/.config/opencode/WORKFLOW.md` muestra el archivo.

- [ ] **Step 3: Commit**

```bash
git add stow/opencode/.config/opencode/WORKFLOW.md && git commit -m "docs(workflow): WORKFLOW.md modo de trabajo opencode central"
```

---

### Task 3: SISTEMA_DOC.md — reescritura post-purga

**Files:**
- Modify: `~/.config/opencode/SISTEMA_DOC.md` (es symlink → `stow/opencode/.config/opencode/SISTEMA_DOC.md` — editar el stow)

**Interfaces:**
- Consumes: números de Global Constraints, WORKFLOW.md (Task 2), ocp (Task 11), notify (Task 12), hermes fix (Task 8).
- Produces: doc maestro del sistema; STATE.md e INVENTORY.md referencian a él.

- [ ] **Step 1: Reemplazar contenido completo de SISTEMA_DOC.md**

Escribir este contenido (reemplaza las 401 líneas desactualizadas):

```markdown
# SISTEMA_DOC — Documentación del sistema (fuente de verdad)

> Última actualización: 2026-09-11 (post-purga 81G). Mantener con `just doc`.
> Par de entrada de sesión: STATE.md (estado) + WORKFLOW.md (cómo trabajar).

## Hardware / OS

- ThinkPad T14 Gen 3 — AMD Ryzen 7 PRO 6850U (16 threads), 13Gi RAM, NVMe 468G
- Ubuntu 26.04.1 LTS "Resolute Raccoon", kernel 7.0.0-29
- Sesión: GNOME (diaria) + Hyprland (configurada con theming completo)
- Disco: 118G usados / 327G libres

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
- stow: 32+1 paquetes (nuevo: matugen) — `stow --adopt -R -d stow -t ~ <pkg>`
- ~/.local/bin: 49 binarios (opencode, codex, hermes, maestro, matugen, swww x2, task TW3.5, television, engram, carapace...)
- Snaps: 25 (brave firefox discord bitwarden thunderbird insomnia vlc trivy auto-cpufreq + runtimes)
- apt: 2116 paquetes (code, google-chrome, flameshot, ksnip, libreoffice, docker)

## Modo de trabajo

→ Ver WORKFLOW.md (stow/opencode). opencode es el hub central.

## IA / Agentes

- **opencode** (central): TUI Bubble Tea, providers 12, LSPs 11, agents 23, plugins 14, skills 24 core + bodega on-demand
- **hermes** (~/.hermes, v0.20.5): asistente CLI 24/7, provider zen
- **codex** (0.152), **Antigravity** (MCP vivo, 2 cuentas)
- Cascade: orquestadores nemotron-3-ultra-free / workers zen/*-free / vision mistral-pixtral

## Memoria

- **engram**: 15 proyectos, 673 observaciones (unificado 2026-09-11 de 40 proyectos)
- **opencode.db**: 5.0G (1230 sesiones; purgada de 8.6G)

## Taskwarrior / Timewarrior

- TW 3.5.0 (~/.local/bin/task, sombra del 2.6.2 apt), sync contra taskchampion-sync :8090
- .taskrc → stow/taskman (keys: sync.server.url, sync.server.client_id, sync.encryption_secret)
- Timewarrior standalone (hook TW2 removido en migración TW3)

## Backups

- restic timer diario 03:00 (systemd): Documents, projects, .config, Pictures, .local/bin, zsh_history, .ssh, .gnupg
- Exclude: .git (GitHub cubre history — todos los repos synced), Downloads, multimedia grande
- GitHub: TODAS las repos personales pusheadas (username reeinharddd, gh auth OK)

## Theming dinámico

- matugen 4.2.0 + swww 0.11.2: wallpaper → colores → hyprland, fuzzel, waybar, mako, ghostty
- Uso: `matugen image ~/Pictures/wallpapers/<file>.png`
- Wallpaper daemon (swww) SOLO en Hyprland (GNOME no tiene wlr-layer-shell)

## Integraciones IA (cross-app)

- Hyprland `$mainMod+O` → ghostty -e opencode
- `ocp` (~/.local/bin) → fuzzel proyectos → opencode en cwd
- Notificaciones mako/GNOME al terminar agentes: nativo `tui.json attention` (ya activo) + hook notify-hook.sh para subagentes (yaml-hooks plugin, evento tool.execute.after scope child).
- hermes: CLI `hermes -z "..."` — provider zen vivo

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

- `just doc` — refrescar INVENTORY.md
- Timer semanal doc-refresh (systemd user)
- `just status` — health check
- Purge por RECENCIA: candidato = no tocado/modificado/ejecutado en mucho tiempo, NO "no está corriendo ahora"
```

- [ ] **Step 2: Verificar**

Run: `wc -l stow/opencode/.config/opencode/SISTEMA_DOC.md && grep -c '2026-09-11' stow/opencode/.config/opencode/SISTEMA_DOC.md`
Expected: ~180 líneas, fecha presente (≥1).

- [ ] **Step 3: Commit**

```bash
git add stow/opencode/.config/opencode/SISTEMA_DOC.md && git commit -m "docs(sistema): reescritura post-purga 118G/4 containers/15 engram"
```

---

### Task 4: CONFIG-CHANGES.md — anexar sesión completa

**Files:**
- Modify: `stow/opencode/.config/opencode/CONFIG-CHANGES.md` (final del archivo)

**Interfaces:**
- Consumes: changelog de la sesión (ver Step 1).

- [ ] **Step 1: Anexar bloque de changelog**

Al final del archivo:

```markdown

## 2026-09-11 — Living System (purga + unificación + integraciones)

- **Purga total**: 199G→118G (81G). Escolar 8° (School, cold/ 19 repos, Downloads, vols docker), docker muerto (22 imágenes, 13.5G builder), caches (npm/bun 6G, tracker, puppeteer), 12 binarios muertos, 18 configs huérfanas, Activepieces (nunca usado), snaps viejos (16 revisions + core20), journal 1G, kernel 7.0.0-22.
- **Performance**: zram-tools zstd 6.9G (PERCENT=50), tracker-miner-fs-3 masked.
- **Taskwarrior 3**: 3.5.0 cmake build reemplaza 2.6.2 (apt queda inofensivo). Migración import-v2 (5 tareas). Sync server docker :8090. Hook on-modify-timewarrior TW2 removido (rompía TW3).
- **Memoria**: engram 40→15 proyectos (merges okit+caveman→maestro, atlas→wedo, unknown→snapmcp, superpowers→opencode, ecc+projects→reeinharrrd), 680 dup eliminados, 17 proyectos escolares fuera. opencode.db 8.6G→5.0G (1161 sesiones muertas, VACUUM 71s con sesiones activas).
- **Theming**: matugen 4.2.0 + swww 0.11.2 (build source) → 5 templates (hyprland/fuzzel/waybar/mako/ghostty). Stow NUEVO: stow/matugen.
- **Restic**: ~/Pictures agregado a backup, ~/dotfiles (path muerto) removido, exclude .git/ se mantiene (GitHub cubre).
- **Integraciones IA**: $mainMod+O, script ocp, notify-hook.sh, alias oc, hermes provider fix, WORKFLOW.md.
- **Docs**: STATE.md nuevo, SISTEMA_DOC reescrito, INVENTORY re-scan, just doc + timer semanal.
```

- [ ] **Step 2: Verificar + commit**

Run: `tail -3 stow/opencode/.config/opencode/CONFIG-CHANGES.md`
Expected: bloque 2026-09-11 visible.

```bash
git add stow/opencode/.config/opencode/CONFIG-CHANGES.md && git commit -m "docs(changelog): sesión living-system completa"
```

---

### Task 5: INVENTORY.md re-scan + MASTER-INDEX/MCP-INVENTORY sync

**Files:**
- Modify: `~/.config/opencode/INVENTORY.md`, `MASTER-INDEX.md`, `MCP-INVENTORY.md` (todos symlinks → stow/opencode/.config/opencode/)

**Interfaces:**
- Consumes: system-inventory.py (`~/.config/opencode/system-inventory.py`, flags --full --update-files --update-engram).

- [ ] **Step 1: Re-correr inventario**

Run: `python3 ~/.config/opencode/system-inventory.py --full --update-files`
Expected: exit 0; INVENTORY.md timestamp actualizado a 2026-09-11.

- [ ] **Step 2: Verificar timestamp y contenido post-purga**

Run: `head -20 ~/.config/opencode/INVENTORY.md`
Expected: fecha ≥2026-09-11. Si menciona proyectos purgados (servease, okit, atlas) en sección proyectos activos: editar el archivo stow y eliminar esas entradas de la sección de activos (los purgados ya no existen en disco).

- [ ] **Step 3: Sync MASTER-INDEX.md y MCP-INVENTORY.md**

En `stow/opencode/.config/opencode/MASTER-INDEX.md`: verificar que números de agentes/MCPs/plugins/skills cuadren (agents 23, MCPs core 9 + on-demand, plugins 14, skills 24 core) — actualizar líneas desactualizadas con los valores reales. En `MCP-INVENTORY.md`: quitar cualquier entrada de MCP que dependa de contenedores purgados (ap-* Activepieces removido) si existiera.

Run: `grep -iE 'servease|activepieces|okit|atlas' stow/opencode/.config/opencode/MASTER-INDEX.md stow/opencode/.config/opencode/MCP-INVENTORY.md || echo CLEAN`
Expected: CLEAN (o editar las líneas que salgan).

- [ ] **Step 4: Commit**

```bash
git add stow/opencode/.config/opencode/ && git commit -m "docs(inventory): re-scan post-purga + index sync"
```

---

### Task 6: just doc — recipe de frescura de docs

**Files:**
- Modify: `justfile` (raíz del repo dotfiles)

**Interfaces:**
- Consumes: system-inventory.py path `~/.config/opencode/system-inventory.py`.
- Produces: target `just doc` usado por el timer doc-refresh (Task 13) y por el humano.

- [ ] **Step 1: Añadir recipe al justfile**

Añadir al final del justfile:

```make

# Refrescar documentación del sistema (INVENTORY.md)
doc:
    @echo "==> Actualizando INVENTORY.md..."
    @python3 ~/.config/opencode/system-inventory.py --full --update-files
    @echo "==> Docs refrescadas: $(date '+%Y-%m-%d %H:%M')"
```

- [ ] **Step 2: Verificar**

Run: `just --list | grep doc`
Expected: línea `doc` presente.

- [ ] **Step 3: Commit**

```bash
git add justfile && git commit -m "feat(just): target doc para refrescar inventario"
```

---

### Task 7: justfile — documentar timew standalone (Capa 2)

**Files:**
- Modify: `justfile` (comentario cerca de los targets con timew: líneas ~33, 37, 65-71, 161)

**Interfaces:**
- Consumes: realidad actual — TW3 sin hook timewarrior (hook TW2 removido en migración).

- [ ] **Step 1: Añadir comentario de contexto**

Insertar este comentario justo antes del primer target que usa timew (~línea 32):

```make
# NOTE: timew corre STANDALONE (sin hook task). El hook on-modify-timewarrior
# de TW2 se removió al migrar a Taskwarrior 3 (rompía modify/delete).
# Para trackear: `timew start <tag>` / `timew stop` manual, o `just start/just stop`.
```

- [ ] **Step 2: Verificar que los targets funcionan standalone**

Run: `timew --version && just summary-today 2>/dev/null || just summary today 2>/dev/null || just --list | grep -i time`
Expected: timew responde versión 1.x; targets listados sin error.

- [ ] **Step 3: Commit**

```bash
git add justfile && git commit -m "docs(just): timew standalone documentado post-TW3"
```

---

### Task 8: hermes — fix provider muerto (Capa 2)

**Files:**
- Modify: `~/.hermes/config.yaml` (NO es stow — instalación propia de hermes)

**Interfaces:**
- Consumes: stack zen del usuario (mismos models free que opencode usa).

- [ ] **Step 1: Listar modelos zen disponibles en el stack**

Run: `grep -B2 -A30 '"zen"' ~/.config/opencode/opencode.jsonc | grep -oE '"[a-z0-9.-]+-free"' | sort -u`
Expected: lista de modelos free (incluye nemotron-3-ultra-free y workers).

- [ ] **Step 2: Editar default de hermes**

En `~/.hermes/config.yaml`, zona model config (líneas 34-70): cambiar `default: "x-preview-f-free"` → `default: "nemotron-3-ultra-free"` (o el primer modelo vivo de la lista del Step 1 que responda en el Step 3).

- [ ] **Step 3: Verificar hermes vivo**

Run: `hermes -z "responde solo: ok"`
Expected: respuesta del modelo (200), sin error 401 "not supported". Si falla, probar el siguiente modelo de la lista del Step 1 (Step 2 de nuevo).

- [ ] **Step 4: Documentar en STATE.md**

Actualizar `## Pendientes` en STATE.md: marcar "Verificar provider zen de hermes" como hecho (quitar la línea).

- [ ] **Step 5: Commit**

```bash
git add STATE.md && git commit -m "fix(hermes): provider default migrado a modelo zen vivo"
```

---

### Task 9: zsh — alias oc + purga de aliases muertos (Capa 2)

**Files:**
- Modify: `stow/shell/.zshrc` (zona de aliases)

**Interfaces:**
- Produces: alias `oc` → opencode (usado en docs WORKFLOW.md).

- [ ] **Step 1: Añadir alias oc**

En la sección de aliases de `stow/shell/.zshrc` (junto a `t=task`, `tl='task list'`):

```zsh
alias oc='opencode'      # opencode TUI — modo principal de trabajo
```

- [ ] **Step 2: Auditar aliases rotos**

Run: `for a in ld lg yz nv gj hf p; do alias_val=$(grep "alias $a=" stow/shell/.zshrc | head -1 | sed "s/alias $a='\(.*\)'/\1/"); cmd=$(echo $alias_val | awk '{print $1}'); command -v $cmd >/dev/null 2>&1 && echo "$a OK ($cmd)" || echo "$a ROTO ($cmd no existe)"; done`
Expected: `ld ROTO (lazydocker no existe)` — lazydocker fue purgado. Los demás OK.

- [ ] **Step 3: Remover alias muerto lazydocker**

Eliminar la línea `alias ld='lazydocker'` de `stow/shell/.zshrc`.

- [ ] **Step 4: Re-stow + verificar en shell nuevo**

Run: `stow --adopt -R -d stow -t ~ shell && zsh -ic 'alias oc; alias ld' 2>&1 | head -5`
Expected: `oc=opencode` presente; `ld` ausente (zsh: command not found o sin salida de alias).

- [ ] **Step 5: Commit**

```bash
git add stow/shell/.zshrc && git commit -m "feat(shell): alias oc opencode + lazydocker purgado"
```

---

### Task 10: Hyprland — bind $mainMod+O (Capa 3)

**Files:**
- Modify: `stow/hyprland/.config/hypr/hyprland.conf` (sección de binds)

**Interfaces:**
- Consumes: ghostty en PATH (bind de $mainMod+RETURN ya lo usa).

- [ ] **Step 1: Verificar que O no está en uso**

Run: `grep -n 'mainMod.*O\b' stow/hyprland/.config/hypr/hyprland.conf || echo LIBRE`
Expected: LIBRE (sin bind O existente). Si existe, usar `$mainMod SHIFT, O`.

- [ ] **Step 2: Añadir el bind**

En la sección de binds (después del bind de $mainMod+RETURN ghostty):

```
bind = $mainMod, O, exec, ghostty -e opencode
```

- [ ] **Step 3: Re-stow + validar config**

Run: `stow --adopt -R -d stow -t ~ hyprland && hyprctl reload 2>/dev/null; echo exit=$?`
Expected: exit 0 (si sesión GNOME actual: reload falla inofensivo — validar sintaxis con `Hyprland --config $(readlink -f ~/.config/hypr/hyprland.conf) -c validate 2>&1 || true`; el bind entra en vigor al abrir Hyprland).

- [ ] **Step 4: Commit**

```bash
git add stow/hyprland/.config/hypr/hyprland.conf && git commit -m "feat(hyprland): \$mainMod+O abre opencode en ghostty"
```

---

### Task 11: Script ocp — selector de proyectos (Capa 3)

**Files:**
- Create: `stow/scripts/.local/bin/ocp` (mismo paquete stow que cliphist-menu.sh)

**Interfaces:**
- Consumes: fuzzel --dmenu, ghostty --working-directory + -e.
- Produces: comando `ocp` (referenciado en WORKFLOW.md, SISTEMA_DOC, STATE.md).

- [ ] **Step 1: Escribir el script**

Crear el archivo (p.ej. `stow/scripts/.local/bin/ocp`):

```bash
#!/usr/bin/env bash
# ocp — selector de proyectos → opencode en ghostty (fuzzel dmenu)
set -euo pipefail

declare -A PROJECTS=(
  ["wedo"]="$HOME/projects/personal/wedo"
  ["dispositivos (9°)"]="$HOME/School/dispositivos"
  ["maestro"]="$HOME/projects/personal/maestro"
  ["snapmcp"]="$HOME/projects/personal/snapmcp"
  ["dotfiles"]="$HOME/projects/personal/dotfiles"
  ["uspace (pausado)"]="$HOME/projects/personal/Uspace"
  ["job-search"]="$HOME/projects/personal/job-search"
  ["ideas"]="$HOME/projects/personal/ideas"
  ["home"]="$HOME"
)

choice=$(printf '%s\n' "${!PROJECTS[@]}" | sort | fuzzel --dmenu --prompt 'opencode ❯ ') || exit 0
dir="${PROJECTS[$choice]:-}"
[[ -d "$dir" ]] || { notify-send -u critical "ocp" "Directorio no existe: $dir"; exit 1; }
exec ghostty --working-directory "$dir" -e opencode
```

- [ ] **Step 3: Permisos + re-stow**

Run: `chmod +x stow/scripts/.local/bin/ocp && stow --adopt -R -d stow -t ~ scripts && command -v ocp`
Expected: ruta de ocp en PATH.

- [ ] **Step 4: Test funcional (modo no-interactivo)**

Run: `bash -n stow/scripts/.local/bin/ocp && echo SINTAXIS_OK; echo "wedo" | fuzzel --dmenu --prompt test >/dev/null 2>&1 || echo "fuzzel dmenu requiere sesión Wayland interactiva — validar manual en Hyprland"`
Expected: SINTAXIS_OK (fuzzel dmenu requiere sesión Wayland interactiva — validar manualmente en Hyprland: `ocp` → elegir wedo → nueva ghostty con opencode en ~/projects/personal/wedo).

- [ ] **Step 5: Commit**

```bash
git add stow/scripts/.local/bin/ocp && git commit -m "feat(ocp): selector fuzzel de proyectos → opencode"
```

---

### Task 12: Notificaciones — hooks.yaml notify + attention nativo (Capa 3)

**Contexto verificado:** `tui.json` YA tiene `attention.notifications=true` (notificaciones nativas cuando opencode pide atención/permisos). Lo que falta: notificar cuando SUBAGENTES/background tasks terminan. Mecanismo real = plugin `opencode-yaml-hooks` (ya instalado, v2026.3.29) con evento `tool.execute.after` + `scope: child`. NO existe clave "notify" en opencode.jsonc ni evento "agent.finish" — descartado tras verificar schema oficial + README del plugin.

**Files:**
- Modify: `stow/opencode/.config/opencode/hooks.yaml` (añadir hook notify)
- Create: `stow/opencode/.config/opencode/notify-hook.sh` (script que parsea y notifica)

**Interfaces:**
- Consumes: plugin opencode-yaml-hooks (en tui.json plugin list), notify-send (/usr/bin), jq.
- Produces: notificación mako/GNOME al terminar tool calls de subagentes (scope: child) y sesiones idle.

- [ ] **Step 1: Crear notify-hook.sh en stow**

`stow/opencode/.config/opencode/notify-hook.sh`:

```bash
#!/usr/bin/env bash
# notify-hook.sh — notificaciones de eventos opencode (yaml-hooks)
# Eventos disponibles: session.created/deleted/idle, tool.execute.after,
# tool.before.*, file.changed. Payload JSON llega por stdin.
set -euo pipefail
input=$(cat)
type=$(printf '%s' "$input" | jq -r '.event // .type // empty' 2>/dev/null) || exit 0
tool=$(printf '%s' "$input" | jq -r '.tool_name // .tool // empty' 2>/dev/null) || true

case "$type" in
  tool.execute.after)
    # subagentes: cada tool terminado en scope child = progreso del agente
    [[ -n "$tool" ]] && notify-send -u low -a opencode "Agente" "Tool terminado: $tool"
    ;;
  session.idle)
    notify-send -u normal -a opencode "Idle" "Sesión esperando input"
    ;;
  *)
    exit 0
    ;;
esac
exit 0
```

- [ ] **Step 2: Añadir hook al stow hooks.yaml**

Añadir al final de `stow/opencode/.config/opencode/hooks.yaml` (después del hook session.idle existente):

```yaml

  # Notificaciones de escritorio para subagentes background (scope: child =
  # solo hooks de sesiones child/subagent, no el main loop)
  - event: tool.execute.after
    scope: child
    async: true
    actions:
      - bash: "$HOME/.config/opencode/notify-hook.sh"
```

- [ ] **Step 3: Permisos + re-stow + test con payload real**

Run: `chmod +x stow/opencode/.config/opencode/notify-hook.sh && stow --adopt -R -d stow -t ~ opencode && echo '{"event":"tool.execute.after","tool_name":"bash"}' | bash ~/.config/opencode/notify-hook.sh && echo SCRIPT_OK`
Expected: SCRIPT_OK + notificación visible en pantalla (daemon GNOME/mako recibe org.freedesktop.Notifications).

- [ ] **Step 4: Verificar tui.json attention intacto**

Run: `jq '.attention' ~/.config/opencode/tui.json 2>/dev/null || python3 -c "import json;print(json.load(open('$HOME/.config/opencode/tui.json'))['attention'])"`
Expected: notifications=true, sound=true — las nativas ya cubren permisos/attention del TUI principal.

- [ ] **Step 5: Commit**

```bash
git add stow/opencode/.config/opencode/hooks.yaml stow/opencode/.config/opencode/notify-hook.sh && git commit -m "feat(notify): hook notificaciones subagentes via yaml-hooks"
```

---

### Task 13: Timer semanal doc-refresh

**Files:**
- Create: `stow/misc/.config/systemd/user/doc-refresh.service` + `doc-refresh.timer` (mismo paquete que restic-backup.timer y los otros timers user)

**Interfaces:**
- Consumes: system-inventory.py (~/.config/opencode/system-inventory.py, symlink → stow/opencode).
- Produces: INVENTORY.md fresco semanal sin intervención.

- [ ] **Step 1: Crear service + timer**

`doc-refresh.service`:
```ini
[Unit]
Description=Refrescar INVENTORY.md (system-inventory.py)

[Service]
Type=oneshot
ExecStart=/usr/bin/python3 /home/reeinharrrd/.config/opencode/system-inventory.py --full --update-files
```

`doc-refresh.timer`:
```ini
[Unit]
Description=Doc refresh semanal (domingo 10:00)

[Timer]
OnCalendar=Sun *-*-* 10:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

- [ ] **Step 2: Re-stow + activar**

Run: `stow --adopt -R -d stow -t ~ misc && systemctl --user daemon-reload && systemctl --user enable --now doc-refresh.timer && systemctl --user list-timers | grep doc`
Expected: doc-refresh.timer en la lista con próximo domingo 10:00.

- [ ] **Step 3: Commit**

```bash
git add stow/misc/ && git commit -m "feat(systemd): timer semanal doc-refresh"
```

---

### Task 14: Verificación completa + push final

**Files:**
- Modify: STATE.md (marcar implementación completa)

**Interfaces:**
- Consumes: todos los tasks anteriores.

- [ ] **Step 1: Checklist de criterios de aceptación del spec**

Run cada verificación:

```bash
echo "=== C1 docs reales ==="; grep -c '118G' stow/opencode/.config/opencode/SISTEMA_DOC.md
echo "=== C2 inventory fresco ==="; head -20 ~/.config/opencode/INVENTORY.md | grep '2026-09'
echo "=== C3 STATE ==="; test -f STATE.md && echo OK
echo "=== C4 justfile ==="; just --list >/dev/null && echo OK
echo "=== C5 hermes ==="; hermes -z "di ok" | head -1
echo "=== C6 bind ==="; grep 'mainMod, O' stow/hyprland/.config/hypr/hyprland.conf
echo "=== C7 ocp ==="; command -v ocp && bash -n ~/.local/bin/ocp && echo OK
echo "=== C8 notify ==="; echo '{"event":"tool.execute.after","tool_name":"bash"}' | bash ~/.config/opencode/notify-hook.sh && echo OK
echo "=== C9 WORKFLOW ==="; test -f ~/.config/opencode/WORKFLOW.md && echo OK
echo "=== C10 stow broken ==="; find ~/.config -xtype l 2>/dev/null | wc -l
```

Expected: C1 ≥1; C2 fecha actual; C3-C9 OK; C10 = 0 symlinks rotos.

- [ ] **Step 2: Actualizar STATE.md**

En `## Últimos cambios` añadir al inicio:
```markdown
- 2026-09-11 (2): living-system implementado — docs fuente de verdad, ocp, $mainMod+O, notify-hook.sh, WORKFLOW.md, timer doc-refresh
```

- [ ] **Step 3: Commit final + push**

```bash
git add -A && git commit -m "feat(living-system): docs + fixes + integraciones IA — spec completo" && git push
```

Expected: push OK a GitHub (remote ssh rewrite .gitconfig maneja la URL).

- [ ] **Step 4: Verificación remota**

Run: `git log --oneline -3 && git status -sb`
Expected: HEAD synced con origin/main, working tree clean.

---

## Notas de ejecución

- Los commits por-task están autorizados: spec criterio #10 los incluye explícitamente (user aprobó "correcto" el spec con commit+push).
- Los tests de $mainMod+O y ocp dmenu requieren sesión Hyprland interactiva: validar manualmente al entrar a Hyprland (hoy sesión es GNOME). bash -n + grep validan sintaxis/wiring ahora.
- notify-hook.sh test (C8) SÍ funciona hoy: notify-send llega al daemon de notificaciones de la sesión activa (GNOME shell sirve org.freedesktop.Notifications).
- Notificaciones: la config nativa `tui.json attention` YA está activa (notifications+sound) — Task 12 solo añade el hook de subagentes vía plugin yaml-hooks ya instalado; no tocar opencode.jsonc (la clave "notify" NO existe en el schema oficial — verificado).
- Si `python3 system-inventory.py` falla por dependencia (ej. browser SQLite locks con Brave abierto): cerrar Brave o correr `just doc` después; es idempotente.
