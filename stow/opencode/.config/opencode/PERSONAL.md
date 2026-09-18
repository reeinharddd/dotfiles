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
- **Terminal**: ghostty | **Shell**: zsh / Starship | **Editor**: Neovim (LazyVim)
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
| Edición | Neovim (LazyVim) |
| Terminal | ghostty, zsh + Starship |
| Archivos | yazi |
| Búsqueda | fzf, rg, fd |
| Git | lazygit, gh |
| Sistema | btop, procs |
| Tareas | taskwarrior, timewarrior, jrnl |
| Backup | restic |
| AI | opencode (TUI) — NO plugin IDE |
| Dotfiles | stow (32 paquetes), repo `~/projects/personal/dotfiles/` |

(→ Inventario completo de tools/apps/proyectos: `INVENTORY.md` en este directorio)

**Nota dev tools real (mise)**: node 24.19, python 3.14, go 1.27, gh, lazygit, fd, ripgrep, fzf, eza, bat, delta, starship, supabase, just, direnv, yt-dlp, pueue, etc. Setup completo en INVENTORY.md §2-5.

## 5. Constraints (reglas fijas)

1. **No sudo** sin contraseña explícita (270922 via `echo "270922" | sudo -S`)
2. **No commits** sin petición del usuario
3. **No type suppression** (`as any`, `@ts-ignore`, `@ts-expect-error`) — nunca
4. **No `rm -rf`** — usar `mv <path> /tmp/opencode-trash/`
5. **Mise para herramientas nuevas**
6. **No instalar** avante.nvim/codecompanion.nvim en nvim (fragmentan contexto)
7. **Verificar antes de afirmar** (nada de suponer sobre código no leído)

## 6. Proveedores y modelos AI (estado 2026-09-18 — SOLO FREE, auditado en vivo)

Providers en `opencode.jsonc` (enabled): `opencode-zen`, `nvidia`, `mistral`, `google`, `openrouter` (tokenrouter en env). Estrategia balanceada multi-proveedor free sin dependencia exclusiva de Antigravity ni Zen.
- Orquestadores interactivos consola (build/smart/plan): `opencode-zen/nemotron-3-ultra-free` (fallbacks: google/gemini-3.8-flash, mistral/mistral-medium-latest, nvidia/deepseek-v4-flash-0731).
- Subagentes y tareas en background (RESILIENCIA TOTAL contra 403 FreeTierError de Zen):
  - `general`, `sisyphus-junior`, `tdd-guide`, `qa-enforcer`, `subagent-orchestrator`: `nvidia/deepseek-ai/deepseek-v4-flash-0731` (fast, API normal, 0 fallos de consola).
  - `oracle`, `consult`: `nvidia/deepseek-ai/deepseek-v4-flash-0731` (fallbacks: antigravity-claude-sonnet-4-6, mistral-medium-latest, gemini-3.8-flash).
  - `metis`, `momus`, `plan-critic`, `code-reviewer`, `security-reviewer`: `mistral/mistral-medium-latest` (razonamiento independiente europeo, SWE-V 77.6%, sin bloqueo de background).
  - `explore`, `scout`, `fast`: `google/gemini-3.5-flash-lite` (ligero, contexto masivo, alta cuota).
  - `librarian`, `docs-lookup`, `senior-researcher`: `google/gemini-3.8-flash` (referencia externa y Context7).
  - `vision`, `multimodal-looker`: `google/gemini-3.8-flash` (fallbacks: antigravity-gemini-3.8-flash, dots-3-note-preview).
- Categorías de tareas en `oh-my-openagent.json`: 100% no-zen para ejecución background (`quick` -> nvidia, `ultrabrain` -> mistral, `deep` -> gemini-3.8, `writing` -> mistral, `visual-engineering` -> gemini-3.8).
- Model global: `google/gemini-3.8-flash` | Small: `opencode-zen/nemotron-3-ultra-free`.
- Modelos allowlist auditados live (exit 0): nvidia deepseek-v4-flash-0731; mistral medium/ministral-8b; google gemini 3.8/3.7/3.5-lite/2.5-lite/2.5-flash, antigravity sonnet-4-6/gemini-3.8; openrouter dots-3-note (512k); zen nemotron-3-ultra/lightning/mimo.
- Descripciones y fallbacks completos: 23/23 agentes en `opencode.jsonc` y 23/23 en `oh-my-openagent.json` con `description` y cadenas escalonadas hasta red de emergencia (Dots-3-Note 512k / Gemini 2.5 Lite).
- Cascadas runtime: `plugins/model-routing-guard.js` v18 = fuente de verdad (sobrescribe opencode.jsonc + oh-my-openagent.json; sincronizados al 100%).
- NO usar: opencode-go (pago), minimax, groq, cerebras, anthropic, github-copilot, fireworks, deepinfra, huggingface, ollama-cloud, together, siliconflow, novita, anyapi — eliminados de config/env por decisión (2026-09-06).
- Keys: `opencode.env` (9: MISTRAL, OPENCODE_ZEN, GITHUB, GOOGLE, MORPH, NVIDIA, MORPH_COMPACT, OPENROUTER, TOKENROUTER).

## 7. Proyectos activos

- `Uspace` — Next.js + Supabase + Vitest
- `maestro` — agent harness en Go
- `ideas` — flujo seeds→research→prototypes→specs→graduated (actual: modernizacion-plantas-ia)
- `dotfiles` — config stow (origen de este archivo + opencode.jsonc)
- Otros: snapmcp, job-search, landing, wedo, ppk (ORBE/SO.FI)

## 8. GitHub (usuario `reeinharddd`) — 0 starred

> Lista completa: `starred-repos.tsv` en este directorio.

## 9. Recursos / investigaciones

- `~/Procesamiento_de_Datos.md` (210 líneas)
- `~/Introduccion_Analisis_Datos_resumen.md` (43 líneas)
- `~/MASTER-INDEX.md` (68 líneas)
- `~/propuesta-utt-modernizacion.md` (311 líneas)
- `~/CONFIG-CHANGES.md` (237 líneas)
- `~/models_complete_analysis.md` (201 líneas)
- `~/models_final_analysis.md` (250 líneas)
- `~/MCP-INVENTORY.md` (71 líneas)
- `~/AGENTS.md` (98 líneas)
- `~/free-llm-api-aggregators-2026.md` (94 líneas)
- **Brave bookmarks**: 12 carpetas organizadas (AI/ML, Job Search, Design/UI, etc.)
- **Brave history**: 100 entradas (patrones: WeDo, opencode, Google Docs, GitHub)
- **Chrome history**: 0 entradas
- `INVENTORY.md` — inventario completo del sistema (tools, apps, proyectos) — fuente de verdad de bajo-frecuencia

> ⚠️ Bookmarks exactos de Google / software compartido de equipo: pendientes de aportación del usuario.

## Autocrecimiento (cómo se actualiza)

- Al terminar una sesión con un dato personal nuevo (una herramienta que me gustó, una preferencia, un bookmark revelante), registrar aquí vía engram `scope=personal` o edición directa.
- Este archivo es **versionable** (dotfiles/stow) — los cambios se persiguen en `~/projects/personal/dotfiles/`.
- Es la fuente de verdad ANTES de cualquier scope de proyecto: cada proyecto lee este contexto global para cerrar su propio scope con las herramientas/artifacts correctos.