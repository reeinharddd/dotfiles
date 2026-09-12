# WORKFLOW.md: Cómo se trabaja en este PC

> opencode es el modo PRINCIPAL de desarrollo, ideas y diseño.
> Par de entrada: STATE.md (qué está pasando) + este archivo (cómo se trabaja).

## Sesión típica (init protocol)

1. `engram mem_context`: recuperar memoria de sesiones previas
2. `engram mem_current_project`: detectar proyecto actual
3. Leer AGENTS.md del proyecto + STATE.md de dotfiles
4. Al cerrar: `engram mem_session_summary` + actualizar STATE.md

## Modos de trabajo

| Modo | Cuándo | Herramientas |
|---|---|---|
| Implementación | build features, bugfix | opencode TUI, delegación a subagentes, TDD |
| Investigación | "cómo funciona X", auditorías | opencode + explore/librarian + firecrawl |
| Ideas / diseño | specs, brainstorming | opencode + skill brainstorming -> specs/ |
| Mantenimiento | limpieza, docs, backups | opencode + just + scripts stow |

## Modelos por tarea (provider zen / cascada)

- **Orquestadores** (deciden, delegan): nemotron-3-ultra-free vía zen
- **Workers** (investigación, código batch): zen/*-free
- **Vision** (imágenes, UI QA): mistral/pixtral
- Cambiar contexto: sesiones opencode, cada una con su modelo asignado

## Background everything

- Subagentes paralelos fire-and-forget desde opencode
- `pueue` (alias `p`) para jobs shell de larga vida
- Delegación: 1-3 lecturas inline; 4+ -> subagent; test/lint/research/web -> delegar primero

## Memoria

- **engram** (persistente cross-session): decisiones, bugs, descubrimientos: `mem_save` proactivo, 15 proyectos vivos
- **opencode.db** (sesiones): historial completo de conversaciones, 5.0G, VACUUM ocasional
- Regla: knowledge -> engram; conversación -> opencode.db; estado -> STATE.md

## Integraciones invocables desde opencode

- `task`: Taskwarrior 3 con sync (server :8090), alias t/tl
- `timew`: Timewarrior standalone (hook TW2 removido; trackear manual)
- `zellij`: sesiones terminal persistentes
- `yazi` (yz), `lazygit` (lg), `gh`, `just`: dentro de bash tool
- `ocp`: selector fuzzel de proyectos -> nueva terminal opencode en cwd
- Notificaciones mako al terminar agentes (notify-hook.sh)

## Reglas de oro

- NUNCA matar sesiones opencode activas: son trabajo en curso
- Editar stow/ primero, re-stow después
- Docs fuente de verdad: SISTEMA_DOC (sistema), INVENTORY (detalle), STATE (vivo)
