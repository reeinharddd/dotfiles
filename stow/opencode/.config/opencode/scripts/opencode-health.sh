#!/usr/bin/env bash
# OpenCode health check. Read-only; delegates policy checks to the harness validator.
set -uo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
CHECK="$CONFIG_DIR/scripts/opencode-harness-check.sh"

if [ -x "$CHECK" ]; then
  "$CHECK"
else
  echo "Missing harness validator: $CHECK"
  exit 1
fi

echo
echo '=== Runtime ==='
opencode --version 2>/dev/null || true
engram doctor --project opencode 2>/dev/null || true
dcg --version 2>/dev/null || true

echo
echo '=== Effective config ==='
if opencode debug config >/dev/null 2>&1; then
  echo '  OK   opencode debug config'
else
  echo '  FAIL opencode debug config'
  exit 1
fi
