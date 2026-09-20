# 06 — OpenCode Ops (diagnóstico y observabilidad)

> Always loaded. Cómo diagnosticar opencode, dónde viven los datos y qué hacer
> cuando algo falla. Aplicado/auditado 2026-09-18 (opencode 1.18.29).

## Comandos de diagnóstico (en orden de uso)

| Necesitas | Comando |
|---|---|
| Snapshot completo (versión, MCPs, errores del día, tokens, telemetría, oracle) | `opencode-trace` (o `--save` para persistir en `~/.local/share/opencode/telemetry/snapshots/`) |
| Modelos fuera de allowlist (no verificados) | `opencode-model-audit` (o `--quiet`; exit 1 si hay ofensores) |
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

## Hooks de plugin en 1.18.29 (shape y capacidades verificadas)

- Existen: `config`, `tool.execute.before`, `chat.params`, `chat.message`, `event`, `permission`, `auth`, `machine`, `file`, `session.idle`, `experimental.chat.*`, `experimental.session.*`.
- NO existen `tool.error` ni `chat.error`: los fallos se detectan por log global, export de sesión (parts con error) y telemetría.
- Firma real: `tool.execute.before(input, output)` con `input = {tool, sessionID, callID}` (NO trae args) y `output = {args}` (aquí sí están). Nunca asumir `input.input`.
- Matriz de capacidades (probada empíricamente 2026-09-17 con `opencode run` + marcador `echo` + `.rtk-stats.jsonl`):

| Capacidad | Funciona | Detalle |
|---|---|---|
| Observar `input.tool` / `output.args.*` | SI | lectura fiable |
| Mutar `output.args.command = ...` | NO | ejecuta el valor ORIGINAL (probado in-place y reasignando `output.args = {...}`) |
| Reemplazar resultado con `output.output = "..."` | NO | el resultado real igual se devuelve |
| Abortar la tool call | SI | solo lanzando `throw` desde el hook (el agente recibe el error) |

- Nota: `opencode run` imprime el comando ORIGINAL (pre-hook); el display NO es evidencia de mutación.
- opencode prefija `export VAR=... ...; ` (separador `;`, incluye `VISUAL=''`) a *algunas* llamadas bash. Regex de detección: `/^(export\s[\s\S]*?(?:;\s*|&&\s*))/`.
- Consecuencia práctica: un plugin NO puede reescribir git/gh -> rtk en 1.18.29 (el rewrite debe venir del hook/PATH shim propio de rtk). Por eso `plugins/opencode-rtk.js` (v5) solo hace de guard de read-path: bloquea por bash `cat/ls/rg/grep/head/tail/sed/awk/find` vía `throw` (salvo pipeline/heredoc/redirección: `|<>`, `$(`, backtick) y registra en `.rtk-stats.jsonl` (tipos `block` / `allow_complex` / `error`).

## Errores conocidos y mitigación

| Síntoma | Causa | Mitigación |
|---|---|---|
| `[503] Upstream error from Nvidia: Service temporarily overloaded` | pico de carga de zen→NVIDIA con `nemotron-3-ultra-free` | fallbacks de oh-my-openagent lo cubren; ignorar si el turno termina |
| `free tier can only be used from within OpenCode` | modelo free de zen invocado por un path que no es la app (subagente mode=all, o delegación background sin contexto Console) | guard v14 (mode: primary) + v15: agente delegado en background debe usar provider NO-zen (general -> nvidia deepseek-v4-flash-0731) |
| `ProviderModelNotFoundError: Model not found: <provider>/<model>` | sesión guardada con modelo de un provider eliminado (github-copilot, opencode-go, minimax, openai/gpt-5.6-luna-fast) | abrir la sesión y cambiar modelo con el picker, o `opencode session delete <id>` |
| `[429] rate limit` en `:free` de OpenRouter | pool compartido saturado upstream | reintentar más tarde o usar otro modelo del tier |
| `Delegation completed without text output` | delegación background: el subagente usa modelo zen-free y falla 403 FreeTierError "free tier can only be used from within OpenCode" (el worker background no lleva el contexto Console); el fallo se traga como "sin output" | el agente delegado debe usar provider NO-zen (guard v15 + `opencode.jsonc` general -> nvidia deepseek-v4-flash-0731). OJO: requiere REINICIAR la app (config/plugins se cargan al arranque; no hot-reload para sesiones de delegación). Verificar: `opencode.db` session.model del subagente |
| `Model is unavailable` (zen union-alpha, muse-spark) | listado en pricing pero upstream no los sirve | no están en ninguna cascada; reintentar en días o eliminar del config |
| plugin custom sin línea "loaded" en log | opencode solo loguea el plugin builtin | verificar con `opencode debug info`; la telemetría emite `boot` al cargar |
| subagente con modelo `opencode/<x>` (deepseek-v4-flash, claude-opus-5, gpt-5.6-sol) | default **builtin** de opencode (provider `opencode` eliminado 2026-09-06); la instancia corre con registry stock sin tus overrides de agentes | reiniciar la app; auditar con `opencode-model-audit` |

## Coordinación

- Entre sesiones: engram (`mem_save`/`mem_context`), `STATE.md` (skill `state-tracking`), task packet `.opencode/state/task.json`.
- Paralelo en el MISMO repo: un worktree por sesión (`opencode-worktree`); nunca dos sesiones editando los mismos archivos.
- Auto-llamamientos: guard `plugins/model-routing-guard.js` fija modelo primario por agente (fuente de verdad); fallbacks en `oh-my-openagent.json`.
- Tareas largas: `pueue add` / background agents; no bloquear la sesión.

## Límites y free tier

- Verificar tier: `opencode models [provider]` (catálogo remoto) + smoke test `opencode run -m "<provider>/<model>" "di OK"`.
- Límites por modelo: declarados en `opencode.jsonc` (`limit.context/output`); pueden ser estimados — ajustar si la app reporta otro.
- Modelo nuevo: verificar SIEMPRE con `opencode run -m "<provider>/<model>" "di OK"` y agregarlo a la allowlist de `scripts/opencode-model-audit` antes de usarlo en cascadas. Un hang/timeout descalifica (ej: `google/gemini-robotics-er-2-preview` colgó >70s y fue retirado 2026-09-18).
- Reasoning: `reasoningEffort` por agente en `oh-my-openagent.json` (ultrabrain/plan → high).
