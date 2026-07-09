#!/bin/bash
# Launch Brave with remote debugging for Chrome DevTools MCP

BRAVE_PATH="/snap/brave/current/opt/brave.com/brave/brave"
DEBUG_PORT=9222
USER_DATA_DIR="/tmp/brave-debug-profile"

# Kill any existing Brave debug instances
pkill -f "remote-debugging-port=$DEBUG_PORT" 2>/dev/null || true

# Launch Brave with remote debugging
exec "$BRAVE_PATH" \
  --remote-debugging-port=$DEBUG_PORT \
  --user-data-dir="$USER_DATA_DIR" \
  --no-first-run \
  --no-default-browser-check \
  --disable-background-timer-throttling \
  --disable-renderer-backgrounding \
  --disable-backgrounding-occluded-windows \
  "$@"