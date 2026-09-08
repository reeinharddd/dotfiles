#!/usr/bin/env bash
# systemInfo Scanner - regenerates hardware/software/project info
set -e

BASE="$(dirname "$0")/.."

echo "=== Scanning Hardware ==="
cat > "$BASE/hardware/current.json" <<EOF
{
  "hostname": "$(hostname)",
  "kernel": "$(uname -r)",
  "os": "$(lsb_release -sd 2>/dev/null)",
  "cpu": "$(lscpu | grep "Model name" | awk -F: '{print $2}' | xargs)",
  "cores": "$(nproc)",
  "ram": "$(free -h | awk '/^Mem:/ {print $2}')",
  "ram_used": "$(free -h | awk '/^Mem:/ {print $3}')",
  "disk": "$(lsblk -ndo NAME,SIZE,TYPE | head -5 | tr '\n' ';')",
  "gpu": "$(lspci | grep -E "VGA|3D" | head -1 | awk -F: '{print $3}' | xargs)"
}
EOF

echo "=== Scanning Software ==="
python3 -W ignore -c "
import subprocess, json, re
def sh(cmd):
    try:
        out = subprocess.check_output(cmd, shell=True, text=True, stderr=subprocess.DEVNULL).strip()
        return re.sub(r'\x1b\[[0-9;]*m', '', out)
    except: return ''
tools = {}
checks = [
    ('mise','mise --version'),('node','node --version'),('bun','bun --version'),
    ('python','python3 --version'),('go','go version'),('rust','rustc --version'),
    ('git','git --version'),('docker','docker --version'),('ollama','ollama --version'),
    ('just','just --version'),('eza','eza --version | head -1'),('batcat','batcat --version'),
    ('ripgrep','rg --version | head -1'),('fd','fdfind --version'),
    ('fzf','fzf --version'),('zoxide','zoxide --version'),('delta','delta --version | head -1'),
    ('lazygit','lazygit --version | head -1'),('lazydocker','lazydocker --version | head -1'),
    ('btop','btop --version | head -1'),('htop','htop --version | head -1'),
    ('fzf','fzf --version'),('atuin','atuin --version | head -1'),
    ('starship','starship --version | head -1'),    ('zellij','zellij --version | head -1'),
    ('yazi','yazi --version | head -1'),('navi','navi --version | head -1'),
    ('procs','procs --version | head -1'),('git-cliff','git-cliff --version | head -1'),
    ('gitleaks','gitleaks --version | head -1'),('sops','sops --version | head -1'),
    ('age','age --version | head -1'),('jj','jj --version | head -1'),
    ('chezmoi','chezmoi --version | head -1'),('gh','gh --version | head -1'),
    ('trivy','trivy --version | head -1'),('semgrep','semgrep --version'),
    ('cargo','cargo --version | head -1'),('npm','npm --version'),
    ('pipx','pipx --version'),('apt','apt --version | head -1 | sed \"s/apt //\"'),
    ('snap','snap --version | head -1 | awk \"{print \\$2}\"'),
    ('make','make --version | head -1 | sed \"s/GNU Make //\" | sed \"s/ Built.*//\"'),
    ('cmake','cmake --version | head -1 | sed \"s/cmake version //\"'),
    ('gcc','gcc -dumpversion'),('g++','g++ -dumpversion'),
    ('curl','curl --version | head -1 | sed \"s/curl //\" | sed \"s/ (.*//\"'),
    ('wget','wget --version | head -1 | sed \"s/GNU Wget //\" | sed \"s/ .*//\"'),
    ('bw','bw --version | head -1')
]
for name, cmd in checks:
    v = sh(cmd)
    if v: tools[name] = v
import os
open(os.path.join('$BASE', 'software', 'current.json'), 'w').write(json.dumps(tools, indent=2))
"

echo "=== Scanning Projects ==="
python3 -c "
import json
from pathlib import Path
projs = []
base = Path.home() / 'projects'
if base.exists():
    for lang in sorted(base.iterdir()):
        if lang.is_dir():
            for p in sorted(lang.iterdir()):
                if p.is_dir():
                    info = {'name': p.name, 'path': str(p), 'lang': lang.name}
                    pkg = p / 'package.json'
                    if pkg.exists():
                        d = json.loads(pkg.read_text())
                        info['version'] = d.get('version','')
                    projs.append(info)
import os
open(os.path.join('$BASE', 'projects', 'registry.json'), 'w').write(json.dumps(projs, indent=2))
"

echo "=== Done ==="
echo "  hardware/current.json  - $(wc -c < "$BASE/hardware/current.json") bytes"
echo "  software/current.json  - $(wc -c < "$BASE/software/current.json") bytes"
echo "  projects/registry.json - $(wc -c < "$BASE/projects/registry.json") bytes"