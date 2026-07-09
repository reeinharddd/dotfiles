#!/usr/bin/env bash
# life-agent.sh — Asistente personal AI
# Abre una sesion de opencode con contexto de vida
# 
# Usage:
#   life-agent                      → Sesion interactiva
#   life-agent "pregunta"           → Respuesta directa
#   life-agent task "descripcion"   → Agrega tarea rapida via AI

set -euo pipefail

# Cargar contexto del dia
CONTEXT=$(mktemp)
cat > "$CONTEXT" << 'EOF'
Eres "Erik" (tu nombre es Erik Alfonso Beltran Ramirez).
Eres un asistente personal integrado en el sistema del usuario.

Tienes acceso a:
- taskwarrior (gestion de tareas: task add/list/done)
- timewarrior (tracking de tiempo: timew start/stop/summary)
- jrnl (journaling: jrnl today: ... / jrnl -on DATE)
- systemd (timers y recordatorios)
- Notificaciones desktop (notify-send)
- Push al telefono (ntfy)
- El sistema de archivos del usuario

Puedes ayudar con:
- Gestion de tareas y proyectos
- Recordatorios y alarmas
- Organizacion personal
- Productividad y enfoque
- Resumen diario/semanal
- Cualquier pregunta sobre el sistema

Contexto del sistema:
EOF

# Add system context
echo "Fecha: $(date '+%A %d %B %Y')" >> "$CONTEXT"
echo "Directorios: projects, personal/dotfiles" >> "$CONTEXT"
task summary 2>/dev/null >> "$CONTEXT" || true

# Invoke claude code with context
opencode "$(cat "$CONTEXT")" "$@"

/usr/bin/rm "$CONTEXT"
