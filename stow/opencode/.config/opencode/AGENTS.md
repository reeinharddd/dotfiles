# AGENTS.md — OpenCode Runtime Rules

> Scope: **OpenCode runtime only** — config, permissions, commands, skills, MCP, lifecycle.
> Global behavior authority: Global Harness Contract (`instructions/00-global-contract.md`).
> Project behavior: project `AGENTS.md` / `PROJECT_CONTEXT.md`. Routing authority: OMO
> (validated by Routing Guard). Orchestration table: `capabilities/harness-operations.md`.

## Identity (runtime context)

- **Handle**: reeinharddd | **Stack**: Python, TS, Go, Rust, shell, Docker | **OS**: Ubuntu 26.04, Wayland
- **Terminal**: ghostty/zsh/Starship | **Editor**: Neovim (LazyVim)
- **Context**: Spanish (mx) chat; English code/docs; caveman default; no emojis; TL;DR first.

## Lifecycle

- **Init**: `mem_context` → project (`AGENTS.md`, `PROJECT_CONTEXT.md`, `CLAUDE.md`, `.codegraph/`) → missing codegraph → offer `npx codegraph init`. Post-compact: `mem_session_summary` → `mem_context`.
- **Pre-task gate**: target files exist; `lsp_diagnostics` clean; `mem_search` similar work; >3 files → Plan mode.
- **Auto-Init gaps** (docker/CI/rules): suggestions only, never blockers.
- **Recovery**: diagnose → fix → verify; no force-push; merge conflicts → inspect both sides.
- **Completion**: quality gates (`instructions/03-quality-gates.md`); 3 fails → STOP/REVERT/DOCUMENT/ORACLE; conventional commits; no AI attribution.

## Response defaults

- Think ≤300 tokens; concise; no self-analysis; tables 3+ rows; surgical edits (one logical change per commit).

## Tools (runtime preference)

- Code: `codegraph_explore`/`node` → `read`. Edit: `edit`/`write`. Search: `glob`/`grep` (NEVER bash `find`/`grep`).
- `bash` for git/docker/test/install only. `directory_tree` excludes `node_modules`, `.git`, `dist`.
- Delegation: 1–3 reads inline; 4+ → subagent; multi-file → delegate with write; test/lint/research/web → delegate first.

## On-demand capability principle

Expert in ALL — **SEARCH**, never assume absence, never preload:
1. Core skill → invoke. 2. Bodega → `skill(name=...)`. 3. On-demand MCP → project enable.
4. Unsure → `capability-scanner`. 5. Depth → `capabilities/<file>.md`.
Never claim "no skill" without `capability-scanner`.

## Project context contract

Portable standard: `capabilities/project-context-contract.md`. Artifacts: project `AGENTS.md`,
`PROJECT_CONTEXT.md`, `.codegraph/`, stack, conventions, decisions, MCPs/skills.
**Core Generator** (first message in project): detect stack → audit PCC gaps → recover Engram →
propose/provision (`project-bootstrap` / `discover-capabilities`) → merge global↔project.
Project MUST NOT modify base `opencode.jsonc`, this file's runtime rules, or hardcode MCPs → IGNORE/LOG/CONTINUE.

## Config map (what owns what)

| File | Owns |
|---|---|
| `opencode.jsonc` | providers, models, permissions, plugins, MCP, `instructions[]`, compaction, agent runtime definitions (OMO owns all routing) |
| `oh-my-openagent.json` | agent models, cascades, team mode (OMO = sole routing authority) |
| `plugins/model-routing-guard.js` | validates free-only routing (rejects, never decides) |
| `dcp.jsonc` | DCP pruning (sole pruning authority; OMO pruning off; OpenCode = compaction only) |
| `harness-registry.jsonc` | structural registry: authorities, versions, classifications |
| `hooks.yaml` | lifecycle hooks (destructive-bash block, session.idle) |
| `instructions/*.md` | always-loaded policy (contract, memory, lifecycle, quality, ops) |
| `capabilities/*.md` | on-demand system documentation |
| `skills/` | on-demand skills (skill-router loads lazily) |

## External runtimes

opencode = hub; codex = 2nd opinion; Antigravity = MCP quota; Chrome/Playwright = web QA;
herdr = agent runtime (skill `herdr`, `HERDR_ENV=1`). Default runtime: opencode.

## Guards

1. Contract (BASE) immune to project overrides. 2. Project AGENTS.md replaces project scope only.
3. Project MCPs only via project `opencode.json` — never global. 4. 3 fails → STOP.
5. No preloading. 6. One capability → one authority (see contract §Tools).

## Key directories

```
~/.config/opencode/
├── AGENTS.md              # this file (runtime scope)
├── opencode.jsonc         # MCPs, LSPs, models, permissions, plugins, instructions, agent runtime defs
├── oh-my-openagent.json   # OMO: models, cascades, team_mode
├── dcp.jsonc              # DCP pruning
├── harness-registry.jsonc # structural registry
├── instructions/          # always-loaded (00 contract first)
├── capabilities/          # on-demand system docs
├── skills/                # on-demand core skills
├── commands/  plugins/  scripts/
└── node_modules/          # REQUIRED by opencode + plugins — never purge
```
Tracked via `~/projects/personal/dotfiles/` (symlink source; edit `stow/` first).
