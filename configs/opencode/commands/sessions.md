Muestra un dashboard de sesiones OpenCode: tokens, costos, proyectos, agentes.

## Uso

```
/sessions                  # últimas 30 sesiones
/sessions list 50          # últimas 50 sesiones
/sessions projects         # breakdown por proyecto
/sessions agents           # breakdown por agente
/sessions daily 7          # tendencias últimos 7 días
/sessions show <id>        # detalle de una sesión específica
```

## Qué hace

Ejecuta `oc-analyze` (script Python en `~/.config/opencode/scripts/`) sobre la base de datos local de OpenCode.

- **list**: sesiones recientes con título, tokens in/out, cache, costo
- **projects**: cuánto has gastado por proyecto
- **agents**: cuánto por agente (sisyphus, oracle, explore, etc.)
- **daily**: tendencias día a día
- **show**: mensajes, partes (tool-use, tool-result), tokens por rol

## Tips

- Usa `/sessions projects` para ver dónde se van los tokens
- Usa `/sessions show <id>` para auditoría de una sesión específica
- Los datos vienen de `~/.local/share/opencode/opencode.db`
