---
name: system-context
description: "Trigger: system context, system info, hardware, software, configuración del sistema. Carga el contexto completo del equipo (OS, hardware, herramientas, config, preferencias) para que el agente entienda el entorno sin configuración extra."
license: Apache-2.0
metadata:
  author: reeinharrrd
  version: "1.0"
---

## Activation Contract

Use this skill when:
- Session starts and agent needs full system awareness
- User asks "what system am I on?", "what tools do I have?", "qué tengo instalado?"
- Need runtimes, paths, aliases, or user preferences
- Any task requiring knowledge of the local environment

Do NOT use for one-off version checks — run the command directly instead.

## Hard Rules

- Skill is self-contained: scripts live in `scripts/`, output cached in `CONTEXT.md` (gitignored)
- Always refresh data via `scripts/scan.sh` before reading cache if >1 hour old
- Output language: Spanish for chat, English for code/docs (matches user preferences)
- Never suggest installing tools already listed in context
- Never ask if tools are available — if context loaded, you know
- Password `270922` only for sudo when explicitly needed (PAM fprintd disabled)

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

- ❌ NO sugerir instalar `eza`, `batcat`, `rg`, `fd`, `zoxide`, `delta`, `fzf`, `btop`, `lazygit`, `lazydocker`, `mise`, `atuin`, `starship`, `zellij`, `yazi`, `navi`, `procs`, `git-cliff`, `gitleaks`, `sops`, `age`, `jj`, `chezmoi`, `ollama`, `docker`, `gh`, `trivy`, `semgrep`
- ❌ NO preguntar "¿está instalado X?" — leer `software/current.json`
- ❌ NO asumir nombres estándar — en Ubuntu `bat` = `batcat`, `fd` = `fdfind`
- ❌ NO pedir sudo por defecto — solo cuando la operación lo requiera

## References

- `scripts/scan.sh` — escaneo de hardware, software y proyectos
- `scripts/render.sh` — generación de CONTEXT.md desde JSON
- `CONTEXT.md` — cache legible (generado, no versionar)