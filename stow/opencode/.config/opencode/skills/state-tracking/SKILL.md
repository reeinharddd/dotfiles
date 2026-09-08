---
name: state-tracking
description: Mantiene STATE.md (estado del proyecto en curso) para continuidad cross-session. Inyecta foco, fase, blockers, next y git status; checkpoint al terminar tareas y sesiones.
---

# State Tracking (STATE.md)

Mantén `.opencode/STATE.md` como la fuente de estado del trabajo en curso. Es estado, no memoria: la memoria de largo plazo la lleva engram. STATE.md es lo que "estoy haciendo AHORA" y sobrevive a sesiones y compactions.

## Formato (3 secciones)

```markdown
# State

## Current
focus: <tarea actual en una línea>
phase: <planning|building|verifying|done>
task: <referencia al plan/task>
blockers: <ninguno o lista corta>
next: <próximo paso concreto>
handoff: <quién continúa y dónde>

## Decisions
- [YYYY-MM-DD] <decisión o approach descartado, append-only>

## Log
- [auto] YYYY-MM-DD HH:MM — session ended, N tool calls, M files changed
```

## Reglas

1. Al iniciar una tarea, escribe la sección Current antes de tocar código (5 campos, una línea cada uno).
2. Cada vez que terminas un paso verificable (test pasa, lint limpio, read-back OK), actualiza `next` y `phase`.
3. Al terminar una sesión o antes de un compact, deja Current completo + un apunte en Log.
4. `Decisions` es append-only: nunca reescribas una decisión, agrega una línea nueva.
5. Si el proyecto no tiene `.opencode/STATE.md`, créalo al iniciar la primera tarea.

## Verificación

- STATE.md actualizado al cierre de cada sesión (el hook session.idle lo anota automáticamente si existe).
- La sección Current describe el estado presente, no lo que se hizo hace 3 horas.