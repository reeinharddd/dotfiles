# Automations & Core Mechanisms

> When to use each (not the exhaustive how). The Core Generator + Coordination Layer are the
> first core→project automations; loops/background/scheduler/worktree/DCP/codegraph are the
> execution tooling the core coordinates through.

## Core Generator (Enforcement Flow)
First automation that runs at session/project start. Audits the project against the PCC
(see `project-context-contract.md`) and provisions missing context from real project signals.
- **Trigger**: opencode opens a project dir, or first user message in a new project.
- **Steps**: (1) detect stack/tech → (2) run the read-only project audit → (3) recover memory
  (`engram`) → (4) provision via proposal-first `project-bootstrap` / `discover-capabilities` →
  (5) merge global↔project without overwriting local rules.
- **Result**: complete context (global core + project) before any work begins.
- **Tools**: `project-bootstrap` (writes `.opencode/PROJECT_CONTEXT.md`), `discover-capabilities`
  (finds unregistered skills/MCPs/binaries), `project-auto-detect` (structured detection).
- **Safety**: `opencode-capability-doctor` validates global tools and secrets without starting
  MCP servers; `opencode-project-audit` reports project gaps and writes only an explicit proposal.

## Coordination Layer
The layer the core adds during execution so the project doesn't lose execution to info overload:
- Follows project rules/methodologies.
- Injects **strong thinking** (reasoning discipline, `verification-before-completion`).
- Injects **capabilities** (on-demand skills/MCPs via the On-Demand Principle).
- Supplied by the core, not the project.

## Loops (oh-my-openagent)
- `ralph-loop` — self-referential development loop until the task is done.
- `ulw-loop` (ultrawork) — ultrawork loop until completion with ultrawork mode.
- Use for long / repetitive implementation work that benefits from autonomous iteration.

## Background Agents (`opencode-background-agents`)
- Persistent delegation that survives outside the session; results saved to disk.
- Use for research, long builds, fire-and-forget parallel work. Recover with `delegation_read`.

## Scheduler (`opencode-scheduler`)
- Recurring jobs via systemd (Linux) / launchd (macOS).
- Commands: `schedule_job`, `list_jobs`, `run_job`, `delete_job`, `get_job`, `update_job`.

## Worktree (`opencode-worktree`)
- Branch isolation for parallel features. TUI to manage git worktrees.

## DCP — Dynamic Context Pruning
- `auto-extract` — distills large tool outputs (>3000 chars) to preserve findings, cut tokens.
- `auto-protect-wrap` — wraps high-value outputs (`codegraph_*`, `task`, `skill`, `firecrawl_*`,
  `context7_*`, `engram_*`, any >5000 chars) in `<protect>` so compression keeps them.

## Codegraph (knowledge graph)
- Pre-computed code intelligence in `.codegraph/` (symbols, edges, callers, blast radius).
- Tools: `codegraph_explore` (primary — call FIRST), `codegraph_node` (read file/symbol),
  `codegraph_search`, `codegraph_callers`.
- Index lags writes ~1s; re-init with `npx codegraph init` if a project lacks it.

## Media Pipeline (verified 2026-08-24)
- No local models (user constraint). Transcription = Mistral Voxtral API (`voxtral-mini-latest`).
- Flow: `yt-dlp` (mise) → `ffmpeg` audio extract → curl `api.mistral.ai/v1/audio/transcriptions`.
  Skill: `transcribe`.
- watch-cli (~/.watch-cli): `watch <url> [frames]` full pipeline; cached archive at
  `~/.watch-cli/archive`. Backends BYO: GROQ_API_KEY + GOOGLE_AI_KEY in `~/.config/watch-cli/env`
  (no Kyma account). Local patch: FORMAT selector fixed for DASH-only YouTube videos.
  Skill: `watch-video`. Requires deno (mise) as yt-dlp JS runtime.

## Hermes (asistente personal 24/7)
- v0.20.5 at ~/.hermes. Provider `zen` → OpenCode Zen gateway (model `x-preview-f-free`),
  key via OPENCODE_ZEN_API_KEY. Headless: `hermes -z "..."`. Command: `/hermes`.
- Cron system functional (`hermes cron list/create`). Telegram/Discord gateway pending
  BotFather token from user.

## Rules
- Automations are triggered by need, not loaded eagerly.
- Long tasks → loops or background agents; recurring → scheduler; parallel features → worktree.
- Always verify (build/test/lint) after an automation completes.
