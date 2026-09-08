# Session Initialization Protocol

> ALWAYS LOADED — runs at every session start before any tool use.

## First Message Protocol

Upon receiving ANY user message (first message or continuation):

1. **Check memory**: call `engram mem_context` immediately — this is NOT optional
2. **Detect project**: call `engram mem_current_project` to identify the current project
3. **Check session state**:
   - If FIRST ACTION REQUIRED banner → call `engram mem_session_summary` IMMEDIATELY
   - Then call `engram mem_context` to recover context
4. **Load project rules**: check for `AGENTS.md`, `CLAUDE.md`, `.opencode/PROJECT_CONTEXT.md`
5. **Verify codegraph**: if `.codegraph/` is missing, offer to init (never force)
6. **Run global read-only checks**:
   - `~/.config/opencode/scripts/opencode-capability-doctor`
   - `~/.config/opencode/scripts/opencode-project-audit "$PWD"`
7. **Provision safely**: if the audit finds missing artifacts, generate a proposal first;
   never overwrite project instructions, dirty files, credentials, or existing manifests silently.
8. **Open the task packet**: if `.opencode/state/task.json` exists, read it before acting. For
   non-trivial work without a packet, initialize one with `opencode-task init` or `/task-init`.

## After Compaction

If compaction message seen:
1. Call `engram mem_session_summary` with what was accomplished
2. Call `engram mem_context` to recover
3. Continue working

## Pre-Task Gate (before ANY task execution)

Before starting ANY task:
1. Verify the target files exist (use `ls`, `glob`, or `codegraph_node`)
2. Check `lsp_diagnostics` for the target file(s)
3. Search engram for similar past work: `engram mem_search query="<keywords>"`
4. If the task is >3 files: use Plan mode first

## Tool Ordering

Always prefer in this order:
- **Understanding code**: `codegraph_explore` > `codegraph_node` > `read` > `grep`
- **Editing**: `morph_edit` (large/scattered) > `edit` (small/exact) > `write` (new)
- **Searching**: `codegraph_search` > `warpgrep_codebase_search` > `grep` > bash grep
- **Web**: `firecrawl_firecrawl_search` > `websearch` > `webfetch`
- **Docs**: `context7_query-docs` > `firecrawl_firecrawl_scrape` > raw search
