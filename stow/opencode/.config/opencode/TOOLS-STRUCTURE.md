# Tools Structure — Convenciones de carga

Reglas para integrar la bodega (`/home/reeinharrrd/tools/`) en OpenCode sin
sobrecargar el contexto global. Toda pieza se activa por ARTEFACTO, no por repo.

## 1. Skills / Agents / Commands — core + bodega (on-demand)
Toda pieza se activa por ARTEFACTO, no por repo.

- **Core activo**: `skills/` (25 skills), `commands/` (universales), agents definidos en
  `opencode.jsonc` + `oh-my-openagent.json` (13). Cargan al iniciar opencode.
- **Bodega (on-demand)**: `~/tools/` indexada por los manifests `plugins/bodega-*.json`
  (~1200+ skills/agents/commands). NO se cargan al iniciar; se invocan bajo demanda
  vía `skill(name=...)` / `capability-scanner`.
- **Activar un artefacto de bodega** = invocarlo por nombre o declararlo en el proyecto;
  no hay carpetas `-archive` ni symlinks (mecanismo legacy eliminado).

## 2. MCPs — 3 fuentes
- Globales: `opencode.jsonc` global `mcp{}` (siempre activos). Ver MCP-INVENTORY.md.
- Por proyecto: `<proyecto>/opencode.jsonc` `mcp{}` (se SUMA al global, no lo reemplaza).
- Inventario total: `MCP-INVENTORY.md` lista todos los MCP disponibles en la bodega
  (incluidos los que requieren install/config) para saber qué añadir a un proyecto.

## 3. Plugins — globales por defecto
- Se declaran en el global (`plugins/` symlink o array `plugin[]`).
- Rara vez por proyecto; si un proyecto lo requiere, va en su `opencode.jsonc`.

## 4. Apps externas (CLI/binario) y conocimiento
- Apps: viven en `tools/<repo>/`; se invocan vía skill wrapper (bash). No cargan nada
  hasta usarse. Requieren install previo según su manifest.
- Conocimiento (penpot API, awesome-llm-apps, etc): no se activa; se consulta vía índice.

## 5. Granularidad por artefacto
No se activa un repo entero. Se activa el artefacto interno concreto
(una skill de gstack, el MCP de ECC, un hook de dcg). Cada repo documenta sus
artefactos en `<repo>/.opencode/MANIFEST.md` con: tipo, modo de activación,
estado de preparación (ready/install/config/knowledge).


## 6. Manifests por repo (la fuente de verdad)

Cada repo en la bodega lleva su manifest de artefactos en:
  <repo>/.opencode/MANIFEST.md

El manifest lista artefacto-por-artefacto (no el repo entero) con:
  name + path | type | activation mode | prep state (ready/install/config/knowledge) | descripcion

Para activar algo: leer el manifest del repo, tomar el artefacto concreto,
aplicar su activation mode (symlink / declarar mcp / plugin / run-binary).

Inventario de manifests:
  find /home/reeinharrrd/tools -name MANIFEST.md -path '*/.opencode/*'

## 7. Activacion por alcance (resumen)
  - Global:      skills/ agents/ commands/ base + MCPs core en opencode.jsonc + plugins globales
  - Proyecto:    <proyecto>/opencode.jsonc mcp{} (se SUMA) + <proyecto>/.opencode/skills
  - Funcion:      artefacto de bodega activado bajo demanda (symlink archive->base, o mcp por proyecto)
  - Conocimiento: consulta via manifest/indice, no se carga