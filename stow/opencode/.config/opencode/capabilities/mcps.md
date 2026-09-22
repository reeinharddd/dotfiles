# MCPs — inventory + activation classes

> Category: SYSTEM DOCUMENTATION (capability reference, not behavioral authority).
> Activation classes: ALWAYS / SPECIALIZED / ON-DEMAND (see harness-registry `mcpPolicy`).
> **Version authority**: `harness-registry.jsonc` `pinnedTools` → mirrored into
> `opencode.jsonc` npx pins (OLA 07). Behavioral routing: Global Harness Contract §Tools.
> **Structural validation**: `scripts/validate-harness-registry.py` (OLA 12) enforces
> the registry as a structural contract — required keys, no mcpPolicy overlap,
> version alignment, one-capability-one-authority. Run before commits.

## Core (enabled in `opencode.jsonc` mcp{} — 9)
| MCP | Type | URL / Command | Class | Purpose |
|-----|------|---------------|-------|---------|
| `context7` | remote | `https://mcp.context7.com/mcp` | ALWAYS | Library/framework docs |
| `engram` | local | `engram mcp --tools=agent` | ALWAYS | Persistent memory |
| `firecrawl` | remote | `https://mcp.firecrawl.dev/.../v2/mcp` | ALWAYS | Web search/scrape |
| `snapmcp` | local | `snapmcp` | ALWAYS | Captures |
| `sequential-thinking` | local | `npx -y @modelcontextprotocol/server-sequential-thinking@<PIN>` | SPECIALIZED | Structured reasoning |
| `metronous` | local | `engram mcp --tools=metronous` | SPECIALIZED | Telemetry/benchmarks |
| `github` | local | `npx -y @modelcontextprotocol/server-github@<PIN>` | ON-DEMAND* | PRs/issues |
| `playwright` | local | `npx -y @playwright/mcp@<PIN>` | ON-DEMAND* | Browser QA |
| `filesystem` | local | `npx -y @modelcontextprotocol/server-filesystem@<PIN>` | ON-DEMAND* | Multi-repo FS |

`<PIN>` = version from `harness-registry.jsonc` `pinnedTools` (sole version authority — OLA 07).
\*Currently `enabled: true` in global config; candidates to demote to project-only in CLEANUP.

## On-Demand (project-only candidates — not in global mcp{})
Listed in registry `mcpPolicy.onDemand` / project `opencode.json` only: royal-mcp, code-review-graph,
page-agent, openpencil, qdrant, agentmemory, postgres, sentry, memory, drive, docs, sheets, brave-search.

**Versions**: edit only in `harness-registry.jsonc` → mirror into `opencode.jsonc` npx pins.
Never `@latest` (see OLA 13). This file is documentation, not authority.

## Best practices
- Prefer `context7` for library docs; `engram` for decisions; `codegraph` for source maps.
- Never hardcode on-demand MCPs globally — project `opencode.json` only.
- If a core MCP is missing/unreachable, report it; do not silently assume absence.