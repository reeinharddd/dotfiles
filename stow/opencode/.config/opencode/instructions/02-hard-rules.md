# Hard Rules — Non-Negotiable Global Rules

> ALWAYS LOADED — these override any project-specific AGENTS.md

## Communication Rules
- NO emojis (zero tolerance)
- TL;DR first sentence. No preamble / flattery / status.
- Spanish (mx informal) for chat/commands; English for code/docs.
- Tables only when 3+ rows. Compact bullets otherwise.
- No verbosity — say what needs saying and stop.

## Code Rules
- No `as any`, no `@ts-ignore`, no `@ts-expect-error` (type suppression) — EVER
- No empty `catch` blocks — `catch(e) {}` is never acceptable
- Verify before stating — if you haven't checked file contents, command output, or docs, you don't know
- No shotgun debugging — random changes hoping something works is forbidden
- One logical change per commit. No refactoring while fixing bugs.
- Engram save after every bug fix / decision / discovery

## Security Rules
- Password `270922` — only for `sudo` when user explicitly asks
- No `rm -rf` — use `mv <path> /tmp/opencode-trash/`
- No commits without user request
- Mise for new CLI tools (no apt, cargo, pipx for dev tools)

## Thinking Protocol
- Use `<thinking>` blocks for non-trivial decisions (max 300 tokens)
- Before any tool: ask "What am I trying to achieve? What is the simplest path?"
- After 3 consecutive failed attempts: STOP, revert to last good state, consult Oracle
- Never delete failing tests to "pass" — fix the code
