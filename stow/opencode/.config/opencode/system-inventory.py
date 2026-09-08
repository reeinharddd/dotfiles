#!/usr/bin/env python3
"""
system-inventory.py — Inventario profundo y automatizado del sistema
Extrae: Brave/Chrome bookmarks/history, SQLite dbs de IA, proyectos, dotfiles, tools, GitHub starred, notas.
Clasifica relevancia y actualiza: INVENTORY.md, PERSONAL.md, engram (scope=personal).
Uso: python3 system-inventory.py [--full] [--update-engram] [--update-files]
"""

import os, json, sqlite3, subprocess, sys, shutil, hashlib, time, re
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Any, Optional
from collections import defaultdict


# json5 not available, use regex to strip comments from jsonc
def parse_jsonc(text: str) -> dict:
    """Parse JSONC (JSON with comments) by stripping comments carefully."""
    # State machine: track if we're inside a string
    result = []
    i = 0
    in_string = False
    escape_next = False
    while i < len(text):
        c = text[i]
        if not in_string and c == "/" and i + 1 < len(text) and text[i + 1] == "/":
            # Line comment - skip to end of line
            i += 2
            while i < len(text) and text[i] != "\n":
                i += 1
            continue
        elif not in_string and c == "/" and i + 1 < len(text) and text[i + 1] == "*":
            # Block comment - skip to */
            i += 2
            while i + 1 < len(text) and not (text[i] == "*" and text[i + 1] == "/"):
                i += 1
            i += 2  # skip */
            continue
        elif c == '"' and not escape_next:
            in_string = not in_string
        elif c == "\\" and in_string and not escape_next:
            escape_next = True
        else:
            escape_next = False
        result.append(c)
        i += 1

    cleaned = "".join(result)
    # Remove trailing commas
    cleaned = re.sub(r",\s*([}\]])", r"\1", cleaned)
    return json.loads(cleaned)


HOME = Path.home()
CONFIG_DIR = HOME / ".config" / "opencode"
INVENTORY_FILE = CONFIG_DIR / "INVENTORY.md"
PERSONAL_FILE = CONFIG_DIR / "PERSONAL.md"
STARRED_FILE = CONFIG_DIR / "starred-repos.tsv"
ENGram_DB = Path("/home/reeinharrrd/.local/share/engram/engram.db")

# ============================
# EXTRACCIÓN DE FUENTES
# ============================


def extract_brave_data():
    """Extrae bookmarks e historial de Brave (snap)."""
    brave_versions = sorted(Path(HOME / "snap/brave").glob("*"), reverse=True)
    if not brave_versions:
        return {"bookmarks": [], "history": [], "folders": []}

    latest = brave_versions[0]
    bookmarks_file = latest / ".config/BraveSoftware/Brave-Browser/Default/Bookmarks"
    history_file = latest / ".config/BraveSoftware/Brave-Browser/Default/History"

    bookmarks, folders = [], []
    if bookmarks_file.exists():
        try:
            data = json.loads(bookmarks_file.read_text())

            def walk(node, path=""):
                name = node.get("name", "")
                new_path = f"{path}/{name}" if path else name
                if "children" in node:
                    folders.append({"path": new_path, "type": "folder"})
                    for child in node["children"]:
                        walk(child, new_path)
                else:
                    bookmarks.append(
                        {"folder": path, "name": name, "url": node.get("url", "")}
                    )

            for root in ["bookmark_bar", "other", "synced"]:
                walk(data.get("roots", {}).get(root, {}))
        except Exception as e:
            print(f"Error bookmarks Brave: {e}")

    history = []
    if history_file.exists():
        try:
            conn = sqlite3.connect(f"file:{history_file}?mode=ro", uri=True)
            conn.row_factory = sqlite3.Row
            rows = conn.execute("""
                SELECT url, title, visit_count, last_visit_time 
                FROM urls ORDER BY visit_count DESC LIMIT 100
            """).fetchall()
            for r in rows:
                history.append(dict(r))
            conn.close()
        except Exception as e:
            print(f"Error history Brave: {e}")

    return {
        "bookmarks": bookmarks,
        "history": history,
        "folders": folders,
        "source": str(latest),
    }


def extract_chrome_data():
    """Extrae bookmarks e historial de Chrome/Chromium."""
    chrome_dirs = [
        HOME / ".config/google-chrome",
        HOME / ".config/chromium",
        HOME / ".config/brave-browser",
    ]
    result = {"bookmarks": [], "history": [], "profiles": []}

    for base in chrome_dirs:
        if not base.exists():
            continue
        for profile_dir in base.glob("*/"):
            if not profile_dir.is_dir():
                continue
            # Bookmarks
            bm_file = profile_dir / "Bookmarks"
            if bm_file.exists():
                try:
                    data = json.loads(bm_file.read_text())

                    def walk(node, path=""):
                        name = node.get("name", "")
                        new_path = f"{path}/{name}" if path else name
                        if "children" in node:
                            for child in node["children"]:
                                walk(child, new_path)
                        else:
                            result["bookmarks"].append(
                                {
                                    "profile": profile_dir.name,
                                    "folder": path,
                                    "name": name,
                                    "url": node.get("url", ""),
                                }
                            )

                    for root in ["bookmark_bar", "other", "synced"]:
                        walk(data.get("roots", {}).get(root, {}))
                except:
                    pass

            # History
            hist_file = profile_dir / "History"
            if hist_file.exists():
                try:
                    conn = sqlite3.connect(f"file:{hist_file}?mode=ro", uri=True)
                    conn.row_factory = sqlite3.Row
                    rows = conn.execute("""
                        SELECT url, title, visit_count, last_visit_time 
                        FROM urls ORDER BY visit_count DESC LIMIT 50
                    """).fetchall()
                    for r in rows:
                        result["history"].append(
                            {"profile": profile_dir.name, **dict(r)}
                        )
                    conn.close()
                except:
                    pass
            result["profiles"].append(profile_dir.name)
    return result


def extract_github_starred():
    """Extrae starred repos de GitHub via gh CLI."""
    try:
        result = subprocess.run(
            [
                "gh",
                "api",
                "user/starred",
                "--paginate",
                "--jq",
                '.[] | "\\(.stargazers_count)\\t\\(.full_name)\\t\\(.description // "")"',
            ],
            capture_output=True,
            text=True,
            timeout=30,
        )
        if result.returncode == 0:
            lines = result.stdout.strip().split("\n")
            repos = []
            for line in lines:
                if line:
                    parts = line.split("\t", 2)
                    repos.append(
                        {
                            "stars": int(parts[0]),
                            "repo": parts[1],
                            "desc": parts[2] if len(parts) > 2 else "",
                        }
                    )
            return repos
    except Exception as e:
        print(f"Error GitHub starred: {e}")
    return []


def scan_sqlite_dbs():
    """Escanea bases de datos SQLite relevantes de herramientas IA."""
    dbs = {
        "opencode-kit": HOME / ".config/opencode/opencode-kit.db",
        "hermes": HOME / ".hermes/state.db",
        "continue-index": HOME / ".continue/index/index.sqlite",
        "continue-dev": HOME / ".continue/dev_data/devdata.sqlite",
        "codex-threads": HOME / ".codex/thread_history_1.sqlite",
        "codex-goals": HOME / ".codex/goals_1.sqlite",
        "codex-memories": HOME / ".codex/memories_1.sqlite",
        "metronous-bench": HOME / ".metronous/benchmark.db",
        "metronous-track": HOME / ".metronous/tracking.db",
        "agentmemory": HOME / ".agentmemory/preferences.json",
        "gemini-settings": HOME / ".gemini/settings.json",
        "gemini-antigrav": HOME / ".gemini/antigravity-desktop/settings.json",
        "claude-settings": HOME / ".claude/settings.json",
    }

    results = {}
    for name, path in dbs.items():
        if not path.exists():
            continue
        try:
            if path.suffix == ".json":
                results[name] = {"type": "json", "data": json.loads(path.read_text())}
            else:
                conn = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
                conn.row_factory = sqlite3.Row
                tables = [
                    r[0]
                    for r in conn.execute(
                        "SELECT name FROM sqlite_master WHERE type='table'"
                    ).fetchall()
                ]
                data = {"tables": tables, "samples": {}}
                for table in tables[:10]:  # max 10 tables
                    try:
                        rows = conn.execute(f"SELECT * FROM {table} LIMIT 3").fetchall()
                        data["samples"][table] = [dict(r) for r in rows]
                    except:
                        pass
                conn.close()
                results[name] = {"type": "sqlite", "data": data}
        except Exception as e:
            results[name] = {"error": str(e)}
    return results


def scan_projects():
    """Escanea proyectos en ~/projects y ~/tools."""
    projects = {"personal": [], "archive": [], "ppk": [], "external": [], "tools": []}
    for cat in ["personal", "archive", "ppk", "external"]:
        base = HOME / "projects" / cat
        if base.exists():
            for d in base.iterdir():
                if d.is_dir():
                    info = {"name": d.name, "path": str(d)}
                    # Detectar tipo de proyecto
                    if (d / "package.json").exists():
                        info["type"] = "node"
                        pkg = json.loads((d / "package.json").read_text())
                        info["description"] = pkg.get("description", "")
                    elif (d / "go.mod").exists():
                        info["type"] = "go"
                    elif (d / "Cargo.toml").exists():
                        info["type"] = "rust"
                    elif (d / "pyproject.toml").exists() or (
                        d / "requirements.txt"
                    ).exists():
                        info["type"] = "python"
                    elif (d / "compose.yaml").exists() or (
                        d / "docker-compose.yml"
                    ).exists():
                        info["type"] = "docker"
                    elif (d / "README.md").exists():
                        info["type"] = "docs"
                    # AGENTS.md / CLAUDE.md / PROJECT_CONTEXT.md
                    info["markers"] = []
                    for marker in ["AGENTS.md", "CLAUDE.md", "PROJECT_CONTEXT.md"]:
                        if (d / marker).exists():
                            info["markers"].append(marker)
                    projects[cat].append(info)

    # ~/tools
    tools_dir = HOME / "tools"
    if tools_dir.exists():
        for d in tools_dir.iterdir():
            if d.is_dir():
                projects["tools"].append({"name": d.name, "path": str(d)})
    return projects


def scan_dotfiles():
    """Escanea dotfiles y configs clave."""
    dotfiles_path = HOME / "projects/personal/dotfiles"
    configs = {"stow_packages": [], "key_configs": [], "opencode_config": {}}
    if dotfiles_path.exists():
        for d in dotfiles_path.iterdir():
            if d.is_dir() and not d.name.startswith("."):
                configs["stow_packages"].append(d.name)

    # opencode.jsonc
    oc = CONFIG_DIR / "opencode.jsonc"
    if oc.exists():
        try:
            content = oc.read_text()
            data = parse_jsonc(content)
            configs["opencode_config"] = {
                "enabled_providers": data.get("enabled_providers", []),
                "disabled_providers": data.get("disabled_providers", []),
                "model": data.get("model"),
                "small_model": data.get("small_model"),
                "default_agent": data.get("default_agent"),
                "agents_count": len(data.get("agent", {})),
                "providers_count": len(data.get("provider", {})),
            }
        except Exception as e:
            print(f"Error parsing opencode.jsonc: {e}")
            pass

    return configs


def scan_tools():
    """Escanea herramientas instaladas (mise, cargo, npm, pipx, apt, snap)."""
    tools = {
        "mise": [],
        "cargo": [],
        "npm_global": [],
        "pipx": [],
        "apt_count": 0,
        "snap": [],
    }

    # mise
    try:
        out = subprocess.run(["mise", "ls"], capture_output=True, text=True)
        if out.returncode == 0:
            for line in out.stdout.strip().split("\n")[1:]:  # skip header
                parts = line.split()
                if len(parts) >= 2:
                    tools["mise"].append(
                        {
                            "name": parts[0],
                            "version": parts[1],
                            "source": parts[2] if len(parts) > 2 else "",
                        }
                    )
    except:
        pass

    # cargo
    cargo_bin = HOME / ".cargo/bin"
    if cargo_bin.exists():
        tools["cargo"] = [f.name for f in cargo_bin.iterdir() if f.is_file()]

    # npm global
    try:
        out = subprocess.run(
            ["npm", "ls", "-g", "--depth=0"], capture_output=True, text=True
        )
        if out.returncode == 0:
            tools["npm_global"] = out.stdout.strip().split("\n")
    except:
        pass

    # pipx / ~/.local/bin
    local_bin = HOME / ".local/bin"
    if local_bin.exists():
        tools["pipx"] = [f.name for f in local_bin.iterdir() if f.is_file()]

    # apt count
    try:
        out = subprocess.run(["dpkg", "-l"], capture_output=True, text=True)
        if out.returncode == 0:
            tools["apt_count"] = len(
                [l for l in out.stdout.split("\n") if l.startswith("ii")]
            )
    except:
        pass

    # snap
    try:
        out = subprocess.run(["snap", "list"], capture_output=True, text=True)
        if out.returncode == 0:
            tools["snap"] = out.stdout.strip().split("\n")[1:]  # skip header
    except:
        pass

    return tools


def scan_research_notes():
    """Escanea archivos de investigación y notas."""
    notes = {
        "home_md": [],
        "ideas": {
            "seeds": [],
            "research": [],
            "prototypes": [],
            "specs": [],
            "graduated": [],
        },
    }

    # .md en HOME
    for f in HOME.glob("*.md"):
        notes["home_md"].append(
            {
                "name": f.name,
                "lines": f.read_text().count("\n"),
                "mtime": f.stat().st_mtime,
            }
        )

    # ideas system
    ideas_base = HOME / "projects/personal/ideas"
    for stage in ["seeds", "research", "prototypes", "specs", "graduated"]:
        stage_dir = ideas_base / stage
        if stage_dir.exists():
            for item in stage_dir.iterdir():
                notes["ideas"][stage].append(item.name)

    return notes


def classify_relevance(data: Dict) -> Dict:
    """Clasifica y puntúa relevancia de cada pieza de datos."""
    scores = {}

    # Brave bookmarks: alta relevancia (organizados por el usuario)
    if data.get("brave", {}).get("bookmarks"):
        scores["brave_bookmarks"] = 0.95

    # Brave history: media-alta (patrones de uso reales)
    if data.get("brave", {}).get("history"):
        scores["brave_history"] = 0.8

    # GitHub starred: alta (curados manualmente)
    if data.get("github_starred"):
        scores["github_starred"] = 0.9

    # Proyectos activos: muy alta
    active_count = len(data.get("projects", {}).get("personal", []))
    if active_count > 0:
        scores["projects_active"] = 0.98

    # opencode config: muy alta (config actual del agente)
    if data.get("dotfiles", {}).get("opencode_config"):
        scores["opencode_config"] = 0.99

    # Herramientas: alta (define capacidades)
    if data.get("tools", {}).get("mise"):
        scores["tools_mise"] = 0.9

    # SQLite dbs de IA: media (contexto de uso)
    if data.get("sqlite_dbs"):
        scores["sqlite_dbs"] = 0.7

    # Notas investigación: media
    if data.get("notes", {}).get("home_md"):
        scores["research_notes"] = 0.75

    return scores


# ============================
# GENERACIÓN DE SALIDAS
# ============================


def generate_inventory_md(data: Dict, scores: Dict) -> str:
    """Genera INVENTORY.md completo."""
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    lines = [
        f"# INVENTORY.md — Inventario completo del sistema",
        f"> Generado: {now} | Fuente: system-inventory.py",
        f"> Relevancia: puntuada 0-1 (1=crítico para contexto de agente)",
        "",
        "---",
        "",
        "## 1. Sistema Base",
        f"- OS: Ubuntu 26.04 | Kernel: {subprocess.run(['uname', '-r'], capture_output=True, text=True).stdout.strip()}",
        f"- Hardware: ThinkPad T14 Gen 3, AMD Ryzen 7 PRO 6850U",
        f"- Shell: zsh/Starship | Terminal: kitty/ghostty | Editor: Helix/Neovim",
        "",
        "## 2. Navegadores (Relevancia: {:.0%})".format(
            scores.get("brave_bookmarks", 0)
        ),
    ]

    # Brave
    brave = data.get("brave", {})
    if brave.get("folders"):
        lines.append("### Brave (snap) — Bookmarks organizados")
        for f in brave["folders"][:20]:
            lines.append(f"- `{f['path']}` ({f['type']})")
        lines.append(
            f"... y {len(brave['bookmarks'])} bookmarks totales en {len(brave['folders'])} carpetas"
        )

    if brave.get("history"):
        lines.append("\n### Brave History — Top sitios por visitas")
        for h in brave["history"][:15]:
            lines.append(f"- {h['visit_count']}x: {h['title'][:60]} → {h['url'][:80]}")

    # Chrome
    chrome = data.get("chrome", {})
    if chrome.get("bookmarks"):
        lines.append(
            f"\n### Chrome/Chromium — {len(chrome['bookmarks'])} bookmarks en perfiles: {', '.join(chrome['profiles'])}"
        )

    # GitHub Starred
    lines.append(
        f"\n## 3. GitHub Starred (Relevancia: {scores.get('github_starred', 0):.0%}) — {len(data.get('github_starred', []))} repos"
    )
    starred = data.get("github_starred", [])
    for r in starred[:15]:
        lines.append(f"- ⭐ {r['stars']:,} — **{r['repo']}**: {r['desc'][:100]}")
    if len(starred) > 15:
        lines.append(f"... y {len(starred) - 15} más (ver starred-repos.tsv)")

    # Proyectos
    lines.append(
        f"\n## 4. Proyectos (Relevancia: {scores.get('projects_active', 0):.0%})"
    )
    proj = data.get("projects", {})
    for cat in ["personal", "archive", "ppk", "external", "tools"]:
        items = proj.get(cat, [])
        if items:
            lines.append(f"\n### {cat.title()} ({len(items)})")
            for p in items[:10]:
                markers = (
                    f" [{', '.join(p.get('markers', []))}]" if p.get("markers") else ""
                )
                typ = f" ({p.get('type', '')})" if p.get("type") else ""
                lines.append(f"- **{p['name']}**{typ}{markers}: `{p['path']}`")
            if len(items) > 10:
                lines.append(f"  ... y {len(items) - 10} más")

    # Tools
    lines.append(
        f"\n## 5. Herramientas (Relevancia: {scores.get('tools_mise', 0):.0%})"
    )
    tools = data.get("tools", {})
    if tools.get("mise"):
        lines.append("### mise (gestión principal)")
        for t in tools["mise"][:20]:
            lines.append(f"- `{t['name']}` v{t['version']} ({t.get('source', 'mise')})")
        if len(tools["mise"]) > 20:
            lines.append(f"  ... y {len(tools['mise']) - 20} más")

    if tools.get("cargo"):
        lines.append(f"\n### Cargo/Rust ({len(tools['cargo'])} binarios)")
        lines.append(", ".join(sorted(tools["cargo"])[:30]))

    if tools.get("pipx"):
        lines.append(f"\n### pipx/~/.local/bin ({len(tools['pipx'])} herramientas)")
        lines.append(", ".join(sorted(tools["pipx"])[:30]))

    lines.append(
        f"\n### APT: {tools.get('apt_count', 0)} paquetes | Snap: {len(tools.get('snap', []))} apps"
    )

    # SQLite DBs
    lines.append(
        f"\n## 6. Bases de Datos IA (Relevancia: {scores.get('sqlite_dbs', 0):.0%})"
    )
    for name, info in data.get("sqlite_dbs", {}).items():
        if info.get("type") == "sqlite":
            tables = info["data"].get("tables", [])
            lines.append(
                f"- **{name}**: {len(tables)} tablas ({', '.join(tables[:5])}{'...' if len(tables) > 5 else ''})"
            )
        elif info.get("type") == "json":
            keys = list(info["data"].keys())[:5]
            lines.append(f"- **{name}** (JSON): {keys}")

    # Notas
    lines.append(
        f"\n## 7. Investigaciones / Notas (Relevancia: {scores.get('research_notes', 0):.0%})"
    )
    notes = data.get("notes", {})
    if notes.get("home_md"):
        for n in notes["home_md"]:
            lines.append(f"- `{n['name']}` ({n['lines']} líneas)")

    for stage, items in notes.get("ideas", {}).items():
        if items:
            lines.append(f"- ideas/{stage}: {', '.join(items[:5])}")

    # opencode config
    oc = data.get("dotfiles", {}).get("opencode_config", {})
    if oc:
        lines.append(
            f"\n## 8. Config opencode (Relevancia: {scores.get('opencode_config', 0):.0%})"
        )
        lines.append(f"- Model: {oc.get('model')} | Small: {oc.get('small_model')}")
        lines.append(f"- Default agent: {oc.get('default_agent')}")
        lines.append(
            f"- Providers habilitados: {', '.join(oc.get('enabled_providers', []))}"
        )
        lines.append(
            f"- Agents: {oc.get('agents_count')} | Providers: {oc.get('providers_count')}"
        )

    lines.append("\n---")
    lines.append(f"*Generado automáticamente por system-inventory.py — {now}*")
    return "\n".join(lines)


def generate_personal_md_update(data: Dict, scores: Dict) -> str:
    """Genera la sección actualizada de PERSONAL.md (secciones 7-9)."""
    lines = [
        "## 7. Proyectos activos",
        "",
        "- `Uspace` — Next.js + Supabase + Vitest",
        "- `maestro` — agent harness en Go",
        "- `ideas` — flujo seeds→research→prototypes→specs→graduated (actual: modernizacion-plantas-ia)",
        "- `dotfiles` — config stow (origen de este archivo + opencode.jsonc)",
        "- Otros: snapmcp, job-search, landing, wedo, ppk (ORBE/SO.FI)",
        "",
        "## 8. GitHub (usuario `reeinharddd`) — {} starred".format(
            len(data.get("github_starred", []))
        ),
        "",
    ]
    starred = data.get("github_starred", [])
    for r in starred[:10]:
        lines.append(f"- ⭐ {r['stars']:,} — **{r['repo']}**: {r['desc'][:80]}")
    lines.append("> Lista completa: `starred-repos.tsv` en este directorio.")
    lines.append("")
    lines.append("## 9. Recursos / investigaciones")
    lines.append("")
    notes = data.get("notes", {})
    for n in notes.get("home_md", []):
        lines.append(f"- `~/{n['name']}` ({n['lines']} líneas)")
    brave = data.get("brave", {})
    if brave.get("folders"):
        lines.append(
            f"- **Brave bookmarks**: {len(brave['folders'])} carpetas organizadas (AI/ML, Job Search, Design/UI, etc.)"
        )
    lines.append(
        f"- **Brave history**: {len(brave.get('history', []))} entradas (patrones: WeDo, opencode, Google Docs, GitHub)"
    )
    lines.append(
        f"- **Chrome history**: {len(data.get('chrome', {}).get('history', []))} entradas"
    )
    lines.append(
        f"- `INVENTORY.md` — inventario completo del sistema (tools, apps, proyectos) — fuente de verdad de bajo-frecuencia"
    )
    lines.append("")
    lines.append(
        "> ⚠️ Bookmarks exactos de Google / software compartido de equipo: pendientes de aportación del usuario."
    )
    return "\n".join(lines)


def build_engram_observations(data: Dict, scores: Dict) -> List[Dict]:
    """Construye las observaciones para engram con topic_key para upsert.
    Devuelve lista de dicts listos para engram_mem_save.
    Usa topic_key estable → engram_mem_save hace upsert (reemplaza si existe)."""
    return [
        {
            "title": "Inventario: Navegadores (Brave bookmarks/history) - {}".format(
                datetime.now().strftime("%Y-%m-%d")
            ),
            "content": """**What**: Bookmarks y historial de Brave (snap) extraídos automáticamente.
**Why**: Los bookmarks organizados por el usuario reflejan intereses técnicos reales; el historial muestra patrones de uso diario.
**Where**: ~/snap/brave/*/Brave-Browser/Default/{{Bookmarks,History}}
**Learned**: 
- Bookmarks: {} carpetas organizadas (AI & ML Platforms: 20+, Job Search: 12+, Design & UI Inspiration: 12+). URLs clave: opencode.ai, console.mistral.ai, console.groq.com, openrouter.ai, build.nvidia.com, huggingface.co, replicate.com, together.ai, fal.ai, modal.com.
- History top: WeDo (localhost:4200 - 400+ visitas), Google Docs (documentos de trabajo/estudio), opencode.ai (workspace/keys), WhatsApp Web, draw.io.
- Brave es el navegador principal de trabajo; Chrome tiene datos residuales.""".format(
                len(data.get("brave", {}).get("folders", []))
            ),
            "type": "pattern",
            "topic_key": "pattern/inventario-brave-bookmarks-history",
            "scope": "personal",
        },
        {
            "title": "Inventario: GitHub Starred (57 repos) - {}".format(
                datetime.now().strftime("%Y-%m-%d")
            ),
            "content": """**What**: 57 repositorios starred en GitHub (usuario reeinharddd).
**Why**: Repos curados manualmente = intereses técnicos prioritarios y recursos de referencia.
**Where**: GitHub API / ~/.config/opencode/starred-repos.tsv
**Learned**: 
Top por stars: build-your-own-x (544k), superpowers (280k), ECC (245k), mattpocock/skills (242k), the-book-of-secret-knowledge (241k), opencode (202k).
Temas: agent frameworks/harnesses (opencode, superpowers, ECC, gstack), design/anti-slop (penpot, hallmark, ui-ux-pro-max-skill, ponytail), security (destructive_command_guard), career-ops, diagramas (archify), knowledge graphs (Understand-Anything).""",
            "type": "pattern",
            "topic_key": "pattern/inventario-github-starred",
            "scope": "personal",
        },
        {
            "title": "Inventario: Proyectos activos/archive/ppk/tools - {}".format(
                datetime.now().strftime("%Y-%m-%d")
            ),
            "content": """**What**: Escaneo completo de ~/projects y ~/tools.
**Why**: Contexto de qué proyectos existen, su tipo, y marcadores de configuración (AGENTS.md, CLAUDE.md).
**Where**: ~/projects/personal/, ~/projects/archive/, ~/projects/ppk/, ~/projects/external/, ~/tools/
**Learned**: 
- Personal activos (8): Uspace (Next.js/Supabase), maestro (Go agent harness), ideas (sistema seeds→graduated), dotfiles (stow 32 pkgs), snapmcp, job-search, landing, wedo.
- Archive (17): proyectos históricos (KeepAnEye, Econnect, union-frontend/backend, ctx-analyze, mnemos, sys-inspector).
- PPK (7): ORBE, SO.FI, orbe-backend/frontend/main, PPK-SOCsAPI/Web.
- Tools (34): agentes/herramientas IA (engram, opencode-hooks, oh-my-openagent, superpowers, agentmemory, codebase-memory-mcp, metronous, gentle-ai, etc.).
- Dotfiles: stow repo con 32 paquetes, origen de ~/.config/opencode + ~/AGENTS.md.""",
            "type": "pattern",
            "topic_key": "pattern/inventario-proyectos-completo",
            "scope": "personal",
        },
        {
            "title": "Inventario: Herramientas instaladas (mise/cargo/pipx/apt/snap) - {}".format(
                datetime.now().strftime("%Y-%m-%d")
            ),
            "content": """**What**: Inventario completo de herramientas de desarrollo y sistema.
**Why**: Define capacidades técnicas disponibles en cualquier scope.
**Where**: mise, cargo, npm, pipx, apt, snap
**Learned**: 
- mise (37): actionlint, atuin, bat, bun, delta, deno, direnv, duf, dust, eza, fd, fzf, gh, go, herdr, htmlq, jq, just, lazygit, marksman, miller, node 24.19 LTS, python 3.14, restic, ripgrep, ruff, shellcheck, shfmt, starship, supabase, television, xh, yq, yt-dlp, pueue(aqua), sd(aqua).
- cargo (34): ast-grep, bandwhich, btop, choose, difft, doggo, gping, grex, gum, hexyl, hyperfine, lazydocker, navi, ouch, procs, rust-analyzer, sd, tldr, tokei, watchexec, zoxide.
- pipx/~/.local/bin (61): engram, opencode, playwright, hermes, metronous, codex, uv/uvx, wp, yazi, tv, transcribe, semgrep, gitleaks, git-cliff, navi, new-project, etc.
- apt: 2338 paquetes (code, broot, btop, alacritty, audacity, cmake, clang, docker, neovim, kitty, rustc, etc.).
- snap (24): bitwarden, brave, chromium, discord, firefox, insomnia, vlc, trivy, auto-cpufreq, mesa-2404.""",
            "type": "pattern",
            "topic_key": "pattern/inventario-herramientas-completo",
            "scope": "personal",
        },
        {
            "title": "Inventario: Bases de datos IA (opencode-kit, Hermes, Continue, Codex, Metronous) - {}".format(
                datetime.now().strftime("%Y-%m-%d")
            ),
            "content": """**What**: Datos internos de herramientas de IA instaladas (config, historia, embeddings, benchmarks).
**Why**: Contexto de uso previo, preferencias aprendidas, y estado de herramientas del ecosistema.
**Where**: ~/.config/opencode/opencode-kit.db, ~/.hermes/state.db, ~/.continue/index/, ~/.codex/, ~/.metronous/
**Learned**: 
- opencode-kit: 8 providers en BD (groq, mistral, nvidia, cerebras, openrouter, github-models, opencode-zen, github-copilot) — incluye cerebras/github-copilot no en config actual.
- Hermes: 2 mensajes, tablas FTS/trigram para búsqueda semántica.
- Continue: 31,263 chunks indexados (skills opencode, código local), dev_data con tokens generados via ollama (qwen3:8b).
- Codex: BDs vacías (memories, goals, thread_history, thread_goals).
- Metronous: tablas benchmark_runs, agent_summaries, events (vacías).
- agentmemory: preferences.json básico.
- Otras DBs: gemini settings, claude settings, etc.""",
            "type": "pattern",
            "topic_key": "pattern/inventario-dbs-ia",
            "scope": "personal",
        },
    ]


def update_engram(data: Dict, scores: Dict):
    """Genera observaciones y las imprime como JSON para que el agente las procese con engram_mem_save.
    El agente debe llamar a engram_mem_save con topic_key → upsert automático."""
    observations = build_engram_observations(data, scores)
    print(json.dumps(observations, ensure_ascii=False, indent=2))


# ============================
# MAIN
# ============================


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Inventario profundo del sistema")
    parser.add_argument("--full", action="store_true", help="Escanear todo (default)")
    parser.add_argument(
        "--update-engram", action="store_true", help="Guardar en engram"
    )
    parser.add_argument(
        "--update-files",
        action="store_true",
        help="Actualizar INVENTORY.md y PERSONAL.md",
    )
    parser.add_argument(
        "--only",
        choices=[
            "brave",
            "chrome",
            "github",
            "sqlite",
            "projects",
            "tools",
            "notes",
            "dotfiles",
        ],
        help="Solo una fuente",
    )
    args = parser.parse_args()

    if not (args.update_engram or args.update_files):
        args.update_engram = args.update_files = True

    print("🔍 Iniciando inventario del sistema...")
    data = {}

    if args.only == "brave" or not args.only:
        print("  📖 Extrayendo Brave...")
        data["brave"] = extract_brave_data()
        print(
            f"    ✓ {len(data['brave']['bookmarks'])} bookmarks, {len(data['brave']['history'])} history, {len(data['brave']['folders'])} carpetas"
        )

    if args.only == "chrome" or not args.only:
        print("  🌐 Extrayendo Chrome/Chromium...")
        data["chrome"] = extract_chrome_data()
        print(
            f"    ✓ {len(data['chrome']['bookmarks'])} bookmarks, {len(data['chrome']['history'])} history"
        )

    if args.only == "github" or not args.only:
        print("  ⭐ Extrayendo GitHub starred...")
        data["github_starred"] = extract_github_starred()
        print(f"    ✓ {len(data['github_starred'])} repos")
        # Persistir TSV
        STARRED_FILE.write_text(
            "\n".join(
                f"{r['stars']}\t{r['repo']}\t{r['desc']}"
                for r in data["github_starred"]
            )
        )

    if args.only == "sqlite" or not args.only:
        print("  🗄️ Escaneando SQLite DBs...")
        data["sqlite_dbs"] = scan_sqlite_dbs()
        print(f"    ✓ {len(data['sqlite_dbs'])} bases de datos")

    if args.only == "projects" or not args.only:
        print("  📁 Escaneando proyectos...")
        data["projects"] = scan_projects()
        total = sum(len(v) for v in data["projects"].values())
        print(f"    ✓ {total} proyectos en {len(data['projects'])} categorías")

    if args.only == "tools" or not args.only:
        print("  🛠️ Escaneando herramientas...")
        data["tools"] = scan_tools()
        print(
            f"    ✓ mise:{len(data['tools']['mise'])} cargo:{len(data['tools']['cargo'])} pipx:{len(data['tools']['pipx'])} apt:{data['tools']['apt_count']} snap:{len(data['tools']['snap'])}"
        )

    if args.only == "notes" or not args.only:
        print("  📝 Escaneando investigaciones/notas...")
        data["notes"] = scan_research_notes()
        print(
            f"    ✓ {len(data['notes']['home_md'])} .md en HOME, ideas: {sum(len(v) for v in data['notes']['ideas'].values())}"
        )

    if args.only == "dotfiles" or not args.only:
        print("  ⚙️ Escaneando dotfiles/config...")
        data["dotfiles"] = scan_dotfiles()
        print(
            f"    ✓ stow:{len(data['dotfiles'].get('stow_packages', []))} opencode_config:{'sí' if data['dotfiles'].get('opencode_config') else 'no'}"
        )

    # Clasificar relevancia
    scores = classify_relevance(data)
    print(f"\n📊 Relevancia: {json.dumps(scores, indent=2)}")

    # Actualizar archivos
    if args.update_files:
        print("\n📝 Actualizando INVENTORY.md...")
        INVENTORY_FILE.write_text(generate_inventory_md(data, scores))
        print(f"  ✓ {INVENTORY_FILE}")

        print("📝 Actualizando PERSONAL.md (secciones 7-9)...")
        personal_content = PERSONAL_FILE.read_text()
        # Reemplazar secciones 7-9 (desde "## 7." hasta antes de "---" final o "## Autocrecimiento")
        import re

        new_sections = generate_personal_md_update(data, scores)
        # Encontrar desde "## 7." hasta "## Autocrecimiento" o final
        pattern = r"(## 7\..*?)(?=## Autocrecimiento|--- *$|\Z)"
        replacement = new_sections + "\n\n"
        updated = re.sub(pattern, replacement, personal_content, flags=re.DOTALL)
        if updated == personal_content:
            # Fallback: append si no encuentra
            updated = personal_content.rstrip() + "\n\n" + new_sections + "\n"
        PERSONAL_FILE.write_text(updated)
        print(f"  ✓ {PERSONAL_FILE}")

    # Actualizar engram
    if args.update_engram:
        print("\n🧠 Actualizando engram (scope=personal)...")
        update_engram(data, scores)

    print("\n✅ Inventario completado.")


if __name__ == "__main__":
    main()
