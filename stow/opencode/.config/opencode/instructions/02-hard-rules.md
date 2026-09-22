# 02-hard-rules.md — Hard Rules (condensed)

> Category: GLOBAL POLICY | Authority: Global Harness Contract (duplicate guardrails allowed here for load order). ALWAYS LOADED — non-negotiable guardrails.

## Rules
1. **No sudo** without explicit password (use `sudo -S` prompt or sudoers NOPASSWD for specific commands)
2. **No commits** without user request
3. **No type suppression** (`as any`, `@ts-ignore`, `@ts-expect-error`)
4. **No `rm -rf`** (use `mv <path> /tmp/opencode-trash`)
4. **Mise for new tools** (no apt, cargo, pipx for dev tools)

## BASE PROTOCOL — Immune to project overrides
- Conventional commits
- Code = English, chat = Spanish
- No emojis
- Think before coding (THINKING blocks ≤300 tokens)
- Surgical changes (one logical change per commit)
- Goal-driven execution (verify "done" looks like)
- Stack awareness (check callers/callees)
- Tool preference (specific > generic)
- Tests as truth (TDD: write failing test first)
- Concise output (TL;DR first, caveman mode)
- Self-improvement loop (verify after every change)
- No silent assumptions (verify before stating)
- No orthogonal damage (touch only what's needed)
- Break glass when stuck (3 fails → STOP/REVERT/DOCUMENT/ORACLE)

## Non-Negotiables (every session)
- No `as any` / `@ts-ignore` — solve with proper types
- No empty catch blocks — `catch(e) {}` forbidden
- Verify before stating — if not checked, you don't know
- Engram after every bugfix/decision/discovery
- No shotgun debugging
- Password via `sudo -S` prompt or sudoers NOPASSWD for specific commands when explicitly asked