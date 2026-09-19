# MCP-INVENTORY — All Configured MCP Servers

> Generated: 2026-07-24 | Actualizado: 2026-09-17 (core 9, snapmcp reemplaza codebase-memory)
> Status by core/on-demand

## Core (Always Enabled — 9)

| MCP | Type | Transport | Purpose |
|-----|------|-----------|---------|
| **context7** | remote | HTTP | Version-pinned library docs. Stops hallucinated APIs. #1 MCP in the ecosystem. |
| **engram** | local | stdio | Persistent cross-session memory. Saves/recalls decisions, bugs, context. |
| **firecrawl** | remote | HTTP | Web scraping + search. Rich extraction, PDF parse, crawl, agent. |
| **snapmcp** | local | stdio | Screenshots y capturas (browser headless, código, terminal, HTML/MD, PDF). Reemplaza codebase-memory. |
| **sequential-thinking** | local | stdio | Dynamic multi-step reasoning. Breaks down complex problems. |
| **metronous** | local | stdio | Telemetría, costos y benchmarks semanales; recomienda cambios de modelo. Daemon systemd (`systemctl --user status metronous`). |
| **github** | local | stdio | PRs, issues, repos en cualquier proyecto (`npx @modelcontextprotocol/server-github@2025.4.8`). |
| **filesystem** | local | stdio | Acceso multi-repo (`npx @modelcontextprotocol/server-filesystem@2026.7.10`). |
| **playwright** | local | stdio | Browser global aislado: headless/isolated/sin service workers, navegación web para research y visual QA (`npx @playwright/mcp@0.0.79`). |

## Per-Project (On-Demand — 13)

Enable only in the project that needs it, preferably by setting `"enabled": true` in that project's `.opencode/opencode.jsonc`.

### Development

| MCP | Enable When | Command |
|-----|-------------|---------|
| **code-review-graph** | Review-heavy projects | `uvx code-review-graph serve` |

### Data & Backend

| MCP | Enable When | Command |
|-----|-------------|---------|
| **postgres** | Database projects, schema introspection | `npx -y @anthropic/mcp-postgres` |
| **qdrant** | Vector search / RAG | `uvx --python 3.12 mcp-server-qdrant` |

### Monitoring & Ops

| MCP | Enable When | Command |
|-----|-------------|---------|
| **sentry** | Error monitoring / on-call | `npx -y mcp-sentry` |

### Memory & Knowledge

| MCP | Enable When | Command |
|-----|-------------|---------|
| **agentmemory** | Deep memory >53 tools. Heavy, large projects only | `npx -y @agentmemory/mcp` |
| **memory** | Lightweight alternative to agentmemory | `npx -y @modelcontextprotocol/server-memory` |

### Services

| MCP | Enable When | Command |
|-----|-------------|---------|
| **brave-search** | Web search (firecrawl fallback) | `npx -y @anthropic/mcp-brave-search` |
| **royal-mcp** | WordPress projects | (remote) |
| **page-agent** | Interactive page browsing | (remote) |
| **openpencil** | Drawing/canvas | (remote) |
| **drive** | Google Drive (ideas, job-search) | `npx -y mcp-remote https://drivemcp.googleapis.com/mcp/v1` |
| **docs** | Google Docs | `npx -y mcp-remote https://docsmcp.googleapis.com/mcp/v1` |
| **sheets** | Google Sheets | `npx -y mcp-remote https://sheetsmcp.googleapis.com/mcp/v1` |

## Install Guide (for new MCPs)

```bash
# Review the manifest, pin the package version, add it to the project config, and restart.
# Avoid enabling optional MCPs in the global configuration.
```

## To remove an MCP

```bash
opencode mcp remove <name>
# Or set "enabled": false in opencode.jsonc
```