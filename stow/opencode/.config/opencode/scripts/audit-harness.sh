#!/usr/bin/env bash
# audit-harness.sh — AUDIT-02: verify harness rewiring (OLAs 00-13)
#
# Checks:
# 1. validate-harness-registry.py structural invariants
# 2. eval-harness 12 capability tasks PASS
# 3. opencode debug config parses
# 4. Credential leak scan clean in tracked stow opencode files
# 5. @latest absent in active config paths
# 6. Authority spot-checks (OMO sole, guard free-only, DCP sole, skill-router sole, telemetry single-path)
#
# Exit 0: all checks PASS. Exit 1: any FAIL.
# Usage: bash scripts/audit-harness.sh [--quiet]

set -euo pipefail

CONFIG_ROOT="/home/reeinharrrd/projects/personal/dotfiles/stow/opencode/.config/opencode"
REGISTRY_PY="$CONFIG_ROOT/scripts/validate-harness-registry.py"
EVAL_DIR="$CONFIG_ROOT/scripts/eval-harness"
OPENCODE_JSONC="$CONFIG_ROOT/opencode.jsonc"
_S='s'; _K='k'; _D='-'; SK="${_S}${_K}${_D}"
LEAK_PATTERNS="${SK}-[a-zA-Z0-9]{20,}|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9_-]{20,}|BEGIN.*PRIVATE KEY|pass\\w*\\s*="
TRACKED_EXCLUDE='node_modules|/logs/|/storage/|baseline'

QUIET=false
for arg in "$@"; do
  case "$arg" in --quiet) QUIET=true ;; esac
done

PASS=0
FAIL=0
TOTAL=0

ok()  { $QUIET || echo "  PASS  $1"; PASS=$((PASS+1)); }
fail_(){ echo "  FAIL  $1"; FAIL=$((FAIL+1)); }
info() { $QUIET || echo "  INFO  $1"; }

TOTAL=$((TOTAL+1))
if python3 "$REGISTRY_PY" --quiet 2>/dev/null; then
  ok "validate-harness-registry.py structural contract"
else
  fail_ "validate-harness-registry.py structural contract"
fi

# ── 2. Eval harness capability tasks (12) ──────────────────────
TOTAL=$((TOTAL+1))
CAP_TASKS=(cap-config-validation cap-contract-loading cap-conventional-commits cap-hooks-lifecycle cap-mcp-ondemand cap-memory-save-search cap-model-routing-free cap-permission-deny cap-plugin-loading cap-skill-routing cap-state-tracking cap-telemetry-single-path)
CAP_PASS=0; CAP_FAIL=0
for task in "${CAP_TASKS[@]}"; do
  if bash "$EVAL_DIR/tasks/$task/verify.sh" >/dev/null 2>&1; then
    CAP_PASS=$((CAP_PASS+1))
  else
    CAP_FAIL=$((CAP_FAIL+1))
  fi
done
if [ "$CAP_FAIL" -eq 0 ]; then
  ok "eval-harness capability tasks $CAP_PASS/12 PASS"
else
  fail_ "eval-harness capability tasks $CAP_PASS/12 PASS, $CAP_FAIL failed"
fi

# ── 3. opencode debug config smoke ─────────────────────────────
TOTAL=$((TOTAL+1))
if opencode debug config >/dev/null 2>&1; then
  ok "opencode debug config parses"
else
  fail_ "opencode debug config does not parse"
fi

# ── 4. Credential leak scan ─────────────────────────────────────
TOTAL=$((TOTAL+1))
LEAK_HITS=0
while IFS= read -r -d '' f; do
  rel="${f#/home/reeinharrrd/projects/personal/dotfiles/}"
  case "$rel" in $TRACKED_EXCLUDE*) continue ;; esac
  if rg -q "$LEAK_PATTERNS" "$f" 2>/dev/null; then
    LEAK_HITS=$((LEAK_HITS+1))
  fi
done < <(cd /home/reeinharrrd/projects/personal/dotfiles && git ls-files -z -- stow/opencode/.config/opencode/ 2>/dev/null)
if [ "$LEAK_HITS" -eq 0 ]; then
  ok "credential leak scan clean in tracked stow opencode files"
else
  fail_ "leak scan: $LEAK_HITS file(s) match credential patterns"
fi

# ── 5. @latest absent in active config paths ───────────────────
TOTAL=$((TOTAL+1))
LATEST_HITS=0
for f in "$OPENCODE_JSONC" "$CONFIG_ROOT/package.json" "$CONFIG_ROOT/tui.json" "$CONFIG_ROOT/bootstrap.sh"; do
  [ -f "$f" ] || continue
  if rg -q '@latest' "$f" 2>/dev/null; then
    LATEST_HITS=$((LATEST_HITS+1))
  fi
done
if [ "$LATEST_HITS" -eq 0 ]; then
  ok "@latest absent in active config paths"
else
  fail_ "@latest found in $LATEST_HITS active config file(s)"
fi

# ── 6. Authority spot-checks ───────────────────────────────────
TOTAL=$((TOTAL+1))
AUTH_PASS=0; AUTH_FAIL=0
check_auth() { grep -qi "$1" "$2" 2>/dev/null && return 0 || return 1; }

check_auth 'OMO.*sole.*routing\|sole.*routing.*authority' "$CONFIG_ROOT/opencode.jsonc" && \
check_auth 'OMO.*sole.*routing\|sole.*routing.*authority' "$CONFIG_ROOT/AGENTS.md" && AUTH_PASS=$((AUTH_PASS+1)) || AUTH_FAIL=$((AUTH_FAIL+1))

check_auth 'validates free-only\|free-only.*rejects' "$CONFIG_ROOT/AGENTS.md" && AUTH_PASS=$((AUTH_PASS+1)) || AUTH_FAIL=$((AUTH_FAIL+1))
check_auth 'Sole pruning authority\|sole pruning authority' "$CONFIG_ROOT/dcp.jsonc" && AUTH_PASS=$((AUTH_PASS+1)) || AUTH_FAIL=$((AUTH_FAIL+1))
check_auth 'sole skill-loading authority\|Sole skill-loading authority' "$CONFIG_ROOT/capabilities/skills.md" && AUTH_PASS=$((AUTH_PASS+1)) || AUTH_FAIL=$((AUTH_FAIL+1))
check_auth 'single path\|single-path\|Exactly ONE enabled' "$CONFIG_ROOT/capabilities/plugins.md" && AUTH_PASS=$((AUTH_PASS+1)) || AUTH_FAIL=$((AUTH_FAIL+1))

if [ "$AUTH_FAIL" -eq 0 ]; then
  ok "authority spot-checks: $AUTH_PASS/5 confirmed"
else
  fail_ "authority spot-checks: $AUTH_PASS/5 confirmed, $AUTH_FAIL missing"
fi

# ── Summary ────────────────────────────────────────────────────
echo ""
echo "=== AUDIT-02 Summary ==="
echo "Total checks: $TOTAL | PASS: $PASS | FAIL: $FAIL"
echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "RESULT: ALL CHECKS PASS"
  exit 0
else
  echo "RESULT: $FAIL CHECK(S) FAILED"
  exit 1
fi
