# MEMORY POLICY — Uso obligatorio y sistemático de Engram

> ALWAYS LOADED — se aplica en CADA sesión, CADA proyecto (`scope`) y CADA agente.
> Este archivo es la garantía de que engram se usa como **cerebro único** del sistema:
> nada importante se pierde, todo aprendizaje relevante se registra.

**Regla de oro**: SI hiciste algo no trivial que valga la pena recordar o reutilizar → **GUARDA EN ENGRAM**. No esperes. No lo dejes "para después". Guardar es obligatorio, no opcional.

---

## 1. Cuándo guardar (triggers por paso / "cada que tenga sentido")

Guarda **inmediatamente después** de cada una de estas situaciones:

| Trigger | Tipo sugerido | Ejemplo |
|---|---|---|
| Corregiste un bug | `bugfix` | "Fixed N+1 query in user list" |
| Tomaste/dejaste una decisión de arquitectura | `decision` / `architecture` | "Switched from sessions to JWT" |
| Descubriste un gotcha / edge case | `discovery` | "FTS5 MATCH no es LIKE — escapá comillas" |
| Cambiaste configuración | `config` | "Añadido provider nvidia a opencode.jsonc" |
| Estableciste un patrón/convención | `pattern` | "Convención: hooks.yaml global bloquea rm -rf" |
| El usuario expresó una preferencia | `decision` | "Usuario NO usa loops de IA" |
| Completaste una tarea / unidad de trabajo | `learning` / `manual` | "Entregado: memoria personal central" |
| Cerraste una sesión | `session_end` | resumen estructurado (ver §5) |
| Hubo compactación de contexto | `session_end` | `mem_session_summary` → luego `mem_context` |
| Iniciaste sesión | (consulta) | `mem_context` + `mem_current_project` |

**Pregunta rápida al terminar cada paso/turno**: *"¿aprendí o decidí algo que otro agente/yo mismo en el futuro necesitaría?"* Si sí → guarda. Si dudas → **guarda** (el exceso de memoria es barato; perder contexto es caro).

## 2. Scope: DÓNDE cae cada memoria

Selecciona el scope **antes** de guardar — es la decisión que organiza el "sistema y cerebro":

| Scope | Contenido que guarda | Cómo |
|---|---|---|
| `personal` | Quién soy, preferencias, estilo de comunicación, herramientas, software, bookmarks, cosas de la persona | `mem_save(scope="personal")` → consolida en `PERSONAL.md` |
| `project` (default) | Decisiones, bugs, patrones, config de UN proyecto específico | `mem_save` (por defecto usa el proyecto activo) |

Regla: si aplica a TODOS los proyectos → `personal`. Si aplica a uno solo → `project`.

## 3. Formato uniforme (SIEMPRE este esquema)

```
**What**: [qué se hizo, conciso]
**Why**: [la razón, pedido, o problema que lo motivó]
**Where**: [archivos/rutas afectadas]
**Learned**: [gotchas, edge cases, decisiones — omitir si no aplica]
```

Ejemplo:
```
**What**: Reemplacé express-session por jsonwebtoken
**Why**: Sesiones no escalan multi-instancia
**Where**: src/middleware/auth.ts, src/routes/login.ts
**Learned**: httpOnly + secure en cookie; refresh tokens con rotación separada
```

## 4. Buscar ANTES (pre-task gate)

Antes de empezar una tarea compleja o desconocida:
1. `mem_context` — memoria reciente de sesiones previas
2. `mem_current_project` — detecta el proyecto activo
3. `mem_search query="<keywords>"` — busca trabajo similar ya hecho

No reinventar: si ya existe memoria de algo, úsala como contexto.

## 5. Ciclo de vida de sesión (obligatorio)

- **Inicio**: `mem_context` → `mem_current_project` → lectura de `AGENTS.md`/`PROJECT_CONTEXT.md`.
- **Tras compactación**: `mem_session_summary` (resumen de lo hecho) → `mem_context`.
- **Fin de sesión**: `mem_session_summary` con estructura Goal/Instructions/Discoveries/Accomplished/Next Steps/Relevant Files.
- **Conflictos**: si `mem_save` devuelve `judgment_required`, resuélvelo con `mem_judge` (silencioso si `related`/`compatible`/`scoped`; pregunta al usuario si `supersedes`/`conflicts_with` sobre arquitectura/política/decisión o confianza <0.7).

## 6. Autogrowth y refinado

- El "cerebro" crece solo: cada sesión con un dato personal nuevo se registra en engram (`personal`) y se consolida en `PERSONAL.md`.
- Si una preferencia cambia, actualiza la observación (topic_key estable) en lugar de duplicar.
- La política aplica a TODOS los agentes y scopes por igual: mismas reglas de memoria siempre.
