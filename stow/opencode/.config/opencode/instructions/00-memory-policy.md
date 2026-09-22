# 00-memory-policy.md — Engram sole authority (condensed)

> Category: MEMORY | Authority: Global Harness Contract §Memory. ALWAYS LOADED — applies EVERY session, project, agent.

## Single authority

| Store | Owns | Never |
|-------|------|-------|
| **Engram** (`mem_save` / `mem_search` / …) | Durable decisions, bugs, discoveries, patterns, preferences, session summaries | Project files, STATE history |
| **STATE.md** (`.opencode/`) | Current work task only (6 sections, replace) | History, decisions log, knowledge base |
| **PROJECT_CONTEXT.md** | Stable project knowledge | Last error, last commit, logs |
| **PERSONAL.md** | Consolidated personal prefs (mirrored from Engram `personal` scope) | Project decisions |

No second memory system. No growing STATE. No dumping durable facts only into chat.

## Rule: Save to Engram IMMEDIATELY after any non-trivial action

**Triggers (save immediately after):**
- Bugfix / decision / discovery / config change / pattern / preference / task completion
- Session end / compaction / user preference expressed

**Scope decision:**
- `personal` = applies to ALL projects (preferences, style, tools)
- `project` (default) = specific to ONE project (bugs, decisions, config)

## Format (ALWAYS this schema)

```
**What**: [concise action]
**Why**: [reason / problem]
**Where**: [files/paths]
**Learned**: [gotchas, edges, decisions — omit if none]
```

## Before Starting (pre-task gate)
1. `mem_context` — recent session memory
2. `mem_current_project` — detect active project
3. `mem_search query="<keywords>"` — find similar past work

## Session Lifecycle (MANDATORY)
- **Start**: `mem_context` → `mem_current_project` → read AGENTS.md/PROJECT_CONTEXT.md
- **After compaction**: `mem_session_summary` → `mem_context`
- **End**: `mem_session_summary` (Goal/Instructions/Discoveries/Accomplished/Next/Files)

## Conflicts
If `mem_save` returns `judgment_required`: resolve with `mem_judge` (silent if related/compatible/scoped; ask user if supersedes/conflicts_with on architecture/policy/decision or confidence <0.7).

## Autogrowth
- Personal prefs → `personal` scope → consolidated in PERSONAL.md
- Preference changes → update existing observation (topic_key) not duplicate
