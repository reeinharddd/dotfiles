#!/usr/bin/env bash
# end-day.sh — Cierre de dia: registra tiempo, resumen, journal

set -euo pipefail

echo "============================================"
echo "  🌙 Cierre del dia — $(date '+%A %d %B %Y')"
echo "============================================"
echo ""

# 1. Detener timewarrior si esta corriendo
if command -v timew &>/dev/null; then
  if timew list 2>/dev/null | grep -q "@"; then
    timew stop 2>/dev/null
    echo "⏱  Timewarrior detenido."
  fi
  echo ""
  echo "📊 Resumen de tiempo hoy:"
  timew summary today 2>/dev/null | tail -n +3
  echo ""
fi

# 2. Abrir journal rapido
echo "📝 Escribe un par de lineas sobre tu dia (Enter para saltar):"
read -r -p "  >> " entry
if [ -n "$entry" ]; then
  jrnl today: "$entry" 2>/dev/null
  echo "✅ Anotado en journal."
fi
echo ""

# 3. Revisar tareas completadas hoy
if command -v task &>/dev/null; then
  echo "✅ Tareas completadas hoy:"
  task completed end:today 2>/dev/null | grep -E "^\d" || echo "  (ninguna)"
  echo ""
fi

# 4. Sugerencia de tareas para manana
if command -v task &>/dev/null; then
  echo "🎯 Top tareas para manana:"
  task list limit:5 2>/dev/null
  echo ""
fi

echo "============================================"
echo "  Buenas noches!"
echo "============================================"
