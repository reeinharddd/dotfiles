# 04-mcp-tools.md — MCP Tools Routing (condensed)

> Category: TOOLS | Authority: capabilities/mcps.md (inventory) + Global Harness Contract §Tools (one capability one authority). ALWAYS LOADED — MCP tool routing map. Classification: ALWAYS=engram,context7 · ON-DEMAND=github,playwright,filesystem,etc · SPECIALIZED=sequential-thinking,metronous (see OLA 07).

## Core MCPs (always on)
| MCP | Type | Purpose |
|-----|------|---------|
| context7 | remote | Live library docs |
| engram | local | `engram mcp --tools=agent` — persistent memory |
| firecrawl | remote | Web scraping (URL: `{env:FIRECRAWL_API_KEY}`) |
| snapmcp | local | Screenshots/code renders |
| sequential-thinking | local | Structured reasoning |
| metronous | local | `engram mcp --tools=metronous` — telemetry |
| github | local | `npx -y @modelcontextprotocol/server-github` |
| playwright | local | `npx -y @playwright/mcp` |
| filesystem | local | `npx -y @modelcontextprotocol/server-filesystem $HOME/projects` |

## On-Demand MCPs (project-scoped)
- postgres, sentry, drive/docs/sheets, royal-mcp, qdrant, memory, page-agent, openpencil, agentmemory, brave-search, code-review-graph, snapmcp

## Routing Rules
- **Libraries/APIs** → context7 (first)
- **Web research** → firecrawl / firecrawl_search
- **Memory/Decisions** → engram
- **GitHub ops** → github
- **Browser/QA** → playwright
- **Files** → filesystem (project-scoped)
- **Screenshots** → snapmcp
- **Reasoning** → sequential-thinking
- **Telemetry** → metronous

## Activation
- Global: `opencode.jsonc` → `mcp` section
- Project: `<project>/opencode.jsonc` → `mcp` (ADDS to global, never replaces)
- Inventory: `MCP-INVENTORY.md` lists all available