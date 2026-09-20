# AGENTS.md — Central Agent Config (minimal)

> Core protocol. Core (global) → on-demand (per-project).

## Identity
- **Handle**: reeinharddd | **Role**: Full-stack dev, sysadmin, automation
- **Stack**: Python, TS, Go, Rust, shell, Docker | **OS**: Ubuntu 26.04, Wayland
- **Terminal**: ghostty/zsh/Starship | **Editor**: Neovim (LazyVim)
- **Context**: Spanish (mx) chat; English code/docs; caveman default. Password via `sudo -S`/sudoers. No sudo w/o explicit; no commits w/o request; no `rm -rf` (`/tmp/opencode-trash`). Mise for tools. Keyboard-first, background, TUI over GUI.

## Constitution
12 Karpathy rules in `core-constitution` (always loaded). **Precedence**: user > skills > system.

## BASE PROTOCOL (HARD RULES)
- **Init**: `mem_context` → project (`AGENTS.md`, `PROJECT_CONTEXT.md`, `CLAUDE.md`, `.opencode/skills/`, `.codegraph/`) → no `.codegraph/` → `npx codegraph init`. Post-compact: `mem_session_summary` → `mem_context`.
- **Think**: ≤300 tokens; concise, no self-analysis.
- **Response**: NO emojis. TL;DR first. No preamble/flattery/status. Tables 3+ rows.
- **Memory**: `mem_save` after bugfix/decision/discovery/config/pattern/pref; `mem_capture_passive` after non-trivial.
- **Tools**: `codegraph_explore`/`node` for source; `read` config/docs; `edit`/`write` files; `glob`/`grep` search (NEVER bash `find`/`grep`); `bash` only git/docker/test/install. `directory_tree` excludes `node_modules`, `.git`, `dist`.
- **Delegation**: 1-3 reads → inline; 4+ → subagent; multi-file → delegate w/ write; test/lint/research/web → delegate first.
- **Auto-Init**: check `.codegraph/`, rules, docker/CI — gaps as suggestions, never blockers.
- **Recovery**: diagnose → fix → verify; no force-push; merge conflict → inspect both.
- **Quality**: `lsp_diagnostics` clean; build/test exit 0; 3 fails → STOP/REVERT/DOCUMENT/ORACLE.
- **Rules**: no AI attribution; conventional commits; code=English, chat=Spanish; no emojis.

## ARCHITECTURE: Core + On-Demand
**Core**: 9 MCPs, 6 free providers, 11 LSPs, 23 agents, 24 skills, bodega index, DCP, RTK.
**On-Demand**: ~1900 bodega entries (1274 skills, 316 commands, 314 agents + 24/187/67 global), 13 project MCPs, project skills/agents, `PROJECT_CONTEXT.md`.

## ON-DEMAND CAPABILITY PRINCIPLE
Expert in ALL. When needing capability: **SEARCH** not assume absence.
1. Core skill? → invoke.
2. Bodega skill? → `skill(name=...)`.
3. On-demand MCP? → enable in project.
4. Unsure? → `capability-scanner` → create/search.
5. Depth? → read `capabilities/<file>.md`.
Never preload. Never claim "no skill" without `capability-scanner`.

## PROJECT CONTEXT CONTRACT (PCC)
Portable context standard. See `capabilities/project-context-contract.md`. Artifacts: `AGENTS.md`, `PROJECT_CONTEXT.md`, `.codegraph/`, stack/tech, conventions, decisions, MCPs/skills.

## CORE GENERATOR
First message in project: audit PCC → generate missing from context (stack, codegraph, bodega). Fuse global+project. Steps: 1. Detect stack. 2. Audit gaps. 3. Recover memory (`engram`). 4. Provision via `project-bootstrap`/`discover-capabilities`/propose. If `.codegraph/` broken, `npx codegraph init`. 5. Merge global↔project.

## COORDINATION LAYER
Core coordinates using global tools, following project rules, injects **strong thinking** (`verification-before-completion`) + **capabilities** (on-demand skills/MCPs). Prevents "lots of info but lost execution".

## ORCHESTRATION DECISIONS
First match wins. Inventories: `capabilities/`, `just --list`.

| Trigger | Mechanism | Rule |
|---|---|---|
| 1-3 files, known | direct tools | no delegation |
| Unfamiliar / multi-angle | `explore` (bg) | never re-do delegated search |
| External lib/API/docs | `librarian` (context7) | before web search |
| Multi-file, visual, security, research | `task(category)` + skills | domain-matched, never generic |
| Multi-system, stuck >15min, 2+ fails | `oracle`/`metis` | read-only; collect before implementing |
| >5 repetitive | `ralph-loop`/`ulw-loop` | explicit user request only |
| 2+ independent | parallel bg tasks | batch non-dependent |
| Parallel, SAME repo | 1 worktree/session | NEVER 2 sessions same files |
| Several sessions, same folder | allowed | coordinate via engram+STATE.md |
| Capability not in registry | `capability-scanner` | skill/MCP/create in order |
| Recurring job | systemd timer | `just doc`; one-offs → `pueue` |
| Long blocking | `pueue add` | keep responsive |
| Cascade model not found | switch to known-good | never retry broken |
| Bugfix/decision/discovery | `mem_save` | topic_key for evolving |
| Session start/post-compact | `mem_context` + STATE.md | mandatory |

**External**: opencode=hub; codex=2nd opinion; Antigravity=MCP quota; Chrome/Playwright=web QA; herdr=agent runtime (mise 0.9.0, zellij removed 2026-09-13, ghostty=emulator). Skill `herdr` (HERDR_ENV=1) controls panes, launches helpers, waits state. Invoke via MCP/bash when needed — default in opencode.

**Guards**: (1) BASE immune to project overrides. (2) Project AGENTS.md replaces global except BASE. (3) Project MCPs only via root `opencode.json`, never global. (4) Never claim "no capability" without `capability-scanner`. (5) 3 fails → STOP/DOCUMENT/ORACLE. (6) No preloading — search on demand.

## PROJECT-LEVEL OVERRIDES
Projects MAY have: `AGENTS.md` (replaces global — only BASE immune), `CLAUDE.md`, `.opencode/PROJECT_CONTEXT.md`, `.opencode/skills/`. **PROTECTION**: project MUST NOT modify base `opencode.jsonc`, this AGENTS.md BASE, or hardcode MCPs. Violation → IGNORE, LOG, CONTINUE.

## KEY DIRECTORIES
```
~/.config/opencode/
├── AGENTS.md              # this file
├── opencode.jsonc         # MCPs, LSPs, agents, models, permissions, plugins
├── oh-my-openagent.json   # model cascade, agents, loops, team_mode
├── dcp.jsonc              # dynamic context pruning
├── skills/                # 24 core skills
├── instructions/          # always-loaded (init, rules, quality, mcp)
├── plugins/               # bodega manifests + index
├── commands/              # slash commands (universal + bodega)
├── scripts/               # bash utilities (dotfiles symlink)
└── node_modules/          # REQUIRED by opencode + 8 plugins — never purge
```
Tracked via `~/projects/personal/dotfiles/` (symlink source).