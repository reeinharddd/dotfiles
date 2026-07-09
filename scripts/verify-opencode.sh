#!/usr/bin/env bash
# verify-opencode.sh — Verifies opencode config integrity
#
# Checks:
# 1. No project has modified base config files (opencode.json, AGENTS.md)
# 2. Symlinks from ~/.config/opencode/ → dotfiles are intact
# 3. Dotfiles are in sync with actual config
# 4. No secret/API keys leaked in git-tracked files
#
# Usage: ./scripts/verify-opencode.sh [--fix] [--quiet]

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_DIR="$DOTFILES_DIR/configs/opencode"
LIVE_DIR="$HOME/.config/opencode"
EXIT_CODE=0
QUIET=false
FIX=false

for arg in "$@"; do
  case "$arg" in
    --quiet) QUIET=true ;;
    --fix) FIX=true ;;
  esac
done

info()  { $QUIET || echo "  INFO  $*"; }
warn()  { echo "  WARN  $*"; EXIT_CODE=1; }
fail()  { echo "  FAIL  $*"; EXIT_CODE=1; }
ok()    { $QUIET || echo "  OK    $*"; }

echo "==> Verifying opencode config integrity"
echo ""

# --- Check 1: Symlink integrity ---
echo "--- Symlink integrity ---"
declare -A SYMLINKS=(
  ["opencode.json"]="$CONFIG_DIR/opencode.json"
  ["opencode.jsonc"]="$CONFIG_DIR/opencode.jsonc"
  ["AGENTS.md"]="$CONFIG_DIR/AGENTS.md"
  ["tui.json"]="$CONFIG_DIR/tui.json"
  ["plugins/crg-plugin.ts"]="$CONFIG_DIR/plugins/crg-plugin.ts"
  ["plugins/engram.ts"]="$CONFIG_DIR/plugins/engram.ts"
  ["plugins/model-variants.ts"]="$CONFIG_DIR/plugins/model-variants.ts"
  ["plugins/skill-registry.ts"]="$CONFIG_DIR/plugins/skill-registry.ts"
  ["plugins/caveman"]="$CONFIG_DIR/plugins/caveman"
  ["plugins/ctx-analyze"]="$CONFIG_DIR/plugins/ctx-analyze"
  ["commands/detect.md"]="$CONFIG_DIR/commands/detect.md"
  ["skills/project-auto-detect"]="$CONFIG_DIR/skills/project-auto-detect"
  ["skills/system-context"]="$CONFIG_DIR/skills/system-context"
)

for local_path in "${!SYMLINKS[@]}"; do
  expected_target="${SYMLINKS[$local_path]}"
  full_path="$LIVE_DIR/$local_path"

  if [ ! -e "$full_path" ] && [ ! -L "$full_path" ]; then
    fail "$full_path — does not exist"
    continue
  fi

  if [ ! -L "$full_path" ]; then
    fail "$full_path — is NOT a symlink (regular file/dir)"
    if $FIX; then
      warn "  -> Run deploy.sh to fix"
    fi
    continue
  fi

  actual_target=$(readlink "$full_path")
  if [ "$actual_target" != "$expected_target" ]; then
    fail "$full_path -> $actual_target (expected: $expected_target)"
  else
    ok "$full_path -> $actual_target"
  fi
done

echo ""

# --- Check 2: No project has local opencode.json or AGENTS.md that shadows base ---
echo "--- Project-level override audit ---"
PROJECTS_DIR="$HOME/projects"
if [ -d "$PROJECTS_DIR" ]; then
  while IFS= read -r -d '' project_file; do
    project_dir=$(dirname "$project_file")
    project_name=$(basename "$project_dir")
    # Check if it has an opencode.json (which could override MCP/server config)
    if [ -f "$project_dir/opencode.json" ]; then
      warn "$project_name has local opencode.json — may override MCP/server config"
    fi
    # Check if project AGENTS.md has dangerous overrides
    if [ -f "$project_dir/AGENTS.md" ]; then
      if grep -qi "opencode.json" "$project_dir/AGENTS.md" 2>/dev/null; then
        warn "$project_name/AGENTS.md references opencode.json — may modify base config"
      fi
      # Check for MCP override attempts
      if grep -qi '"mcp"' "$project_dir/opencode.json" 2>/dev/null; then
        warn "$project_name/opencode.json defines MCP servers — may conflict with base"
      fi
    fi
  done < <(find "$PROJECTS_DIR" -maxdepth 3 -name "opencode.json" -o -name "AGENTS.md" -print0 2>/dev/null)
else
  info "No projects directory found at $PROJECTS_DIR"
fi

echo ""

# --- Check 3: Dotfiles are clean (no uncommitted changes to opencode configs) ---
echo "--- Dotfiles git status ---"
cd "$DOTFILES_DIR"
if git diff --name-only -- configs/opencode/ 2>/dev/null | grep -q .; then
  warn "dotfiles has uncommitted changes to opencode configs:"
  git diff --stat -- configs/opencode/ 2>/dev/null | sed 's/^/    /'
else
  ok "dotfiles opencode configs are clean (no uncommitted changes)"
fi

echo ""

# --- Check 4: No leaked secrets in tracked files ---
echo "--- Secrets leak check ---"
LEAKS=0
while IFS= read -r -d '' tracked_file; do
  rel_path=$(echo "$tracked_file" | sed "s|$DOTFILES_DIR/||")
  # Skip binary files
  case "$tracked_file" in
    *.png|*.jpg|*.jpeg|*.gif|*.svg|*.ico|*.woff|*.woff2) continue ;;
  esac
  # Check for potential API keys/tokens (heuristic)
  if grep -Eq '(sk-[a-zA-Z0-9]{20,}|api[_-]?key["\s:=]+["\''][A-Za-z0-9]{16,}|token["\s:=]+["\''][A-Za-z0-9]{16,})' "$tracked_file" 2>/dev/null; then
    warn "Possible secret leak in $rel_path"
    LEAKS=$((LEAKS + 1))
  fi
done < <(cd "$DOTFILES_DIR" && git ls-files -z -- configs/opencode/ 2>/dev/null)

if [ "$LEAKS" -eq 0 ]; then
  ok "No secrets detected in tracked opencode configs"
fi

echo ""
echo "==> Done. Exit code: $EXIT_CODE"
exit "$EXIT_CODE"
