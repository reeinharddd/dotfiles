# PERSONAL.md — Memoria Personal Central (Capa Superior)

> **Jerarquía de memoria**: este archivo es la capa EXTERNA/GLOBAL (identidad y preferencias de la persona).
> - **Global/personal** (este archivo + engram `scope=personal`): quién soy, cómo hablo, cómo trabajo, herramientas, equipo, recursos. Aplica a TODOS los proyectos/scopes.
> - **Proyecto** (engram `scope=project`): decisiones, bugs, patrones de un proyecto específico.
> - **Scope del momento** (`STATE.md` / task packet): foco de la tarea actual.
>
> Flujo: al iniciar cualquier sesión/proyecto, el core lee este archivo para cerrar el scope con el contexto correcto
> (estilo de comunicación, herramientas preferidas, constraints), y usa engram para memoria específica.

---

## 1. Identidad

- **Nombre/handle**: reeinharrrd
- **Rol**: Full-stack dev + sysadmin + automatización
- **Stack**: Python, TypeScript, Go, Rust, shell, Docker
- **Hardware/OS**: ThinkPad T14 Gen 3, AMD Ryzen 7 PRO 6850U, Ubuntu 26.04, Wayland (Hyprland)
- **Terminal**: kitty / ghostty | **Shell**: zsh / Starship | **Editor**: Helix / Neovim (LazyVim)
- **Idiomas**: chat/comandos en **español (mx informal)**; código/docs en **inglés**

## 2. Comunicación (cómo hablo)

- **Caveman mode activo** por defecto: frases cortas, sin artículos/relleno/licencias verbales.
- Respuestas TL;DR primero: 1 frase de resumen, luego detalle.
- **Español informal MX** para conversación; **inglés** para código y documentación.
- NO emojis (tolerancia cero).
- Tablas solo cuando 3+ filas; bullets compactos.
- Sin preámbulo / halagos / "status updates".

## 3. Cómo trabajo (preferencias de flujo)

- **Keyboard-first**: sin mouse, todo via atajos.
- **Background everything**: subagentes paralelos para tareas independientes.
- **TUI over GUI** cuando sea posible.
- **Plan antes de build** para tareas >3 archivos.
- **NO usar loops de IA** (ralph-loop, ulw-loop) — desarrollo directo.
- **Guardar decisiones** con engram tras cada bugfix/decisión/hallazgo.
- Preferir ediciones pequeñas y enfocadas sobre refactors grandes; arreglar bugs mínimo, sin refactorizar al mismo tiempo.

## 4. Herramientas y software del equipo

**Dev tools** (gestionadas con **mise**, no apt/cargo/pipx para dev tools):

| Área | Herramientas |
|---|---|
| Edición | Helix, Neovim (LazyVim) |
| Terminal | kitty, ghostty, zsh + Starship |
| Archivos | yazi, broot |
| Búsqueda | fzf, tv, rg, fd |
| Git | lazygit, jj, gh |
| Sistema | btop, procs |
| Tareas | taskwarrior, timewarrior, jrnl |
| Backup | restic |
| AI | opencode (TUI) — NO plugin IDE |
| Dotfiles | stow (32 paquetes), repo `~/projects/personal/dotfiles/` |

(→ Inventario completo de tools/apps/proyectos: `INVENTORY.md` en este directorio)

**Nota dev tools real (mise)**: node 24.19, python 3.14, go 1.27, gh, lazygit, jj, fd, ripgrep, fzf, eza, bat, delta, starship, supabase, just, direnv, yt-dlp, pueue, etc. Setup completo en INVENTORY.md §2-5.

## 5. Constraints (reglas fijas)

1. **No sudo** sin contraseña explícita (270922 via `echo "270922" | sudo -S`)
2. **No commits** sin petición del usuario
3. **No type suppression** (`as any`, `@ts-ignore`, `@ts-expect-error`) — nunca
4. **No `rm -rf`** — usar `mv <path> /tmp/opencode-trash/`
5. **Mise para herramientas nuevas**
6. **No instalar** avante.nvim/codecompanion.nvim en nvim (fragmentan contexto)
7. **Verificar antes de afirmar** (nada de suponer sobre código no leído)

## 6. Proveedores y modelos AI (estado 2026-09-11 — SOLO FREE, auditado en vivo)

Providers en `opencode.jsonc` (enabled): `opencode-zen`, `tokenrouter`, `mistral`, `google`, `nvidia`, `openrouter` — 86 modelos verificados.
- Orquestadores (build/smart/plan/reviewers/metis/momus): `opencode-zen/nemotron-3-ultra-free` (fallbacks: mimo-v2.5-free, gemini-3.8-flash, deepseek-v4-pro, mistral-medium-latest)
- Deep reasoning (oracle): fallbacks deepseek-v4-pro → antigravity-claude-sonnet-4-6 → gemini-3.8-flash → mimo
- Fast tier (fast/sisyphus-junior): primary `nemotron-3.5-lightning-free` (fallbacks: big-pickle, gemini-3.5-flash-lite, ministral-8b, gemini-2.5-flash-lite)
- Vision: primary `mimo-v2.5-free` (pixtral MUERTO desde Sep 2026; fallbacks: gemini-3.8-flash, antigravity-gemini-3.8-flash, mistral-medium-latest, er-2-preview)
- Docs/librarian: primary `google/gemini-3.8-flash`
- Model global: `google/gemini-3.8-flash` | Small: `opencode-zen/nemotron-3-ultra-free`
- Free verificados en vivo: zen 7 (+deepseek-v4-flash-free), nvidia 10 (deepseek-v4-pro SWE-V 80.6%, kimi-k3, nemotron ultra/super/lightning, laguna-xs SWE-V 70.9%, gemma-4-31b, muse-glimmer SWE-V 76%), mistral 27 chat-vivos (medium-3.5 SWE-V 77.6% el mejor; caps reales 256k), openrouter 17 :free (+dots-3-note 512k/460k, inkling 1M agentic-only, nex-n2.5-pro, nano-omni), tokenrouter 1 (glm-5.3-free; nano-omni:free fake), google 24 (gemini-3.8-flash TB 90.8%, er-2-preview, gemma-4, antigravity-*)
- Muertos (eliminados de config): pixtral-12b, gpt-oss-120b, glm-5.2:free, mistral-large/devstral/zai-glm/mistral-code-agent/small-4-0, er-1.6; NVIDIA kimi-k2.6/nemotron-nano-3 = 404 not-for-account; OR gemma-4 :free = 429 upstream (usar Google directo)
- Cascadas runtime: `plugins/model-routing-guard.js` v11 = fuente de verdad (sobrescribe opencode.jsonc + oh-my-openagent.json; mantener los 3 sincronizados)
- NO usar: opencode-go (pago), minimax, groq, cerebras, anthropic, github-copilot, fireworks, deepinfra, huggingface, ollama-cloud, together, siliconflow, novita, anyapi — eliminados de config/env por decisión (2026-09-06)
- Keys: `opencode.env` (9: MISTRAL, OPENCODE_ZEN, GITHUB, GOOGLE, MORPH, NVIDIA, MORPH_COMPACT, OPENROUTER, TOKENROUTER)

## 7. Proyectos activos

- `Uspace` — Next.js + Supabase + Vitest
- `maestro` — agent harness en Go
- `ideas` — flujo seeds→research→prototypes→specs→graduated (actual: modernizacion-plantas-ia)
- `dotfiles` — config stow (origen de este archivo + opencode.jsonc)
- Otros: snapmcp, job-search, landing, wedo, ppk (ORBE/SO.FI)

## 8. GitHub (usuario `reeinharddd`) — 59 starred

- ⭐ 19 — **JoshRob297/opencode-antigravity-auth**: Google Antigravity OAuth plugin for OpenCode (Revived & Extended) - Unlocks Gemi
- ⭐ 3,212 — **ashemag/human-atlas**: Open-source 3D anatomy explorer: 2,234 selectable BodyParts3D meshes, system lay
- ⭐ 58,589 — **tt-a1i/archify**: Agent skill for beautiful, verifiable architecture, workflow, sequence, data-flo
- ⭐ 184 — **collidingScopes/liquid-logo**: A free, open-source tool for creating animated logos with a liquid metal aesthet
- ⭐ 2,426 — **ruucm/shadergradient**: Create beautiful moving gradients on Framer, Figma and React
- ⭐ 82,067 — **Egonex-AI/Understand-Anything**: Graphs that teach > graphs that impress. Turn any code into an interactive knowl
- ⭐ 59,902 — **penpot/penpot**: Penpot: The open-source design platform for Product teams that need scalable col
- ⭐ 28,448 — **Nutlope/hallmark**: Anti-AI-slop design skill for Claude Code, Cursor, and Codex.
- ⭐ 5,955 — **Dicklesworthstone/destructive_command_guard**: The Destructive Command Guard (dcg) is for blocking dangerous git and shell comm
- ⭐ 71,297 — **career-ops-hq/career-ops**: Open-source AI job search: scan job portals, evaluate listings into a structured
> Lista completa: `starred-repos.tsv` en este directorio.

## 9. Recursos / investigaciones

- `~/Procesamiento_de_Datos.md` (210 líneas)
- `~/Introduccion_Analisis_Datos_resumen.md` (43 líneas)
- `~/MASTER-INDEX.md` (68 líneas)
- `~/propuesta-utt-modernizacion.md` (311 líneas)
- `~/CONFIG-CHANGES.md` (226 líneas)
- `~/models_complete_analysis.md` (201 líneas)
- `~/models_final_analysis.md` (250 líneas)
- `~/MCP-INVENTORY.md` (71 líneas)
- `~/AGENTS.md` (98 líneas)
- `~/free-llm-api-aggregators-2026.md` (94 líneas)
- **Brave bookmarks**: 12 carpetas organizadas (AI/ML, Job Search, Design/UI, etc.)
- **Brave history**: 0 entradas (patrones: WeDo, opencode, Google Docs, GitHub)
- **Chrome history**: 0 entradas
- `INVENTORY.md` — inventario completo del sistema (tools, apps, proyectos) — fuente de verdad de bajo-frecuencia

> ⚠️ Bookmarks exactos de Google / software compartido de equipo: pendientes de aportación del usuario.

## Autocrecimiento (cómo se actualiza)

- Al terminar una sesión con un dato personal nuevo (una herramienta que me gustó, una preferencia, un bookmark revelante), registrar aquí vía engram `scope=personal` o edición directa.
- Este archivo es **versionable** (dotfiles/stow) — los cambios se persiguen en `~/projects/personal/dotfiles/`.
- Es la fuente de verdad ANTES de cualquier scope de proyecto: cada proyecto lee este contexto global para cerrar su propio scope con las herramientas/artifacts correctos.