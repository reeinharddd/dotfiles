# Plugins — classification (OLA 08)

> Category: SYSTEM DOCUMENTATION (capability reference, not behavioral authority).
> **Telemetry single path**: one sink only — see Telemetry row below. Do not enable a second.

## Loading mechanism (OpenCode)

| Source | How registered | Where |
|--------|----------------|-------|
| **Local files** | Auto-loaded at startup from plugin directory | `~/.config/opencode/plugins/*.{js,ts}` — no `plugin[]` entry needed |
| **npm packages** | Must be listed in config `plugin[]` array | `opencode.jsonc` `plugin[]` (pin version, no `@latest`) |
| **OMO (both halves)** | TUI half + server half must both register | `tui.json` `plugin[]` **and** `opencode.jsonc` `plugin[]` |

Load order: global config → project config → global `plugins/` dir → project `.opencode/plugins/`.

Verified via `opencode debug config` (resolved `plugin[]` includes `file://` entries for every local plugin).

## Classes

| Class | Meaning |
|-------|---------|
| **ROUTING** | Agent/model routing validation (never decides) |
| **MEMORY/DCP** | Context pruning / extract / protect (DCP = pruning authority) |
| **TELEMETRY** | Observability — **exactly one active path** |
| **LIFECYCLE** | Hooks, sessions, notify |
| **GUARD** | Safety / permission / config guards |
| **EXTERNAL** | npm-installed provider integrations |

## Inventory

| Plugin | Source | Class | Notes |
|--------|--------|-------|-------|
| `model-routing-guard.js` | local | ROUTING | Validates free-only vs OMO; never injects models |
| `regenerate-manifests.py` | local script | META | Generates bodega manifests (`--check`/`--dry-run`) |
| `bodega-index.js` | local | META | Bodega discovery index |
| `opencode-dcp` / `@tarquinen/opencode-dcp` | npm | MEMORY/DCP | DCP pruning sole authority (`dcp.jsonc`) |
| `opencode-telemetry.js` | local | TELEMETRY | Prefer this path; disable others when enabled |
| `metronous.ts` | local | TELEMETRY | **Alt path** — only if telemetry.js off (see Telemetry) |
| `@langfuse/opencode-observability-plugin@0.5.0` | npm `plugin[]` | TELEMETRY | **Alt path** — pin; disable if telemetry.js on |
| `envsitter-guard@0.0.4` | npm `plugin[]` | GUARD | `.env` safety |
| `opencode-rtk.js` | local | LIFECYCLE | Output filtering proxy hooks |
| `opencode-notify` | npm | LIFECYCLE | Notifications |
| `opencode-yaml-hooks` | npm | LIFECYCLE | hooks.yaml runner |
| `opencode-vibeguard` | npm | GUARD | Vibe/permission guard |
| `opencode-background-agents` | npm | LIFECYCLE | Background task plumbing |
| `oh-my-openagent@4.19.4` | npm `plugin[]` + `tui.json` | ROUTING | OMO sole routing authority; **both halves required** (server in `opencode.jsonc`, TUI in `tui.json`) |
| `dcg` | local dir | MEMORY/DCP | DCP-related helper |
| `caveman` | local dir | META | Token-strip helper (skill-backed) |
| `opencode-power-pack.js` | local | META | Power-pack glue |
| `superpowers.js` | local | META | Superpowers skill glue |
| `herdr-agent-state.js` | local | LIFECYCLE | Herdr state (skill `herdr`) |
| `opencode-antigravity-auth` | local | GUARD | Antigravity auth helper |
| `@morphllm/opencode-morph-plugin` | npm | EXTERNAL | Morph provider |
| `@opencode-ai/plugin`, `@opencode-ai/sdk` | npm | EXTERNAL | OpenCode SDK (required) |
| `jsonc-parser` | npm | EXTERNAL | Used by guards/validators |

## Telemetry (single path policy)

**Exactly ONE enabled:**

| Rank | Path | Enable when |
|------|------|-------------|
| 1 (preferred) | `plugins/opencode-telemetry.js` + `experimental.openTelemetry` | Default local metrics |
| 2 | `@langfuse/opencode-observability-plugin` in `plugin[]` | Langfuse instance available |
| 3 | `metronous` MCP / `metronous.ts` | Weekly cost/bench ingest only |

`oh-my-openagent.json` `"telemetry": false` stays false unless switching paths.
`profile.personal` `METRONOUS_ENABLED` is ingest flag, not a second APM.

## Anti-patterns

- ❌ Two telemetry plugins active at once
- ❌ Copying a third-party plugin into stow without local modification rule
- ❌ Editing npm plugin source in place (pin version instead)
- ❌ `@latest` in `plugin[]` (use registry `pinnedTools`)
- ❌ OMO registered in only one half (`tui.json` without `opencode.jsonc` → server tools/hooks dead)
