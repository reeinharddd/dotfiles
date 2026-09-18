# 06 — OpenCode Ops (diagnóstico y observabilidad)

> Always loaded. Cómo diagnosticar opencode, dónde viven los datos y qué hacer
> cuando algo falla. Aplicado/auditado 2026-09-17 (opencode 1.18.29).

## Comandos de diagnóstico (en orden de uso)

| Necesitas | Comando |
|---|---|
| Snapshot completo (versión, MCPs, errores del día, tokens, telemetría, oracle) | `opencode-trace` (o `--save` para persistir en `~/.local/share/opencode/telemetry/snapshots/`) |
| Tokens/costos por modelo y tool usage | `opencode stats --days 7 --models 6 --tools 10` |
| Config resuelta (agentes, plugins, providers) | `opencode debug config` |
| Config de un agente (permisos, modelo, prompt) | `opencode debug agent <name>` |
| Plugins cargados + versión | `opencode debug info` |
| Skills disponibles (globales + proyecto) | `opencode debug skill` |
| Log detallado de un run puntual | `opencode run "<prompt>" --print-logs --log-level DEBUG` |
| Historial/transcripción de una sesión | `opencode export <sessionID>` (JSON con parts; `--sanitize` para redactar) |
| Sesiones guardadas | `opencode session list` |

## Dónde viven los datos

- Log global: `~/.local/share/opencode/log/opencode.log` (rotar si crece >50MB; errores históricos son ruido).
- Telemetría propia: `~/.local/share/opencode/telemetry/events/YYYY-MM-DD.jsonl` (fecha LOCAL). Eventos: `boot` (carga de plugin, cwd, #agentes), `tool` (tool, sessionID, callID, ok, args), `delegation` (delegate/task + flag `background`), `session_idle`, `plugin_error`. Dump crudo: `OPENCODE_TELEMETRY_DUMP=1 opencode run ...`.
- Snapshots: `~/.local/share/opencode/telemetry/snapshots/trace-*.txt`.
- Tokens/costos: DB de opencode vía `opencode stats`.

## Hooks de plugin en 1.18.29 (shape verificado)

- Existen: `config`, `tool.execute.before`, `chat.params`, `chat.message`, `event`, `permission`, `auth`, `machine`, `file`, `session.idle`, `experimental.chat.*`, `experimental.session.*`.
- NO existen `tool.error` ni `chat.error`: los fallos se detectan por log global, export de sesión (parts con error) y telemetría.
- `tool.execute.before(input, output)`: `input = {tool, sessionID, callID}`; los argumentos van en **`output.args`** (mutables: `output.args.x = ...`). Setear `output.output = "..."` reemplaza el resultado/aborta. Regla: nunca asumir `input.input`.

## Errores conocidos y mitigación

| Síntoma | Causa | Mitigación |
|---|---|---|
| `[503] Upstream error from Nvidia: Service temporarily overloaded` | pico de carga de zen→NVIDIA con `nemotron-3-ultra-free` | fallbacks de oh-my-openagent lo cubren; ignorar si el turno termina |
| `free tier can only be used from within OpenCode` | modelo free de zen invocado por un path que no es la app (p.ej. subagente con mode=all) | guard v14: todos los agentes en `mode: primary` |
| `ProviderModelNotFoundError: Model not found: <provider>/<model>` | sesión guardada con modelo de un provider eliminado (github-copilot, opencode-go, minimax, openai/gpt-5.6-luna-fast) | abrir la sesión y cambiar modelo con el picker, o `opencode session delete <id>` |
| `[429] rate limit` en `:free` de OpenRouter | pool compartido saturado upstream | reintentar más tarde o usar otro modelo del tier |
| `Task not found` / `Delegation completed without text output` | delegación **async** (`run_in_background=true`) en batch: el resultado no se recoge | en `opencode run` usar delegación sync (`run_in_background=false`) o `delegation_read` tras completar |
| `Model is unavailable` (zen union-alpha, muse-spark) | listado en pricing pero upstream no los sirve | no están en ninguna cascada; reintentar en días o eliminar del config |
| plugin custom sin línea "loaded" en log | opencode solo loguea el plugin builtin | verificar con `opencode debug info`; la telemetría emite `boot` al cargar |

## Coordinación

- Entre sesiones: engram (`mem_save`/`mem_context`), `STATE.md` (skill `state-tracking`), task packet `.opencode/state/task.json`.
- Paralelo en el MISMO repo: un worktree por sesión (`opencode-worktree`); nunca dos sesiones editando los mismos archivos.
- Auto-llamamientos: guard `plugins/model-routing-guard.js` fija modelo primario por agente (fuente de verdad); fallbacks en `oh-my-openagent.json`.
- Tareas largas: `pueue add` / background agents; no bloquear la sesión.

## Límites y free tier

- Verificar tier: `opencode models [provider]` (catálogo remoto) + smoke test `opencode run -m "<provider>/<model>" "di OK"`.
- Límites por modelo: declarados en `opencode.jsonc` (`limit.context/output`); pueden ser estimados — ajustar si la app reporta otro.
- Reasoning: `reasoningEffort` por agente en `oh-my-openagent.json` (ultrabrain/plan → high).
