# Harness Operations — runtime data, storage, retention

> How the harness consumes disk, where runtime data lives, and the retention policy.
> Companion to `plugins.md` (plugins) and `mcps.md` (MCP servers).

## Runtime data locations

| Location | Size (2026-09-08) | What | Policy |
|---|---|---|---|
| `~/.local/share/opencode/opencode.db` | 8.5G | SQLite: sessions, messages, parts (2369 sessions since 2026-06-10) | No prune now — see below |
| `~/.local/share/opencode/log/` | 43M | Current `opencode.log` only | Old logs trashed 2026-09-08; re-sweep when >100M |
| `~/.local/share/opencode/snapshot/` | 58M | 13 snapshots | Keep (session resume) |
| `~/.local/share/opencode/storage/` | 24M | Plugin storage (21M) | Keep |
| `~/.omo/codegraph/projects/` | 3.1G | OMO codegraph indexes. `School-bdd…/codegraph.db` = 3.0G (93%) | Active use (328 sessions); keep. Revisit if School work ends |
| `~/.codegraph/` | 28K | Codegraph MCP index (global) | Keep |
| `~/.config/opencode/node_modules/` | 626M | 13 packages (pruned from 979M/~330) | REQUIRED — never purge |
| `~/.config/opencode/plugins/` | — | 14 active plugins (see `plugins.md`) | — |

## opencode.db retention policy

- **Decision (2026-09-08): NO prune.** DB is 3 months old (2026-06-10 → 2026-09-08), 0 sessions
  older than 6 months, `freelist_count=0` (no vacuum space to reclaim without deleting rows).
- **Backup-first rule**: any future prune MUST be preceded by `cp opencode.db opencode.db.bak`
  (or restic snapshot). Sessions are context recovery — deleting them is irreversible.
- **Trigger to revisit**: DB > 15G, or sessions older than 6 months exist, or opencode ships a
  native retention/cleanup mechanism (check release notes each update).
- **Prune candidates when triggered** (in order): `/tmp/opencode/*` session parts (76.8M),
  School coursework sessions (703M of parts — coursework ages out), `global` project sessions
  with no directory value. Never prune the current project's sessions.
- **Cost context**: $100.98 total across all sessions; 748M input / 25.8M output tokens.
  Top dirs by parts: `~/.config/opencode` 243.7M, School/Segunda evaluacion 209.8M, wedo 158.4M.

## CodeGraph index policy

- OMO codegraph (`~/.omo/codegraph/projects/`) is per-project; `harness-check` warns when any
  index > 2GiB. The School index (3.0G) is the known trigger — accepted, not a bug.
- If a project's index goes stale (project deleted / work finished): delete the project dir
  under `~/.omo/codegraph/projects/` — it reindexes on demand when the project reopens.

## Update cadence

- opencode binary: official installer (`curl -fsSL https://opencode.ai/install | bash`),
  NOT mise. Current: v1.18.29 (2026-09-08, was 1.18.22).
- After any opencode update: run `scripts/opencode-harness-check.sh` to validate plugins load.
- npm deps: `npm install --legacy-peer-deps` (DCP peer-wants @opentui/core 0.4.x, root pins 0.5.1).
