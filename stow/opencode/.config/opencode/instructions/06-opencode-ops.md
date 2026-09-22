# 06-opencode-ops.md — OpenCode Operations (condensed)

> Category: OPENCODE OPERATIONS | Authority: Global Harness Contract (behavior).
> **Routing**: OMO (`oh-my-openagent.json`) is sole authority; `model-routing-guard` validates
> free-only against `model-registry.free.yaml` (rejects, never decides). Do NOT maintain model
> tables here — they go stale (see OLA 05). ALWAYS LOADED — OpenCode-specific rules.

## Delegation
- 1-3 reads → inline; 4+ → subagent (`task` + category)
- Multi-file → delegate with write; test/lint/research/web → delegate first
- Background → `run_in_background=true`

## Routing (single source: OMO)
- Edit models/fallbacks only in `oh-my-openagent.json`
- free=UNKNOWN → not routed; primary needs free:KNOWN; fallbacks KNOWN|QUOTA; max 3
- Guard: `plugins/model-routing-guard.js` (validate only)
- Registry: `model-registry.free.yaml`
- No zen in background subagents (403 FreeTierError historically)
- LiteLLM (`provider.litellm` → `localhost:4000`): **provider failover only**, not model choice;
  diag: if 5xx/timeouts, check `litellm` process + baseURL before changing OMO

## Team Mode
- Enabled, 4 parallel, 8 max, 120min wall-clock
- Background: 5 concurrency, 2 depth, 30min stale timeout
- Circuit breaker: 200 tool calls, 10 consecutive threshold

## Permissions (opencode.jsonc)
- Profiles documented in OLA 10 (permission profiles); base: bash ask+allowlist, webfetch ask,
  read deny .env*/.ssh/sops/auth.json, edit ask opencode.jsonc/workflows, deny .git/hooks

## Hooks
- `tool.before.bash`: deny destructive (rm -rf, sudo rm, mkfs, dd, git reset --hard, git push --force)
- `session.idle`: auto-save script + **idempotent** STATE.md `Last checkpoint:` line
- `tool.execute.after` (child): notify-send on bash/edit/write

## Key Scripts
- `stow-sync.sh --dry-run` / `stow-sync.sh`
- `bootstrap.sh --check`
- `scripts/ctx-budget` — verify ≤15 KB
- `scripts/verify-claims.sh`
- `just doc` — refresh INVENTORY.md
