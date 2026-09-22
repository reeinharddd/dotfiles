# 06-opencode-ops.md — OpenCode Operations (condensed)

> Category: OPENCODE OPERATIONS | Authority: Global Harness Contract (behavior) + OMO (routing tables below are informational — OMO is sole routing authority, Routing Guard validates; models may lag reality, verify before relying). ALWAYS LOADED — OpenCode-specific rules.

## Delegation
- 1-3 reads → inline; 4+ → subagent (`task` + category)
- Multi-file → delegate with write; test/lint/research/web → delegate first
- Background → `run_in_background=true`

## Agents (oh-my-openagent)
| Category | Primary | Fallbacks |
|----------|---------|-----------|
| fast | gemini-3.5-flash-lite | mistral/ministral-8b, nvidia/deepseek-v4-flash |
| deep | gemini-3.8-flash | mistral/medium, nvidia/deepseek-v4-flash, openrouter/dots-3-note:free |
| ultrabrain | mistral/medium | antigravity-claude-sonnet, gemini-3.8-flash, nvidia/deepseek-v4-flash |
| vision | gemini-3.8-flash | antigravity-gemini-3.8-flash, openrouter/dots-3-note:free |
| quick | nvidia/deepseek-v4-flash | mistral/ministral-8b, gemini-2.5-flash-lite |

## Key Agents
- **smart** (default): nemotron-3-ultra-free (zen)
- **build**: nemotron-3-ultra-free (zen)
- **general**: nvidia/deepseek-v4-flash
- **oracle**: nvidia/deepseek-v4-flash
- **code-reviewer**: mistral/medium
- **explore**: gemini-3.5-flash-lite
- **docs-lookup**: gemini-3.8-flash
- **tdd-guide**: nvidia/deepseek-v4-flash
- **qa-enforcer**: nvidia/deepseek-v4-flash
- **vision**: gemini-3.8-flash
- **librarian**: gemini-3.8-flash
- **metis/momus**: mistral/medium

## Model Routing (model-routing-guard v18)
- Free-only: zen, nvidia, google, mistral, openrouter free
- No zen in background (403 FreeTierError)
- Vision → google/gemini-3.8-flash
- Fallback chains: 3+ per agent, different providers
- Routing guard owns decisions; LiteLLM only provider failover

## Team Mode
- Enabled, 4 parallel, 8 max, 120min wall-clock
- Background: 5 concurrency, 2 depth, 30min stale timeout
- Circuit breaker: 200 tool calls, 10 consecutive threshold

## Permissions (opencode.jsonc)
- `bash`: `ask` + allowlist (mise, git, stow, npm, cargo, python3, node, gh, docker, systemctl, journalctl)
- `webfetch`: `ask`
- `read`: deny .env*, .ssh/*, sops/*, auth.json
- `edit`: ask for opencode.jsonc, .github/workflows/*, deny .git/hooks/*

## Hooks
- `tool.before.bash`: deny destructive (rm -rf, sudo rm, mkfs, dd, git reset --hard, git push --force)
- `session.idle`: auto-save context + STATE.md checkpoint
- `tool.execute.after` (child): notify-send on bash/edit/write

## Key Scripts
- `stow-sync.sh --dry-run` — preview
- `stow-sync.sh` — apply with backup
- `bootstrap.sh --check` — verify prerequisites
- `scripts/ctx-budget` — verify ≤15 KB
- `scripts/verify-claims.sh` — threat model claims
- `just doc` — refresh INVENTORY.md