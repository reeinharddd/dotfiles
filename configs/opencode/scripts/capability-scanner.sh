#!/usr/bin/env bash
# capability-scanner: Descubre capabilities no registradas en OpenCode
# Escanea: skills locales, MCPs en node_modules/.bin, binarios en PATH
# Filtra contra: skills/, REGISTRY.md, opencode.json mcp section, PROJECT_CONTEXT.md
# Output: JSON estructurado con candidatos + comandos de carga

set -uo pipefail

REGISTRY="${HOME}/.config/opencode/skills/REGISTRY.md"
SKILLS_DIR="${HOME}/.config/opencode/skills/core"
OPENCODE_CONFIG="${HOME}/.config/opencode/opencode.json"
LOCAL_SKILLS_DIR="${HOME}/.config/opencode/skills"
NODE_MODULES="${HOME}/.config/opencode/node_modules"

PROJECT_ROOT="${1:-$PWD}"
PROJECT_CTX="$PROJECT_ROOT/.opencode/PROJECT_CONTEXT.md"

declare -A REG_SKILL
declare -A REG_MCP

for entry in "$SKILLS_DIR"/*; do
  [ -e "$entry" ] || continue
  if [ -L "$entry" ]; then
    target=$(readlink "$entry")
    name=$(basename "$target")
  else
    name=$(basename "$entry")
  fi
  REG_SKILL["$name"]="core"
done

if [ -f "$REGISTRY" ]; then
  : > /tmp/.cap_scan_registry.tmp
  grep -aE '^\|[^|]' "$REGISTRY" 2>/dev/null | while IFS='|' read -r line; do
    name=$(echo "$line" | awk -F'|' '{print $2}' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/[\">]//g; s/`//g')
    if [[ "$name" =~ ^[a-z][a-z0-9-]+$ ]]; then
      echo "$name" >> /tmp/.cap_scan_registry.tmp
    fi
  done
  sort -u /tmp/.cap_scan_registry.tmp -o /tmp/.cap_scan_registry.tmp
  while IFS= read -r name; do
    REG_SKILL["$name"]="registry"
  done < /tmp/.cap_scan_registry.tmp
  rm -f /tmp/.cap_scan_registry.tmp
fi

# MCPs registrados (solo enabled: true cuenta como registrado)
if [ -f "$OPENCODE_CONFIG" ]; then
  while IFS= read -r mcp; do
    [ -n "$mcp" ] && REG_MCP["$mcp"]=1
  done < <(node -e "
const j = JSON.parse(require('fs').readFileSync('$OPENCODE_CONFIG','utf-8'));
if (j.mcp) Object.entries(j.mcp).filter(([k,v]) => !k.startsWith('_') && v.enabled === true).forEach(([k]) => console.log(k));
" 2>/dev/null)
fi

# Project context
if [ -f "$PROJECT_CTX" ]; then
  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+([a-z][a-z0-9-]+)$ ]]; then
      REG_SKILL["${BASH_REMATCH[1]}"]="project"
    fi
  done < "$PROJECT_CTX"
fi

# Escanear skills locales
DISCOVERED_SKILLS=()
SKILL_TOTAL=0
for skill_dir in "$LOCAL_SKILLS_DIR"/*/; do
  [ -d "$skill_dir" ] || continue
  SKILL_TOTAL=$((SKILL_TOTAL + 1))
  name=$(basename "$skill_dir")
  [[ "$name" == "sdd-"* ]] && continue
  [[ "$name" == "_shared" ]] && continue
  [[ "$name" == "geo-seo" ]] && continue
  if [[ -z "${REG_SKILL[$name]:-}" ]]; then
    desc=""
    [ -f "$skill_dir/SKILL.md" ] && desc=$(awk '/^description:/,/^---$/' "$skill_dir/SKILL.md" | head -3 | tr '\n' ' ' | sed 's/description: //; s/---//g' | tr -d '"' | cut -c1-80)
    DISCOVERED_SKILLS+=("{\"name\":\"$name\",\"desc\":\"$desc\",\"load\":\"skill(name=\\\"$name\\\")\"}")
  fi
done

# Escanear MCPs (binarios en node_modules/.bin)
DISCOVERED_MCPS=()
PLUGIN_BINARIES=("oh-my-openagent" "oh-my-opencode" "opencode-wakatime" "opencode-worktree" "opencode-conductor" "opencode-background-agents" "opencode-vibeguard" "opencode-notify" "opencode-scheduler")

DISABLED_MCPS=()
if [ -f "$OPENCODE_CONFIG" ]; then
  while IFS= read -r entry; do
    name=$(echo "$entry" | cut -d'|' -f1)
    cmd=$(echo "$entry" | cut -d'|' -f2-)
    [ -n "$name" ] && DISABLED_MCPS+=("{\"name\":\"$name\",\"cmd\":\"$cmd\",\"action\":\"set enabled: true in opencode.json\"}")
  done < <(node -e "
const j = JSON.parse(require('fs').readFileSync('$OPENCODE_CONFIG','utf-8'));
if (j.mcp) {
  Object.entries(j.mcp)
    .filter(([k,v]) => !k.startsWith('_') && v.enabled === false)
    .forEach(([k,v]) => {
      const cmd = Array.isArray(v.command) ? v.command.join(' ') : (v.url || '');
      console.log(k + '|' + cmd);
    });
}
" 2>/dev/null)
fi

if [ -d "$NODE_MODULES/.bin" ]; then
  for bin in "$NODE_MODULES/.bin/"*; do
    [ -x "$bin" ] || continue
    binname=$(basename "$bin")
    if [[ "$binname" =~ ^opencode- ]] || [[ "$binname" =~ ^oh-my- ]] || \
       [[ "$binname" == "code-review-graph" ]] || [[ "$binname" == "engram" ]] || \
       [[ "$binname" == "agentmemory" ]] || [[ "$binname" == "firecrawl" ]] || \
       [[ "$binname" == "chrome-devtools" ]] || [[ "$binname" == "playwright" ]] || \
       [[ "$binname" == "mcp-server-"* ]]; then
      mcp_candidate="${binname#opencode-}"
      is_plugin=false
      for p in "${PLUGIN_BINARIES[@]}"; do
        [[ "$binname" == "$p" ]] && is_plugin=true && break
      done
      if [[ "$is_plugin" == false ]] && \
         [[ -z "${REG_MCP[$mcp_candidate]:-}" ]] && \
         [[ -z "${REG_MCP[$binname]:-}" ]]; then
        DISCOVERED_MCPS+=("{\"name\":\"$binname\",\"type\":\"binary\",\"action\":\"enable in opencode.json mcp section\"}")
      fi
    fi
  done
fi

for dm in "${DISABLED_MCPS[@]}"; do
  DISCOVERED_MCPS+=("$dm")
done

# Stats
REG_COUNT=${#REG_SKILL[@]}
MCP_COUNT=${#REG_MCP[@]}

# Construir JSON
{
  echo "{"
  echo "  \"summary\": {"
  echo "    \"core_skills\": $(ls "$SKILLS_DIR" 2>/dev/null | wc -l),"
  echo "    \"registry_skills\": $REG_COUNT,"
  echo "    \"local_skills_total\": $SKILL_TOTAL,"
  echo "    \"registered_mcps\": $MCP_COUNT,"
  echo "    \"discovered_skills\": ${#DISCOVERED_SKILLS[@]},"
  echo "    \"discovered_mcps\": ${#DISCOVERED_MCPS[@]}"
  echo "  },"
  echo "  \"discovered_skills\": ["
  if [ ${#DISCOVERED_SKILLS[@]} -gt 0 ]; then
    printf '    %s\n' "${DISCOVERED_SKILLS[0]}"
    for ((i=1; i<${#DISCOVERED_SKILLS[@]}; i++)); do
      printf '    ,\n    %s\n' "${DISCOVERED_SKILLS[$i]}"
    done
  fi
  echo "  ],"
  echo "  \"discovered_mcps\": ["
  if [ ${#DISCOVERED_MCPS[@]} -gt 0 ]; then
    printf '    %s\n' "${DISCOVERED_MCPS[0]}"
    for ((i=1; i<${#DISCOVERED_MCPS[@]}; i++)); do
      printf '    ,\n    %s\n' "${DISCOVERED_MCPS[$i]}"
    done
  fi
  echo "  ]"
  echo "}"
} | node -e "
let data = '';
process.stdin.on('data', c => data += c);
process.stdin.on('end', () => {
  try {
    const obj = JSON.parse(data);
    console.log(JSON.stringify(obj, null, 2));
  } catch (e) {
    console.error('Parse error:', e.message);
    console.error('Input was:');
    console.error(data.substring(0, 500));
    process.exit(1);
  }
});
"