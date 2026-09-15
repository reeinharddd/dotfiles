#!/usr/bin/env bash
# Restart herdr server: stop 0.8.2 → start 0.9.0 on session main.
# Run AFTER agents are idle. Restores snapshot layout + resumes opencode
# sessions via integration v11 (opencode --session <id>).
set -u

SOCKET="$HOME/.config/herdr/sessions/main/herdr.sock"

if pgrep -f "herdr server" >/dev/null; then
	HERDR_SOCKET_PATH="$SOCKET" herdr server stop
	sleep 3
fi

if pgrep -f "herdr server" >/dev/null; then
	echo "ERROR: server did not stop" >&2
	exit 1
fi

herdr --session main --detach >/dev/null 2>&1 || herdr session attach main --detach >/dev/null 2>&1 || true
sleep 2
herdr status
herdr --version
echo "RESTART DONE"
