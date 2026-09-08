#!/usr/bin/env bash
# capability-scanner: Descubre capabilities (skills, MCPs) no registradas en OpenCode.
# Escanea: skills personales, bodega (~/tools), manifest del plugin, MCPs en opencode.jsonc.
# Filtra contra: skills ya conocidas (core + bodega indexadas) y MCPs habilitados.
# Output: JSON estructurado con candidatos + comandos de carga.
#
# Uso: capability-scanner.sh [project-root]

set -o pipefail

TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/opencode-capabilities.XXXXXX")
trap 'rm -r -- "$TMP_DIR"' EXIT

OC_DIR="${HOME}/.config/opencode"
REGISTRY="${OC_DIR}/REGISTRY.md"
SKILLS_DIR="${OC_DIR}/skills"
TOOLS_DIR="${HOME}/tools"
PLUGIN_MANIFEST="${OC_DIR}/plugins/bodega-global-skills.json"
OPENCODE_CONFIG="${OC_DIR}/opencode.jsonc"
PROJECT_ROOT="${1:-$PWD}"
PROJECT_CTX="$PROJECT_ROOT/.opencode/PROJECT_CONTEXT.md"

declare -A KNOWN_SKILL
declare -A KNOWN_MCP

# 1. Skills personales core (siempre conocidas)
if [ -d "$SKILLS_DIR" ]; then
	for entry in "$SKILLS_DIR"/*; do
		[ -e "$entry" ] || continue
		name=$(basename "$entry")
		KNOWN_SKILL["$name"]="core"
	done
fi

# 2. Skills indexadas por el plugin (bodega global selecta)
if [ -f "$PLUGIN_MANIFEST" ]; then
	while IFS= read -r d; do
		[ -n "$d" ] || continue
		base=$(basename "$d")
		KNOWN_SKILL["$base"]="indexed"
	done < <(node -e "try{JSON.parse(require('fs').readFileSync('$PLUGIN_MANIFEST','utf8')).forEach(d=>console.log(d))}catch(e){}" 2>/dev/null)
fi

# 3. Todas las skills de la bodega (para no reportar lo ya disponible bajo demanda)
if [ -d "$TOOLS_DIR" ]; then
	while IFS= read -r d; do
		[ -n "$d" ] || continue
		base=$(basename "$d")
		KNOWN_SKILL["$base"]="bodega"
  done < <(cd "$TOOLS_DIR" && rg --files --hidden -g 'SKILL.md' -g '!node_modules/**' -g '!dist/**' 2>/dev/null | while read -r p; do basename "$(dirname "$p")"; done | sort -u)
fi

# 4. Skills en REGISTRY.md (tabla)
if [ -f "$REGISTRY" ]; then
	while IFS='|' read -r _ name _; do
		name=$(echo "$name" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/[\"`]//g')
		if [[ "$name" =~ ^[a-z][a-z0-9-]+$ ]]; then
			KNOWN_SKILL["$name"]="registry"
		fi
	done < <(grep -aE '^\|[^|]' "$REGISTRY" 2>/dev/null)
fi

# 5. Skills en PROJECT_CONTEXT.md del proyecto
if [ -f "$PROJECT_CTX" ]; then
	while IFS= read -r line; do
		if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+([a-z][a-z0-9-]+)$ ]]; then
			KNOWN_SKILL["${BASH_REMATCH[1]}"]="project"
		fi
	done <"$PROJECT_CTX"
fi

# --- MCPs registrados (habilitados cuentan como conocidos) ---
if [ -f "$OPENCODE_CONFIG" ]; then
	while IFS= read -r mcp; do
		[ -n "$mcp" ] && KNOWN_MCP["$mcp"]=1
	done < <(node -e "
const fs=require('fs');
try {
  const t=fs.readFileSync('$OPENCODE_CONFIG','utf8');
  const s=t.replace(/\/\*[\s\S]*?\*\//g,'').replace(/^\s*\/\/.*\$/gm,'');
  const j=JSON.parse(s);
  if(j.mcp) Object.entries(j.mcp).filter(([k,v])=>!k.startsWith('_')&&v.enabled===true).forEach(([k])=>console.log(k));
} catch(e){}
" 2>/dev/null)
fi

# --- Escanear skills locales (personales) no conocidas ---
DISCOVERED_SKILLS=()
SKILL_TOTAL=0
if [ -d "$SKILLS_DIR" ]; then
  for skill_dir in "$SKILLS_DIR"/*/; do
    [ -d "$skill_dir" ] || continue
    SKILL_TOTAL=$((SKILL_TOTAL + 1))
    name=$(basename "$skill_dir")
    if [[ -z "${KNOWN_SKILL[$name]:-}" ]]; then
      desc=""
      [ -f "$skill_dir/SKILL.md" ] && desc=$(awk 'f&&/^---$/{exit} /^description:/{f=1} f{print}' "$skill_dir/SKILL.md" 2>/dev/null | sed 's/^description:[[:space:]]*//; s/[`"]//g' | tr '\n' ' ' | cut -c1-80)
      DISCOVERED_SKILLS+=("$name|$desc")
    fi
  done
fi

# --- MCPs deshabilitados (candidatos a habilitar) ---
DISCOVERED_MCPS=()
if [ -f "$OPENCODE_CONFIG" ]; then
  while IFS='|' read -r name cmd; do
    [ -n "$name" ] && DISCOVERED_MCPS+=("$name|$cmd")
  done < <(node -e "
const fs=require('fs');
try {
  const t=fs.readFileSync('$OPENCODE_CONFIG','utf8');
  const s=t.replace(/\/\*[\s\S]*?\*\//g,'').replace(/^\s*\/\/.*$/gm,'');
  const j=JSON.parse(s);
  if(j.mcp) Object.entries(j.mcp).filter(([k,v])=>!k.startsWith('_')&&v.enabled===false).forEach(([k,v])=>{const c=Array.isArray(v.command)?v.command.join(' '):(v.url||'');console.log(k+'|'+c);});
} catch(e){}
" 2>/dev/null)
fi

REG_COUNT=${#KNOWN_SKILL[@]}
MCP_COUNT=${#KNOWN_MCP[@]}

# --- Construir JSON en node (evita escapado roto en shell) ---
printf '%s\n' "${DISCOVERED_SKILLS[@]}" > "$TMP_DIR/skills" 2>/dev/null
printf '%s\n' "${DISCOVERED_MCPS[@]}" > "$TMP_DIR/mcps" 2>/dev/null
node -e "
const fs=require('fs');
const sk=fs.readFileSync('$TMP_DIR/skills','utf8').split('\n').filter(Boolean).map(l=>{const i=l.indexOf('|');const name=l.slice(0,i);const desc=l.slice(i+1);return {name,desc,load:'skill(name=\"'+name+'\")'};});
const mc=fs.readFileSync('$TMP_DIR/mcps','utf8').split('\n').filter(Boolean).map(l=>{const i=l.indexOf('|');return {name:l.slice(0,i),cmd:l.slice(i+1),action:'enable only in project config'};});
const out={summary:{local_skills_total:$SKILL_TOTAL,known_skills:$REG_COUNT,registered_mcps:$MCP_COUNT,discovered_skills:sk.length,discovered_mcps:mc.length},discovered_skills:sk,discovered_mcps:mc};
console.log(JSON.stringify(out,null,2));
"
