# DOCUMENTACIÓN COMPLETA DEL SISTEMA — reeinharrrd (Sept 2026)

---

## 1. ARQUITECTURA GENERAL

```
┌─────────────────────────────────────────────────────────────────┐
│                        CORE (inmutable)                          │
│  ~/.config/opencode/                                            │
│  ├── opencode.jsonc      ← CONFIG PRINCIPAL (proveedores,       │
│  │                          agentes, MCPs, plugins, skills)    │
│  ├── tui.json            ← Config TUI (plugins UI, tema, keys) │
│  ├── oh-my-openagent.json← UI overlay (NO proveedores/agentes) │
│  ├── hooks.yaml          ← Safety blocks + idle checkpoint     │
│  ├── PERSONAL.md         ← Memoria personal global (capa sup.)  │
│  ├── SISTEMA_DOC.md      ← ESTE ARCHIVO                         │
│  ├── INVENTORY.md        ← Inventario completo del PC           │
│  ├── INSTRUCTIONS/       ← Instrucciones core (siempre cargadas)│
│  │   ├── 00-memory-policy.md  ← Memoria obligatoria (engram)   │
│  │   ├── 01-initialization.md ← Protocolo inicio sesión        │
│  │   ├── 02-hard-rules.md     ← Reglas inmutables              │
│  │   ├── 03-quality-gates.md  ← Gates de calidad               │
│  │   └── 04-mcp-tools.md      ← Guía herramientas MCP          │
│  ├── skills/             ← 24 core skills (auto-cargadas)      │
│  ├── plugins/            ← Plugins instalados (node_modules)   │
│  ├── commands/           ← 33 slash commands (vivos)           │
│  ├── scripts/            ← Scripts de verificación/auditoría   │
│  ├── opencode.env        ← API Keys (VibeGuard placeholders)   │
│  └── (opencode-kit.db removido 2026-09-07 — legacy)            │
└─────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     PROJECT OVERLAY (mutable)                    │
│  ~/project/.opencode/                                           │
│  ├── AGENTS.md / CLAUDE.md / PROJECT_CONTEXT.md  ← Contexto    │
│  ├── STATE.md          ← Estado actual (fase, blockers, next)  │
│  └── hooks.yaml        ← Hooks específicos del proyecto        │
└─────────────────────────────────────────────────────────────────┘
```

**Regla de oro**: Core = inmutable, solo se modifica desde `~/.config/opencode/`. Proyectos tienen overlay mutable que NUNCA afecta global.

---

## 2. PROVEEDORES Y MODELOS (12 habilitados)

| Provider | npm | BaseURL | Modelos clave | Uso |
|---|---|---|---|---|
| **opencode-zen** | nativo | `opencode.ai/zen/v1` | nemotron-3-ultra-free, mimo-v2.5-free, ling-3.0-flash-fin-free, big-pickle, muse-spark-1.2-contributor-free, nemotron-3.5-lightning-free | Workers gratuitos (fast, explore, scout, general) |
| **mistral** | nativo | `api.mistral.ai/v1` | mistral-large-latest, codestral-2508, mistral-medium-latest (vision), ministral-8b-latest | Vision, coding, agentes multimodales |
| **google** | `@ai-sdk/google` | nativo | gemini-3.7-flash, gemini-3.5-flash-lite, gemini-2.5-pro, gemma-4-31b-it | Fallback, embeddings, modelos nuevos |
| **nvidia** | `@ai-sdk/openai-compatible` | `integrate.api.nvidia.com/v1` | deepseek-v4-pro-0813, nemotron-3-ultra, nemotron-3.5-lightning, gpt-oss-120b | Coding fuerte, razonamiento |
| **openrouter** | `@ai-sdk/openai-compatible` | `openrouter.ai/api/v1` | openrouter/free, nemotron-3.5-lightning:free, nemotron-3-ultra:free, glm-5.2:free, minimax-m3:free | Modelos gratuitos variados (:free = perpetuo, 20 req/min) |

**Configuración de modelos por agente** (en `opencode.jsonc`):
- **Orquestadores** (build, smart, oracle, plan, code-reviewer, security-reviewer, tdd-guide, qa-enforcer, subagent-orchestrator, metis, momus, consult, plan-critic): `opencode-zen/nemotron-3-ultra-free` + fallbacks mimo-v2.5-free/gemini-3.7-flash/mistral-medium-latest
- **Workers** (fast, explore, scout, docs-lookup, general, sisyphus-junior): `opencode-zen/nemotron-3-ultra-free` + fallbacks zen/google/go/mistral
- **Vision** (vision, multimodal-looker): `mistral/pixtral-12b-latest` + fallbacks mistral-medium-latest/gemini-3.7-flash
- **Research** (librarian, senior-researcher, docs-lookup): `opencode-zen/nemotron-3-ultra-free` + fallbacks zen/google/go/mistral

---

## 3. AGENTES (24 configurados)

| Agente | Modelo | Rol | Cuándo usar |
|---|---|---|---|
| **build** | deepseek-v4-pro | Construcción/compilar | Compilar, build, CI/CD |
| **smart** | deepseek-v4-pro | Agente por defecto | Trabajo general, razonamiento |
| **oracle** | deepseek-v4-pro | Arquitectura/debugging duro | Decisiones técnicas, debugging complejo |
| **plan** | deepseek-v4-pro | Planificación | Crear planes, descomponer tareas |
| **fast** | nemotron-3-ultra-free | Respuestas rápidas | Tareas simples, lookup |
| **explore** | nemotron-3-ultra-free | Exploración código | Leer/entender código base |
| **code-reviewer** | deepseek-v4-pro | Code review | Revisar PRs, detectar bugs |
| **security-reviewer** | deepseek-v4-pro | Security audit | Auditar auth, pagos, IO |
| **tdd-guide** | deepseek-v4-pro | TDD | Red-Green-Refactor |
| **explore** | nemotron-3-ultra-free | Code exploration | "Cómo funciona X" |
| **docs-lookup** | nemotron-3-ultra-free | Documentación | Buscar docs librerías (context7) |
| **librarian** | nemotron-3-ultra-free | Investigación | Research profundo |
| **senior-researcher** | nemotron-3-ultra-free | Research avanzado | Deep research |
| **qa-enforcer** | deepseek-v4-pro | Quality gates | Verificar tests, lint, build |
| **subagent-orchestrator** | deepseek-v4-pro | Orquestar subagentes | Delegar tareas paralelas |
| **metis** | deepseek-v4-pro | Plan consultant | Consultar planes |
| **momus** | deepseek-v4-pro | Plan critic | Criticar planes |
| **plan-critic** | deepseek-v4-pro | Plan critic | Equivalente metis/momus |
| **sisyphus-junior** | nemotron-3-ultra-free | Dev loop | Auto-dev hasta done |
| **consult** | deepseek-v4-pro | Architecture consultant | Read-only advisor |
| **vision** | mistral-medium-latest | Vision | Análisis imágenes |
| **multimodal-looker** | mistral-medium-latest | Multimodal | Imagen + texto |
| **general** | nemotron-3-ultra-free | Todo propósito | Fallback universal |

---

## 4. SKILLS CORE (24 - siempre cargadas)

| Skill | Para qué | Comando |
|---|---|---|
| **auto-extract** | Comprime outputs grandes (DCP) | Auto |
| **auto-protect-wrap** | Protege outputs valiosos (DCP) | Auto |
| **brainstorming** | Explora intención/requisitos ANTES de codear | `/brainstorming` |
| **capability-scanner** | Descubre skills/MCPs/binarios no registrados | `/capability-scanner` |
| **caveman** | Comprime tokens (-65% verbose) | Auto |
| **code-architect** | Diseña arquitectura feature | `/code-architect` |
| **code-explorer** | Analiza feature existente | `/code-explorer` |
| **code-reviewer** | Review bugs, security, quality | `/code-reviewer` |
| **core-constitution** | 12 reglas Karpathy + valores | Auto (inmutable) |
| **dispatching-parallel-agents** | Paraleliza tareas independientes | `/dispatching-parallel-agents` |
| **executing-plans** | Ejecuta plan escrito con checkpoints | `/executing-plans` |
| **feature-dev** | Workflow 7 fases feature completo | `/feature-dev` |
| **handoff** | Comprime sesión para continuar | `/handoff` |
| **pre-compaction-save** | Auto-save engram antes compactación | Auto |
| **project-auto-detect** | Detecta stack/framework/proyecto | Auto (inicio sesión) |
| **skill-router** | Router lazy para skills dominio | `/skill-router` |
| **state-tracking** | Mantiene STATE.md cross-session | Auto |
| **system-context** | Carga contexto HW/SW/preferencias | `/system-context` |
| **systematic-debugging** | Debug hypothesis-driven | `/systematic-debugging` |
| **test-driven-development** | TDD antes de implementar | `/test-driven-development` |
| **transcribe** | Audio/video → texto (Voxtral) | `/transcribe` |
| **verification-before-completion** | Evidencia antes de "done" | `/verification-before-completion` |
| **watch-video** | "Ver" video (frames + transcript) | `/watch-video` |
| **writing-plans** | Escribe plan antes de codear | `/writing-plans` |

**Regla**: Skills se invocan con `/skill-name` o via `skill(name="...")`.

---

## 5. MCPs HABILITADOS (12)

| MCP | Tipo | Para qué |
|---|---|---|
| **context7** | remote | Docs librerías actualizadas (context7.com) |
| **engram** | local | Memoria persistente cross-session |
| **firecrawl** | remote | Web search, scrape, crawl (firecrawl.dev) |
| **codebase-memory** | local | Code graph (codebase-memory-mcp) |
| **sequential-thinking** | local | Reasoning estructurado |
| **metronous** | local | Telemetría, benchmarks, calibración |
| **playwright** | local | Browser automation (headless/isolated) |
| **drive** | remote | Google Drive (via mcp-remote OAuth) |
| **docs** | remote | Google Docs (via mcp-remote OAuth) |
| **sheets** | remote | Google Sheets (via mcp-remote OAuth) |
| **snapmcp** | local | UI/visual projects (disabled) |
| **code-review-graph** | local | Review-heavy projects (disabled) |

**MCPs disabled** (on-demand): snapmcp, code-review-graph, page-agent, openpencil, qdrant, github, agentmemory, postgres, sentry, filesystem, memory, brave-search

---

## 6. PLUGINS TUI (7 en tui.json)

| Plugin | Para qué |
|---|---|
| **opencode-subagent-statusline** | Statusline subagentes |
| **oh-my-openagent@latest** | UI enhancements (latest) |
| **oh-my-openagent@4.19.4** | UI enhancements (pinned) |
| **opencode-workspaces** | Workspace management via git worktrees |
| **opencode-vibeguard** | Sustituye `__VG_CREDENTIAL_xxx__` → keys reales (CRÍTICO) |
| **opencode-yaml-hooks** | Hooks yaml (safety + idle) |
| **opencode-dcp** | Dynamic Context Pruning (comprime contexto) |

---

## 7. HERRAMIENTAS CLI (mise / cargo / local)

### mise (39 tools) — Runtime manager principal
```bash
mise ls                    # Listar todo
mise use node@lts          # Instalar versión
mise use -g tool@latest    # Instalar global
mise activate zsh          # En .zshrc (PATH dinámico)
```

**Runtimes**: node 24.19 LTS, python 3.14, go 1.27, bun 1.4
**CLI tools**: gh, glab, lazygit, jj, fd, ripgrep, fzf, bat, delta, eza, starship, jq, yq, just, direnv, atuin, restic, yt-dlp, supabase, codex, shellcheck, shfmt, actionlint, marksman, miller, tv, xh, navi, tldr, sd, navi, hyperfine, tokei, hexyl, gum, choose, doggo, gping, grex, ouch, watchexec, bandwhich, tokei, zoxide, procs, difft, sd, navi, hyperfine

### cargo (3 tools esenciales)
```bash
cargo install ast-grep      # AST code search (sg)
cargo install zoxide        # cd inteligente
cargo install btop          # System monitor (top moderno)
```

### ~/.local/bin (47 tools)
| Tool | Uso |
|---|---|
| `opencode` | AI coding agent principal |
| `engram` | Memoria persistente: `engram mem_save`, `engram mem_search` |
| `codex` | OpenAI Codex CLI |
| `hermes` | AI assistant: `hermes -z "pregunta"` |
| `metronous` | Telemetría/benchmarks |
| `yazi` | File manager TUI |
| `uv / uvx` | Python pkg manager |
| `wp` | WordPress CLI |
| `playwright` | Browser automation |
| `semgrep` | SAST: `semgrep --config auto .` |
| `gitleaks` | Secrets: `gitleaks detect` |
| `git-cliff` | Changelog: `git-cliff -o CHANGELOG.md` |
| `maestro` | Go agent harness (proyecto) |
| `new-project` | Scaffolding proyectos |
| `transcribe` | Audio/video → texto |
| `bw` | Bitwarden CLI |
| `cliphist` | Clipboard history |
| `gdu` | Disk analyzer TUI |
| `onefetch` | Git repo info |
| `carapace` | Shell completions |

---

## 8. FLUJOS DE TRABAJO COMUNES

### Iniciar sesión nueva
```bash
# Terminal (ghostty) abre → zsh carga → mise activate → opencode listo
opencode                    # Abre TUI
opencode run "mensaje"      # Headless con mensaje
opencode run -c "continuar" # Continuar última sesión
```

### Desarrollo feature (workflow completo)
```bash
# 1. Brainstorming (requerido ANTES de codear)
/brainstorming "quiero agregar auth JWT"

# 2. Writing plans
/writing-plans

# 3. Feature-dev (7 fases)
/feature-dev

# 4. Verification
/verification-before-completion
```

### Debugging
```bash
/systematic-debugging "error X en Y"
/code-explorer "cómo funciona auth"
/code-reviewer (review cambios)
```

### Memoria (engram)
```bash
engram mem_save --title "Decisión X" --content "**What**: ... **Why**: ... **Where**: ... **Learned**: ..."
engram mem_search "palabras clave"
engram mem_context          # Contexto sesiones previas
engram mem_session_summary  # Al final de sesión
```

### Research
```bash
/watch-video "https://youtube.com/..."  # Ver video
/transcribe archivo.mp4                 # Transcribir
/capability-scanner "buscar skill X"    # Descubrir capabilities
```

### Code graph
```bash
# Via codebase-memory-mcp (MCP)
codegraph_explore "AuthService login"
codegraph_search "update settings"
codegraph_callers "UserService.create"
```

---

## 8. CONFIGURACIONES CLAVE

### ~/.zshrc (puntos clave)
```bash
# PATH
path=(
  "$HOME/.cargo/bin"
  "$HOME/.local/bin"
  "$HOME/.local/share/broot/launcher/bash"
  "$BUN_INSTALL/bin"
  "$GOPATH/bin"
  $path
)

# Runtime managers
eval "$(mise activate zsh)"    # ← CRÍTICO: PATH dinámico mise
source "$HOME/.cargo/env"

# direnv
eval "$(direnv hook zsh)"

# Aliases modernos
alias ls="eza --icons --group-directories-first"
alias cat="bat --paging=never"
alias grep="rg"
alias find="fd"
alias cd="z"              # ← zoxide
alias du="dust"
alias top="btop"
alias help="tldr"
alias ps="procs"
```

### ~/.config/ghostty/config (puntos clave)
```ini
theme = Catppuccin Mocha
font-family = JetBrainsMono Nerd Font Mono
font-size = 12
background-opacity = 0.95
background-blur = true
mouse-hide-while-typing = true
window-inherit-working-directory = true
split-inherit-working-directory = true
```

### opencode.jsonc (estructura)
```json
{
  "model": "mistral/mistral-large-latest",
  "small_model": "opencode-zen/nemotron-3-ultra-free",
  "default_agent": "smart",
  "provider": { ... 6 providers ... },
  "enabled_providers": ["opencode-zen", "tokenrouter", "mistral", "google", "nvidia", "openrouter"],
  "agent": { ... 23 agents ... },
  "mcp": { ... 9 core mcp ... },
  "plugin": [ ... 14 plugins ... ],
  "instructions": [ ... PERSONAL.md + 6 core instructions + morph ... ]
}
```

### API Keys (opencode.env - VibeGuard placeholders)
```bash
# Las keys reales están en opencode.env (permisos 600)
# VibeGuard sustituye __VG_CREDENTIAL_xxx__ → key real en runtime
CEREBRAS_API_KEY=...
GROQ_API_KEY=...
MISTRAL_API_KEY=...
OPENCODE_ZEN_API_KEY=...
OPENROUTER_API_KEY=...
NVIDIA_API_KEY=...
GOOGLE_API_KEY=...
MISTRAL_API_KEY=...
OPENCODE_GO_API_KEY=...
MORPH_API_KEY=...
```

---

## 9. COMANDOS ÚTILES

| Comando | Qué hace |
|---|---|
| `just ship "msg"` | git add + commit + push |
| `just sync` | Re-stow dotfiles |
| `just status` | System health |
| `just daily` / `just end-day` | Rutinas |
| `engram mem_save --title "X" --content "..."` | Guardar memoria |
| `engram mem_search "query"` | Buscar memoria |
| `opencode providers list` | Ver credenciales |
| `opencode models zen` | Listar modelos zen |
| `opencode debug config` | Ver config resuelta |
| `mise ls` | Tools instalados |
| `mise use tool@latest` | Instalar tool |
| `cargo install tool` | Instalar cargo tool |

---

## 10. TROUBLESHOOTING

| Problema | Solución |
|---|---|
| "command not found herdr" | Eliminado de .zshrc (línea 168) |
| Providers no cargan keys | Verificar opencode-vibeguard en tui.json + plugins/ |
| OOM kill Chrome | Cerrar tabs, usar Brave |
| OPENTCODE no inicia | `opencode debug config` → ver config |
| Permisos denegados | Revisar hooks.yaml (safety blocks) |
| npm install falla | `npm install --legacy-peer-deps` |
| ZSH lento | `atuin` sync, limpiar history |

---

## 11. UBICACIONES IMPORTANTES

| Archivo/Directorio | Qué contiene |
|---|---|
| `~/.config/opencode/` | Core config |
| `~/projects/personal/dotfiles/` | Source of truth (stow) |
| `~/.local/share/opencode/auth.json` | Credenciales providers |
| `~/.config/opencode/opencode.env` | API Keys (VibeGuard) |
| `~/.config/opencode/hooks.yaml` | Safety + idle hooks |
| `~/.config/opencode/oh-my-openagent.json` | UI overlay only |
| `~/.config/opencode/tui.json` | TUI plugins |
| `~/.config/mise/config.toml` | Tools runtime |
| `~/.zshrc` | Shell config |
| `~/.config/ghostty/config` | Terminal config |
| `~/projects/personal/` | Proyectos activos |
| `~/projects/cold/` | Proyectos archivados |
| `~/tools/` | Repos tools (bodega) |
| `/var/tmp/opencode-trash/` | Trash temporal (limpiar manual) |

---

**Última actualización**: 2026-09-05
**Versión opencode**: 1.18.22
**Disco**: 170GB / 275GB (39%)

