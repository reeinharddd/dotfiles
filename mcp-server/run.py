#!/usr/bin/env python3
"""systemInfo MCP Server - exposes hardware/software info to AI agents."""

import json
import os
import subprocess
import sys
from pathlib import Path

SYSTEMINFO = Path(os.path.expanduser("~/systemInfo"))


def sh(cmd: str) -> str:
    try:
        return subprocess.check_output(cmd, shell=True, text=True, stderr=subprocess.DEVNULL).strip()
    except Exception:
        return ""


def hardware() -> dict:
    return {
        "hostname": sh("hostname"),
        "kernel": sh("uname -r"),
        "os": sh("lsb_release -sd"),
        "cpu": sh("lscpu | grep 'Model name' | awk -F: '{print $2}'").strip(),
        "cores": sh("nproc"),
        "ram": sh("free -h | awk '/^Mem:/ {print $2}'"),
        "ram_used": sh("free -h | awk '/^Mem:/ {print $3}'"),
        "disk": sh("lsblk -ndo NAME,SIZE,TYPE | head -5"),
        "gpu": sh("lspci | grep -E 'VGA|3D' | head -1"),
        "temp": sh("sensors 2>/dev/null | grep 'Package' | head -1"),
    }


def software() -> dict:
    tools = {}
    checks = [
        ("node", "node --version"),
        ("bun", "bun --version"),
        ("python", "python3 --version"),
        ("go", "go version"),
        ("rust", "rustc --version"),
        ("cargo", "cargo --version"),
        ("git", "git --version"),
        ("docker", "docker --version"),
        ("docker_compose", "docker compose version"),
        ("gh", "gh --version | head -1"),
        ("mise", "mise --version"),
        ("ollama", "ollama --version"),
        ("just", "just --version"),
        ("zoxide", "zoxide --version"),
        ("eza", "eza --version | head -1"),
        ("bat", "bat --version"),
        ("ripgrep", "rg --version | head -1"),
        ("fd", "fd --version"),
        ("fzf", "fzf --version"),
        ("lazygit", "lazygit --version | head -1"),
        ("lazydocker", "lazydocker --version | head -1"),
        ("gum", "gum --version"),
        ("glow", "glow --version"),
        ("delta", "delta --version | head -1"),
        ("dust", "dust --version"),
        ("btop", "btop --version | head -1"),
        ("tmux", "tmux -V"),
    ]
    for name, cmd in checks:
        v = sh(cmd)
        if v:
            tools[name] = v
    return tools


def projects() -> list[dict]:
    result = []
    base = Path.home() / "projects"
    if base.exists():
        for lang in sorted(base.iterdir()):
            if lang.is_dir():
                for p in sorted(lang.iterdir()):
                    if p.is_dir():
                        info = {"name": p.name, "path": str(p), "lang": lang.name}
                        pkg = p / "package.json"
                        if pkg.exists():
                            data = json.loads(pkg.read_text())
                            info["version"] = data.get("version", "")
                            info["type"] = "js"
                        result.append(info)
    return result


def handle(req: dict) -> dict:
    tool = req.get("tool", "")
    args = req.get("args", {})
    try:
        if tool == "system_info":
            result = {"hardware": hardware(), "software": software()}
        elif tool == "list_tools":
            cat = args.get("category", "")
            s = software()
            result = {cat: s[cat]} if cat in s else s
        elif tool == "list_projects":
            result = projects()
        elif tool == "scan":
            hw = hardware()
            sw = software()
            path = SYSTEMINFO / "hardware" / "current.json"
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(json.dumps(hw, indent=2))
            path = SYSTEMINFO / "software" / "current.json"
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(json.dumps(sw, indent=2))
            result = {"status": "ok", "hardware": len(hw), "software": len(sw)}
        else:
            result = {"error": f"unknown tool: {tool}"}
    except Exception as e:
        result = {"error": str(e)}
    return {"result": result}


if __name__ == "__main__":
    for line in sys.stdin:
        req = json.loads(line.strip())
        resp = handle(req)
        sys.stdout.write(json.dumps(resp) + "\n")
        sys.stdout.flush()
