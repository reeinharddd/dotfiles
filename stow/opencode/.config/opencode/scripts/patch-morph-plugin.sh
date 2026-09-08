#!/usr/bin/env bash
# Re-aplica el fix de fail-open para @morphllm/opencode-morph-plugin.
# Bug: client.config.get() cuelga el init de la TUI sin MORPH_API_KEY (issue #28).
# El patch se pierde cuando opencode purga ~/.cache/opencode/packages.
set -euo pipefail

ROOT=~/.config/opencode
OLD='const cfg = await client.config?.get().catch(() => null);'
NEW='const cfg = await Promise.race([
            client.config?.get().catch(() => null),
            new Promise((r) => setTimeout(() => r(null), 3000)),
        ]);'

patch_dir() {
    local f="$1/dist/index.js"
    [[ -f "$f" ]] || return 0
    if grep -q 'Promise.race' "$f"; then
        echo "OK (ya parcheado): $f"
    elif grep -qF "$OLD" "$f"; then
        node -e '
const fs=require("fs");const p=process.argv[1];
let s=fs.readFileSync(p,"utf8");
s=s.replace(process.argv[2],process.argv[3]);
fs.writeFileSync(p,s);' "$f" "$OLD" "$NEW"
        echo "PATCHED: $f"
    else
        echo "SKIP (patron no encontrado): $f"
    fi
}

# node_modules local
patch_dir "$ROOT/node_modules/@morphllm/opencode-morph-plugin"
# cache de opencode (todas las variantes)
for d in "$HOME/.cache/opencode/packages/@morphllm/opencode-morph-plugin" \
         "$HOME/.cache/opencode/packages/@morphllm/opencode-morph-plugin@latest" \
         "$HOME/.cache/opencode/packages/@morphllm/opencode-morph-plugin@2.0.16"; do
    patch_dir "$d/node_modules/@morphllm/opencode-morph-plugin"
done
echo "Done."
