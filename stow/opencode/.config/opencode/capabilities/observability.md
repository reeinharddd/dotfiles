# Observability — eval harness & telemetry path

> Category: SYSTEM DOCUMENTATION (observability reference).
> **Telemetry single path**: one sink only — see Telemetry row in `plugins.md`.

## Eval harness

The eval harness lives at `scripts/eval-harness/`. It reuses the existing framework
without inventing a new evaluation system.

### Structure

```
scripts/eval-harness/
├── run-eval.sh          # Main runner: run all tasks or a specific task
├── calibrate.sh         # Compare two models on the eval dataset
└── tasks/               # Task directories (each with prompt.txt + verify.sh)
    ├── 01-fix-bug-python/
    ├── 02-refactor-config/
    ├── ...              # 20+ coding tasks (01-20, fib, fixbug, readme)
    └── cap-01 through cap-12/   # Harness capability verification tasks
```

### Running the eval

```bash
# Run all tasks
bash scripts/eval-harness/run-eval.sh --all

# Run a specific task
bash scripts/eval-harness/run-eval.sh cap-contract-loading

# Run specific coding task
bash scripts/eval-harness/run-eval.sh 01-fix-bug-python
```

### Task schema

Each task directory contains exactly two files:

| File | Purpose |
|------|---------|
| `prompt.txt` | Human-readable description of what the task verifies |
| `verify.sh` | Executable bash script: exits 0 on pass, non-zero on fail |

`run-eval.sh` iterates `$TASKS_DIR/*/`, checks for `verify.sh`, runs it, and reports
pass/fail. `calibrate.sh` runs the same tasks against two models to inform routing.

### Task categories

| Category | Tasks | What they test |
|----------|-------|----------------|
| **Coding benchmark** | 01-20, fib, fixbug, readme | Code generation quality |
| **Capability verification** | cap-01 through cap-12 | Harness config & policy enforcement |

The 12 capability tasks cover: contract loading, skill routing, model routing free-only,
memory save/search, MCP on-demand, permission deny, telemetry single-path, plugin loading,
hooks lifecycle, config validation, state tracking, and conventional commits.

## Telemetry path

### Single active path (Rank 1)

| Component | Location | What it does |
|-----------|----------|--------------|
| `plugins/opencode-telemetry.js` | `plugins/` dir | Event ledger: boot, tool, delegation, session.idle events |
| `experimental.openTelemetry` | `opencode.jsonc` | Enables the telemetry plugin hooks |
| Output | `~/.local/share/opencode/telemetry/events/YYYY-MM-DD.jsonl` | Structured JSONL event log |

The plugin emits:
- **boot**: plugin load, cwd, agent count
- **tool**: tool name, args (truncated), ok/fail, error
- **delegation**: `delegate`/`task` calls with `run_in_background` flag
- **session_idle**: session ID, turn number

Fail-open: any error is swallowed; telemetry never blocks tool execution.

### Inactive alt paths

| Path | Status | Notes |
|------|--------|-------|
| `@langfuse/opencode-observability-plugin@0.5.0` | Listed in `plugin[]` but **not active** | Would be Rank 2 if enabled; currently a second telemetry source |
| `metronous` MCP | Rank 3, weekly ingest only | Not active for APM |

**Policy**: exactly ONE telemetry path is active. `opencode-telemetry.js` +
`experimental.openTelemetry` is the active path. The `@langfuse` plugin is registered
in `plugin[]` but per `plugins.md` §Telemetry it must be disabled when the preferred
path is on. See `plugins.md` for the full policy.

### Eval results → telemetry

Running `run-eval.sh` does not directly emit telemetry events — the eval harness
verifies config correctness. The eval harness itself is observable through the
telemetry plugin: tool calls during eval execution (bash, python3, grep) are
logged as `tool` events, and `session.idle` events capture turn boundaries.

To correlate eval runs with telemetry:
1. Run `run-eval.sh --all`
2. Check `~/.local/share/opencode/telemetry/events/$(date +%F).jsonl` for the
   tool events emitted during the eval
3. Each `tool` event has `tool`, `ok`, `args`, and optional `error` fields

## Result storage

- Eval pass/fail: printed to stdout by `run-eval.sh`
- Telemetry events: `~/.local/share/opencode/telemetry/events/YYYY-MM-DD.jsonl`
- No persistent eval database — results are ephemeral unless captured externally

## Configuration references

| File | Relevance |
|------|-----------|
| `opencode.jsonc` | `experimental.openTelemetry: true`, `plugin[]`, `permission`, `mcp` |
| `plugins.md` | Telemetry single-path policy (Rank 1/2/3) |
| `harness-registry.jsonc` | MCP policy, pinned tools, routing config |
| `scripts/eval-harness/run-eval.sh` | Task runner implementation |
| `scripts/eval-harness/calibrate.sh` | Model calibration implementation |
