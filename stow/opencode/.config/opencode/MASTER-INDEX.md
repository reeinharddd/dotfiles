# MASTER-INDEX — OpenCode Global Configuration

> Updated: 2026-08-15 | Core setup for reeinharrrd

## Architecture

```
~/.config/opencode/           # Core (always active, minimal)
  ├── opencode.jsonc           # Main config: providers, MCPs, agents, plugins
  ├── ../.omo/omo.jsonc        # Canonical OMO agent routing and fallbacks
  ├── harness-registry.jsonc   # Canonical harness policy and capability routing
  ├── dcp.jsonc                # Dynamic Context Pruning + extract
  ├── hooks.yaml               # Lifecycle hooks (safety + auto-save)
  ├── opencode.env             # Provider environment variables (mode 600)
  ├── MASTER-INDEX.md          # This file
  ├── MCP-INVENTORY.md         # MCP reference
  ├── CONFIG-CHANGES.md        # Change log
  ├── skills/                  # 21 core skills (all symlinks)
  ├── plugins/                 # Local plugins and generated bodega manifests
  └── node_modules/            # Plugin dependencies

~/tools/                       # Bodega (on-demand per project)
  ├── opencode-hooks/hooks.yaml        # Complete hooks reference
  ├── destructive_command_guard/       # dcg v0.6.7
  ├── agentmemory/                     # deep memory (53 MCP tools)
  ├── gstack/                          # 30+ specialized skills
  ├── superpowers/                     # skill-based development superpowers
  ├── opencode-power-pack/             # skill portfolio
  └── ...
```

## Core Specs

| Dimension | Count | Details |
|-----------|-------|---------|
| Providers | 6 active | opencode-zen, tokenrouter, mistral, google, nvidia, openrouter |
| Agents | 19+ | inline agents, OMO builtins, and bodega agents |
| Core MCPs | 9 | context7, engram, firecrawl, codebase-memory, sequential-thinking, metronous, github, playwright, filesystem |
| On-demand MCPs | 11 | agentmemory, qdrant, postgres, sentry, memory, brave-search, snapmcp, code-review-graph, page-agent, openpencil, royal-mcp |
| Plugins | 14 active | oh-my-openagent, model-routing-guard, rtk, bodega-index, morph-plugin, yaml-hooks, notify, background-agents, opencode-dcp, caveman, superpowers, metronous, vibeguard, antigravity-auth |
| Skills (core) | 24 | mix: stow symlinks + external repos (superpowers, power-pack) |
| Categories | 6 | fast, deep, ultrabrain, vision, writing, business-logic |
| Security | sandbox-run (docker/bwrap, red default-deny) + hooks.yaml blocks + dcg skill + permission denies |

## Provider Key

Orquestadores (build/smart/oracle/plan/reviewers): `opencode-zen/nemotron-3-ultra-free`.
Workers (fast/explore/scout/general): `opencode-zen/*-free` (nemotron-3-ultra-free / hy3-free).
Vision: `mistral/pixtral-12b-latest` (fallback mistral-medium-latest, gemini-3.7-flash).
Docs/research: `google/gemini-3.8-flash` (model global).
small_model (títulos/compaction): `opencode-zen/nemotron-3-ultra-free`.

## Quick Start Per-Project

```bash
# Add only the MCPs required by the project in its `.opencode/opencode.jsonc`.
# The global configuration keeps nonessential MCPs disabled.
```

## Security

- dcg v0.6.7 blocks `rm -rf /`, `sudo rm`, `mkfs`, `dd if=` before execution
- vibeguard activo (plugin opencode-vibeguard@0.1.0) — redacta secretos/PII antes de cada llamada LLM y restaura antes de ejecutar tools
- hooks.yaml has tool.before.bash safety blocks
- No rm -rf; use `mv <path> /tmp/`
- Provider credentials must live in environment variables or protected files, never in generated docs.
- Run `scripts/opencode-harness-check.sh` before changing global configuration.
- Review `HARNESS-OPERATIONS.md` for execution profiles and retention rules.
