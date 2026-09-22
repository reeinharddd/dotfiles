# 01-initialization.md — Session Init Protocol (condensed)

> Category: LIFECYCLE | Authority: Global Harness Contract §Context/§Memory. ALWAYS LOADED — runs at EVERY session start.

## First Message Protocol
1. `engram mem_context` — recover context (NOT optional)
2. `engram mem_current_project` — detect project
3. If FIRST ACTION REQUIRED → `engram mem_session_summary` → `mem_context`
4. Load project rules: `AGENTS.md`, `CLAUDE.md`, `.opencode/PROJECT_CONTEXT.md`
5. Verify codegraph: if missing → offer `npx codegraph init`
6. Run read-only checks: capability-doctor, project-audit
7. Provision safely: propose first, never overwrite silently
8. Read `.opencode/state/task.json` or init with `/task-init`

## After Compaction
1. `engram mem_session_summary` (what was accomplished)
2. `engram mem_context` → continue

## Pre-Task Gate (before ANY task)
1. Verify target files exist (ls/glob/codegraph_node)
2. Check `lsp_diagnostics` on target
3. `engram mem_search` for similar past work
4. If >3 files → Plan mode first

## Tool Ordering (ALWAYS)
- Code: `codegraph_explore` > `codegraph_node` > `read` > `grep`
- Edit: `edit` (small) > `write` (new) > python3 for scattered
- Search: `codegraph_explore` > `warpgrep` > `grep` > `glob`
- Web: `firecrawl_search` > `websearch` > `webfetch`
- Docs: `context7` > `firecrawl_scrape` > raw search