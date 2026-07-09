#!/usr/bin/env bash
# pomodoro.sh — Focus timer with notifications
# Usage: pomodoro [minutes] [task-name]
# Default: 25 minutes "Focus session"

set -euo pipefail

MINUTES="${1:-25}"
TASK="${2:-Focus session}"
SECONDS=$((MINUTES * 60))
WORK_DIR="${POMODORO_WORK_DIR:-$HOME/projects}"

notify() {
  local title="$1"
  local msg="$2"
  notify-send -t 5000 "$title" "$msg"
  echo "$msg"
}

notify "🍅 Pomodoro iniciado" "$MINUTES min — $TASK"

# Loop de cuenta regresiva con feedback cada 5 min
for ((i=MINUTES; i>0; i--)); do
  if ((i % 5 == 0)); then
    notify-send -t 2000 "🍅" "$i min restantes — $TASK"
  fi
  sleep 60
done

# Fin del pomodoro
notify "🍅 Pomodoro completo!" "Bien hecho! Toma 5 min de descanso."

# Reproducir sonido si hay speaker
if command -v speaker-test &>/dev/null; then
  paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null || true
fi

# Preguntar si registro tiempo en timewarrior
read -r -p "Registrar este pomodoro en timewarrior? (y/N): " reply
if [[ "$reply" =~ ^[Yy]$ ]]; then
  timew start "$TASK"
  echo "⏱ Timewarrior tracking started for: $TASK"
fi
