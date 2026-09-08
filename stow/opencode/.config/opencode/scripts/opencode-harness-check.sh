#!/usr/bin/env bash
# Read-only health and drift check for the global OpenCode harness.
set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
REGISTRY="$CONFIG_DIR/harness-registry.jsonc"
DOTFILES_RUNTIME="$HOME/projects/personal/dotfiles/stow/opencode/.config/opencode/opencode.jsonc"
errors=0
warnings=0

ok() { printf '  OK   %s\n' "$1"; }
warn() { printf '  WARN %s\n' "$1"; warnings=$((warnings + 1)); }
fail() { printf '  FAIL %s\n' "$1"; errors=$((errors + 1)); }

echo '=== OpenCode Harness Check (read-only) ==='

if command -v opencode >/dev/null 2>&1 && opencode debug config >/tmp/opencode-harness-config.$$ 2>/tmp/opencode-harness-config.err; then
  ok 'effective OpenCode config parses'
else
  fail 'effective OpenCode config does not parse'
fi
rm -f /tmp/opencode-harness-config.$$ /tmp/opencode-harness-config.err

for file in "$REGISTRY" "$CONFIG_DIR/dcp.jsonc" "$CONFIG_DIR/hooks.yaml"; do
  [ -f "$file" ] && ok "present: ${file#$CONFIG_DIR/}" || fail "missing: ${file#$CONFIG_DIR/}"
done

for bin in opencode engram dcg; do
  command -v "$bin" >/dev/null 2>&1 && ok "binary: $bin" || fail "missing binary: $bin"
done

if [ -d "$CONFIG_DIR/skills" ]; then
  broken=0
  while IFS= read -r skill; do
    [ -f "$skill/SKILL.md" ] || broken=$((broken + 1))
  done < <(printf '%s\n' "$CONFIG_DIR"/skills/* 2>/dev/null)
  [ "$broken" -eq 0 ] && ok 'core skills are intact' || fail "$broken core skills are broken"
fi

codegraph_dir="$HOME/.omo/codegraph/projects"
if [ -d "$codegraph_dir" ]; then
  bytes=$(du -sb "$codegraph_dir" 2>/dev/null | awk '{print $1}')
  if [ "${bytes:-0}" -gt 2147483648 ]; then
    warn "CodeGraph exceeds 2 GiB (${bytes} bytes); review retention before pruning"
  else
    ok 'CodeGraph is below the configured 2 GiB review threshold'
  fi
fi

if [ "$(stat -L -c '%a' "$CONFIG_DIR/opencode.jsonc" 2>/dev/null || echo 0)" != 600 ]; then
  warn 'opencode.jsonc is not mode 600; verify it contains no inline credentials'
fi

if [ -f "$DOTFILES_RUNTIME" ] && ! cmp -s "$CONFIG_DIR/opencode.jsonc" "$DOTFILES_RUNTIME"; then
  warn 'active runtime config differs from the dotfiles copy; review drift before re-stowing'
fi

if rg -n '"apiKey"[[:space:]]*:[[:space:]]*"(sk-|gsk_|AQ\.|jRS|[A-Za-z0-9]{24,})' "$CONFIG_DIR/opencode.jsonc" >/dev/null 2>&1; then
  warn 'possible inline provider credential found in opencode.jsonc; migrate it to {env:VAR}'
fi

doctor="$CONFIG_DIR/scripts/opencode-capability-doctor"
if [ -x "$doctor" ]; then
  if "$doctor"; then
    ok 'capability doctor passed'
  else
    warn 'capability doctor reported degraded capabilities'
  fi
fi

project_audit="$CONFIG_DIR/scripts/opencode-project-audit"
if [ -x "$project_audit" ] && [ "$PWD" != "$CONFIG_DIR" ]; then
  "$project_audit" "$PWD" || warn 'project audit could not complete'
fi

manifest_check="$CONFIG_DIR/plugins/regenerate-manifests.py"
if [ -f "$manifest_check" ]; then
  if python3 "$manifest_check" --check >/tmp/opencode-manifest-check.$$ 2>&1; then
    ok 'bodega manifests are clean (no dead paths)'
  else
    warn 'bodega manifests contain dead paths; run regenerate-manifests.py to refresh'
  fi
  rm -f /tmp/opencode-manifest-check.$$
fi

duplicates=$(rg -o 'duplicate skill name' "$CONFIG_DIR/logs" "$HOME/.opencode-notify.log" 2>/dev/null | wc -l || true)
[ "$duplicates" -gt 0 ] && warn "duplicate skill warnings found in logs: $duplicates" || ok 'no duplicate skill warnings in checked logs'

echo
printf 'Result: %s errors, %s warnings\n' "$errors" "$warnings"
exit "$errors"
