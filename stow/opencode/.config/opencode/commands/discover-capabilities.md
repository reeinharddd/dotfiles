---
description: Descubre skills, MCPs y binarios no registrados en core/registry/project-context
---
Descubre capabilities (skills, MCPs, binarios) que existen en el sistema pero NO están registradas en core/registry/project-context.

## Uso

```
/discover-capabilities              # escanea cwd
/discover-capabilities [path]       # escanea path específico
```

## Qué hace

Ejecuta `~/.config/opencode/scripts/capability-scanner.sh` que escanea:

| Fuente | Encuentra |
|--------|-----------|
| `~/.config/opencode/skills/*/SKILL.md` | Skills instaladas |
| `~/.config/opencode/node_modules/.bin/` | Binarios npm ejecutables |
| Filtra contra | core-skills/, REGISTRY.md, opencode.json, PROJECT_CONTEXT.md |

## Output

JSON con:
- `summary`: contadores
- `discovered_skills`: skills en el sistema no registradas
- `discovered_mcps`: binarios MCP no registrados

## Después de descubrir

**Para skill existente:**
```
skill(name="<nombre>")
```

**Para MCP existente:**
Editar `~/.config/opencode/opencode.json` mcp section:
```json
"<nombre>": {
  "command": ["..."],
  "type": "local",
  "enabled": true
}
```

**Para agregar al proyecto actual:**
Agregar a `<project>/.opencode/PROJECT_CONTEXT.md`:
- Sección "Project Skills" → `- <skill-name>`
- Sección "Project MCPs" → `- <mcp-name>`

## Importante

- El scanner NO instala nada, solo detecta lo que ya existe
- Si una capability no aparece en discovered → NO existe en el sistema
- Para instalar algo nuevo: `npm install -g <paquete>` o `skill-creator`