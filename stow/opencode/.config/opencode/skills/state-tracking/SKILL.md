---
name: state-tracking
classification: CORE
description: Mantiene .opencode/STATE.md — solo estado actual del trabajo (task, completed, in progress, blocked, next, temporary context). No es memoria histórica: decisiones duraderas → engram. Reemplaza secciones, nunca append infinito.
---

# State Tracking (STATE.md)

Mantén `.opencode/STATE.md` como la fuente de **estado del trabajo en curso**. Es estado, no memoria:
- Memoria persistente (decisiones, bugs, descubrimientos) → **engram**
- Conocimiento estable del proyecto → **PROJECT_CONTEXT.md**
- STATE = "qué estoy haciendo AHORA"; sobrevive a sesiones/compaction pero no crece para siempre

Plantilla: `~/.config/opencode/templates/STATE.template.md` (ver también PCC §STATE).

## Formato (secciones a reemplazar)

```markdown
# State

## Current task:
<una línea>

## Completed:
<checkpoints de este esfuerzo>

## In progress:
<trabajo empezado>

## Blocked:
<blockers + por qué | none>

## Next:
<paso concreto siguiente>

## Important temporary context:
<path, puerto, branch necesarios hasta cerrar la tarea>
```

## Reglas

1. Al iniciar una tarea, escribe Current task antes de tocar código.
2. Cada paso verificable (test pasa, lint limpio) actualiza Completed / In progress / Next.
3. Al terminar sesión o antes de compact, deja las 6 secciones completas.
4. **Reemplaza** secciones; no hagas append-only de historial. Decisions vivas van a engram con topic_key.
5. `Important temporary context` se limpia al terminar la tarea.
6. Si el proyecto no tiene `.opencode/STATE.md`, créalo al iniciar la primera tarea (template arriba).

## Verificación

- STATE.md actualizado al cierre de cada sesión (hook session.idle checkpointa de forma idempotente si existe).
- La sección Current task describe el presente, no lo que se hizo hace 3 horas.
