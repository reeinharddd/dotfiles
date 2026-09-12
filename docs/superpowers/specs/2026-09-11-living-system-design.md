# Living System: docs fuente de verdad + IA cross-app con opencode central

**Fecha:** 2026-09-11
**Estado:** Aprobado por usuario (diseño de 3 capas)
**Contexto:** Post-purga 81G (199G→118G), engram unificado (40→15 proyectos), TW3+sync, matugen, zram. Las docs existentes quedaron desactualizadas en Sep-1/Sep-5, antes de todos estos cambios.

## Problema

La documentación del sistema NO falta — existe y está versionada en el repo dotfiles (stow → `~/.config/opencode/`). El problema es que está **desactualizada y dispersa**: SISTEMA_DOC.md dice 170GB usados (real: 118G), INVENTORY.md se corrió pre-purga, CONFIG-CHANGES.md no registra la sesión de hoy, y no existe ningún archivo de **estado vivo** que una sesión nueva pueda leer para saber en qué está el sistema HOY.

Además, hay configuraciones rotas o a medio integrar tras la purga (justfile llama timew que perdió su hook TW2, hermes usa un provider muerto) y ninguna integración cross-app real: opencode no tiene atajo global, fuzzel no abre proyectos, no hay notificaciones cuando agentes background terminan.

## Objetivo

1. Docs existentes reflejan el estado REAL del sistema y se mantienen frescas sin intervención manual.
2. Configs rotas post-purga quedan corregidas o limpiadas.
3. Opencode se convierte en el hub central de IA accesible desde cualquier punto del flujo de trabajo (Hyprland, fuzzel, notificaciones, asistente 24/7).
4. El MODO DE TRABAJO con opencode queda documentado: desarrollo, ideas y diseño fluyen mediante opencode — esa es la interfaz principal del PC y debe estar documentada como tal (user, m0355).

## Capa 1 — Docs fuente de verdad (refrescar, no duplicar)

Todos los archivos viven ya en el árbol stow del repo dotfiles (`~/projects/personal/dotfiles/stow/opencode/.config/opencode/`); se editan ahí y se despliegan vía stow.

| Archivo | Acción |
|---|---|
| `SISTEMA_DOC.md` | Reescribir post-purga: arquitectura core/project, 15 proyectos engram (no 40), 4 containers (wedo-db, qdrant, taskchampion-sync, mikedb), zram activo, TW3 sync 8090, matugen+swww, números reales (118G/468G) |
| `INVENTORY.md` | Re-correr `system-inventory.py` → refleja disco/repos/tools post-purga |
| `CONFIG-CHANGES.md` | Anexar changelog de la sesión 2026-09-10/11 completa (purga 81G, TW3, matugen, zram, engram unify, restic fix, commit 2767222) |
| `MASTER-INDEX.md` + `MCP-INVENTORY.md` | Sync: providers vivos, MCPs activos post-purga (sin postgres MCP de proyectos muertos si aplica) |
| `STATE.md` (NUEVO) | En raíz del repo dotfiles: estado vivo del sistema — proyecto activo, fase actual, pendientes, última sesión. Lo leen sesiones futuras al iniciar (integrado al Init Protocol) |

**Frescura:** timer systemd semanal (usuario) re-corre `system-inventory.py`; `just doc` en justfile para regeneración manual.

## Capa 2 — Auditoría + fixes de configs post-purga

| Ítem | Diagnóstico | Fix |
|---|---|---|
| `justfile` timew x7 targets | Timewarrior perdió su hook TW2 (`on-modify-timewarrior` removido — incompatible TW3) | Documentar timew como standalone en TOOLS-STRUCTURE.md + limpiar/ajustar targets del justfile que asumen integración task↔timew |
| hermes provider `x-preview-f-free` | Provider zen muerto/renombrado (HTTP 401) | Migrar config hermes a provider vivo del stack (zen nemotron-3-ultra-free u otro free) |
| Alias zsh (oc, just, task, pq) | No verificados post-purga | Verificar flujo real de cada alias; corregir los rotos |
| Configs stow | Post-cirugía engram + matugen | `just sync` + verificación 0 rotos (lsp/parse de cada config tocada) |

## Capa 3 — IA cross-app (opencode como central)

1. **Hyprland `$mainMod+O`** → abre ghostty ejecutando `opencode` directo (bind en stow hyprland.conf).
2. **Fuzzel proyectos** → script `~/.local/bin/ocp`: `fuzzel --dmenu` sobre lista de proyectos vivos → abre ghostty con `opencode` en el cwd elegido (wedo, School/dispositivos, maestro, snapmcp, dotfiles, Uspace, job-search, ideas). Bind Hyprland dedicado o entrada dentro de fuzzel.
3. **Notificaciones agentes background** → cuando un subagente de opencode termina tool calls, notificar vía daemon de notificaciones (mako/GNOME). Mecanismo: nativo `tui.json attention` (ya activo: cubre attention/permisos del TUI) + plugin opencode-yaml-hooks con evento `tool.execute.after` scope `child` para subagentes.
4. **Hermes 24/7 funcional** → tras fix de provider, documentar uso (`hermes -z`, gateway pendiente tokens).
5. **Todo documentado en SISTEMA_DOC.md** sección "Integraciones IA".

## Capa 4 — Modo de trabajo opencode (la interfaz principal del PC)

Opencode no es una herramienta más: es el entorno donde ocurre TODO el trabajo — código, ideas, diseño, investigación. El PC se opera DESDE opencode.

### 4.1 Guía de flujo de trabajo (WORKFLOW.md NUEVO)

Documento nuevo en `stow/opencode/.config/opencode/` que captura CÓMO se trabaja:

- **Sesión típica**: init protocol (mem_context → project detect → AGENTS.md) → trabajo → mem_save al cerrar. Cómo una sesión nueva retoma contexto.
- **Modos**: implementación (plan→build→verify), investigación (explore/librarian background), ideas/brainstorming (skill brainstorming → spec → plan), mantenimiento (auditoría como esta sesión).
- **Modelos por tarea**: orquestadores (GLM/Opus-class) vs workers free (zen/*-free) vs vision (mistral/pixtral) — cuál usar cuándo, según MASTER-INDEX.
- **Background everything**: subagentes paralelos, pueue para colas, delegación por categoría.
- **Memoria como flujo**: engram (persistente cross-sesión) ↔ opencode.db (histórico sesiones) — cómo consultar pasado, cómo se guarda lo nuevo.
- **Integraciones del ecosistema**: task/timew (planeación), zellij (multiplex), yazi (files), just (ruts), gh (repo) — todo invocable DESDE opencode.

### 4.2 STATE.md vivo (ya Capa 1) alimenta el loop

STATE.md + WORKFLOW.md son el par que una sesión nueva lee al iniciar: dónde estoy + cómo trabajo.

### 4.3 Salud del harness

- Verificar LSPs 11 activos, plugins 14, agents 23 cargando sin errores post-purga.
- Documentar en SISTEMA_DOC sección harness con números reales.

## Flujo de datos

```
system-inventory.py (scanner)
    → INVENTORY.md + engram (memoria)
    → SISTEMA_DOC.md / MASTER-INDEX (docs fuente de verdad, stow)
    → STATE.md (estado vivo, checkpoint de sesión)
    → sesiones opencode leen al iniciar (Init Protocol ya lo hace)
    → loop: timer semanal + just doc manual
```

## Fuera de scope

- Migrar a nuevo sistema de docs (Wiki, Obsidian, etc.) — se queda en Markdown + stow.
- Gateway Telegram/Discord de hermes — requiere tokens del user, solo se documenta el paso.
- Atuin self-host, sync cloud de engram — ya evaluados, quedan como optional future.

## Criterios de aceptación

1. `SISTEMA_DOC.md` refleja 118G, 4 containers, 15 proyectos engram, zram, TW3 — sin números pre-purga.
2. `system-inventory.py` corre limpio y `INVENTORY.md` timestamp ≥ 2026-09-11.
3. `STATE.md` existe, es leíble por una sesión nueva y tiene fecha de hoy.
4. `justfile` sin targets rotos; `timew` documentado standalone.
5. `hermes -z "test"` responde 200 de un provider vivo.
6. `$mainMod+O` abre opencode (verificado en Hyprland session).
7. `ocp` muestra los proyectos vivos y abre opencode en el cwd correcto (test manual).
8. Notificación de escritorio llega al terminar un tool call de subagente (test real con notify-hook.sh + attention nativo intacto).
9. `WORKFLOW.md` existe, cubre sesión típica + modos + modelos + memoria + integraciones, y vive en stow.
10. Commit con todo (convencional) + push a GitHub.
