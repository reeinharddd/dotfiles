# MCP Tool Selection Guide

> ALWAYS LOADED — tool routing for efficient execution.

## Code Understanding
| Intent | Tool | Fallback |
|--------|------|----------|
| "How does X work?" (any question) | `codegraph_explore` | `codegraph_node` |
| Read a file | `codegraph_node <file>` | `read` |
| Find a symbol | `codegraph_search` | `grep` |
| Who calls this? | `codegraph_callers` | `lsp_find_references` |
| What does this call? | `codegraph_node <symbol>` | `codegraph_explore` |
| Natural-language code search | `warpgrep_codebase_search` | `codegraph_explore` |

## Editing
| Intent | Tool | When |
|--------|------|------|
| Large file, scattered changes | `morph_edit` | 300+ lines or multiple spots |
| Small exact replacement | `edit` | Single, known string |
| New file | `write` | Brand new file |
| Rename symbol | `lsp_rename` | Across workspace |

## Web & Docs
| Intent | Tool | Fallback |
|--------|------|----------|
| Library documentation | `context7_query-docs` | `firecrawl_firecrawl_scrape` |
| Web search | `firecrawl_firecrawl_search` | `websearch` |
| Web page content | `firecrawl_firecrawl_scrape` | `webfetch` |
| GitHub repo internals | `warpgrep_github_search` | clone + grep |

## Memory
| Intent | Tool |
|--------|------|
| Save decision/bug/discovery | `engram mem_save` |
| Recall past work | `engram mem_context` then `engram mem_search` |
| Session summary | `engram mem_session_summary` |
| Full observation | `engram mem_get_observation` |

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

