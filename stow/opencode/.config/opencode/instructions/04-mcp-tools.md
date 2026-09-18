# Tool Routing Canonical — qué tool usar para cada acción (tokens/velocidad)

> ALWAYS LOADED. Fuente única de routing de tools. Objetivo: MENOS llamadas, MENOS tokens,
> más rápido. Orden real (empírico 2026-09-18, opencode 1.18.29):
> codegraph > lsp > grep/glob/read > web. Este doc reemplaza rutas anteriores (morph, warpgrep-first).

## Reglas de oro (reducen tool calling y contexto acumulado)
1. **codegraph PRIMERO**: una sola `codegraph_explore` responde "cómo funciona X" (source verbatim + call path + blast radius, sub-ms). Trátala como read: NO re-leas ni re-verifiques con grep.
2. **Batch**: llamadas independientes en UN mensaje (multi-read / multi-grep en paralelo).
3. **`glob` para localizar archivos, NUNCA `find`** (rtk lo bloquea con throw).
4. **bash SOLO git/docker/test/install/build**. NUNCA file ops (rtk bloquea cat/ls/rg/grep/head/tail/sed/awk/find).
5. **context7 ANTES que web search** para librerías. **engram `mem_search` ANTES** de tareas complejas (evita re-explorar trabajo ya hecho).
6. **morph_edit está MUERTO (HTTP 402)** en este entorno: NO usarlo. Para editar symlinks/archivos scattered: **python3 in-place** (open+w sigue el symlink).
7. **Config/plugins NO tienen hot-reload**: REINICIAR la app para que apliquen. Delegaciones y subagentes usan la config CARGADA AL ARRANQUE (fuente del bug "model not found" / builtin `opencode/*`).

## Matriz por acción (1ª opción → fallback)

| Acción | 1ª opción (por qué) | Fallback |
|---|---|---|
| "Cómo funciona X" / flujo X→Y | `codegraph_explore` (1 llamada: source + call path + blast radius) | `codebase-memory trace_path/search_graph` si indexado |
| Símbolo / definición | `codegraph_explore` | `lsp_goto_definition` |
| Quién llama / impacto | `codegraph_explore` (blast radius) | `lsp_find_references` / `codebase-memory trace_path` |
| Búsqueda NL en codebase | `warpgrep_codebase_search` (multi-turn agentic) | `grep` |
| Keyword exacta | `grep` (compacto, sin API, cap 60s) | `grep_app_searchGitHub` (público) |
| Localizar archivos por patrón | `glob` (rápido, cheap) | `ls` solo si carpeta pequeña |
| Leer archivos | `read` (paralelizar; si el source ya vino de codegraph, está leído) | `filesystem_read_multiple_files` (batch 1 llamada) |
| Config/docs no indexados | `read` directo | — |
| Editar (pequeño, exacto) | `edit` | — |
| Crear archivo nuevo | `write` | — |
| Editar symlink / scattered / grande | `python3` in-place (morph MUERTO 402) | `edit` por bloque |
| Refactor / rename | `lsp_rename` + `lsp_find_references` | `grep` + `edit` |
| Gate de calidad | `lsp_diagnostics` (0 errores) | `opencode-verify` |
| Docs de librería | `context7 resolve-library-id` → `query-docs` (≤3 llamadas) | `firecrawl_scrape` |
| Web search | `firecrawl_search` (`categories:["developer"]` para código) | `websearch_web_search_exa` / `webfetch` |
| Memoria | `engram mem_context` (inicio) / `mem_search` (pre-task) / `mem_save` (post-decisión) | — |
| Git / GitHub | bash `git`/`gh` CLI (rtk no los bloquea) | — |
| Build/test/terminal | bash; `pueue add` si es largo | — |
| Browser / visual QA | `playwright` (snapshot/actions) | `snapmcp_capture_*` |
| Diagnóstico opencode | `opencode-trace` / `opencode-model-audit` | `opencode debug config` |
| Datos (CSV/parquet) | skill `data-scientist` (DuckDB/Polars, uv) | — |

## Modelos (gobernanza — evitar "model not found" / no verificados)
- **Allowlist VERIFICADA** (smoke test live 2026-09-18) vive en `scripts/opencode-model-audit`. Correrla tras tocar configs; ya está wireada en `opencode-trace`.
- NUNCA añadir un modelo sin verificar: `opencode run -m "<provider>/<model>" "di OK"`. Un **hang/timeout TAMBIÉN descalifica** (ej: `google/gemini-robotics-er-2-preview` colgó >70s → retirado de configs 2026-09-18).
- Modelos `opencode/*` (deepseek-v4-flash, claude-opus-5, gpt-5.6-sol) = defaults **builtin** de opencode con el provider `opencode` ELIMINADO (decisión 2026-09-06). Si un subagente sale con esos modelos → la instancia corre con registry stock → REINICIAR la app.
- Fuente de verdad del cascade: `plugins/model-routing-guard.js`; fallbacks runtime en `oh-my-openagent.json`. Mantener los 3 sincronizados con la allowlist.

## MCPs por proyecto (on-demand, fuera del core)

Los MCPs especificos de un stack se definen en `opencode.json` en la RAIZ del repo (config se mergea por capas; seguro de commitear). NUNCA en el global. Bloques copy-paste:

| Stack | MCP | Bloque (vacio en el repo si no aplica) |
|---|---|---|
| WordPress | royal-mcp | `{"mcp":{"royal-mcp":{"enabled":true,"type":"remote","url":"http://localhost:8080/wp-json/royal-mcp/v1/mcp"}}}` |
| UI/visual | snapmcp | `{"mcp":{"snapmcp":{"enabled":true,"type":"local","command":["npx","-y","snapmcp"]}}}` |
| review pesado | code-review-graph | `{"mcp":{"code-review-graph":{"enabled":true,"type":"local","command":["uvx","code-review-graph","serve"]}}}` |
| page-agent | page-agent | `{"mcp":{"page-agent":{"enabled":true,"type":"remote","url":"http://localhost:3000/mcp"}}}` |
| openpencil | openpencil | `{"mcp":{"openpencil":{"enabled":true,"type":"remote","url":"http://localhost:8765/mcp"}}}` |
| RAG/vector | qdrant | `{"mcp":{"qdrant":{"enabled":true,"type":"local","command":["uvx","--python","3.12","mcp-server-qdrant"],"QDRANT_URL":"http://localhost:6333","COLLECTION_NAME":"opencode-knowledge","EMBEDDING_PROVIDER":"fastembed"}}}` |
| memoria profunda | agentmemory | `{"mcp":{"agentmemory":{"enabled":true,"type":"local","command":["npx","-y","@agentmemory/mcp"],"AGENTMEMORY_URL":"${AGENTMEMORY_URL:-http://localhost:3111}"}}}` |
| backend/DB (Uspace, maestro) | postgres | `{"mcp":{"postgres":{"enabled":true,"type":"local","command":["npx","-y","@anthropic/mcp-postgres"]}}}` — requiere `DATABASE_URL` |
| errores/traces | sentry | `{"mcp":{"sentry":{"enabled":true,"type":"local","command":["npx","-y","mcp-sentry"]}}}` |
| RAG local | memory | `{"mcp":{"memory":{"enabled":true,"type":"local","command":["npx","-y","@modelcontextprotocol/server-memory"]}}}` |
| Google Drive (ideas, job-search) | drive | `{"mcp":{"drive":{"enabled":true,"type":"local","command":["npx","-y","mcp-remote","https://drivemcp.googleapis.com/mcp/v1"]}}}` |
| Google Docs | docs | `{"mcp":{"docs":{"enabled":true,"type":"local","command":["npx","-y","mcp-remote","https://docsmcp.googleapis.com/mcp/v1"]}}}` |
| Google Sheets | sheets | `{"mcp":{"sheets":{"enabled":true,"type":"local","command":["npx","-y","mcp-remote","https://sheetsmcp.googleapis.com/mcp/v1"]}}}` |
| web search extra | brave-search | `{"mcp":{"brave-search":{"enabled":true,"type":"local","command":["npx","-y","@anthropic/mcp-brave-search"]}}}` |
