#!/bin/bash
# ┌──────────────────────────────────────────────────────────────────┐
# │ Instala systemd timer para backup automatico con restic           │
# │ Llama a este script desde `just backup-install-timer`               │
# └──────────────────────────────────────────────────────────────────┘

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SCRIPT="$SCRIPT_DIR/backup-restic.sh"
SERVICE_FILE="$HOME/.config/systemd/user/restic-backup.service"
TIMER_FILE="$HOME/.config/systemd/user/restic-backup.timer"

if [ ! -f "$BACKUP_SCRIPT" ]; then
    echo "ERROR: backup script not found at $BACKUP_SCRIPT"
    exit 1
fi

mkdir -p ~/.config/systemd/user

cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Restic backup service
After=network-online.target

[Service]
Type=oneshot
ExecStart=$BACKUP_SCRIPT
Nice=10
EOF

cat > "$TIMER_FILE" << EOF
[Unit]
Description=Restic backup timer (daily 3am)

[Timer]
OnCalendar=*-*-* 03:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now restic-backup.timer
echo "Timer instalado y habilitado:"
systemctl --user status restic-backup.timer --no-pager | head -10
