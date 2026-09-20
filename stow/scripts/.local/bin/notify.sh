#!/usr/bin/env bash
# notify.sh — Send notification via ntfy
# Usage: notify.sh "message"

set -euo pipefail

TOPIC_FILE="$HOME/.config/ntfy/topic"

if [ ! -f "$TOPIC_FILE" ]; then
    echo "No ntfy topic configured at $TOPIC_FILE"
    exit 1
fi

TOPIC=$(cat "$TOPIC_FILE")
MESSAGE="${1:-Notificación sin mensaje}"

ntfy publish "$TOPIC" "$MESSAGE" 2>/dev/null || true