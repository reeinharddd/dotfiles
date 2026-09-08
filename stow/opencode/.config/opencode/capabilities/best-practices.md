# Best Practices (researched, per type)

> Consolidated guidance for using skills, MCPs, agents, delegation, and verification well.
> Sourced from the installed skills' own SKILL.md docs + verified config behavior.

## Skills
- Load a skill when the task matches its description; don't hand-roll the workflow.
- Creative/feature work → `brainstorming` then `feature-dev` / `writing-plans`.
- Bugs → `systematic-debugging` (≥3 hypotheses, confirm root cause, lock with a failing test).
- Never preload the whole bodega (~1200 skills); search via `capability-scanner` / `skill-router`.
- After building something non-trivial, run `pre-compaction-save` (auto) + `mem_capture_passive`.

## MCPs
- `context7` for library docs (current, sourced) — prefer over web search for APIs.
- `engram` for durable memory: save on every bugfix/decision/discovery/config/pattern/preference.
- `codebase-memory` / `codegraph` for source understanding — call BEFORE reading files.
- `firecrawl` for web search/scrape/crawl; use `firecrawl_search_feedback` to improve quality.
- `qdrant` for long-term semantic RAG, not ephemeral notes.
- On-demand MCPs (`royal-mcp`, `snapmcp`, `code-review-graph`, `page-agent`, `openpencil`) →
  enable per project via dotfiles, never hardcode in project config.

## Agents / Delegation
- 1–3 reads → inline; 4+ → subagent; multi-file feature → delegate with write.
- test / lint / research / web → delegate first (background agents for long work).
- Use typed agents: `explore`/`librarian` for read-only research, `build` for implementation,
  `oracle` for review, `docs-lookup` for docs, `tdd-guide` for TDD.
- Pass prompts in English; keep them self-contained (full task, not "continue").
- Recover background results with `delegation_read`; don't block unnecessarily.

## Verification (evidence before claims)
- Run build/test/lint and confirm exit 0 before claiming done (`verification-before-completion`).
- `lsp_diagnostics` clean is a quality gate; after 3 failures STOP / REVERT / DOCUMENT.
- For web/UIs, do visual QA (`/visual-qa` or Playwright) before declaring done.
- Commit only when asked; inspect `git status`/`diff`/`log` first.

## Context Hygiene
- Use DCP: `auto-extract` for big outputs, `auto-protect-wrap` for valuable ones.
- Keep the central prompt lean — rely on `capabilities/*.md` on demand, not inline lists.
- `directory_tree` must exclude `node_modules`, `.git`, `dist`.

## Safety
- `vibeguard` redacts secrets/PII before the LLM — keep it active.
- No `rm -rf`; move to `/tmp/opencode-trash`. No sudo without explicit password.
- Project must not modify base `opencode.jsonc` or global AGENTS.md BASE PROTOCOL.
