#!/usr/bin/env bash
# daily-review.sh — Revision diaria automatizada
# Corre al iniciar el dia (via systemd timer)

set -euo pipefail

echo "============================================"
echo "  ☀️  Buenos dias, Erik — $(date '+%A %d %B %Y')"
echo "============================================"
echo ""

# 1. Tareas de hoy
echo "📋 Tareas pendientes:"
if command -v task &>/dev/null; then
  task list 2>/dev/null || echo "  (taskwarrior sin tareas)"
fi
echo ""

# 2. Tareas vencidas
echo "⚠️  Vencidas:"
if command -v task &>/dev/null; then
  task overdue 2>/dev/null || echo "  (ninguna)"
fi
echo ""

# 3. Clima (via wttr.in)
echo "🌤  Clima hoy:"
curl -s "wttr.in?format=%C+%t+%w" 2>/dev/null || echo "  (no disponible)"
echo ""

# 4. Recordatorios del dia
echo "🔔 Recordatorios:"
if [ -f "$HOME/.local/share/reminders/today.txt" ]; then
  cat "$HOME/.local/share/reminders/today.txt"
else
  echo "  (ninguno configurado)"
fi
echo ""

# 5. Estado del sistema
echo "💻 Sistema:"
echo "  RAM: $(free -h | awk '/Mem:/ {print $3 "/" $2}')"
echo "  CPU: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'N/A')"
echo "  Bateria: $(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)% $(cat /sys/class/power_supply/BAT0/status 2>/dev/null)"
echo ""

# 6. Frase del dia
echo "💡 Tip del dia:"
TIPS=(
  "Divide las tareas grandes en pasos pequenos."
  "Revisa tu @waiting list semanalmente."
  "Un pomodoro a la vez. No multitasking."
  "Actualiza tu journal cada noche, aunque sean 2 lineas."
  "Prioriza por impacto, no por urgencia."
  "Si tomas menos de 2 min, hazlo ahora."
)
RAND=$((RANDOM % ${#TIPS[@]}))
echo "  \"${TIPS[$RAND]}\""
echo ""
echo "============================================"
