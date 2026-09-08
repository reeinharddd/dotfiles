# CONFIG-CHANGES — Audit Log

> All modifications to OpenCode global config

## 2026-08-28 — Tiering + DCP + Plugins (core duro)

### Model routing (tiering)
- Orquestadores (build/smart/oracle/plan/code-reviewer/security-reviewer/metis/momus/tdd-guide/qa-enforcer/subagent-orchestrator/consult/plan-critic) → `opencode-go/deepseek-v4-pro`
- Workers (fast/explore/scout/general/sisyphus-junior/docs-lookup/librarian/senior-researcher) → `opencode-zen/nemotron-3-ultra-free` (free)
- Categorías omo: fast/unspecified-low/quick → `hy3-free`; ultrabrain/deep/unspecified-high → `deepseek-v4-pro`; writing/business-logic → free
- `model-routing-guard.js` CASCADE alineado al tiering (es el enforcer real del ruteo)

### groq ELIMINADO
- Provider block, fallbacks y registry limpiados (0 referencias). API key existe pero límites inviables.

### Activaciones
- DCP: `dynamic_context_pruning.enabled=true` + hooks pre_compaction_save/auto_protect_wrap/auto_extract=true
- `codegraph.enabled=true`
- Plugins cargados: `./plugins/opencode-dcp/dist/index.js`, `./plugins/caveman/plugin.js`, `./plugins/superpowers.js`

### Pendiente (roadmap)
- Sandbox bash, Metronous (observabilidad), eval harness, STATE.md, team_mode, benchmark de calibración.

### Fase 2 (2026-08-28)

- **Metronous instalado** (v0.42.1): binario en `~/.local/bin`, daemon systemd user activo (`metronous.service`), plugin `plugins/metronous.ts` + MCP `metronous` en opencode.jsonc. Benchmarks semanales (lun 02:00) + TUI.
- **team_mode activo** (`enabled:true`, max_parallel 4) + `circuitBreaker.enabled:true` (corta loops de fan-out).
- **Sandbox**: `scripts/sandbox-run` (docker primario / bwrap fallback; red default-deny; rootfs read-only; cap-drop ALL; workspace = cwd).
- **Eval harness**: `scripts/eval-harness/` (run-eval.sh + calibrate.sh + 3 tareas con verifiers funcionales: fib, fixbug, readme).
- **STATE.md**: skill `state-tracking` (Current/Decisions/Log) + hook session.idle auto-log en hooks.yaml.
- Docs MASTER-INDEX/MCP-INVENTORY alineados al estado actual.

### Limpieza de estado (2026-08-28)

- `dcp.jsonc`: removidos bloques `extract` y `protect` (keys desconocidas en schema de DCP v3.1.14 — causaban el warning), removidas referencias groq y modelos inexistentes en `modelMaxLimits`/`modelMinLimits`; agregado `hy3-free`. 0 unknown keys vs schema.
- `~/.omo/omo.jsonc`: alineado al tiering actual (workers en free, sin groq). Strict valid.
- Archivos heredados con groq movidos a `.backups-20260828/legacy/`.

### Cierre de puntos finales (2026-08-28)

- **Calibración ejecutada**: free 2/3, deepseek-v4-pro 3/3 → el tiering queda validado con datos (orquestador strong).
- **vibeguard activo**: plugin `opencode-vibeguard@0.1.0` + config global `enabled:true` (dedupe del key duplicado). Redacta secretos antes de cada llamada LLM.
- **playwright**: navegación web habilitada (se quita `--allowed-hosts`); se mantiene headless/isolated/sin service workers.
- **justfile**: fusionados los targets faltantes (`update-env`, alias `pq-add`) al justfile de productividad existente; eliminado el `Justfile` duplicado que causaba colisión. Todos los targets de AGENTS.md operativos (66 total).

### Ataque a errores identificados (2026-08-28)

- **Morph 429 (compact)**: `MORPH_COMPACT=false` en opencode.env — el plugin `@morphllm/opencode-morph-plugin` registra el hook compact solo si esa var no es `"false"`; el fallback nativo ya funcionaba. Se desactiva el compact API de Morph (morph_edit sigue activo).
- **Nvidia 502 overload (277× en log)**: provider `nvidia` eliminado por completo (bloque provider + enabled_providers + 21 fallbacks en agents + guard.js). Fallbacks nvidia → `google/gemini-3.7-flash`. 0 referencias nvidia, 0 groq. enabled_providers = [opencode-zen, mistral, google, opencode-go].
- **prettier 'failed' (~800×)**: ruido transitorio por edición; OMO NO tiene formatters propios (0 matches prettier/biome/ruff/gofmt en bundle) → el formatter global prettier es el único y se mantiene.
- **Hooks muertos OMO eliminados**: `hooks` (pre_compaction_save/auto_protect_wrap/auto_extract) quitados de oh-my-openagent.json — el bundle OMO no los implementa (0 matches). La funcionalidad extract/protect la cubre el plugin DCP real (dcp.jsonc).
- **STATE.md wedo creado**: `.opencode/STATE.md` (skill state-tracking) — el hook session.idle auto-log de hooks.yaml ahora sí tiene dónde escribir.
- **Verificado**: opencode.jsonc/oh-my-openagent.json/vibeguard.config.json/harness-registry.jsonc/dcp.jsonc = VALID JSON; guard.js `node --check` OK; 23 agents; 0 refs nvidia/groq.

## 2026-07-24 — Comprehensive Overhaul

### Phase 1: Provider Audit
- Tested Together AI → 401 (invalid key) — REMOVED
- Tested MiniMax → 401 (invalid key) — REMOVED
- Tested Ollama Cloud → 404 (dead endpoint) — REMOVED
- OpenRouter → requires $10 deposit (declined) — NOT CONFIGURED
- **Result: 0 new providers added**

### Phase 2: MCP Ecosystem
- **Added 6 new MCPs** (all on-demand, project-specific):
  - `playwright` — browser automation (Top 3 MCP globally)
  - `postgres` — database introspection
  - `sentry` — error monitoring
  - `filesystem` — multi-repo access
  - `memory` — lightweight RAG
  - `brave-search` — web search fallback
- Moved `qdrant` from core → on-demand
- Kept 5 core MCPs: context7, engram, firecrawl, codebase-memory, sequential-thinking
- **Total: 19 MCPs (5 core + 14 on-demand)**

### Phase 3: Security
- dcg v0.6.7 confirmed installed at ~/.local/bin/dcg (was already installed)
- Created bodega skill for dcg on-demand use
- hooks.yaml created with destructive-command safety blocks

### Phase 4: Hooks & Automation
- Installed `opencode-yaml-hooks@2026.3.29` plugin
- Created core hooks.yaml: safety blocks + idle auto-save
- Created external hooks reference at ~/tools/opencode-hooks/hooks.yaml

### Phase 5: Agent & Category Cleanup
- **Agents: restored all 13** (smart, build, fast, oracle, plan, code-reviewer, security-reviewer, explore, scout, docs-lookup, tdd-guide, qa-enforcer, subagent-orchestrator)
- **Categories merged: 11 → 6** (fast, deep, ultrabrain, vision, writing, business-logic)
- **Fixed OMO fallbacks**: replaced mistral-medium-latest → magistral-medium-latest (model was removed)

### Phase 6: Provider & Plugin Optimization
- Reduced Mistral models: 17 → 4 (large, codestral, magistral, ministral)
- Removed plugins from core: opencode-scheduler, opencode-worktree, opencode-websearch-cited
- Commented dead provider keys in .env.providers + opencode.env
- Cleaned 4 dead keys: Together, MiniMax, OllamaCloud, OpenRouter

### DCP Optimization
- Enabled `extract` (auto-distill outputs >3000 chars)
- Enabled `protect` (auto-wrap high-value outputs)
- Increased nudge frequency: 8 → 6 (more aggressive compression)
- Added all model limits for free tier models

### Documentation Created
- MASTER-INDEX.md — comprehensive reference of everything
- MCP-INVENTORY.md — complete MCP ecosystem reference
- CONFIG-CHANGES.md — this file

## 2026-07-24 — System Prompts & Always-On Instructions

### Instructions Directory Created
- Created `instructions/` directory with 4 always-loaded instruction files:
  - `01-initialization.md` — Session init protocol (mem_context, detect project, pre-task gate, tool ordering)
  - `02-hard-rules.md` — Non-negotiable rules (communication, code, security, thinking protocol)
  - `03-quality-gates.md` — Mandatory pre-completion checks (LSP, build, tests, memory, end-of-session)
  - `04-mcp-tools.md` — Tool selection guide (code understanding, editing, web/docs, memory by intent)
- All 5 instructions files registered in `opencode.jsonc.instructions` array

### opencode.jsonc Enhanced
- `instructions`: now 5 files (4 local .md + morph-tools from node_modules)
- `compaction`: configured smart mode (minContextRatio 0.3, preserveMessages 5, preserveTools 6)
- `pre_context`: "The core-constitution skill (Karpathy 12 rules) is already loaded..."
- `post_context`: "Remember: TL;DR first. No emojis. Verify before stating..."

### AGENTS.md Hierarchy Fixed
- Core `~/.config/opencode/AGENTS.md`: stale counts fixed (6→19 MCPs, 25→21 skills, 10→8 plugins)
- User `~/AGENTS.md`: added Init Protocol, Rules Hierarchy section, updated MCP ecosystem (14 on-demand)

### Complete Load Order Established
1. instructions/*.md (5 always-loaded files)
2. core-constitution skill (12 Karpathy rules)
3. ~/AGENTS.md (init protocol, constraints, workflows)
4. ~/.config/opencode/AGENTS.md (BASE PROTOCOL, architecture)
5. 21 core skills
6. Per-project AGENTS.md/CLAUDE.md

### 2026-09-07 — Core Sync & Architecture Closure
- Sync vivo→stow completo: opencode.jsonc, oh-my-openagent.json, tui.json, harness-registry.jsonc, PERSONAL.md, INVENTORY.md, SISTEMA_DOC.md, TOOLS-STRUCTURE.md, HARNESS-OPERATIONS.md, mise.toml, vibeguard.config.json, lsp-install-decisions.json, starred-repos.tsv, system-inventory.py, package.json, package-lock.json, instructions/ (6), capabilities/ (8), skills/state-tracking, 11 commands, plugins (manifests bodega, bodega-index.js, metronous.ts, opencode-power-pack.js, regenerate-manifests.py, superpowers.js, opencode-rtk.js, caveman/, dcg/)
- stow --adopt -R exit=0: 25+ symlinks relativos
- 82 dead symlinks commands/ removidos (~/tools/ECC y ~/tools/caveman ya no existen) → /tmp/opencode-trash/dead-symlinks-commands/
- skills/caveman nesting roto fixeado (stow tenía el bueno)
- .env.providers ELIMINADO (4 keys muertas: GOOGLE_AI, GOOGLE_GEMINI, CEREBRAS, FIREWORKS) + línea removida de opencode-backup.sh
- Residuos a trash: opencode-kit.db*, bun.lock, .backups-20260828/, hook/, agent/, oh-my-openagent.json.bak, plugins-disabled/, stale-baks
- Docs actualizados: AGENTS.md (24 skills, 6 providers, ~1900 bodega), PERSONAL.md §6 (+tokenrouter, 9 keys), MASTER-INDEX.md, SISTEMA_DOC.md, INVENTORY.md
- Arquitectura central cerrada: CORE (siempre-cargado, pequeño, fijo) + ON-DEMAND (registro abierto e ilimitado: bodega 1274 skills / 316 commands / 314 agents + 14 project MCPs + starred repos + fuentes internet)
