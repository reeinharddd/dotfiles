---
name: system-context
description: "ON-DEMAND only — full machine context (OS, hardware, tools, config). Triggers: 'what do I have installed?', 'how is my Linux configured?', 'what version of X do I have?', 'why is Docker failing?', 'qué tengo instalado?'. Does NOT run at session start merely because OpenCode booted."
license: Apache-2.0
metadata:
  author: reeinharrrd
  version: "1.1"
---

## Activation Contract

**On-demand only.** Explicit triggers:

- User asks "what system am I on?", "what tools do I have?", "qué tengo instalado?", "cómo está configurado mi Linux?", "qué versión de X tengo?"
- Task fails in a way that needs environment facts (e.g. "por qué falla Docker?", PATH/toolchain issues)
- Need runtimes, paths, aliases, or machine-wide preferences not derivable from one command

Do NOT use when:
- Session merely started (no system question) — skip
- One-off version check — run the command directly
- Project stack questions → `project-auto-detect`
- Project rules → project AGENTS.md / PROJECT_CONTEXT.md

## Hard Rules

- Skill is self-contained: scripts live in `scripts/`, output cached in `CONTEXT.md` (gitignored)
- Always refresh data via `scripts/scan.sh` before reading cache if >1 hour old
- Output language: Spanish for chat, English for code/docs (matches user preferences)
- Never suggest installing tools already listed in context
- Never ask if tools are available — if context loaded, you know
- Password via `sudo -S` prompt or sudoers NOPASSWD for specific commands (PAM fprintd disabled)

## Data Sources

| Source | Purpose | Refresh |
|--------|---------|---------|
| `scripts/scan.sh` | Genera `hardware/current.json`, `software/current.json`, `projects/registry.json` | On demand |
| `scripts/render.sh` | Genera `CONTEXT.md` legible desde los JSON | On demand |
| `CONTEXT.md` | Cache legible para lectura rápida | Auto-refresh si >1h |

## Execution Steps

### 1. Refresh data (if needed)
```bash
# Desde el directorio del skill
./scripts/scan.sh
./scripts/render.sh
```

### 2. Read context
```bash
cat CONTEXT.md
```

### 3. Use specific data
```bash
# Solo hardware
cat hardware/current.json | jq .

# Solo software/herramientas
cat software/current.json | jq .

# Solo proyectos
cat projects/registry.json | jq .
```

## Decision Gates

| Need | Action |
|------|--------|
| Contexto completo legible | `cat CONTEXT.md` |
| Datos estructurados (JSON) | Leer `hardware/`, `software/`, `projects/` |
| Solo runtimes/versiones | `jq -r 'keys[]' software/current.json` |
| Verificar herramienta específica | `jq -r '.toolname' software/current.json` |

## Output Contract

Returns:
- `CONTEXT.md` — markdown completo con todo el contexto del sistema
- `hardware/current.json` — hostname, kernel, OS, CPU, RAM, GPU, disk
- `software/current.json` — todas las herramientas con versiones
- `projects/registry.json` — proyectos detectados bajo `~/projects/`

## Anti-Patterns

- ❌ NO sugerir instalar `eza`, `batcat`, `rg`, `fd`, `zoxide`, `delta`, `fzf`, `btop`, `lazygit`, `lazydocker`, `mise`, `atuin`, `starship`, `herdr`, `yazi`, `navi`, `procs`, `git-cliff`, `gitleaks`, `sops`, `age`, `chezmoi`, `ollama`, `docker`, `gh`, `trivy`, `semgrep`
- ❌ NO preguntar "¿está instalado X?" — leer `software/current.json`
- ❌ NO asumir nombres estándar — en Ubuntu `bat` = `batcat`, `fd` = `fdfind`
- ❌ NO pedir sudo por defecto — solo cuando la operación lo requiera

## References

- `scripts/scan.sh` — escaneo de hardware, software y proyectos
- `scripts/render.sh` — generación de CONTEXT.md desde JSON
- `CONTEXT.md` — cache legible (generado, no versionar)