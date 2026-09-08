#!/usr/bin/env bash
# discover-capabilities.sh — Lista capacidades disponibles en /tools SIN cargarlas.
# Uso: discover-capabilities [--json] [filter]
# El agente usa esto para decidir que symlinkar per-project bajo demanda.
set -euo pipefail

TOOLS_DIR="${HOME}/tools"
OC_DIR="${HOME}/.config/opencode"
JSON=0
[ "${1:-}" = "--json" ] && { JSON=1; shift; }
FILTER="${1:-}"

echo "=== opencode capability registry ==="
echo ""
echo "## Skills disponibles (en /tools, listos para symlink)"
echo "----------------------------------------"
for d in "${TOOLS_DIR}"/*/skills/*/; do
  [ -d "$d" ] || continue
  name=$(basename "$d")
  skillmd="${d}SKILL.md"
  [ -f "$skillmd" ] || continue
  desc=$(grep -m1 -E '^(description|^# )' "$skillmd" 2>/dev/null | head -1 | sed 's/^# *//; s/^description: *//')
  linked=""
  [ -L "${OC_DIR}/skills/${name}" ] && linked=" [LINKED]"
  if [ -z "$FILTER" ] || echo "$name $desc" | grep -qi "$FILTER"; then
    printf "  - %-28s %s%s\n" "$name" "${desc:-no desc}" "$linked"
  fi
done

echo ""
echo "## Commands disponibles (en /tools/*/commands)"
echo "----------------------------------------"
for c in "${TOOLS_DIR}"/*/commands/*.md; do
  [ -f "$c" ] || continue
  name=$(basename "$c" .md)
  if [ -z "$FILTER" ] || echo "$name" | grep -qi "$FILTER"; then
    printf "  - %s\n" "$name"
  fi
done

echo ""
echo "## Agents disponibles (en /tools/opencode-agents)"
echo "----------------------------------------"
for a in "${TOOLS_DIR}"/opencode-agents/*.md; do
  [ -f "$a" ] || continue
  name=$(basename "$a" .md)
  linked=""
  [ -L "${OC_DIR}/agents/${name}" ] && linked=" [LINKED]"
  if [ -z "$FILTER" ] || echo "$name" | grep -qi "$FILTER"; then
    printf "  - %s%s\n" "$name" "$linked"
  fi
done

echo ""
echo "## MCP servers (binarios en ~/.local/bin)"
echo "----------------------------------------"
for m in "${HOME}"/.local/bin/*mcp*; do
  [ -x "$m" ] || continue
  name=$(basename "$m")
  printf "  - %s\n" "$name"
done

echo ""
echo "=== Uso: para activar per-project, symlink al .opencode/ del proyecto ==="
echo "  ln -sf /tools/<repo>/skills/<name> .opencode/skills/<name>"
