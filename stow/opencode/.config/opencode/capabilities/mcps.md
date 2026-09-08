# MCPs — 6 core + 5 on-demand

> Source: `opencode.jsonc` `mcp{}` block. Core = `enabled: true` (always on). On-demand =
> `enabled: false` (enable per project). All core MCPs verified working via real handshakes.

## Core (always on)
| MCP | Type | URL / Command | Purpose | Key tools |
|-----|------|---------------|---------|-----------|
| `context7` | remote | `https://mcp.context7.com/mcp` | Current library/framework docs on demand. | `resolve-library-id`, `query-docs` |
| `engram` | local | `engram mcp --tools=agent` | Persistent memory across sessions/compactions. | `mem_save`, `mem_search`, `mem_context`, `mem_session_summary`, `mem_capture_passive` |
| `firecrawl` | remote | `https://mcp.firecrawl.dev/.../v2/mcp` | Web search, scrape, crawl, extract. | `firecrawl_search`, `firecrawl_scrape`, `firecrawl_crawl`, `firecrawl_agent` |
| `codebase-memory` | local | `codebase-memory-mcp` | Code knowledge graph (symbols, edges, callers). | `index_repository`, `search_graph`, `query_graph`, `trace_path`, `get_architecture` |
| `sequential-thinking` | local | `npx @modelcontextprotocol/server-sequential-thinking` | Structured step-by-step reasoning. | `sequentialthinking` |
| `qdrant` | local | `uvx mcp-server-qdrant` (Docker :6333, collection `opencode-knowledge`, fastembed) | Vector store / semantic RAG, global. | `qdrant-store`, `qdrant-find` |

## On-Demand (enable per project)
| MCP | Type | Command / URL | When to enable | Note |
|-----|------|---------------|----------------|------|
| `royal-mcp` | remote | `http://localhost:8080/wp-json/royal-mcp/v1/mcp` | WordPress / WooCommerce projects. | project-specific |
| `snapmcp` | local | `npx snapmcp` | UI / visual projects. | project-specific |
| `code-review-graph` | local | `uvx code-review-graph serve` | Review-heavy projects. | project-specific |
| `page-agent` | remote | `http://localhost:3000/mcp` | Browser automation projects. | requires `npm i page-agent` |
| `openpencil` | remote | `http://localhost:8765/mcp` | Drawing / diagram projects. | requires `brew install openpencil` |

## Best practices
- **Prefer `context7`** over web search for library docs (current, sourced).
- **Save decisions to `engram`** proactively (bugfix / decision / discovery / config / pattern).
- **Use `codebase-memory` / `codegraph`** for source understanding instead of reading files directly.
- **`qdrant`** is for durable semantic knowledge (long-term RAG), not ephemeral notes.
- Never hardcode on-demand MCPs into project config — select them via dotfiles / PCC.
- If a core MCP is missing/unreachable, report it; do not silently assume absence.
