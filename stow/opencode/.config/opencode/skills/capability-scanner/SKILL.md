---
name: capability-scanner
description: >
  Descubre capabilities (skills, MCPs, binarios) que existen en el sistema pero no
  están registradas en core/registry/project context. Trigger: "I need a skill for X
  but it's not in registry", "is there an MCP for X", "find tools for Y", "what else
  can I use for Z".
---

# Capability Scanner — Auto-Discovery

> **Único mecanismo para descubrir capabilities no registradas.**
> El sistema escanea 3 fuentes y devuelve candidatos sin instalar nada.

## Cuándo invocarme

- La skill que necesitas NO está en core, ni en PROJECT_CONTEXT, ni en REGISTRY
- El usuario pide una funcionalidad y dices "no encuentro skill para eso"
- Quieres ver TODAS las herramientas disponibles en el sistema

## Flujo de acción

### Paso 1: Ejecutar el scanner

```bash
~/.config/opencode/scripts/capability-scanner.sh [project-root]
```

Output: JSON con:
- `summary`: contadores (core/registry/local/registered/discovered)
- `discovered_skills`: skills en `~/.config/opencode/skills/` que NO están registradas
- `discovered_mcps`: binarios npm/MCP que NO están registrados en opencode.json

### Paso 2: Interpretar resultados

**Si `discovered_skills` contiene la skill que el usuario quiere:**
- Carga directa: `skill(name="<nombre>")`
- NO requiere instalación — ya existe

**Si `discovered_mcps` contiene el MCP:**
- El binario ya existe en `node_modules/.bin/`
- Para activarlo: editar `opencode.json` mcp section → `"enabled": true`
- O ejecutar `project-bootstrap` que detecta y habilita automáticamente

**Si no hay nada en discovered:**
- La skill/MCP NO existe en el sistema
- Opciones:
  1. Buscar npm: `npm search <keywords>` para encontrar paquete
  2. Preguntarle a reeinharrrd si quiere instalar algo nuevo
  3. Crear la skill con `skill-creator` si es trabajo recurrente

### Paso 3: Persistir el descubrimiento (opcional)

Si la capability se va a usar en este proyecto:
- Agregar a `PROJECT_CONTEXT.md` → sección "Project Skills" o "Project MCPs"
- Esto la hace visible sin re-escanear

## Fuentes de descubrimiento

| Fuente | Ruta | Qué encuentra |
|--------|------|---------------|
| Skills locales | `~/.config/opencode/skills/*/SKILL.md` | Skills instaladas |
| MCPs npm | `~/.config/opencode/node_modules/.bin/` | Binarios ejecutables |
| Binarios PATH | `which <cmd>` (manual) | Tools CLI globales |

## Limitaciones

- El scanner NO busca skills en internet o repos remotos
- El scanner NO escanea skills dentro de sub-paquetes (e.g. `geo-seo/skills/`)
- Para descubrir skills nuevas, usar `skill-creator` o `npm search`

## Anti-patrones

❌ Decir "no encuentro la skill" sin antes ejecutar el scanner
❌ Instalar paquetes nuevos antes de verificar si ya existen
❌ Agregar a PROJECT_CONTEXT skills que NO existen (haría fallar la invocación)

## Output esperado

Cuando me invoques, ejecuta el scanner y devuelve:
1. JSON con discovered_skills y discovered_mcps
2. Para cada match relevante, comando de carga: `skill(name="...")` o edit opencode.json
3. Si no hay match → búsqueda npm o instalación nueva