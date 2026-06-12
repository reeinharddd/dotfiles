#!/usr/bin/env bash
# systemInfo Scanner - regenerates hardware/software/project info
set -e

BASE="$HOME/systemInfo"

echo "=== Scanning Hardware ==="
cat > "$BASE/hardware/current.json" <<'EOF'
{
  "hostname": "'$(hostname)'",
  "kernel": "'$(uname -r)'",
  "os": "'$(lsb_release -sd 2>/dev/null)'",
  "cpu": "'$(lscpu | grep "Model name" | awk -F: "{print \$2}" | xargs)'",
  "cores": "'$(nproc)'",
  "ram": "'$(free -h | awk "/^Mem:/ {print \$2}")'",
  "ram_used": "'$(free -h | awk "/^Mem:/ {print \$3}")'",
  "disk": "'$(lsblk -ndo NAME,SIZE,TYPE | head -5 | tr '\n' ';')'",
  "gpu": "'$(lspci | grep -E "VGA|3D" | head -1 | awk -F: "{print \$3}" | xargs)'"
}
EOF

echo "=== Scanning Software ==="
python3 -c "
import subprocess, json
def sh(cmd):
    try: return subprocess.check_output(cmd, shell=True, text=True, stderr=subprocess.DEVNULL).strip()
    except: return ''
tools = {}
checks = [
    ('node','node --version'),('bun','bun --version'),('python','python3 --version'),
    ('go','go version'),('rust','rustc --version'),('git','git --version'),
    ('docker','docker --version'),('mise','mise --version'),('ollama','ollama --version'),
    ('just','just --version'),('eza','eza --version | head -1'),('bat','bat --version'),
    ('ripgrep','rg --version | head -1'),('fd','fd --version'),
    ('fzf','fzf --version'),('zoxide','zoxide --version'),('delta','delta --version | head -1'),
    ('lazygit','lazygit --version | head -1'),('lazydocker','lazydocker --version | head -1'),
    ('gum','gum --version'),('glow','glow --version'),('btop','btop --version | head -1'),
]
for name, cmd in checks:
    v = sh(cmd)
    if v: tools[name] = v
open('$BASE/software/current.json','w').write(json.dumps(tools, indent=2))
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
open('$BASE/projects/registry.json','w').write(json.dumps(projs, indent=2))
"

echo "=== Done ==="
echo "  hardware/current.json  - $(wc -c < $BASE/hardware/current.json) bytes"
echo "  software/current.json  - $(wc -c < $BASE/software/current.json) bytes"
echo "  projects/registry.json - $(wc -c < $BASE/projects/registry.json) bytes"
