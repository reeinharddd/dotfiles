import json
import os
import subprocess
from pathlib import Path
from typing import Any

SYSTEMINFO_DIR = Path(os.path.expanduser("~/systemInfo"))


def read_json(path: Path) -> dict[str, Any]:
    if path.exists():
        return json.loads(path.read_text())
    return {}


def run(cmd: list[str]) -> str:
    try:
        return subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL).strip()
    except Exception:
        return ""


def scan_hardware() -> dict:
    cpu = run(["lscpu"]).split("\n")[:5]
    mem = run(["free", "-h"]).split("\n")[1].split()
    disk = run(["lsblk", "-o", "NAME,SIZE,TYPE,MOUNTPOINTS", "-n"]).split("\n")[:5]
    return {
        "hostname": run(["hostname"]),
        "kernel": run(["uname", "-r"]),
        "os": run(["lsb_release", "-sd"]),
        "cpu": cpu,
        "memory": {"total": mem[1], "used": mem[2], "available": mem[6]} if len(mem) >= 7 else {},
        "disk": [l.strip() for l in disk if l.strip()],
        "gpu": run(["lspci", "|", "grep", "-E", "VGA|3D|Display"]),
    }


def scan_software() -> dict:
    tools = {
        "node": run(["node", "--version"]),
        "bun": run(["bun", "--version"]),
        "python": run(["python3", "--version"]),
        "go": run(["go", "version"]),
        "rust": run(["rustc", "--version"]),
        "cargo": run(["cargo", "--version"]),
        "git": run(["git", "--version"]),
        "docker": run(["docker", "--version"]),
        "docker_compose": run(["docker", "compose", "version"]),
        "gh": run(["gh", "--version"]).split("\n")[0] if run(["gh", "--version"]) else "",
        "zsh": run(["zsh", "--version"]).split("\n")[0] if run(["zsh", "--version"]) else "",
        "mise": run(["mise", "--version"]),
        "ollama": run(["ollama", "--version"]),
        "just": run(["just", "--version"]),
        "lazygit": run(["lazygit", "--version"]).split("\n")[0] if run(["lazygit", "--version"]) else "",
    }
    return {k: v for k, v in tools.items() if v}


def scan_configs() -> dict:
    configs = {}
    for f in ["~/.zshrc", "~/.gitconfig", "~/.config/mise/config.toml"]:
        p = Path(f).expanduser()
        if p.exists():
            configs[p.name] = p.read_text().split("\n")[:20]
    return configs


def scan_projects() -> list[dict]:
    projects = []
    base = Path.home() / "projects"
    if base.exists():
        for lang_dir in base.iterdir():
            if lang_dir.is_dir():
                for proj in lang_dir.iterdir():
                    if proj.is_dir():
                        proj_info = {"name": proj.name, "path": str(proj), "language": lang_dir.name}
                        if (proj / "package.json").exists():
                            pkg = json.loads((proj / "package.json").read_text())
                            proj_info["type"] = pkg.get("type", "js")
                            proj_info["version"] = pkg.get("version", "")
                        projects.append(proj_info)
    return projects


def system_info() -> str:
    return json.dumps({
        "hardware": scan_hardware(),
        "software": scan_software(),
    }, indent=2)


def list_tools(category: str = "") -> str:
    all_tools = scan_software()
    if category and category in all_tools:
        return json.dumps({category: all_tools[category]}, indent=2)
    return json.dumps(all_tools, indent=2)


def list_projects() -> str:
    return json.dumps(scan_projects(), indent=2)


def installed_packages(count: int = 20) -> str:
    apt = run(["dpkg", "-l"]).split("\n")[5:5 + count]
    return "\n".join(apt) if apt else ""


MCP_SERVER_SCRIPT = """
import sys
import json
sys.path.insert(0, {systeminfo!r})
from server import system_info, list_tools, list_projects, installed_packages


def handle_request(request: dict) -> dict:
    tool = request.get("tool", "")
    args = request.get("args", {{}})
    
    if tool == "system_info":
        result = system_info()
    elif tool == "list_tools":
        result = list_tools(args.get("category", ""))
    elif tool == "list_projects":
        result = list_projects()
    elif tool == "installed_packages":
        result = installed_packages(args.get("count", 20))
    else:
        result = json.dumps({{"error": f"Unknown tool: {tool}"}})
    
    return {{"result": result}}


if __name__ == "__main__":
    for line in sys.stdin:
        req = json.loads(line)
        resp = handle_request(req)
        sys.stdout.write(json.dumps(resp) + "\\n")
        sys.stdout.flush()
"""

if __name__ == "__main__":
    print("systemInfo MCP Server loaded")
    print(f"  Tools: system_info, list_tools, list_projects, installed_packages")
