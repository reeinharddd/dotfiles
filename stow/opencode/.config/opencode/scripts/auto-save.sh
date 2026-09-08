#!/usr/bin/env bash
# auto-save.sh — Project-level auto-save helper
# Runs on session.idle hook. Saves context state to .opencode/auto-save/
# Called by hooks.yaml in core or per-project

set -euo pipefail

PROJECT_DIR="${OPENCODE_PROJECT_DIR:-$(pwd)}"
SAVE_DIR="$PROJECT_DIR/.opencode/auto-save"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "$SAVE_DIR"

# Save recent git history (last 5 commits)
if git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    git -C "$PROJECT_DIR" log --oneline -5 > "$SAVE_DIR/git-log-$TIMESTAMP.txt" 2>/dev/null
    git -C "$PROJECT_DIR" diff --stat HEAD~1 > "$SAVE_DIR/git-diffstat-$TIMESTAMP.txt" 2>/dev/null
fi

# Save session state note (just timestamp, no heavy files)
echo "Auto-save at $TIMESTAMP" > "$SAVE_DIR/last-save.txt"

# Keep only last 20 saves
ls -1t "$SAVE_DIR"/*.txt 2>/dev/null | tail -n +21 | xargs rm -f 2>/dev/null

echo "[auto-save] Saved at $TIMESTAMP"
