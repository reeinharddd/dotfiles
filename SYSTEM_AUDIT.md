# System Audit — reeinharrrd @ ThinkPad-T14-Gen-3
> Fecha: 2026-07-03 | OS: Ubuntu 26.04 LTS (Resolute Raccoon)
> Kernel: 7.0.0-22-generic | Shell: zsh

---

## 1. TERMINAL EMULATORS

| App | Source | Status | Accion |
|-----|--------|--------|--------|
| **Ghostty** 1.3.0-dev | apt (oficial .deb) | ✅ **PRIMARY** | Keep |
| **Kitty** 0.45.0 | apt | ❌ Duplicate | **REMOVE** — 4 paquetes (kitty, kitty-doc, kitty-shell-integration, kitty-terminfo) |
| **Ptyxis** | apt (default GNOME) | ❌ Unused | **REMOVE** |
| **gnome-terminal** | apt (default) | ❌ Unused | **REMOVE** |

**Duplicados:** 4 terminales instalados, usas 1 (Ghostty). Kitty consume 4 paquetes.

---

## 2. MULTIPLEXERS

| App | Source | Status | Accion |
|-----|--------|--------|--------|
| **Herdr** 0.7.1 | mise | ✅ **PRIMARY** | Keep |
| ~~zellij~~ | (removido) | ✅ Gone | OK |
| ~~tmux~~ | (nunca instalado) | ✅ N/A | OK |

**Overlap:** Ninguno. Herdr es el unico.

---

## 3. SHELLS

| App | Version | Status |
|-----|---------|--------|
| **zsh** 5.9 | apt | ✅ **PRIMARY** |
| bash | sistema | ⚠️ Default de sistema |
| dash | sistema | ⚠️ /bin/sh symlink |

**OMZ:** ~/.oh-my-zsh/ **18MB** — ya NO se carga en el zshrc (grep count = 0). Solo queda en disco. **Se puede eliminar.**

**Plugins actuales en zshrc:** solo los packages de apt (zsh-autosuggestions, zsh-syntax-highlighting) + compilations de gh/docker/carapace/fzf. Correcto.

---

## 4. PACKAGE MANAGERS — 6 formas de instalar cosas

| Manager | Uso | Overlap? |
|---------|-----|----------|
| **apt** | Sistema base | ❌ Muchos paquetes que ahora maneja mise |
| **mise** | Tools modernas | ✅ **UNIVERSAL** — runtimes + CLI |
| **snap** | Firefox, Bitwarden, Brave, VLC, Trivy | ⚠️ Necesario para algunas GUI |
| **cargo** | Rust tools | ⚠️ ~2.6GB! Muchos ya en mise o .local/bin |
| **npm** | LSP servers + AI tools | ⚠️ ~20 paquetes globales |
| **pip** | Python tools | ⚠️ fastmcp, mcp, uv |

### APT duplicados con mise (9 paquetes que sobran):

| Paquete apt | Version apt | Version mise | Diferencia |
|-------------|-------------|-------------|------------|
| bat | vieja | 0.26.1 (latest) | mise gana |
| duf | vieja | 0.9.1 (latest) | mise gana |
| eza | vieja | 0.23.4 (latest) | mise gana |
| fd-find | vieja | 10.4.2 (latest) | mise gana |
| fzf | 0.67.0 | 0.73.1 (latest) | mise gana |
| gh | 2.46.0 | 2.96.0 (latest) | mise gana |
| jq | 1.8.1 | 1.8.2 (latest) | mise gana |
| ripgrep | vieja | 15.1.0 (latest) | mise gana |
| starship | (nunca apt) | 1.26.0 (latest) | ✅ |

**Recomendacion:** `apt purge` estos 8 paquetes. Las shims de mise ya estan activas y toman prioridad.

---

## 5. NODE / JS ECOSYSTEM — CAOS TOTAL

| Gestion | Proposito | Size |
|---------|-----------|------|
| **nvm** ~/.nvm | 3 versiones node (v20, v22, v24) | **660MB** |
| **mise node** | 1 version (v24 LTS) | ~50MB |
| **bun** ~/.bun | JS runtime + bundler | **2.8GB** |
| **npm global** | 20+ paquetes | variable |

**Problemas:**
- **nvm + mise node = DUPLICADO.** Mise ya maneja node. nvm tiene 3 versiones inactivas que solo ocupan espacio.
- **bun + mise node = PARCIALMENTE DUPLICADO.** Bun puede reemplazar node pero no es 100% compatible. Si no usas bun activamente, son 2.8GB de bloat.
- **npm global packages:** Varios LSP servers que podrian ir con su package manager nativo (pyright -> pip, bash-language-server -> apt, etc.)

**Recomendacion:** 
- `rm -rf ~/.nvm` — nvm completo. Mise maneja node.
- `rm -rf ~/.bun` si no usas bun activamente. O al menos evaluar si realmente lo necesitas.
- Revisar npm globales: los LSP servers (@angular/cli? realmente necesario?)

---

## 6. CARGO (RUST) — 2.6GB

| Package | Proposito | Ya en mise/.local? |
|---------|-----------|-------------------|
| bat | cat++ | ✅ mise (0.26.1) |
| delta | git diff | ✅ mise (0.19.2) |
| du-dust | du++ | ✅ mise (dust 1.2.4) |
| eza | ls++ | ✅ mise (0.23.4) |
| fd | find++ | ✅ mise (10.4.2) |
| fzf | fuzzy find | ✅ mise (0.73.1) |
| gh | GitHub CLI | ✅ mise (2.96.0) |
| jq | JSON | ✅ mise (1.8.2) |
| just | task runner | ✅ mise (1.55.1) |
| ripgrep | grep++ | ✅ mise (15.1.0) |
| starship | prompt | ✅ mise (1.26.0) |
| **zoxide** | cd++ | ❌ Solo cargo |
| **procs** | ps++ | ❌ Solo cargo + .local |
| **navi** | cheatsheets | ❌ Solo cargo + .local |
| **btop** | system monitor | ❌ Solo cargo |
| **sd** | sed++ | ❌ Solo cargo |
| **choose** | cut++ | ❌ Solo cargo |
| **doggo** | DNS lookup | ❌ Solo cargo |
| **bandwhich** | network | ❌ Solo cargo |
| **grex** | regex gen | ❌ Solo cargo |
| **difftastic** | diff | ❌ Solo cargo (pero delta ya hace diff) |
| **ouch** | compress | ❌ Solo cargo |
| **ast-grep** | code search | ❌ Solo cargo |

**Duplicados masivos:** ~15 de los 24 paquetes cargo estan TAMBIEN en mise. Cuando activas mise, los bins de mise ganan. Los de cargo jamas se ejecutan. Son **~1.5GB de binarios muertos**.

**Recomendacion:** 
- `cargo uninstall` los que ya tiene mise (no se ejecutan jamas).
- Conservar en cargo solo los que NO estan en mise: zoxide, procs, navi, btop, sd, choose, doggo, bandwhich, grex, difftastic, ouch, ast-grep.
- Evaluar si realmente necesitas los 12. Algunos (choose, grex, ouch, bandwhich, doggo) probablemente nunca los usas.

---

## 7. ~/.local/bin — 30 archivos, algunos redundantes

| Archivo | Problema |
|---------|----------|
| **starship** | ✅ Y tambien en mise (duplicado, pero mismo binary version) |
| **opencode** | Duplicado con ~/.opencode/bin/opencode |
| **navi, procs** | Duplicados con ~/.cargo/bin/ |
| **mise** | Binario standalone pero mise shims maneja |
| **btm** (bottom) | **DUPLICADO con btop!** Ambos son system monitors TUI |
| **yazi + yazi-x86_64...** | El mismo binario con dos nombres |
| **pysemgrep + semgrep** | Duplicados (pysemgrep es wrapper) |
| **chezmoi** | **REDUNDANTE con stow.** Ambas herramientas de dotfiles management |

**Recomendacion:**
- `btm` vs `btop`: elegir UNO (btop via cargo es mas completo).
- `yazi-x86_64-unknown-linux-musl`: eliminar (sobra la copia con hash).
- `pysemgrep`: eliminar, usar `semgrep` directamente.
- `chezmoi`: eliminar si usas stow. Decidir cual mantener.
- Limpiar los README.md/LICENSE que no son binarios.

---

## 8. DOTFILES MANAGEMENT — STOW VS CHEZMOI

| Herramienta | Status | Proposito |
|-------------|--------|-----------|
| **stow** | ⚠️ **NO INSTALADO!** | Mencionado en bootstrap.sh pero jamas se instalo |
| **chezmoi** | ✅ Instalado en .local/bin | Alternativa a stow |

**Problema CRITICO:** El bootstrap.sh usa stow (`stow -R -d stow -t "$HOME" "$pkg"`) pero **stow no esta instalado** en el sistema (`apt install stow` nunca se ejecuto). Los configs en `stow/` existen como archivos, no como symlinks.

**Recomendacion:** 
- Stow no esta instalado. O lo instalas (`apt install stow`) y actualizas bootstrap.sh, O usas chezmoi (que ya tienes) y abandonas stow.
- Si sigues con stow: los configs en stow/ necesitan `stow -R` para crear los symlinks.

---

## 9. SYSTEM MONITORS — 4 HERRAMIENTAS PARA LO MISMO

| Tool | Source | Proposito |
|------|--------|-----------|
| **btop** | cargo (0.1.0) | System monitor TUI |
| **btm** (bottom) | ~/.local/bin | System monitor TUI |
| **htop** | apt | System monitor TUI (legacy) |
| **fastfetch** | apt | Neofetch replacement (info rapida) |
| **powertop** | apt | Power consumption |
| **radeontop** | apt | AMD GPU monitor |
| **procs** | cargo + .local | ps replacement |

**Duplicados:** btop + btm + htop = 3 tools para monitorear el sistema. Ademas procs reemplaza ps (parcialmente solapado con htop).

**Recomendacion:** 
- btop > btm > htop (btop es el mas completo y mantenido). Eliminar btm y htop.
- procs: conservar si usas `ps` frecuentemente.

---

## 10. GIT TOOLS — MUCHAS OPCIONES

| Tool | Source | Proposito |
|------|--------|-----------|
| **git** | apt | ✅ Default |
| **gh** | mise | ✅ GitHub CLI |
| **lazygit** | mise | ✅ TUI git |
| **delta** | mise | ✅ git diff pager |
| **difftastic** | cargo | Structural diff (overlap con delta!) |
| **git-cliff** | .local/bin | Changelog generator |
| **gitleaks** | .local/bin | Git secret scanner |
| **jj** | .local/bin | Jujutsu — git alternative |
| **pre-commit** | .local/bin | Git hooks manager |

**Duplicados:** delta + difftastic = 2 diff tools. Delta ya hace syntax-highlighted diffs. difftastic es estructural (compara ASTs). Si no lo usas, sobra.

**Recomendacion:** 
- jj: solo si realmente lo usas. Es una alternativa completa a git que añade complejidad.
- git-cliff: solo si haces releases.
- gitleaks: util solo si trabajas en equipo con secrets.

---

## 11. AI CODING TOOLS — MUCHOS AGENTS

| Tool | Source |
|------|--------|
| **opencode** | apt + .local |
| **claude** (code) | apt |
| **codex** | directorio ~/.codex |
| **continue** | VS Code extension |
| **gentle-ai** | .local |
| **maestro** | .local |
| **page-agent** | npm global |
| **aoagents/ao** | npm global |
| **agentmemory** | npm global |
| **clawteam** | npm global |
| **ecc-universal** | npm global |
| **opencode-triage** | npm global |

**Problema:** Muchos agents/sdks instalados que probablemente no usas todos. Varios son npm globales que cargan siempre.

**Recomendacion:** Evaluar cuales usas realmente. Los sdks tipo agentmemory, aoagents, clawteam, ecc-universal son librerias, no tools de linea de comandos que necesites en PATH.

---

## 12. LANGUAGE SERVERS (LSP)

| LSP | Source | Alternativa mas limpia |
|-----|--------|----------------------|
| bash-language-server | npm global | ❌ No hay alternativa apt |
| pyright | npm global | pip install pyright |
| typescript-language-server | npm global | ✅ OK via npm |
| yaml-language-server | npm global | ✅ OK via npm |
| dockerfile-language-server | npm global | ✅ OK via npm |
| marksman | npm global | ✅ OK via npm |
| @taplo/cli (TOML) | npm global | ✅ OK via npm |
| vscode-langservers-extracted | npm global | ✅ OK via npm (HTML/CSS/JSON) |

**Overlap:** Todos necesarios para VS Code. No hay duplicados pero podrian moverse a pip donde aplique.

---

## 13. DISK USAGE — BLOAT TOTAL

| Directorio | Size | Contenido |
|------------|------|-----------|
| ~/.bun/ | **2.8 GB** | Bun runtime (redundante con node via mise) |
| ~/.cargo/ | **2.6 GB** | Rust toolchain + 24 packages |
| ~/.nvm/ | **660 MB** | 3 node versions (redundante con mise) |
| ~/.oh-my-zsh/ | **18 MB** | Ya no se usa (OMZ no cargado) |
| ~/.cache/ | variable | Cache de varias herramientas |
| **TOTAL bloat** | **~6 GB** | Solo lo que esta claramente muerto |

**Espacio disponible:** 360GB libres de 468GB. No es critico, pero ~6GB de archivos muertos es desorden.

---

## 14. SERVICIOS Y DAEMONS

| Servicio | Proposito | Necesario? |
|----------|-----------|------------|
| docker.service | Container runtime | ⚠️ Solo si desarrollas con Docker |
| postgresql | DB | ⚠️ Solo si usas DB local |
| containerd | Docker dependency | ⚠️ Solo con Docker |
| cups / cups-browsed | Printing | ❌ Sin impresora? |
| avahi-daemon | mDNS | ❌ Generalmente innecesario |
| bluetooth.service | Bluetooth | ⚠️ Segun uso |
| fprintd | Fingerprint reader | Si tienes lector |
| tlp / powertop | Power management | ✅ Util en laptop |
| cpufrequtils | CPU scaling | ✅ Util en laptop |
| accounts-daemon | GNOME | ⚠️ Solo si usas GNOME |
| geoclue | Location | ❌ Privacy concern |
| whoopsie | Crash reports | ❌ Puede deshabilitarse |
| gdm.service | Display manager | ✅ GNOME requiere |

---

## 15. PROYECTOS — 30+ REPOS

| Carpeta | Cantidad | Estado |
|---------|----------|--------|
| projects/archive/ | ~20 | Archivo historico |
| projects/external/ | 1 | career-ops |
| projects/personal/ | 7 | Activos: dotfiles, job-search, landing, maestro, reeinharddd, snapmcp, wedo |
| projects/ppk/ | 7 | Activos: ORBE, PPK-SOCsAPI, PPK-SOCsWeb, SO.FI, orbe-backend, orbe-frontend, orbe-main |

**Observacion:** ~20 proyectos en archive/ que probablemente nunca revisas. Ocupan espacio pero son codigo, no bloat de sistema.

---

## 16. DOCKER — IMAGES Y CONTAINERS

| Imagen | Size | Status |
|--------|------|--------|
| wordpress:latest | 278MB (1.09GB disk) | ✅ Activo (wp_app) |
| mysql:8.0 | 249MB (1.1GB disk) | ✅ Activo (wp_db) |
| mysql:8.0.33 | 166MB (772MB disk) | ❌ Stale (mysql:8.0 ya cubre) |
| postgres:16-alpine | 117MB (420MB disk) | ✅ Activo (wedo-db) |
| postgres:15-alpine | 116MB (417MB disk) | ❌ Stale (no se usa) |
| floci/floci | 149MB (600MB disk) | ❌ Sin container activo |
| phonestore-app | 160MB (681MB disk) | ❌ Sin container activo |

**Total usado:** ~2.5GB reales, ~5GB en disco (layer overlap). Se pueden limpiar imagenes stale.

---

## 17. CONFIG DIRECTORIES ~/.config/

Abreviado — los relevantes:

| Directorio | Proposito | Status |
|------------|-----------|--------|
| ghostty/ | Terminal ✅ | Activo |
| kitty/ | Terminal legacy | ❌ Puede eliminarse |
| herdr/ | Multiplexer ✅ | Activo |
| zellij/ | Multiplexer legacy | ✅ Ya removido |
| starship/ | Prompt ✅ | Activo |
| atuin/ | Shell history ✅ | Activo |
| mise/ | Tool mgr ✅ | Activo |
| nvm/ | Node (via mise) | ❌ Ya no necesario |
| fish/ | Shell (no usas) | ❌ Puede eliminarse |
| carapace/ | Completions | ⚠️ Ya tienes mise |
| oh-my-zsh/ (en ~/) | Framework | ❌ No cargado, 18MB |

---

## PLAN DE ACCION RECOMENDADO

### Prioridad Alta (Ahorro inmediato ~4GB)

1. **`apt purge` 12 paquetes**: kitty*, ptyxis, gnome-terminal, bat, duf, eza, fd-find, fzf, gh, jq, ripgrep
2. **`rm -rf ~/.nvm`**: 660MB — mise node reemplaza
3. **`rm -rf ~/.oh-my-zsh`**: 18MB — no se carga
4. **`cargo uninstall` duplicados**: bat, delta, du-dust, eza, fd-find, fzf, gh, jq, ripgrep, starship (10 packages que ya tiene mise)
5. **Instalar stow**: `apt install stow` + correr stow para crear symlinks
6. **Limpiar `~/.local/bin`**: eliminar btm, chezmoi, README.md, LICENSE, yazi-x86_64...

### Prioridad Media (~2-3GB)

7. **Evaluar bun**: `rm -rf ~/.bun` si no usas bun (2.8GB)
8. **Limpiar Docker**: `docker image prune` y `docker system prune`
9. **Limpiar `~/.config/kitty/`**: configs legacy
10. **btm vs btop**: elegir uno (btop es mejor)
11. **stow vs chezmoi**: decidir cual usar (stow + bootstrap.sh vs chezmoi)

### Prioridad Baja (Organizacional)

12. **Revisar npm globales**: angular/cli realmente necesario?
13. **Revisar cargo packages**: elegir solo los que usas
14. **Decidir workflow**: ghostty -> herdr -> zsh -> mise tools -> starship
15. **VS Code extensions**: revisar que no haya LSP duplicados
16. **projects/archive/**: considerar mover a backup externo

---

*Fin del reporte. Quieres que ejecute alguna de estas acciones?*
