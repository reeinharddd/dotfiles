# MCPs — 9 core + 13 on-demand

> Category: SYSTEM DOCUMENTATION (capability reference, not behavioral authority).
> Explains: what an MCP is here, how it registers, how it activates, policy. Behavioral routing lives in the Global Harness Contract §Tools; activation classification (ALWAYS/ON-DEMAND/SPECIALIZED/DISABLED) is owned by harness-registry + opencode.jsonc `mcp{}` (OLA 07).
> Source: `opencode.jsonc` `mcp{}` block. Core = `enabled: true` (always on). On-demand =
> `enabled per project` (listado en AGENTS.md / MCP-INVENTORY). All core MCPs verified working
> via real handshakes.

## Core (always on — 9)
| MCP | Type | URL / Command | Purpose | Key tools |
|-----|------|---------------|---------|-----------|
| `context7` | remote | `https://mcp.context7.com/mcp` | Current library/framework docs on demand. | `resolve-library-id`, `query-docs` |
| `engram` | local | `engram mcp --tools=agent` | Persistent memory across sessions/compactions. | `mem_save`, `mem_search`, `mem_context`, `mem_session_summary`, `mem_capture_passive` |
| `firecrawl` | remote | `https://mcp.firecrawl.dev/.../v2/mcp` | Web search, scrape, crawl, extract. | `firecrawl_search`, `firecrawl_scrape`, `firecrawl_crawl`, `firecrawl_agent` |
| `snapmcp` | local | `npx -y snapmcp` | Capturas: browser headless, código, terminal, HTML/MD, PDF. Reemplaza codebase-memory (2026-09-17). | `capture_browser`, `capture_code`, `capture_terminal`, `capture_pdf`, `capture_markdown` |
| `sequential-thinking` | local | `npx -y @modelcontextprotocol/server-sequential-thinking@2026.7.4` | Structured step-by-step reasoning. | `sequentialthinking` |
| `metronous` | local | `~/.local/bin/metronous mcp` | Telemetría, costos y benchmarks semanales; recomienda cambios de modelo. Daemon systemd. | `ingest` |
| `github` | local | `npx -y @modelcontextprotocol/server-github@2025.4.8` | PRs, issues, repos en cualquier proyecto. | `get_issue`, `list_pull_requests`, `search_code`, `create_or_update_file` |
| `filesystem` | local | `npx -y @modelcontextprotocol/server-filesystem@2026.7.10` | Acceso multi-repo. | list/read/write/search |
| `playwright` | local | `npx -y @playwright/mcp@0.0.79 --headless --isolated` | Browser global aislado: navegación web research + visual QA. | `browser_navigate`, `browser_snapshot`, `browser_click`, `browser_take_screenshot` |

## On-Demand (per project — 13)
| MCP | Type | Command / URL | When to enable | Note |
|-----|------|---------------|----------------|------|
| `royal-mcp` | remote | `http://localhost:8080/wp-json/royal-mcp/v1/mcp` | WordPress / WooCommerce projects. | project-specific |
| `code-review-graph` | local | `uvx code-review-graph serve` | Review-heavy projects. | project-specific |
| `page-agent` | remote | `http://localhost:3000/mcp` | Browser automation projects. | requires `npm i page-agent` |
| `openpencil` | remote | `http://localhost:8765/mcp` | Drawing / diagram projects. | requires `brew install openpencil` |
| `qdrant` | local | `uvx --python 3.12 mcp-server-qdrant` (Docker :6333, collection `opencode-knowledge`, fastembed) | Vector store / semantic RAG. | project-specific |
| `agentmemory` | local | `npx -y @agentmemory/mcp` | Deep memory >53 tools. Heavy, large projects only. | project-specific |
| `postgres` | local | `npx -y @anthropic/mcp-postgres` | Database projects, schema introspection. | project-specific |
| `sentry` | local | `npx -y mcp-sentry` | Error monitoring / on-call. | project-specific |
| `memory` | local | `npx -y @modelcontextprotocol/server-memory` | Lightweight alternative to agentmemory. | project-specific |
| `drive` | local | `npx -y mcp-remote https://drivemcp.googleapis.com/mcp/v1` | Google Drive (ideas, job-search). | project-specific |
| `docs` | local | `npx -y mcp-remote https://docsmcp.googleapis.com/mcp/v1` | Google Docs. | project-specific |
| `sheets` | local | `npx -y mcp-remote https://sheetsmcp.googleapis.com/mcp/v1` | Google Sheets. | project-specific |
| `brave-search` | local | `npx -y @anthropic/mcp-brave-search` | Web search (firecrawl fallback). | project-specific |

## Best practices
- **Prefer `context7`** over web search for library docs (current, sourced).
- **Save decisions to `engram`** proactively (bugfix / decision / discovery / config / pattern).
- **Use `codegraph`** for source understanding instead of reading files directly.
- **`qdrant`** is for durable semantic knowledge (long-term RAG), not ephemeral notes.
- Never hardcode on-demand MCPs into project config — select them via dotfiles / PCC.
- If a core MCP is missing/unreachable, report it; do not silently assume absence.