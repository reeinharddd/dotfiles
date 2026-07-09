#!/usr/bin/env bash
# notify.sh — Notificaciones desktop + push al telefono
# Usage: notify [title] [message] [ntfy-topic]

set -euo pipefail

TITLE="${1:-Notificacion}"
MESSAGE="${2:-}"
NTFY_TOPIC="${3:-}"

# Desktop notification
notify-send -t 6000 "$TITLE" "$MESSAGE"

# Push notification via ntfy (si hay topic configurado)
if [ -n "$NTFY_TOPIC" ]; then
  ntfy publish "$NTFY_TOPIC" "$TITLE: $MESSAGE" 2>/dev/null || true
elif [ -f "$HOME/.config/ntfy/topic" ]; then
  topic=$(cat "$HOME/.config/ntfy/topic")
  ntfy publish "$topic" "$TITLE: $MESSAGE" 2>/dev/null || true
fi
