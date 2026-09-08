# MCP-INVENTORY — All Configured MCP Servers

> Generated: 2026-07-24 | Status by core/on-demand

## Core (Always Enabled — 6)

| MCP | Type | Transport | Purpose |
|-----|------|-----------|---------|
| **context7** | remote | HTTP | Version-pinned library docs. Stops hallucinated APIs. #1 MCP in the ecosystem. |
| **engram** | local | stdio | Persistent cross-session memory. Saves/recalls decisions, bugs, context. |
| **firecrawl** | remote | HTTP | Web scraping + search. Rich extraction, PDF parse, crawl, agent. |
| **codebase-memory** | local | stdio | Knowledge graph over code. Symbol index, callers/callees, blast radius. |
| **sequential-thinking** | local | stdio | Dynamic multi-step reasoning. Breaks down complex problems. |
| **metronous** | local | stdio | Telemetría, costos y benchmarks semanales; recomienda cambios de modelo. Daemon systemd (`systemctl --user status metronous`). |

## Per-Project (On-Demand — 14)

Enable only in the project that needs it, preferably by setting `"enabled": true` in that project's `.opencode/opencode.jsonc`.

### Development

| MCP | Enable When | Command |
|-----|-------------|---------|
| **github** | Any GitHub project (PRs, issues, commits) | `npx -y @modelcontextprotocol/server-github` |
| **playwright** | Frontend/E2E testing, browser automation | `npx -y @playwright/mcp` |
| **filesystem** | Working across >1 repo simultaneously | `npx -y @modelcontextprotocol/server-filesystem` |
| **snapmcp** | UI/visual design projects | `npx -y snapmcp` |
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
