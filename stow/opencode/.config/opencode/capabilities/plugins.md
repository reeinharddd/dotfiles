# Plugins (14) — real function + activation

> Active plugin array lives in `opencode.jsonc` `plugin[]` (14 entries). Source of truth for
> what loads at startup. This doc describes each one's role.
> `node_modules/` (626M, 13 pkgs) is **REQUIRED** by opencode + these plugins — never purge.

## 1. oh-my-openagent `4.19.4`
- **Role**: Core harness — "Batteries-Included OpenCode Plugin with Multi-Model Orchestration,
  Parallel Background Agents, and Crafted LSP/AST Tools."
- **Provides**: model cascade + agents (oracle, librarian, team mode), codegraph component,
  caveman mode, rules engine, skills loader. Backbone of most automation.
- **Author**: YeonGyu-Kim. License SUL-1.0.

## 2. model-routing-guard.js `v10` (own, stow)
- **Role**: The routing enforcer. Forces the all-free CASCADE on every agent/model request:
  primary `opencode-zen/nemotron-3-ultra-free`, fallbacks `mimo-v2.5-free` /
  `gemini-3.7-flash` / `mistral`. Multimodal-looker → `mistral/pixtral-12b-latest`.
- **Note**: antigravity models are deliberately OUT of the cascade (see Routing Policy below).

## 3. opencode-rtk.js (own, stow)
- **Role**: Rewrites `git`/`gh` commands to `rtk git status/diff/log/stash` — the RTK layer.

## 4. bodega-index.js `1.0.0` (own, stow)
- **Role**: The on-demand mechanism. Reads the 6 `bodega-*.json` manifests, dedups by name
  (core first) and realpath, injects into `config.skills.paths` / `config.agent` /
  `config.command`. Skills/agents/commands are registered as discoverable, NOT loaded at
  startup — invoked on demand.

## 5. @morphllm/opencode-morph-plugin `2.0.16`
- **Role**: Morph SDK — `morph_edit` (fast partial-file apply) + WarpGrep codebase search.
- **Use**: large/scattered edits (prefer `morph_edit` for 300+ line files or many changes);
  WarpGrep for natural-language code search. Always-on instruction in `morph-tools.md`.

## 6. opencode-yaml-hooks `2026.3.29`
- **Role**: Loads `hooks.yaml` — global destructive-bash safety blocks (rm -rf, sudo rm, mkfs,
  dd, git reset --hard/clean/push --force, wp db reset) + session.idle auto-save.

## 7. opencode-notify `0.3.1`
- **Role**: Native OS notifications with actionable buttons (Linux via dbus/notifier).
- **Use**: alert when a long task / background agent finishes.

## 8. opencode-background-agents `0.1.1`
- **Role**: Persistent background delegation. Subagents survive outside the session and
  report later. Fire-and-forget for long research/build tasks.

## 9. opencode-dcp `3.1.14` (~/tools reference)
- **Role**: Dynamic Context Pruning — `compress` tool, extract/protect hooks, range-mode
  compression. Config in `dcp.jsonc`.

## 10. caveman/plugin.js (own, stow)
- **Role**: Caveman output mode — strips narration, keeps technical facts. Active via
  `.caveman-active` marker file.

## 11. superpowers.js (~/tools reference)
- **Role**: Superpowers skill framework — brainstorming, TDD, systematic-debugging, and the
  skill-invocation discipline (loaded every session).

## 12. metronous.ts (own, stow)
- **Role**: Observability — telemetry events, benchmarks (weekly lun 02:00), TUI. Daemon
  `metronous.service` (systemd user).

## 13. opencode-vibeguard `0.1.0`
- **Role**: Privacy redaction. Replaces secrets/PII with `__VG_...__` placeholders before
  LLM calls, restores after. Config: `vibeguard.config.json`.

## 14. opencode-antigravity-auth `v1.10.0+local` (~/tools reference)
- **Role**: Google Antigravity OAuth — gemini/claude models via Google credentials,
  multi-account rotation on quota exhaustion (500ms failover), native `antigravity_quota`
  tool (5h + weekly windows), thinking variants, Google Search grounding.
- **Local patch** (branch `local-v1.10.0`, commit `bffa4a0`): strips `x-goog-api-key` header
  (Antigravity endpoints reject API keys). Update procedure: fetch upstream → rebase patch.
- **Storage**: clone in `~/tools/opencode-antigravity-auth` + symlink in `plugins/`.

## Routing Policy — antigravity models
- The 8 antigravity model entries in `opencode.jsonc` (~lines 713-770) are **manual/overflow
  use only** — deliberately excluded from the model-routing-guard cascade.
- Rationale: (1) ToS grey-area — Anthropic blocked OpenCode from Claude; Antigravity OAuth is
  the workaround; ban risk exists. (2) Quota scarcity — 2 accounts, weekly windows at
  100%/97%. (3) Primary stack is all-free (zen cascade) — antigravity is secondary.
- Rule: never add antigravity models to the guard cascade. Use them by explicit model
  selection when a task needs gemini-3.x-pro / claude-4-6 quality and free tier can't deliver.
- Alternative plugin if Opus errors appear: `shekohex/opencode-google-antigravity-auth`
  (recommended by anomalyco maintainer, issue #6064). Plan B only — do not switch
  preventively.

## Notes
- Plugins activate automatically when declared in `opencode.jsonc` `plugin[]`; `bodega-index`
  runs as a `config` hook on every startup.
- Removed 2026-09-08: `opencode-scheduler`, `opencode-websearch-cited`, `opencode-worktree`
  (dead deps, 0 references), `opencode-power-pack` npm dep (real source = `~/tools/` clone +
  symlinks; plugin file `plugins/opencode-power-pack.js` is a no-op guard — early-returns
  because `skills/` exists).
